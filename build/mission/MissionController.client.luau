--[[
	MissionController — cliente da missão Friendship 7 (missaoUm.md §7.1).
	Recebe o estado do servidor (MissionUpdate) e cuida do que é local: primeira pessoa,
	painéis (PanelDisplays), botões (PanelInteractionController), olhar (GazeInteractionController),
	vibração (CameraShakeController), sons (AudioController), luzes de alerta e cor da tela.
	Ao sair (concluída, abortada, morte) restaura câmera, luzes e interfaces.
	O resultado de cada tarefa é decidido só pelo servidor.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local MS = RS:WaitForChild("MissionSystem")
local Config = require(MS:WaitForChild("Config"):WaitForChild("Friendship7Config"))
local Remotes = MS:WaitForChild("Remotes")

local here = script
local FirstPerson = require(here:WaitForChild("FirstPersonController"))
local Shake = require(here:WaitForChild("CameraShakeController"))
local Gaze = require(here:WaitForChild("GazeInteractionController"))
local Interact = require(here:WaitForChild("PanelInteractionController"))
local Audio = require(here:WaitForChild("AudioController"))
local Panels = require(here:WaitForChild("PanelDisplays"))

Gaze.init(Config, Remotes.MissionAction)

local map = workspace:WaitForChild("NASAComplex")
local snap -- último estado
local inMission = false
local parts -- peças da cápsula (resolvidas ao entrar; com streaming podem chegar tarde)
local lightMode
local cabinLights = {} -- [PointLight] = brilho original
local cc
local renderConn
local retainHeld = false
local lastRadioAt, lastErrorAt, lastIndex

-- efeitos por fase: vibração, luzes, sons contínuos, cor
local FX = {
	t1_alert = { shake = 0.5, lights = "orange_flash", loops = { alarm = true } },
	t1_manual = { shake = 0.32, lights = "orange_flash", loops = { alarm = true } },
	t1_done = { shake = 0, loops = {}, sound = "confirm" },
	t2_blackout = { shake = 0.15, lights = "amber", loops = { static = true } },
	t2_done = { shake = 0, loops = {}, sound = "confirm" },
	t3_alert = { shake = 0.42, lights = "red_flash", loops = { alarm_fast = true }, tint = Color3.fromRGB(255, 232, 226) },
	t3_reentry = { shake = 0.62, lights = "red", loops = { rumble = true }, tint = Color3.fromRGB(255, 214, 180) },
	t3_done = { shake = 0.08, loops = {}, sound = "confirm" },
	failed = { shake = 0, lights = "red_dim", loops = {}, sound = "error" },
	complete = { shake = 0, loops = {} },
}

local LIGHT = {
	orange_flash = { color = Color3.fromRGB(255, 140, 40), flash = true },
	amber = { color = Color3.fromRGB(255, 180, 70), flash = false, brightness = 1.2 },
	red_flash = { color = Color3.fromRGB(255, 50, 40), flash = true },
	red = { color = Color3.fromRGB(255, 70, 40), flash = false, brightness = 2.2 },
	red_dim = { color = Color3.fromRGB(255, 50, 40), flash = false, brightness = 0.8 },
}

-------------------------------------------------------------------------------
-- peças
-------------------------------------------------------------------------------
local function resolveParts()
	local cab = map:WaitForChild("OrionInterior", 10)
	local root = cab and cab:WaitForChild("Friendship7Mission", 10)
	if not root then return nil end
	local con = cab:WaitForChild("Console")
	local p = {
		cab = cab,
		root = root,
		displays = { con:WaitForChild("Display_Unit_1"), con:WaitForChild("Display_Unit_2"), con:WaitForChild("Display_Unit_3") },
		papers = {},
		windows = {},
		beacons = {},
	}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Paper" then table.insert(p.papers, d) end
		if d:IsA("BasePart") and d.Name == "Warning_Light" then table.insert(p.beacons, d) end
	end
	for _, d in cab:GetChildren() do
		if d:IsA("BasePart") and d.Name == "Window" then table.insert(p.windows, d) end
	end
	table.sort(p.windows, function(a, b) return a.Position.Z < b.Position.Z end)
	local shell = cab:FindFirstChild("Shell")
	if shell then
		for _, d in shell:GetDescendants() do
			if d:IsA("PointLight") then cabinLights[d] = d.Brightness end
		end
	end
	return p
end

-------------------------------------------------------------------------------
-- botões
-------------------------------------------------------------------------------
local function phase() return snap and snap.phase end

local function onPress(action)
	local ph = phase()
	if action ~= "CodeInput" then Audio.play("click", 0.95 + math.random() * 0.1) end
	if action == "Autopilot" then
		if ph == "t1_alert" then
			Interact.setDown("Autopilot", true)
			Remotes.MissionAction:FireServer("Autopilot")
		end
	elseif action == "Retry" then
		if ph == "failed" then Remotes.MissionAction:FireServer("Retry") end
	elseif action == "Confirm" then
		if ph == "t2_blackout" then Remotes.SubmitCode:FireServer(Panels.codeText()) end
	elseif action == "Eject" then
		if ph == "t2_blackout" then Remotes.MissionAction:FireServer("Eject") end
	elseif action == "Jettison" then
		if ph == "t3_alert" then Remotes.SubmitChoice:FireServer("Jettison") end
	elseif action == "Retain" then
		retainHeld = true
		Interact.setDown("Retain", true)
		if ph == "t3_alert" then
			Remotes.SubmitChoice:FireServer("Retain")
		elseif ph == "t3_reentry" then
			Remotes.MissionAction:FireServer("Hold", true)
		end
	elseif action == "CodeInput" then
		Panels.focusCode()
	end
end

local function onRelease(action)
	if action == "Retain" then
		retainHeld = false
		Interact.setDown("Retain", false)
		if phase() == "t3_reentry" then Remotes.MissionAction:FireServer("Hold", false) end
	end
end

-- luzes dos botões conforme a fase (o que se pode apertar agora)
local function updateButtonLights(s)
	local ph = s.phase
	Interact.setLit("Autopilot", ph == "t1_alert", Color3.fromRGB(255, 70, 50))
	Interact.setLit("Retry", ph == "failed", Color3.fromRGB(255, 190, 60))
	Interact.setLit("Confirm", ph == "t2_blackout", Color3.fromRGB(70, 230, 120))
	Interact.setLit("Eject", false)
	Interact.setLit("Jettison", ph == "t3_alert", Color3.fromRGB(255, 60, 50))
	Interact.setLit("Retain", ph == "t3_alert" or ph == "t3_reentry", Color3.fromRGB(70, 230, 120))
	if ph ~= "t1_manual" and ph ~= "t1_done" then Interact.setDown("Autopilot", false) end
end

-------------------------------------------------------------------------------
-- efeitos
-------------------------------------------------------------------------------
local function setTint(color)
	if not cc then return end
	TweenService:Create(cc, TweenInfo.new(0.8), { TintColor = color or Color3.new(1, 1, 1), Saturation = color and -0.1 or 0 }):Play()
end

local clock = 0
local function stepLights(dt)
	clock += dt
	local m = lightMode and LIGHT[lightMode]
	for _, b in parts.beacons do
		local l = b:FindFirstChildOfClass("PointLight")
		if m then
			local on = not m.flash or math.sin(clock * 8) > 0
			b.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			b.Color = m.color
			if l then
				l.Enabled = true
				l.Color = m.color
				l.Brightness = on and (m.brightness or 3) or 0.2
			end
		else
			b.Material = Enum.Material.SmoothPlastic
			b.Color = Color3.fromRGB(90, 30, 25)
			if l then l.Enabled = false end
		end
	end
	for l, base in cabinLights do
		l.Brightness = m and base * 0.35 or base
	end
end

local function applyPhase(prev, s)
	local fx = FX[s.phase] or {}
	Shake.set(fx.shake or 0)
	lightMode = fx.lights
	Audio.setLoops(fx.loops or {}, 0.6)
	if fx.sound then Audio.play(fx.sound) end
	if s.phase == "t2_done" then Audio.play("squelch") end
	setTint(fx.tint)
	-- olhar só no controle manual
	if s.phase == "t1_manual" then
		Gaze.begin(Panels.gazeWorld, Panels.setDwell)
	else
		Gaze.finish()
	end
	-- a escolha MANTER já pode virar o "segurar" se o jogador não soltou o botão
	if s.phase == "t3_reentry" and retainHeld then Remotes.MissionAction:FireServer("Hold", true) end
	if s.phase ~= "t3_reentry" and s.phase ~= "t3_alert" then
		retainHeld = false
		Interact.setDown("Retain", false)
	end
end

-------------------------------------------------------------------------------
-- entrar / sair da missão
-------------------------------------------------------------------------------
local function enter()
	parts = parts or resolveParts()
	if not parts then return false end
	inMission = true
	FirstPerson.enter(parts.displays[2].Position) -- vira para o console (tela do meio)
	Audio.init(Config)
	Panels.create(Config, parts)
	Panels.onCodeSubmit(function(text)
		if phase() == "t2_blackout" then Remotes.SubmitCode:FireServer(text) end
	end)
	Interact.init(parts.root, { [parts.displays[2]] = "CodeInput" }, onPress, onRelease)
	Interact.enable()
	Shake.start()
	cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "F7_Tint"
	cc.Parent = workspace.CurrentCamera
	renderConn = RunService.RenderStepped:Connect(function(dt)
		local now = workspace:GetServerTimeNow()
		Panels.step(dt, now)
		stepLights(dt)
		Panels.setReticle(UIS.MouseBehavior == Enum.MouseBehavior.LockCenter)
	end)
	lastRadioAt, lastErrorAt, lastIndex = nil, nil, nil
	return true
end

local function exit()
	if not inMission then return end
	inMission = false
	if renderConn then renderConn:Disconnect() end
	renderConn = nil
	Gaze.finish()
	Shake.stop()
	Interact.disable()
	Audio.setLoops({}, 0.4)
	Panels.destroy()
	lightMode = nil
	if parts then stepLights(0) end
	if cc then cc:Destroy() end
	cc = nil
	FirstPerson.exit()
	retainHeld = false
end

-------------------------------------------------------------------------------
-- estado do servidor
-------------------------------------------------------------------------------
Remotes.MissionUpdate.OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then return end
	local prev = snap
	snap = s
	if s.active then
		if not inMission and not enter() then return end
		local changed = not prev or not prev.active or prev.phase ~= s.phase or prev.task ~= s.task
		Panels.render(s)
		updateButtonLights(s)
		if changed then applyPhase(prev, s) end
		if s.phase == "t1_manual" then
			if lastIndex and s.index and s.index > lastIndex then Audio.play("confirm", 1 + 0.06 * s.index) end
			Gaze.setIndex(s.index or 1)
		end
		lastIndex = s.index
		if s.errorAt and s.errorAt ~= lastErrorAt then
			lastErrorAt = s.errorAt
			Audio.play("error")
		end
		if s.radio and s.radioAt ~= lastRadioAt then
			lastRadioAt = s.radioAt
			Panels.subtitle(s.radio)
			Audio.play("squelch", 1.1)
		end
	else
		local wasIn = inMission
		if s.phase == "complete" and wasIn then
			Panels.render(s)
			if s.radio and s.radioAt ~= lastRadioAt then Panels.subtitle(s.radio) end
			Audio.setLoops({}, 1)
			Audio.play("confirm", 0.9)
			Shake.set(0)
			lightMode = nil
			setTint(nil)
			Gaze.finish()
			Interact.disable()
			-- deixa a Terra nas janelas enquanto o resumo está aberto
			Panels.showSummary(s, exit)
		else
			exit()
			if s.endReason == "aborted" and s.detail then Panels.toast(s.detail) end
		end
	end
end)

-------------------------------------------------------------------------------
-- prompt "Start mission": só aparece para quem está sentado no assento dele
-------------------------------------------------------------------------------
local prompts = {}
local function trackPrompt(d)
	if d:IsA("ProximityPrompt") and d:GetAttribute("MissionStart") then prompts[d] = true end
end
for _, d in map:GetDescendants() do trackPrompt(d) end
map.DescendantAdded:Connect(trackPrompt)
map.DescendantRemoving:Connect(function(d) prompts[d] = nil end)

local function refreshPrompts()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seatPart = hum and hum.SeatPart
	for pr in prompts do
		local ref = pr.Parent and pr.Parent:FindFirstChild("SeatRef")
		pr.Enabled = not inMission and seatPart ~= nil and ref ~= nil and ref.Value == seatPart
	end
end
PPS.PromptShown:Connect(refreshPrompts)
task.spawn(function()
	while true do
		refreshPrompts()
		task.wait(0.3)
	end
end)

-- morte/renascimento: o servidor encerra a missão; garante a limpeza local
player.CharacterRemoving:Connect(function()
	if inMission then exit() end
end)
