--[[
	Decolagem — cutscene da saída do foguete durante a fase "Lancamento" (12 s, Sessao:lancar).

	O jogador já está sentado na cápsula (longe do mapa); a câmera mostra, só para ele, uma cópia
	local do SLS + Mobile Launcher (TransportSystem.TransportAssembly) sobre a plataforma 39B:
	  0–3,2 s  vista ampla da área de observação, contagem T-3, T-2, T-1;
	  3,2–7 s  câmera baixa junto à plataforma: ignição, fogo e fumaça, o foguete sobe;
	  7–fim    acompanha o foguete subindo; escurece e volta para dentro da cápsula.
	A cópia é guardada enquanto o jogador está perto do VAB (com StreamingEnabled o modelo some
	quando ele embarca); a plataforma é pedida pelo servidor (RequestStreamAroundAsync em
	Sessao:lancar). Quem embarca no meio da contagem vê só o restante. "Skip ›" volta à cápsula.
	Coordenadas: SLS no VAB em Z 265 e na plataforma em Z 700 (centro dos pedestais da 39B, topo
	em Y 7); base da Mobile Launcher em Y 0 no VAB.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("UI"))

local D = {}
local player = Players.LocalPlayer

local PAD_Z, PAD_TOP = 700, 7
local LIFTOFF = 3.2 -- segundos de contagem antes da subida
local ACCEL = 9 -- studs/s² (subida visual, não física)

local cache, cacheParts = nil, 0
local running = nil

local function countParts(m)
	local n = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then n += 1 end
	end
	return n
end

-- guarda uma cópia do foguete enquanto ele está carregado (perto do VAB)
local function tryCache()
	local map = workspace:FindFirstChild("NASAComplex")
	local ts = map and map:FindFirstChild("TransportSystem")
	local ta = ts and ts:FindFirstChild("TransportAssembly")
	local sls = ta and ta:FindFirstChild("SLSRocket")
	local ml = ta and ta:FindFirstChild("MobileLauncher")
	if not (sls and ml) then return end
	local n = countParts(sls) + countParts(ml)
	if n <= cacheParts then return end
	local m = Instance.new("Model")
	m.Name = "LaunchStack"
	local ok = pcall(function()
		sls:Clone().Parent = m
		ml:Clone().Parent = m
	end)
	if ok then
		if cache then cache:Destroy() end
		cache, cacheParts = m, n
	end
end

local function ease(a)
	return a < 0.5 and 2 * a * a or 1 - (-2 * a + 2) ^ 2 / 2
end

local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	for k, v in props do e[k] = v end
	e.Parent = parent
	return e
end

local function buildGui()
	local gui = UI.screenGui("LaunchCutscene", 45)
	gui.IgnoreGuiInset = true
	local bars = {}
	for i, anchor in { 0, 1 } do
		bars[i] = UI.new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, anchor), Position = UDim2.fromScale(0, anchor),
			Size = UDim2.fromScale(1, 0.11), Parent = gui,
		})
	end
	local count = UI.new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.fromOffset(600, 80), Text = "", TextColor3 = Color3.new(1, 1, 1), TextSize = 56,
		FontFace = UI.font(Enum.FontWeight.Heavy), TextStrokeTransparency = 0.4, Parent = gui,
	})
	local fade = UI.new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = gui,
	})
	local skip = UI.botao(gui, {
		Text = "Skip ›", cor = UI.C.panel2, Size = UDim2.fromOffset(110, 44),
		Position = UDim2.new(1, -126, 0, 60),
	})
	skip.Name = "SkipLaunch"
	return gui, count, fade, skip
end

function D.parar()
	local r = running
	if not r then return end
	running = nil
	player:SetAttribute("InCutscene", nil)
	pcall(function() RunService:UnbindFromRenderStep("LaunchCutsceneCamera") end)
	pcall(function() CAS:UnbindAction("LaunchCutsceneSkip") end)
	local cam = workspace.CurrentCamera
	if cam == r.cam then
		cam.FieldOfView = r.fov
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
	end
	if r.stack then r.stack:Destroy() end
	if r.fx then r.fx:Destroy() end
	if r.gui then
		-- desfaz o escuro já dentro da cápsula
		local fade = r.fade
		fade.BackgroundTransparency = 0
		local tw = TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
		tw:Play()
		local gui = r.gui
		tw.Completed:Connect(function() gui:Destroy() end)
	end
end

-- fimServidor: workspace:GetServerTimeNow() em que a fase Lancamento termina
function D.tocar(fimServidor)
	if running and running.fim == fimServidor then return end
	D.parar()
	local restante = (fimServidor or 0) - workspace:GetServerTimeNow()
	if restante < 2.5 or not cache then return end
	local cam = workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Custom then return end
	local total = 12
	local inicio = os.clock() - math.max(0, total - restante)

	-- foguete na plataforma (cópia local, sem colisão)
	local stack = cache:Clone()
	for _, d in stack:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
		end
	end
	local sls = stack:FindFirstChild("SLSRocket")
	local ml = stack:FindFirstChild("MobileLauncher")
	local base = ml and ml:FindFirstChild("Base") or ml
	local bcf, bsize = base:GetBoundingBox()
	local scf = sls:GetBoundingBox()
	stack:PivotTo(stack:GetPivot() + Vector3.new(0, PAD_TOP - (bcf.Position.Y - bsize.Y / 2), PAD_Z - scf.Position.Z))
	stack.Parent = cam
	local slsStart = sls:GetPivot()
	local _, slsSize = sls:GetBoundingBox()
	local slsCf = sls:GetBoundingBox()
	local bottomY = slsCf.Position.Y - slsSize.Y / 2

	-- efeitos: fogo nos motores (acompanha o foguete) e nuvem de fumaça na plataforma
	local fx = Instance.new("Folder")
	fx.Name = "LaunchFX"
	fx.Parent = cam
	local function anchorPart(pos, size)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
		p.Size = size
		p.CFrame = CFrame.new(pos)
		p.Parent = fx
		return p
	end
	local flameOffsets = { Vector3.new(0, 0, 0), Vector3.new(-8, 0, 0), Vector3.new(8, 0, 0) }
	local flames = {}
	for i, off in flameOffsets do
		local p = anchorPart(Vector3.new(slsCf.Position.X, bottomY, slsCf.Position.Z) + off, Vector3.new(4, 1, 4))
		local e = emitter(p, {
			Texture = "rbxasset://textures/particles/fire_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 120, 40)),
			LightEmission = 1, Rate = 0, Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(30, 45),
			EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(8, 8),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, i == 1 and 4 or 5), NumberSequenceKeypoint.new(1, 1) }),
			Transparency = NumberSequence.new(0.1, 1),
		})
		table.insert(flames, { part = p, off = off, e = e })
	end
	local smokePart = anchorPart(Vector3.new(slsCf.Position.X, PAD_TOP + 2, PAD_Z), Vector3.new(30, 1, 30))
	local smoke = emitter(smokePart, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(235, 235, 230), Color3.fromRGB(170, 170, 165)),
		Rate = 0, Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(12, 24),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(80, 80),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 30) }),
		Transparency = NumberSequence.new(0.2, 1), Drag = 1.5,
	})
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness, glow.Enabled = Color3.fromRGB(255, 170, 80), 60, 0, true
	glow.Parent = flames[1].part

	local gui, count, fade, skip = buildGui()
	local r = { cam = cam, fov = cam.FieldOfView, stack = stack, fx = fx, gui = gui, fade = fade, fim = fimServidor }
	running = r
	player:SetAttribute("InCutscene", true) -- NavigationClient esconde setas e objetivo
	local function pular()
		if running == r then r.pular = true end
	end
	skip.Activated:Connect(pular)
	CAS:BindActionAtPriority("LaunchCutsceneSkip", function(_, state)
		if state == Enum.UserInputState.Begin then pular() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 60, Enum.KeyCode.Return, Enum.KeyCode.ButtonB)

	local axis = Vector3.new(slsCf.Position.X, 0, PAD_Z)
	cam.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("LaunchCutsceneCamera", Enum.RenderPriority.Camera.Value + 3, function()
		if running ~= r then return end
		if workspace.CurrentCamera ~= cam then return D.parar() end
		local t = os.clock() - inicio
		if r.pular or t >= total then
			fade.BackgroundTransparency = 0
			return D.parar()
		end
		local rise = t > LIFTOFF and 0.5 * ACCEL * (t - LIFTOFF) ^ 2 or 0
		sls:PivotTo(slsStart + Vector3.new(0, rise, 0))
		for _, f in flames do
			f.part.CFrame = CFrame.new(Vector3.new(slsCf.Position.X, bottomY + rise, slsCf.Position.Z) + f.off)
			f.e.Rate = t > LIFTOFF - 0.6 and 140 or 0
		end
		smoke.Rate = (t > LIFTOFF - 0.8 and t < LIFTOFF + 5) and 60 or 0
		glow.Brightness = t > LIFTOFF - 0.6 and 6 or 0
		-- contagem
		if t < LIFTOFF then
			count.Text = "T-" .. math.max(1, math.ceil(LIFTOFF - t))
		elseif t < LIFTOFF + 1.6 then
			count.Text = "LIFTOFF!"
		else
			count.Text = ""
		end
		-- tomadas
		local center = axis + Vector3.new(0, 70 + rise, 0)
		local camCF
		if t < LIFTOFF then
			local a = ease(t / LIFTOFF)
			camCF = CFrame.lookAt(Vector3.new(-100, 18, 655):Lerp(Vector3.new(-90, 20, 662), a), axis + Vector3.new(0, 66, 0))
		elseif t < 7 then
			camCF = CFrame.lookAt(Vector3.new(38, 9, 664), axis + Vector3.new(0, bottomY + rise + 26, 0))
		else
			local a = ease(math.clamp((t - 7) / 5, 0, 1))
			local pos = Vector3.new(70, 30, 636):Lerp(Vector3.new(80, 60, 620), a)
			camCF = CFrame.lookAt(pos, center)
		end
		cam.CFrame = camCF
		cam.FieldOfView = 70
		-- escurece no fim
		fade.BackgroundTransparency = t > total - 0.7 and math.clamp((total - t) / 0.7, 0, 1) or 1
	end)
	return true
end

function D.iniciar()
	task.spawn(function()
		while true do
			-- guarda/atualiza a cópia enquanto o foguete está carregado
			if not running then tryCache() end
			task.wait(3)
		end
	end)
	player.CharacterRemoving:Connect(D.parar)
end

return D
