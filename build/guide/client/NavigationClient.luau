--[[
	NavigationClient — setas vermelhas no chão e objetivo no HUD (spec §6).

	O servidor manda o caminho (pathfinding) pelo NavigationUpdate; aqui só se desenha:
	- setas estáticas deitadas no chão ao longo do caminho (nunca através de paredes: o caminho
	  contorna as paredes), até 45 studs à frente; ficam paradas até o caminho mudar;
	- objetivo curto no canto superior esquerdo.
	Tudo é local (peças na câmera): cada jogador vê só as próprias setas.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local GS = RS:WaitForChild("GuideSystem")
local Settings = require(GS:WaitForChild("Config"):WaitForChild("Settings"))
local Dialogues = require(GS:WaitForChild("Config"):WaitForChild("Dialogues"))
local UI = require(script.Parent:WaitForChild("GuideUI"))

local player = Players.LocalPlayer
local NavigationClient = {}
local missionMode, missionRoute = false, nil

-- Mesmo desenho/oclusão da seta dos guias; a task fornece a estação atual.
-- Rota da missão: pathfinding local (cada jogador calcula a própria rota) da posição até a
-- estação da task atual; enquanto calcula, nenhuma seta (exact = 1). Sem caminho, linha reta.
local missionSeq = 0
local function missionPath(route, from)
	missionSeq += 1
	local seq = missionSeq
	route.exact = 1
	route.pathAt = os.clock()
	task.spawn(function()
		local path = PathfindingService:CreatePath(Settings.Agent)
		local ok = pcall(function() path:ComputeAsync(from, route.target) end)
		if seq ~= missionSeq or missionRoute ~= route then return end
		if ok and path.Status == Enum.PathStatus.Success then
			local pts = {}
			for _, w in path:GetWaypoints() do table.insert(pts, w.Position) end
			if #pts >= 2 then
				route.points, route.exact = pts, #pts
				return
			end
		end
		route.points, route.exact = { from, route.target }, 2
	end)
end

function NavigationClient.missionTarget(active, target, position)
	missionMode = active
	if not target then
		missionRoute = nil
		missionSeq += 1
	elseif not (missionRoute and (missionRoute.target - target).Magnitude < 0.5) then
		-- rota nova só quando o alvo muda: as setas do chão ficam paradas
		missionRoute = { points = { position, target }, idx = 2, target = target, beacon = true }
		missionPath(missionRoute, position)
	elseif position and missionRoute.exact and missionRoute.exact > 2 and os.clock() - missionRoute.pathAt > 2 then
		-- saiu da rota (> 10 studs do caminho): recalcula
		local pts, off = missionRoute.points, math.huge
		for i = 2, #pts do
			local a, b = pts[i - 1], pts[i]
			local ab = b - a
			local t = ab:Dot(ab) > 1e-6 and math.clamp((position - a):Dot(ab) / ab:Dot(ab), 0, 1) or 0
			off = math.min(off, (position - (a + ab * t)).Magnitude)
		end
		if off > 10 then missionPath(missionRoute, position) end
	end
end

local A = Settings.Arrow
local state = { points = nil, idx = 1, target = nil, beacon = false, objective = nil, stage = nil, exact = nil, ring = nil }

-- Setas desligadas perto do alvo, com histerese: apagam ao chegar (NEAR) e só voltam se o
-- jogador se afastar além de FAR ou se surgir um objetivo novo. Vale para o Marcos e a Ana
-- (alvo que anda) e para a estação da task nas missões.
local NEAR = { guide = 12, mission = 6 }
local FAR = { guide = 22, mission = 12 }
local arrived, arrivedKey = false, nil
local lastRepath = 0

---------------------------------------------------------------------------------
-- Seta 3D (haste + ponta de duas cunhas), apontando para −Z do CFrame
---------------------------------------------------------------------------------

local function arrowModel(name, scale, semLuz)
	local m = Instance.new("Model")
	m.Name = name
	local parts = {}
	local function part(class, size)
		local p = Instance.new(class)
		p.Size = size * scale
		p.Color = A.Color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = m
		table.insert(parts, p)
		return p
	end
	local shaftLen, headW, headD = 1.6, 1.3, 1.3
	local shaft = part("Part", Vector3.new(0.45, 0.3, shaftLen))
	local headR = part("WedgePart", Vector3.new(0.3, headW / 2, headD))
	local headL = part("WedgePart", Vector3.new(0.3, headW / 2, headD))
	local light = Instance.new("PointLight")
	light.Color = A.Color
	light.Range = 6 * scale
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = shaft
	if semLuz then light:Destroy() end
	local offsets = {
		[shaft] = CFrame.new(0, 0, shaftLen * scale / 2),
		[headR] = CFrame.new(headW * scale / 4, 0, -headD * scale / 2) * CFrame.Angles(0, 0, -math.pi / 2),
		[headL] = CFrame.new(-headW * scale / 4, 0, -headD * scale / 2) * CFrame.Angles(0, 0, math.pi / 2),
	}
	return {
		model = m,
		set = function(cf)
			for p, off in offsets do p.CFrame = cf * off end
		end,
		visible = function(v)
			for _, p in parts do p.Transparency = v and 0 or 1 end
			if light.Parent then light.Enabled = v end
		end,
	}
end

---------------------------------------------------------------------------------
-- HUD do objetivo
---------------------------------------------------------------------------------

local hud = {}

local function buildHud()
	local gui = UI.screenGui("GuideObjective", 8)
	local frame = UI.new("Frame", {
		Name = "Objective",
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.12,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	UI.corner(frame, 12)
	UI.stroke(frame, UI.C.line)
	UI.pad(frame, 10)
	UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(340, 200), Parent = frame })
	local head = UI.text(frame, {
		Text = "▶  OBJECTIVE", Color = A.Color, Weight = Enum.FontWeight.Bold, TextSize = 13,
		Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1,
	})
	local body = UI.text(frame, {
		Text = "", TextSize = 17, Weight = Enum.FontWeight.SemiBold,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})
	local hint = UI.text(frame, {
		Text = "", TextSize = 14, Color = UI.C.muted,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3,
	})
	hud.gui, hud.frame, hud.head, hud.body, hud.hint = gui, frame, head, body, hint
end

-- dica de controle conforme o dispositivo atual
local function hintFor(stage)
	local h = stage and Dialogues.Hints and Dialogues.Hints[stage]
	if not h then return "" end
	if h.all then return h.all end
	local ok, pref = pcall(function() return UIS.PreferredInput end)
	if ok and pref == Enum.PreferredInput.Gamepad then return h.pad or h.kb or "" end
	if UI.isTouch() then return h.touch or h.kb or "" end
	return h.kb or ""
end

local blip
local function playBlip()
	if not blip then
		blip = Instance.new("Sound")
		blip.SoundId = Settings.Sounds.Blip.Id
		blip.Volume = Settings.Sounds.Blip.Volume
		blip.Parent = SoundService
	end
	blip:Play()
end

-- Objetivo novo: o anterior aparece por 1,2 s como concluído (texto + ✓, não só cor) e então
-- o novo entra; um objetivo por vez.
local objSeq = 0
local function showObjective(text)
	hud.head.Text = "▶  OBJECTIVE"
	hud.head.TextColor3 = A.Color
	hud.body.Text = text
	hud.hint.Text = hintFor(state.stage)
	hud.hint.Visible = hud.hint.Text ~= ""
	hud.frame.Visible = true
	hud.frame.Position = UDim2.fromOffset(-320, 10)
	TweenService:Create(hud.frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(12, 10),
	}):Play()
	playBlip()
end

local function setObjective(text)
	if text == state.objective then return end
	local previous = state.objective
	state.objective = text
	objSeq += 1
	local seq = objSeq
	if previous and hud.frame.Visible then
		hud.head.Text = "✓  COMPLETED"
		hud.head.TextColor3 = Color3.fromHex("5BD17A")
		hud.hint.Visible = false
		playBlip()
		task.delay(1.2, function()
			if seq ~= objSeq then return end
			if text then showObjective(text) else hud.frame.Visible = false end
		end)
		return
	end
	if not text then
		hud.frame.Visible = false
		return
	end
	showObjective(text)
end

---------------------------------------------------------------------------------
-- Caminho
---------------------------------------------------------------------------------

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function distToSegment(p, a, b)
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then return (p - a).Magnitude end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- próximo ponto do caminho a seguir (monotônico: nunca volta para trás)
local function nextPoint(pos, route)
	route = route or state
	local pts = route.points
	if not pts or #pts == 0 then return nil end
	local i = math.clamp(route.idx, 1, #pts)
	while i < #pts do
		local d = flat(pts[i] - pos).Magnitude
		local dy = math.abs(pts[i].Y - pos.Y)
		-- só pula para o próximo ponto se ele estiver no mesmo nível (escadas: não pular o lance)
		local nextSameLevel = math.abs(pts[i + 1].Y - pos.Y) < 6
		if (d < 4 and dy < 6) or (nextSameLevel and flat(pts[i + 1] - pos).Magnitude < d) then
			i += 1
		else
			break
		end
	end
	route.idx = i
	-- saiu muito da rota: pede outro caminho ao servidor
	local off = math.huge
	if i > 1 then off = distToSegment(pos, pts[i - 1], pts[i]) else off = 0 end
	if not missionMode and off > 18 and os.clock() - lastRepath > 2.5 then
		lastRepath = os.clock()
		GS.Remotes.NavigationUpdate:FireServer("Repath")
	end
	return pts[i]
end

---------------------------------------------------------------------------------

-- Setas no chão (estáticas): chevrons deitados a cada SPACING studs ao longo do caminho,
-- mostrando até AHEAD studs à frente do jogador. As posições só mudam quando o caminho muda.
local SPACING, AHEAD, MAXARROWS = 4.5, 45, 12
local refreshFilter

function NavigationClient.start()
	buildHud()
	local holder = workspace.CurrentCamera
	local pool = {}
	local function arrowAt(i)
		local a = pool[i]
		if not a then
			a = arrowModel("GuideFloorArrow", 0.9, true)
			a.model.Parent = holder
			a.visible(false)
			pool[i] = a
		end
		return a
	end
	-- a câmera pode ser trocada (cutscenes do museu/Rookie); recoloca as setas na câmera atual
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		holder = workspace.CurrentCamera
		for _, a in pool do a.model.Parent = holder end
	end)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true

	GS:WaitForChild("Remotes"):WaitForChild("NavigationUpdate").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then return end
		state.stage = data.stage
		setObjective(data.objective)
		state.points = data.points
		state.exact = type(data.exact) == "number" and data.exact or (data.exact and math.huge or 2)
		state.ring = type(data.ring) == "table" and data.ring or nil
		state.idx = data.points and math.min(2, #data.points) or 1
		state.target = data.target
		state.beacon = data.beacon == true
		state.stage = data.stage
	end)

	-- raios ignoram personagens, NPCs e as próprias setas/círculo
	local filterAt = -math.huge
	refreshFilter = function()
		filterAt = os.clock()
		local filter = { holder }
		for _, pl in Players:GetPlayers() do
			if pl.Character then table.insert(filter, pl.Character) end
		end
		local map = workspace:FindFirstChild("NASAComplex")
		local npcs = map and map:FindFirstChild("Guides")
		if npcs then table.insert(filter, npcs) end
		rayParams.FilterDescendantsInstances = filter
	end
	local function filterStale() return os.clock() - filterAt > 3 end

	-- amostras do caminho: { cf no chão, s = distância ao longo do caminho }
	local layoutFor, layoutExact, samples, segs = nil, nil, {}, {}
	local function build(points, exact)
		samples, segs = {}, {}
		refreshFilter()
		local acc, nextS = 0, SPACING
		for i = 2, math.min(#points, exact or #points) do
			local a, b = points[i - 1], points[i]
			local d = b - a
			local len = d.Magnitude
			table.insert(segs, { a = a, b = b, s0 = acc, len = len })
			local dir = Vector3.new(d.X, 0, d.Z)
			if len > 1e-3 and dir.Magnitude > 0.05 then
				dir = dir.Unit
				while nextS <= acc + len do
					local p = a + d * ((nextS - acc) / len)
					local hit = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), rayParams)
					if hit and hit.Normal.Y > 0.6 then
						local at = Vector3.new(p.X, hit.Position.Y + 0.17, p.Z)
						table.insert(samples, { cf = CFrame.lookAt(at, at + dir), s = nextS })
					end
					nextS += SPACING
				end
			end
			acc += len
		end
		return acc
	end
	local total = 0

	-- distância percorrida pelo jogador ao longo do caminho (projeção no trecho mais próximo)
	local function progress(pos)
		local best, bd = 0, math.huge
		for _, g in segs do
			local ab = g.b - g.a
			local t = g.len > 1e-3 and math.clamp((pos - g.a):Dot(ab) / (g.len * g.len), 0, 1) or 0
			local d = (pos - (g.a + ab * t)).Magnitude
			if d < bd then best, bd = g.s0 + g.len * t, d end
		end
		return best
	end

	local function hideFrom(i)
		for k = i, #pool do pool[k].visible(false) end
	end

	-- Museu: ao entrar na sala da exposição (perto e com linha de visão), as setas vermelhas dão
	-- lugar a uma circunferência branca no chão em volta da exposição (§2 da spec de melhorias).
	local RING_SEGS = 32
	local ringParts, ringFor, ringVisible = {}, nil, false
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		for _, p in ringParts do p.Parent = workspace.CurrentCamera end
	end)
	local function ringPart(i)
		local p = ringParts[i]
		if not p then
			p = Instance.new("Part")
			p.Name = "GuideExhibitRing"
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.Neon
			p.Color = Color3.new(1, 1, 1)
			p.Transparency = 1
			p.Parent = holder
			ringParts[i] = p
		end
		return p
	end
	local function layoutRing(ring)
		local c, r = ring.center, ring.radius
		if filterStale() then refreshFilter() end
		local hit = workspace:Raycast(c + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
		local y = (hit and hit.Position.Y or c.Y) + 0.12
		local seg = 2 * math.pi * r / RING_SEGS
		for i = 1, RING_SEGS do
			local a = (i - 0.5) / RING_SEGS * 2 * math.pi
			local at = Vector3.new(c.X + r * math.cos(a), y, c.Z + r * math.sin(a))
			local p = ringPart(i)
			p.Size = Vector3.new(0.35, 0.12, seg * 1.04)
			p.CFrame = CFrame.lookAt(at, at + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
	end
	local function showRing(v)
		if v == ringVisible then return end
		ringVisible = v
		for _, p in ringParts do p.Transparency = v and 0.15 or 1 end
	end
	local losAt, losOk = 0, false
	local hiddenByCutscene = false
	local function ringNear(pos, ring)
		local flatD = (Vector3.new(ring.center.X, 0, ring.center.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
		if flatD > ring.radius + 28 or math.abs(pos.Y - ring.center.Y) > 10 then return false end
		if os.clock() - losAt > 0.3 then
			losAt = os.clock()
			if filterStale() then refreshFilter() end
			local eye = pos + Vector3.new(0, 1.5, 0)
			local hit = workspace:Raycast(eye, ring.target - eye, rayParams)
			losOk = not hit or (hit.Position - ring.target).Magnitude < ring.radius + 2
		end
		return losOk
	end

	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local route = state
		if missionMode then route = missionRoute end
		-- cutscene (chegada, museu, decolagem): sem setas, círculo nem objetivo; voltam ao terminar
		if player:GetAttribute("InCutscene") then
			if hud.frame.Visible then
				hud.frame.Visible = false
				hiddenByCutscene = true
			end
			showRing(false)
			return hideFrom(1)
		elseif hiddenByCutscene then
			hiddenByCutscene = false
			if state.objective and not missionMode then hud.frame.Visible = true end
		end
		-- Settings → Navigation arrows: Off esconde as setas (o objetivo no HUD continua)
		if player:GetAttribute("GuideArrows") == false then return hideFrom(1) end
		if missionMode then hud.frame.Visible = false end
		local ring = not missionMode and state.stage == "Museum" and state.ring or nil
		if not ring then showRing(false) end
		if not root or not route or not route.points or not route.target or #route.points < 2 then return hideFrom(1) end
		local pos = root.Position
		if ring and ringNear(pos, ring) then
			if ringFor ~= ring then
				ringFor = ring
				layoutRing(ring)
			end
			ringVisible = true
			-- pulso suave para chamar atenção sem piscar
			local t = 0.1 + 0.15 * (0.5 + 0.5 * math.sin(os.clock() * 3))
			for _, p in ringParts do p.Transparency = t end
			return hideFrom(1)
		end
		showRing(false)
		local tgt = route.target
		-- chegou perto do alvo: apaga as setas até o jogador se afastar ou o objetivo mudar
		local key = missionMode
			and string.format("M:%d:%d:%d", math.floor(tgt.X + 0.5), math.floor(tgt.Y + 0.5), math.floor(tgt.Z + 0.5))
			or ("G:" .. tostring(state.stage) .. ":" .. tostring(state.objective))
		if key ~= arrivedKey then
			arrivedKey = key
			arrived = false
		end
		local kind = missionMode and "mission" or "guide"
		local dist = (tgt - pos).Magnitude
		if not arrived and dist < NEAR[kind] then
			arrived = true
		elseif arrived and dist > FAR[kind] then
			arrived = false
		end
		if arrived then return hideFrom(1) end
		-- caminho novo → recalcula as posições (fixas no mundo)
		if layoutFor ~= route.points or layoutExact ~= route.exact then
			layoutFor, layoutExact = route.points, route.exact
			total = build(route.points, route.exact)
		end
		if not missionMode then nextPoint(pos, route) end -- pede caminho novo se sair da rota
		local sp = progress(pos)
		local n = 0
		for _, smp in samples do
			if smp.s > sp + 2 and smp.s < sp + AHEAD and smp.s < total - 1.5 then
				n += 1
				if n > MAXARROWS then break end
				local a = arrowAt(n)
				a.set(smp.cf)
				a.visible(true)
			end
		end
		hideFrom(math.min(n, MAXARROWS) + 1)
	end)
end

return NavigationClient
