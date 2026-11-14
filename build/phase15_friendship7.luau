--[[
	NASA Space Adventure — Fase 15: missão Friendship 7 dentro da cápsula (missaoUm.md)

	A cápsula continua a da Fase 8 (NASAComplex.OrionInterior): esta fase só acrescenta
	objetos ao console e instala os scripts da missão. Nada da Fase 8 é movido nem apagado.

	Peças (OrionInterior.Friendship7Mission, BuildPhase = 15):
	- ControlPanel: botão AUTOPILOT OFF; tela = Display_Unit_1 (ObjectValue Display).
	- CommunicationPanel: CONFIRM, EJECT CAPSULE e as folhas de procedimento (PaperDocument,
	  uma em cada Switch_Panel, para o comandante e o piloto); tela = Display_Unit_2.
	- ReentryPanel: JETTISON RETROPACK e RETAIN RETROPACK; tela = Display_Unit_3.
	- RetryButton (repetir a tarefa depois de uma falha).
	- MissionStart: âncoras invisíveis diante das telas 1 (CDR) e 3 (PLT) com o prompt
	  "Start mission" (atributo MissionStart, ObjectValue SeatRef → assento).
	- MissionEffects.WarningLights: duas luzes de alerta (PointLight desligada; o cliente acende).
	Botões: Models com o atributo MissionButton (ação); peças Base e Cap aceitam o raio do cliente.
	O que cada jogador vê nas telas, no papel e nas janelas é desenhado no cliente dele.

	Scripts (fonte em build/mission/, baixada pelo mesmo servidor HTTP):
	- ReplicatedStorage.MissionSystem: Remotes (StartMission, MissionUpdate, MissionAction,
	  SubmitCode, SubmitChoice) e Config.Friendship7Config.
	- ServerScriptService.MissionSystem.Friendship7MissionService (+ Task1/2/3 como módulos).
	- StarterPlayerScripts.MissionClient.MissionController (+ controladores como módulos).

	Com o Rojo (default.project.json) conectado, os scripts vêm dele e esta fase só cria as peças.
	Executar depois da Fase 8 (o run_in_studio.luau já inclui esta fase).
]]

local lib = ...
local B = lib.builder(15)

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map and Map:FindFirstChild("OrionInterior"), "Execute a Fase 8 antes")
B.clear(Map)

local cab = Map.OrionInterior
local con = cab.Console
local seats = cab.Crew_Seats
local DECOR_NS = { collide = false, shadow = false }
local HIDDEN = { collide = false, shadow = false, transparency = 1 }
local N = Enum.NormalId
local top = con.Console_Top
local TOP = top.Position.Y + top.Size.Y / 2 -- topo do console (Y −56,4)
local BX = 11.35 -- fileira dos botões (os controladores manuais ficam em X 10,4..11,2)
local LX = 10.66 -- plaquetas, na borda do console voltada para a tripulação

local function ref(parent, name, value)
	local v = Instance.new("ObjectValue")
	v.Name = name
	v.Value = value
	v:SetAttribute("BuildPhase", 15)
	v.Parent = parent
	return v
end

local root = B.group(cab, "Friendship7Mission")
local ctl = B.group(root, "ControlPanel")
local com = B.group(root, "CommunicationPanel")
local ree = B.group(root, "ReentryPanel")
local fx = B.group(root, "MissionEffects")
local starts = B.group(root, "MissionStart")
ref(ctl, "Display", con.Display_Unit_1)
ref(com, "Display", con.Display_Unit_2)
ref(ree, "Display", con.Display_Unit_3)

---------------------------------------------------------------------------------
-- 1. Botões físicos no topo do console (um Model por botão)
---------------------------------------------------------------------------------
local function plate(parent, z, w, text, color)
	local pos = Vector3.new(LX, TOP + 0.02, z)
	-- frente da peça para +Z: na face Top o texto corre em +Z e o topo das letras aponta para +X,
	-- então fica de pé para quem está sentado olhando o console (conferido em captura)
	local p = B.part(parent, "Label", CFrame.lookAt(pos, pos + Vector3.zAxis), Vector3.new(0.46, 0.04, w), "black", "SmoothPlastic", DECOR_NS)
	B.sign(p, text, nil, { face = N.Top, bg = "black", titleColor = color or "white", ppu = 110 })
	return p
end

local function button(parent, name, action, z, color, text, o)
	o = o or {}
	local m = B.group(parent, name)
	m:SetAttribute("MissionButton", action)
	local dia = o.dia or 0.55
	local base = B.cyl(m, "Base", BX, z, TOP, TOP + 0.1, dia + 0.26, o.base or "darkGray", "Metal")
	local cap = B.cyl(m, "Cap", BX, z, TOP + 0.1, TOP + 0.28, dia, color, "SmoothPlastic")
	for _, p in { base, cap } do
		p.CanCollide = false -- CanQuery continua true: o raio do cliente precisa achar o botão
		p.CastShadow = false
	end
	m.PrimaryPart = cap
	plate(m, z, o.labelW or 1.15, text, o.textColor)
	return m
end

button(ctl, "AutopilotButton", "Autopilot", 260.2, "#C8281E", "AUTOPILOT\nOFF", { textColor = "#FF6B5E" })
button(root, "RetryButton", "Retry", 263.0, "#E0A21C", "RETRY", { textColor = "safety", labelW = 1.0 })
button(com, "ConfirmButton", "Confirm", 264.3, "#2E9E4F", "CONFIRM", { textColor = "#46E07A", labelW = 1.1 })
local eject = button(com, "EjectButton", "Eject", 265.7, "#C8281E", "EJECT\nCAPSULE", { base = "safety", textColor = "#FF6B5E", labelW = 1.1 })
-- guarda da ejeção (duas hastes listradas ao lado do botão)
for _, dz in { -0.45, 0.45 } do
	B.box(eject, "Guard", BX - 0.05, BX + 0.05, TOP, TOP + 0.36, 265.7 + dz - 0.04, 265.7 + dz + 0.04, "black", "Metal", DECOR_NS)
end
button(ree, "JettisonButton", "Jettison", 266.95, "#C8281E", "JETTISON\nRETROPACK", { textColor = "#FF6B5E", labelW = 1.1 })
button(ree, "RetainButton", "Retain", 269.5, "#2E9E4F", "RETAIN\nRETROPACK", { dia = 0.75, textColor = "#46E07A", labelW = 1.3 })

---------------------------------------------------------------------------------
-- 2. Folhas de procedimento de emergência, presas aos painéis de chaves laterais
--    (face Back = voltada para dentro da cabine, como a SurfaceGui do painel)
---------------------------------------------------------------------------------
local doc = B.group(com, "PaperDocument")
local panels = {}
for _, d in cab:GetChildren() do
	if d.Name == "Switch_Panel" and d:IsA("BasePart") then table.insert(panels, d) end
end
table.sort(panels, function(a, b) return a.Position.Z < b.Position.Z end)
for _, sp in panels do
	local cf = sp.CFrame * CFrame.new(0.55, -0.05, 0.075) * CFrame.Angles(0, 0, math.rad(-2.5))
	local paper = B.part(doc, "Paper", cf, Vector3.new(1.9, 2.15, 0.02), "#F3EEDC", "SmoothPlastic", DECOR_NS)
	B.sign(paper, "EMERGENCY PROCEDURE", "RESTORATION CODE: issued during a communication blackout.\n\nENTER THE CODE AT THE RADIO TERMINAL.",
		{ face = N.Back, bg = "#F3EEDC", titleColor = "#B3261E", bodyColor = "#1D2330", titleScale = 0.22, ppu = 150, maxBody = 22 })
	B.part(doc, "Clip", sp.CFrame * CFrame.new(0.55, 1.05, 0.1), Vector3.new(0.7, 0.2, 0.07), "metalGray", "Metal", DECOR_NS)
end

---------------------------------------------------------------------------------
-- 3. Início da missão: prompt diante da tela de cada assento da frente
---------------------------------------------------------------------------------
for _, s in { { "Seat_CDR", 1 }, { "Seat_PLT", 3 } } do
	local d = con["Display_Unit_" .. s[2]]
	local a = B.part(starts, "MissionStart_" .. string.sub(s[1], 6), d.CFrame * CFrame.new(0, 0, -0.5), Vector3.new(0.4, 0.4, 0.4), "white", "SmoothPlastic", HIDDEN)
	ref(a, "SeatRef", seats[s[1]].Seat)
	local pr = Instance.new("ProximityPrompt")
	pr.ObjectText = "Friendship 7"
	pr.ActionText = "Start mission"
	pr.KeyboardKeyCode = Enum.KeyCode.F
	pr.GamepadKeyCode = Enum.KeyCode.ButtonX
	pr.HoldDuration = 0.4
	pr.MaxActivationDistance = 7
	pr.RequiresLineOfSight = false
	pr.Enabled = false -- o cliente mostra só para quem está sentado neste assento
	pr:SetAttribute("MissionStart", true)
	pr:SetAttribute("BuildPhase", 15)
	pr.Parent = a
end

---------------------------------------------------------------------------------
-- 4. Luzes de alerta (acima das janelas da frente)
---------------------------------------------------------------------------------
local wl = B.group(fx, "WarningLights")
for _, z in { 262.4, 267.6 } do
	B.part(wl, "Warning_Light_Base", CFrame.new(9.7, -47.05, z), Vector3.new(0.7, 0.15, 0.7), "darkGray", "Metal", DECOR_NS)
	local b = B.part(wl, "Warning_Light", CFrame.new(9.7, -47.3, z), Vector3.new(0.5, 0.35, 0.5), "#5A1E19", "SmoothPlastic", DECOR_NS)
	B.light(b, "PointLight", { Enabled = false, Range = 16, Brightness = 3, Color = Color3.fromRGB(255, 90, 40), Shadows = false })
end
B.group(fx, "WindowEffects", "Folder") -- Terra e plasma: SurfaceGuis criadas no cliente
B.group(fx, "AudioSources", "Folder") -- sons: AudioPlayers criados no cliente (AudioController)

---------------------------------------------------------------------------------
-- 5. Scripts da missão
---------------------------------------------------------------------------------
local H = game:GetService("HttpService")
local BASE = "http://127.0.0.1:8765/mission/"
local function src(file)
	return H:GetAsync(BASE .. file .. "?t=" .. os.clock(), true)
end
local function folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end
local function put(class, parent, name, file)
	local s = Instance.new(class)
	s.Name = name
	s.Source = src(file)
	s.Parent = parent
	return s
end
local function fresh(parent, name)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	return folder(parent, name)
end

local RS = game:GetService("ReplicatedStorage")
-- Com o Rojo conectado (default.project.json), os scripts e remotes vêm do Rojo, que marca
-- ReplicatedStorage.MissionSystem com o atributo RojoManaged: aí esta fase não os reinstala.
local existing = RS:FindFirstChild("MissionSystem")
local rojo = existing ~= nil and existing:GetAttribute("RojoManaged") == true
if not rojo then
	local ms = fresh(RS, "MissionSystem")
	local remotes = folder(ms, "Remotes")
	for _, n in { "StartMission", "MissionUpdate", "MissionAction", "SubmitCode", "SubmitChoice" } do
		local r = Instance.new("RemoteEvent")
		r.Name = n
		r.Parent = remotes
	end
	put("ModuleScript", folder(ms, "Config"), "Friendship7Config", "Friendship7Config.luau")

	local server = fresh(game:GetService("ServerScriptService"), "MissionSystem")
	local svc = Instance.new("Script")
	svc.Name = "Friendship7MissionService"
	svc.Source = src("Friendship7MissionService.server.luau")
	for _, n in { "Task1ControlService", "Task2CommunicationService", "Task3ReentryService" } do
		put("ModuleScript", svc, n, n .. ".luau")
	end
	svc.Parent = server

	local sps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local client = fresh(sps, "MissionClient")
	local ctrl = Instance.new("LocalScript")
	ctrl.Name = "MissionController"
	ctrl.Source = src("MissionController.client.luau")
	for _, n in { "FirstPersonController", "CameraShakeController", "GazeInteractionController", "PanelInteractionController", "AudioController", "PanelDisplays" } do
		put("ModuleScript", ctrl, n, n .. ".luau")
	end
	ctrl.Parent = client

end
local n = 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then n += 1 end
end
return string.format("Fase 15: missão Friendship 7 — %d peças no console; scripts: %s", n, rojo and "gerenciados pelo Rojo (não reinstalados)" or "instalados de build/mission/")
