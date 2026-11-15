--[[
	RocketExplorer — "Explore rocket" do Saturn V (docs/museu-foguete-interativo.md).

	- enter(model, data, cb): câmera Scriptable vai, numa transição curta, para um ponto lateral
	  (um pouco para o lado dos motores) que enquadra o modelo inteiro na área livre da tela
	  (à esquerda do painel). O ponto é escolhido entre vários candidatos: o primeiro que cabe
	  com o campo de visão atual e tem linha de visão livre (raycast) até o foguete; se nenhum
	  couber, abre o campo de visão até 90°.
	- Regiões clicáveis: uma caixa invisível por componente (data.Explore[i].Region), feita das
	  peças reais do modelo, local ao jogador (na câmera); não muda o foguete nem colide.
	  Mouse: passar por cima destaca e mostra o nome; clique seleciona. Toque: toque seleciona.
	  Controle: a lista do painel (o PanelController põe a seleção da GUI nela); B volta.
	  Pontos discretos marcam cada parte (também clicáveis).
	- exit(): devolve câmera (tipo, alvo, campo de visão), controles de toque e movimento.
	  Sai sozinho ao renascer, ao morrer, se a câmera for trocada ou se a GUI sumir.
	Tudo é local: os outros jogadores não veem nada disso.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local PPS = game:GetService("ProximityPromptService")

local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))

local Explorer = {}

local player = Players.LocalPlayer
local st = nil -- estado enquanto ativo

local HOVER = Color3.new(1, 1, 1)
local SELECTED = UI.C.accent

local function reduceMotion()
	return State.settings().reduceMotion == true
end

---------------------------------------------------------------------------------
-- Regiões
---------------------------------------------------------------------------------

local function regionParts(model, region)
	local stage = region.Stage and model:FindFirstChild(region.Stage)
	if not stage then return {} end
	local roots = {}
	if region.Only then
		for _, n in region.Only do
			local c = stage:FindFirstChild(n)
			if c then table.insert(roots, c) end
		end
	else
		roots = { stage }
	end
	local except = {}
	for _, n in region.Except or {} do
		local c = stage:FindFirstChild(n)
		if c then table.insert(except, c) end
	end
	local out = {}
	for _, r in roots do
		local list = r:GetDescendants()
		if r:IsA("BasePart") then table.insert(list, r) end
		for _, d in list do
			if d:IsA("BasePart") and d.Transparency < 1 then
				local keep = true
				for _, ex in except do
					if d == ex or d:IsDescendantOf(ex) then keep = false break end
				end
				if keep and region.Prefixes then
					keep = false
					for _, pre in region.Prefixes do
						if string.sub(d.Name, 1, #pre) == pre then keep = true break end
					end
				end
				if keep then table.insert(out, d) end
			end
		end
	end
	return out
end

-- caixa das peças no referencial F (orientação do modelo)
local function boxOf(parts, F)
	local mn, mx = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in parts do
		local h = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local l = F:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
					mn, mx = mn:Min(l), mx:Max(l)
				end
			end
		end
	end
	if mn.X == math.huge then return nil end
	return F * CFrame.new((mn + mx) / 2), mx - mn
end

---------------------------------------------------------------------------------
-- Enquadramento
---------------------------------------------------------------------------------

local function corners(cf, size)
	local out, h = {}, size / 2
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				table.insert(out, cf:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
			end
		end
	end
	return out
end

-- câmera olhando o centro e girada para a direita, para o foguete ficar no meio da área livre
local function cameraAt(pos, center, tanH, inset)
	local yaw = math.atan(inset * tanH)
	return CFrame.lookAt(pos, center) * CFrame.Angles(0, -yaw, 0)
end

local function fits(pts, camCF, tanV, tanH, inset, margin)
	local xMin, xMax = -1 + margin, 1 - 2 * inset - margin
	for _, c in pts do
		local l = camCF:PointToObjectSpace(c)
		local z = -l.Z
		if z < 1 then return false end
		local x, y = l.X / (z * tanH), l.Y / (z * tanV)
		if x < xMin or x > xMax or y < -1 + margin or y > 1 - margin then return false end
	end
	return true
end

-- menor distância (ao longo de dir) em que o modelo inteiro cabe
local function fitDistance(pts, center, dir, tanV, tanH, inset, margin)
	local lo, hi = 2, 600
	if not fits(pts, cameraAt(center + dir * hi, center, tanH, inset), tanV, tanH, inset, margin) then return nil end
	for _ = 1, 28 do
		local mid = (lo + hi) / 2
		if fits(pts, cameraAt(center + dir * mid, center, tanH, inset), tanV, tanH, inset, margin) then hi = mid else lo = mid end
	end
	return hi
end

local function rayParams(model)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local list = { model, workspace.CurrentCamera }
	for _, pl in Players:GetPlayers() do
		if pl.Character then table.insert(list, pl.Character) end
	end
	local map = workspace:FindFirstChild("NASAComplex")
	local guides = map and map:FindFirstChild("Guides")
	if guides then table.insert(list, guides) end
	rp.FilterDescendantsInstances = list
	return rp
end

-- linha de visão do ponto da câmera até vários pontos do foguete (nada opaco no caminho)
local function clearView(pos, targets, rp)
	for _, t in targets do
		local dir = t - pos
		local from = pos
		for _ = 1, 4 do
			local hit = workspace:Raycast(from, dir, rp)
			if not hit then break end
			-- parede, vidro ou qualquer peça sólida bloqueia (a câmera não pode ficar fora do salão)
			if hit.Instance.CanCollide or hit.Instance.Transparency < 0.7 then return false end
			from = hit.Position + dir.Unit * 0.05
			dir = t - from
		end
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = rp.FilterDescendantsInstances
	for _, p in workspace:GetPartBoundsInRadius(pos, 2, op) do
		if p.CanCollide or p.Transparency < 0.7 then return false end
	end
	return true
end

local function plan(model, data, inset)
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	local aspect = vp.X / math.max(vp.Y, 1)
	local cf, size = model:GetBoundingBox()
	local center = cf.Position
	local pts = corners(cf, size)
	-- eixo do foguete = maior dimensão da caixa; "trás" = lado dos motores
	local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
	local dims = { size.X, size.Y, size.Z }
	local ai = 1
	for i = 2, 3 do if dims[i] > dims[ai] then ai = i end end
	local A = axes[ai]
	-- data.ExploreBack = Attachment no lado dos motores: "trás" aponta para ele
	local back = A
	local anchor = data.ExploreBack and model:FindFirstChild(data.ExploreBack, true)
	if anchor and anchor:IsA("Attachment") and (anchor.WorldPosition - center):Dot(A) < 0 then back = -A end
	local up = Vector3.yAxis
	local side = back:Cross(up)
	if side.Magnitude < 0.1 then side = Vector3.xAxis end
	side = side.Unit
	local L = dims[ai]
	local targets = { center, center + A * L * 0.25, center - A * L * 0.25, center + A * L * 0.45, center - A * L * 0.45 }
	local rp = rayParams(model)
	local margin = 0.06
	-- se não couber na área livre, aceita o painel cobrindo parte da ponta (inset menor)
	for _, ins in { inset, inset * 0.6, 0 } do
	for _, fov in { cam.FieldOfView, 80, 90 } do
		local tanV = math.tan(math.rad(fov) / 2)
		local tanH = tanV * aspect
		for _, phi in { 75, 90, 62, 105, 50, 118, 40, 130, 32 } do
			for _, elev in { 14, 24, 6 } do
				for _, s in { 1, -1 } do
					local p, e = math.rad(phi), math.rad(elev)
					local dir = ((side * s * math.sin(p) + back * math.cos(p)) * math.cos(e) + up * math.sin(e)).Unit
					local d = fitDistance(pts, center, dir, tanV, tanH, ins, margin)
					if d then
						local pos = center + dir * d
						if clearView(pos, targets, rp) then
							return cameraAt(pos, center, tanH, ins), fov
						end
					end
				end
			end
		end
	end
	end
	-- nada livre: vista lateral no ponto mais afastado sem obstáculo, campo de visão aberto
	local dir = (side + up * 0.25).Unit
	local hit = workspace:Raycast(center, dir * 600, rp)
	local d = hit and math.max(8, (hit.Position - center).Magnitude - 3) or 120
	local tanH = math.tan(math.rad(90) / 2) * aspect
	return cameraAt(center + dir * d, center, tanH, inset), 90
end

---------------------------------------------------------------------------------
-- Seleção
---------------------------------------------------------------------------------

local function pick(screenPos)
	if not st then return nil end
	local ray = workspace.CurrentCamera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local include = {}
	for _, r in st.regions do table.insert(include, r.part) end
	local best, bestVol = nil, math.huge
	for _ = 1, 4 do
		rp.FilterDescendantsInstances = include
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000, rp)
		if not hit then break end
		local r = st.byPart[hit.Instance]
		if r then
			local vol = r.part.Size.X * r.part.Size.Y * r.part.Size.Z
			-- caixas que se sobrepõem (motores dentro da saia do estágio): vale a menor
			if vol < bestVol then best, bestVol = r, vol end
		end
		table.remove(include, table.find(include, hit.Instance))
		if #include == 0 then break end
	end
	return best
end

local function setHover(r)
	if not st or st.hover == r then return end
	st.hover = r
	for _, x in st.regions do
		local sel = x == st.selected
		x.box.Visible = sel or x == r
		x.box.Color3 = sel and SELECTED or HOVER
		x.box.LineThickness = sel and 0.2 or 0.1
	end
	if st.tip then
		st.tip.Visible = r ~= nil
		if r then st.tip.Text = r.comp.Name end
	end
end

function Explorer.select(id, fromList)
	if not st then return end
	local r = st.byId[id]
	if not r then return end
	st.selected = r
	for _, x in st.regions do
		local sel = x == r
		x.box.Visible = sel or x == st.hover
		x.box.Color3 = sel and SELECTED or HOVER
		x.box.LineThickness = sel and 0.2 or 0.1
		x.box.SurfaceTransparency = sel and 0.85 or 1
		x.label.Enabled = sel
	end
	if not fromList and st.cb.onSelect then st.cb.onSelect(r.comp) end
end

function Explorer.selectedId()
	return st and st.selected and st.selected.comp.Id or nil
end

---------------------------------------------------------------------------------
-- Entrar / sair
---------------------------------------------------------------------------------

function Explorer.isActive()
	return st ~= nil
end

-- transição calculada no passo de render (sem TweenService): de onde a câmera está até o alvo
local function tweenCamera(goal, fov, t)
	local cam = workspace.CurrentCamera
	if reduceMotion() then t = 0.05 end
	st.move = { from = st.camCF or cam.CFrame, fromFov = cam.FieldOfView, goal = goal, fov = fov, t0 = os.clock(), dur = t }
end

local function stepCamera()
	local m = st.move
	if not m then return end
	local a = math.clamp((os.clock() - m.t0) / m.dur, 0, 1)
	local e = 1 - (1 - a) * (1 - a) -- Quad Out
	st.camCF = m.from:Lerp(m.goal, e)
	st.cam.FieldOfView = m.fromFov + (m.fov - m.fromFov) * e
	if a >= 1 then st.move = nil end
end

-- fração da largura da tela coberta pelo painel (à direita); refaz o enquadramento
function Explorer.setInset(frac)
	if not st then return end
	frac = math.clamp(frac or 0, 0, 0.6)
	if st.inset and math.abs(st.inset - frac) < 0.01 and st.viewport == workspace.CurrentCamera.ViewportSize then return end
	st.inset = frac
	st.viewport = workspace.CurrentCamera.ViewportSize
	local goal, fov = plan(st.model, st.data, frac)
	tweenCamera(goal, fov, st.started and 0.4 or 0.9)
	st.started = true
end

function Explorer.exit()
	local s = st
	if not s then return end
	st = nil
	for _, x in s.cleanup do
		if typeof(x) == "RBXScriptConnection" then x:Disconnect() else pcall(function() x:Destroy() end) end
	end
	pcall(function() RunService:UnbindFromRenderStep("RocketExplorerCamera") end)
	pcall(function() CAS:UnbindAction("RocketExplorerFreeze") end)
	pcall(function() CAS:UnbindAction("RocketExplorerBack") end)
	if s.touchSaved ~= nil then GuiService.TouchControlsEnabled = s.touchSaved end
	if s.promptsSaved ~= nil then PPS.Enabled = s.promptsSaved end
	local cam = workspace.CurrentCamera
	if cam == s.cam then
		cam.FieldOfView = s.saved.fov
		cam.CameraType = s.saved.type == Enum.CameraType.Scriptable and Enum.CameraType.Custom or s.saved.type
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		cam.CameraSubject = hum or s.saved.subject
	end
	if s.cb.onExit then task.defer(s.cb.onExit) end
end

-- cb = { onSelect(comp), onExit(), overUi(Vector2) -> bool }
function Explorer.enter(model, data, cb)
	Explorer.exit()
	local cam = workspace.CurrentCamera
	if not (model and data and data.Explore) then return false end
	-- outra câmera controlada (show do museu, diálogo, missão) está ativa: não briga com ela
	if cam.CameraType ~= Enum.CameraType.Custom then return false, "busy" end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false, "busy" end

	local s = {
		model = model, data = data, cb = cb or {}, cam = cam,
		saved = { type = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView },
		camCF = cam.CFrame, regions = {}, byPart = {}, byId = {}, cleanup = {},
	}
	st = s

	-- regiões e marcadores (locais, na câmera)
	local folder = Instance.new("Folder")
	folder.Name = "RocketExplorer"
	folder.Parent = cam
	table.insert(s.cleanup, folder)
	local F = model:GetPivot().Rotation
	for i, comp in data.Explore do
		local parts = regionParts(model, comp.Region or {})
		local cf, size = boxOf(parts, F)
		if cf then
			local p = Instance.new("Part")
			p.Name = "Region_" .. comp.Id
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, true, false
			p.Transparency = 1
			p.CFrame = cf
			p.Size = size:Max(Vector3.one * 3) + Vector3.one * 0.4 -- mínimo de 3 studs: dá para tocar
			p.Parent = folder
			local box = Instance.new("SelectionBox")
			box.Adornee = p
			box.Visible = false
			box.LineThickness = 0.1
			box.SurfaceColor3 = SELECTED
			box.SurfaceTransparency = 1
			box.Color3 = HOVER
			box.Parent = p
			-- ponto discreto (alterna acima/abaixo do eixo para não amontoar) e nome quando selecionado
			local up = (i % 2 == 0) and 1 or -1
			local dot = Instance.new("BillboardGui")
			dot.Name = "Dot"
			dot.Adornee = p
			dot.AlwaysOnTop = true
			dot.LightInfluence = 0
			dot.Size = UDim2.fromOffset(26, 26)
			dot.StudsOffsetWorldSpace = Vector3.new(0, up * (p.Size.Y / 2 + 1.5), 0)
			dot.Active = true
			dot.Parent = UI.playerGui()
			table.insert(s.cleanup, dot)
			local hit = Instance.new("TextButton")
			hit.Size = UDim2.fromScale(1, 1)
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.Parent = dot
			local mark = Instance.new("Frame")
			mark.AnchorPoint = Vector2.new(0.5, 0.5)
			mark.Position = UDim2.fromScale(0.5, 0.5)
			mark.Size = UDim2.fromOffset(10, 10)
			mark.BackgroundColor3 = Color3.new(1, 1, 1)
			mark.BackgroundTransparency = 0.25
			mark.Parent = hit
			UI.corner(mark, 5)
			UI.new("UIStroke", { Color = UI.C.panel, Thickness = 1.5, Parent = mark })
			local label = Instance.new("BillboardGui")
			label.Name = "Label"
			label.Adornee = p
			label.AlwaysOnTop = true
			label.LightInfluence = 0
			label.Size = UDim2.fromOffset(220, 30)
			label.StudsOffsetWorldSpace = Vector3.new(0, -up * (p.Size.Y / 2 + 2.5), 0)
			label.Enabled = false
			label.Parent = UI.playerGui()
			table.insert(s.cleanup, label)
			local t = UI.new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.panel, BackgroundTransparency = 0.1,
				Text = comp.Name, TextScaled = true, FontFace = UI.font(Enum.FontWeight.Bold),
				TextColor3 = UI.C.text, Parent = label,
			})
			UI.corner(t, 4)
			UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = t })
			UI.new("UIStroke", { Color = SELECTED, Thickness = 1.5, Parent = t })
			local r = { comp = comp, part = p, box = box, label = label }
			hit.Activated:Connect(function() Explorer.select(comp.Id) end)
			hit.MouseEnter:Connect(function() setHover(r) end)
			hit.MouseLeave:Connect(function() if st and st.hover == r then setHover(nil) end end)
			table.insert(s.regions, r)
			s.byPart[p] = r
			s.byId[comp.Id] = r
		else
			warn("[RocketExplorer] sem peças para " .. tostring(comp.Id))
		end
	end

	-- nome sob o cursor (mouse)
	local tipGui = UI.screenGui("RocketExplorerTip", 30)
	table.insert(s.cleanup, tipGui)
	s.tip = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UI.C.panel, BackgroundTransparency = 0.1, TextColor3 = UI.C.text,
		FontFace = UI.font(Enum.FontWeight.SemiBold), TextSize = 15, Text = "", Visible = false, Parent = tipGui,
	})
	UI.corner(s.tip, 4)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = s.tip })

	-- câmera
	cam.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("RocketExplorerCamera", Enum.RenderPriority.Camera.Value + 1, function()
		if not st or not st.camCF then return end
		if workspace.CurrentCamera ~= st.cam then return Explorer.exit() end
		stepCamera()
		st.cam.CameraType = Enum.CameraType.Scriptable
		st.cam.CFrame = st.camCF
	end)

	-- personagem parado e seguro; no celular, sem direcional por cima do foguete
	CAS:BindActionAtPriority("RocketExplorerFreeze", function() return Enum.ContextActionResult.Sink end, false,
		Enum.ContextActionPriority.High.Value + 50,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump,
		Enum.KeyCode.Thumbstick1)
	CAS:BindActionAtPriority("RocketExplorerBack", function(_, state)
		if state == Enum.UserInputState.Begin then Explorer.exit() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 50, Enum.KeyCode.ButtonB)
	-- prompts (só deste jogador) desligados: um clique no foguete acionaria o "Examine" e fecharia o painel
	s.promptsSaved = PPS.Enabled
	PPS.Enabled = false
	if UI.isTouch() then
		s.touchSaved = GuiService.TouchControlsEnabled
		GuiService.TouchControlsEnabled = false
	end

	local function overUi(pos)
		return s.cb.overUi and s.cb.overUi(pos) or false
	end
	table.insert(s.cleanup, UIS.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		s.tip.Position = UDim2.fromOffset(pos.X + 14, pos.Y - 6)
		if overUi(pos) then return setHover(nil) end
		setHover(pick(pos))
	end))
	table.insert(s.cleanup, UIS.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		if overUi(pos) then return end
		local r = pick(pos)
		if r then Explorer.select(r.comp.Id) end
	end))
	table.insert(s.cleanup, UIS.TouchTapInWorld:Connect(function(pos, processed)
		if processed or overUi(pos) then return end
		local r = pick(pos)
		if r then Explorer.select(r.comp.Id) end
	end))

	-- saídas automáticas: renascer, morrer, trocar de câmera
	table.insert(s.cleanup, player.CharacterRemoving:Connect(function() Explorer.exit() end))
	table.insert(s.cleanup, hum.Died:Connect(function() Explorer.exit() end))
	table.insert(s.cleanup, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Explorer.exit() end))
	table.insert(s.cleanup, tipGui.AncestryChanged:Connect(function() if not tipGui.Parent then Explorer.exit() end end))
	return true
end

return Explorer
