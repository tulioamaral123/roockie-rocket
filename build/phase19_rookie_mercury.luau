--[[
	NASA Space Adventure — Fase 19: Mercury ampliada e Mission Briefing no LCC.
	Contrato: docs/rookie-contrato.md. Só geometria, placas fixas, luzes e plasma desligado.
	Executar depois das Fases 12/14. Não depende da Orion nem instala sistemas.
]]

local lib = ...
local B = lib.builder(19)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as fases de estrutura antes")
local lcc = Map:FindFirstChild("LaunchControlCenter")
assert(lcc and lcc:IsA("Model"), "Execute a Fase 12 antes")
local architecture = lcc:FindFirstChild("Architecture")
local walls = architecture and architecture:FindFirstChild("Walls")
local northDoor = walls and walls:FindFirstChild("North_Lintel")
local floors = lcc:FindFirstChild("Floors")
-- Busca recursiva: o piso pode estar agrupado com os acabamentos do LCC.
local lobbyFloor = (floors and floors:FindFirstChild("Lobby_Floor")) or lcc:FindFirstChild("Lobby_Floor", true)
assert(northDoor and lobbyFloor, "LCC sem North_Lintel ou Lobby_Floor")

---------------------------------------------------------------------------------
-- 1. Retira a missão sentada antiga e somente as peças desta fase
---------------------------------------------------------------------------------
local oldBuilder = lib.builder(15)
oldBuilder.clear(Map)
for _, entry in {
	{ game:GetService("ReplicatedStorage"), "MissionSystem" },
	{ game:GetService("ServerScriptService"), "MissionSystem" },
	{ game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"), "MissionClient" },
} do
	local old = entry[1] and entry[1]:FindFirstChild(entry[2])
	if old then old:Destroy() end
end
B.clear(Map)

-- A raiz compartilhada não recebe BuildPhase: limpar 19 nunca remove a ISS (20).
local root = Map:FindFirstChild("RookieRocket")
if not root then
	root = Instance.new("Folder")
	root.Name = "RookieRocket"
	root.Parent = Map
end
assert(root:IsA("Folder"), "NASAComplex.RookieRocket deve ser Folder")

local DECOR = { collide = false, shadow = false }
local HIDDEN = { collide = false, shadow = false, transparency = 1 }
local CREAM = "#D9D2BC"
local GREEN = "#45B868"
local BASE = CFrame.new(-3000, 1200, 0)
local N = Enum.NormalId
local mercury = B.group(root, "Mercury")
mercury.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

-- Cápsula de 16 lados inspirada na Orion: Ø32 no piso, Ø24 no teto, H15.
local function part(parent, name, x, y, z, sx, sy, sz, color, material, options, rotation, shape)
	return B.part(parent, name, BASE * CFrame.new(x, y, z) * (rotation or CFrame.identity),
		Vector3.new(sx, sy, sz), color, material, options, shape)
end
local function marker(parent, name, x, y, z, sx, sy, sz, rotation)
	return part(parent, name, x, y, z, sx or 1, sy or 1, sz or 1, "white", "SmoothPlastic", HIDDEN, rotation)
end
local function label(parent, text, cf, width, height, face)
	local p = B.part(parent, "Label", cf, Vector3.new(width, height, 0.06), "black", "SmoothPlastic", DECOR)
	B.sign(p, text, nil, { face = face or N.Front, bg = "black", titleColor = CREAM, ppu = 60 })
	return p
end
mercury.PrimaryPart = marker(mercury, "Origin", 0, 0, 0)
marker(mercury, "Bounds", 0, 7.5, 0, 32, 15, 32)
local spawns = B.group(mercury, "Spawns", "Folder")
for i, p in { { -3, -4 }, { 3, -4 }, { -3, 2 }, { 3, 2 } } do
	marker(spawns, "Spawn" .. i, p[1], 3, p[2], 1, 1, 1, CFrame.Angles(0, math.pi, 0))
end

---------------------------------------------------------------------------------
-- 2. Cabine fechada: vidros ocupam vãos reais, sem parede opaca por trás
---------------------------------------------------------------------------------
local shell = B.group(mercury, "Cabin")
local windows = B.group(mercury, "Windows", "Folder")
local sides, height = 16, 15
local ap0, ap1 = 16 * math.cos(math.pi / sides), 12 * math.cos(math.pi / sides)
local width = 2 * ap0 * math.tan(math.pi / sides) + 0.12
local slope = math.sqrt(height ^ 2 + (ap0 - ap1) ^ 2)
local function wallCF(k, h)
	local a = k * 2 * math.pi / sides
	local radial = Vector3.new(math.cos(a), 0, math.sin(a))
	local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
	local up = (Vector3.new(0, height, 0) + radial * (ap1 - ap0)).Unit
	return BASE * CFrame.fromMatrix(radial * (ap0 + (ap1 - ap0) * h / height) + Vector3.new(0, h, 0), tangent, up)
end
-- Vidros substituem painéis; nenhuma parede opaca fica atrás dos alvos.
for k = 0, sides - 1 do
	local glass = k == 0 or k == 8 or k == 3 or k == 4 or k == 5
	if glass then
		for _, band in { { 2, 4 }, { 13, 4 } } do
			B.part(shell, "WindowBulkhead", wallCF(k, band[1]), Vector3.new(width, band[2] * slope / height, 0.5), CREAM, "Metal")
		end
		B.part(windows, "Window" .. k, wallCF(k, 7.5), Vector3.new(width, 7 * slope / height, 0.5), "glass", "Glass", { transparency = 0.35 })
	else
		B.part(shell, "PressurePanel", wallCF(k, 7.5), Vector3.new(width, slope, 0.5), CREAM, "Metal")
	end
	B.part(shell, "PressureRib", wallCF(k, 7.5) * CFrame.new(width / 2 - 0.1, 0, 0), Vector3.new(0.16, slope, 0.65), "metalGray", "Metal", DECOR)
	B.part(shell, "PanelTrim", wallCF(k, 2), Vector3.new(width - 0.3, 0.18, 0.65), "darkGray", "Metal", DECOR)
end
part(shell, "Floor", 0, -0.5, 0, 1, 32.6, 32.6, "darkGray", "Metal", nil, CFrame.Angles(0, 0, math.pi / 2), "Cylinder")
part(shell, "Ceiling", 0, 15.25, 0, 0.5, 24.6, 24.6, CREAM, "Metal", nil, CFrame.Angles(0, 0, math.pi / 2), "Cylinder")
marker(mercury, "CapsuleBounds", 0, 7.5, 0, 32, 15, 32)

---------------------------------------------------------------------------------
-- 3. Consoles anos 60: instrumentos físicos, chaves e placas fixas
---------------------------------------------------------------------------------
local stations = B.group(mercury, "Stations", "Folder")
local function console(parent, name, cf, width)
	local body = B.part(parent, name, cf * CFrame.new(0, 2.1, 0), Vector3.new(width, 4.2, 2), "darkGray", "Metal")
	B.part(parent, "InstrumentPanel", cf * CFrame.new(0, 3.1, -1.04), Vector3.new(width - 0.3, 1.9, 0.08), CREAM, "Metal", DECOR)
	for x = -width / 2 + 0.9, width / 2 - 0.7, 1.7 do
		-- Eixo do cilindro girado para Z, mostrador na face voltada ao jogador.
		B.part(parent, "GaugeRim", cf * CFrame.new(x, 3.25, -1.13) * CFrame.Angles(0, math.pi / 2, 0),
			Vector3.new(0.12, 0.85, 0.85), "metalGray", "Metal", DECOR, "Cylinder")
		B.part(parent, "GaugeFace", cf * CFrame.new(x, 3.25, -1.21) * CFrame.Angles(0, math.pi / 2, 0),
			Vector3.new(0.04, 0.68, 0.68), "black", "SmoothPlastic", DECOR, "Cylinder")
		B.part(parent, "GaugeNeedle", cf * CFrame.new(x + 0.06, 3.31, -1.25) * CFrame.Angles(0, 0, -0.4),
			Vector3.new(0.04, 0.48, 0.025), CREAM, "SmoothPlastic", DECOR)
		B.part(parent, "Toggle", cf * CFrame.new(x, 2.5, -1.2) * CFrame.Angles(0.3, 0, 0),
			Vector3.new(0.12, 0.3, 0.2), "metalGray", "Metal", DECOR)
	end
	return body
end
local frontCF = BASE * CFrame.new(0, 0, 10)
console(stations, "FlightPanel", frontCF, 12)
label(stations, "01  /  ATTITUDE CONTROL", frontCF * CFrame.new(0, 4.65, -1.02), 10, 0.65)
-- Periscópio ao lado do campo panorâmico principal.
part(stations, "Periscope", 7, 6, 10, 1.4, 3, 1.2, "darkGray", "Metal")
part(stations, "PeriscopeLens", 7, 5.8, 9.35, 1, 0.7, 0.1, "glass", "Glass", { transparency = 0.3 })
local prep = part(stations, "PrepConsole", -6, 3.5, -9, 4, 1.2, 1.8, "nasaBlue", "Metal")
part(stations, "PrepStand", -6, 1.45, -9, 2.8, 2.9, 1.4, "darkGray", "Metal")
label(stations, "FLIGHT MANIFEST", prep.CFrame * CFrame.new(0, 0, -0.94), 3.6, 0.8)
local exit = part(stations, "Exit", 0, 4.5, -13.7, 7, 9, 0.3, "darkGray", "Metal")
label(stations, "RETURN TO LCC", exit.CFrame * CFrame.new(0, 1.7, 0.2) * CFrame.Angles(0, math.pi, 0), 5.8, 0.8)
part(stations, "HatchWheel", 0, 4, -13.4, 2, 2, 0.2, "metalGray", "Metal", DECOR, nil, "Ball")

local nav = B.group(stations, "NavTable")
local navCF = BASE * CFrame.new(-10.5, 0, 0)
B.part(nav, "Tabletop", navCF * CFrame.new(0, 3.25, 0), Vector3.new(4, 0.4, 5), CREAM, "Metal")
for _, x in { -1.4, 1.4 } do
	for _, z in { -1.7, 1.7 } do
		B.part(nav, "TableLeg", navCF * CFrame.new(x, 1.5, z), Vector3.new(0.3, 3, 0.3), "metalGray", "Metal")
	end
end
B.part(nav, "ClipboardBacking", navCF * CFrame.new(0, 3.52, 0), Vector3.new(2.8, 0.12, 3.8), "rust", "Wood", DECOR)
-- A face Top fica livre: o código é responsabilidade do cliente.
B.part(nav, "Clipboard", navCF * CFrame.new(0, 3.63, 0), Vector3.new(2.5, 0.1, 3.5), "#F5EED8", "SmoothPlastic", DECOR)
B.part(nav, "Clip", navCF * CFrame.new(0, 3.74, -1.65), Vector3.new(0.8, 0.13, 0.22), "metalGray", "Metal", DECOR)
label(nav, "02  /  NAVIGATION", navCF * CFrame.new(0, 2.6, -2.56), 5.6, 0.65)

local radio = B.group(stations, "Radio")
local radioCF = BASE * CFrame.new(9, 0, 4) * CFrame.Angles(0, math.pi / 2, 0)
console(radio, "Cabinet", radioCF, 8)
-- Controles a 3,5 studs, na face livre voltada ao corredor.
B.part(radio, "Keypad", radioCF * CFrame.new(-1.5, 3.5, -1.4), Vector3.new(2, 1.1, 0.4), "black", "Metal")
for row = 0, 2 do
	for col = 0, 2 do
		B.part(radio, "Key", radioCF * CFrame.new(-2.1 + col * 0.6, 3.15 + row * 0.34, -1.63),
			Vector3.new(0.4, 0.22, 0.06), CREAM, "SmoothPlastic", DECOR)
	end
end
B.part(radio, "EjectButton", radioCF * CFrame.new(2, 3.5, -1.4), Vector3.new(0.9, 0.9, 0.4), "red", "Neon")
label(radio, "EJECT CAPSULE", radioCF * CFrame.new(2, 2.65, -1.3), 3, 0.45)
label(radio, "03  /  RADIO", radioCF * CFrame.new(0, 4.7, -1), 7, 0.65)

local reentry = B.group(stations, "Reentry")
local reentryCF = BASE * CFrame.new(9, 0, -7) * CFrame.Angles(0, math.pi, 0)
console(reentry, "RetropackCabinet", reentryCF, 8)
for _, button in { { "RetainButtonA", -3.5, GREEN }, { "RetainButtonB", 3.5, GREEN }, { "EjectButton", 0, "red" } } do
	B.part(reentry, button[1], reentryCF * CFrame.new(button[2], 3.5, -1.4), Vector3.new(1, 1, 0.4), button[3], "SmoothPlastic")
	label(reentry, button[1] == "EjectButton" and "EJECT CAPSULE" or "HOLD RETROPACK",
		reentryCF * CFrame.new(button[2], 2.6, -1.3), 3.7, 0.5)
end
label(reentry, "03  /  RETROPACK", reentryCF * CFrame.new(0, 4.7, -1), 11, 0.65)

---------------------------------------------------------------------------------
-- 4. Luzes de cabine e alvos externos: linhas de mira a partir do piso + 5
---------------------------------------------------------------------------------
local lights = B.group(mercury, "Lights", "Folder")
for i, p in { { -5, -5 }, { 5, -5 }, { -5, 5 }, { 5, 5 } } do
	local lamp = part(lights, "CabinLight" .. i, p[1], 14.4, p[2], 3, 0.3, 1.5, "#FFF0D2", "Neon", DECOR)
	B.light(lamp, "PointLight", { Brightness = 1.8, Range = 30, Color = Color3.fromRGB(255, 235, 205), Shadows = false })
end
local exterior = B.group(mercury, "Exterior", "Folder")
local points = B.group(exterior, "AlignPoints", "Folder")
-- Alvos alinhados aos vidros, visíveis do corredor central na altura dos olhos.
for i, p in { { -12, 6, 65 }, { 12, 6, 65 }, { -64, 6, 0 }, { 64, 6, 0 } } do
	part(points, "Point" .. i, p[1], p[2], p[3], 4, 4, 4, "red", "Neon", DECOR, nil, "Ball")
end
local plasma = B.group(exterior, "PlasmaEmitters", "Folder")
for i, p in { { -5, 4, 17 }, { 5, 4, 17 }, { -17, 4, -3 }, { -17, 4, 3 }, { 17, 4, -3 }, { 17, 4, 3 } } do
	local anchor = marker(plasma, "Emitter" .. i, p[1], p[2], p[3])
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Plasma"
	emitter.Enabled = false
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 55, 15))
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Brightness = 3
	emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	emitter.Rate = 35
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Speed = NumberRange.new(12, 20)
	emitter.EmissionDirection = N.Top
	emitter.SpreadAngle = Vector2.new(18, 18)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 3), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.6, 0.4), NumberSequenceKeypoint.new(1, 1) })
	emitter:SetAttribute("BuildPhase", 19)
	emitter.Parent = anchor
end

---------------------------------------------------------------------------------
-- 5. Quiosque no saguão real, a oeste do eixo porta sul → porta norte
---------------------------------------------------------------------------------
-- A base acompanha o pivot atual do modelo (inclusive rotação/translação).
-- A porta norte define o eixo; o piso define altura e profundidade do saguão.
local floorPose = lcc:GetPivot()
local doorLocal = floorPose:PointToObjectSpace(northDoor.Position)
local lobbyLocal = floorPose:PointToObjectSpace(lobbyFloor.Position)
local floorY = lobbyLocal.Y + lobbyFloor.Size.Y / 2
local kioskBase = floorPose * CFrame.new(doorLocal.X - 4.8, floorY, lobbyLocal.Z + 6)
	* CFrame.Angles(0, -math.pi / 2, 0)
local kiosk = B.group(root, "Kiosk")
kiosk.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local function kioskPart(name, x, y, z, sx, sy, sz, color, options)
	return B.part(kiosk, name, kioskBase * CFrame.new(x, y, z), Vector3.new(sx, sy, sz), color, "Metal", options)
end
-- Profundidade total de 1,4; borda leste ainda a 4,1 studs do eixo de passagem.
kioskPart("Cabinet", 0, 3.4, 0, 9, 6.8, 0.9, "darkGray")
kioskPart("ScreenFrame", 0, 4.8, -0.5, 8.5, 5, 0.2, "metalGray", DECOR)
kioskPart("Screen", 0, 4.8, -0.64, 8, 4.5, 0.08, "black", DECOR)
local heading = kioskPart("Heading", 0, 8, 0, 9, 1.1, 0.8, "nasaBlue")
B.sign(heading, "MISSION BRIEFING", nil, { bg = "nasaBlue", titleColor = "white" })
for _, entry in { { "BoardMercury", -2.3, "MERCURY" }, { "BoardISS", 2.3, "ISS" } } do
	local board = kioskPart(entry[1], entry[2], 1.5, -0.6, 3.9, 1, 0.4, "nasaBlue")
	B.sign(board, entry[3], nil, { bg = "nasaBlue", titleColor = "white" })
end
kioskPart("ReturnPoint", 0, 3, -4.8, 1, 1, 1, "white", HIDDEN)

local count = 0
for _, instance in mercury:GetDescendants() do
	if instance:IsA("BasePart") then count += 1 end
end
local kioskCount = 0
for _, instance in kiosk:GetDescendants() do
	if instance:IsA("BasePart") then kioskCount += 1 end
end
return string.format("Fase 19: Mercury %d peças; quiosque %d peças em %s; missão antiga removida", count, kioskCount, tostring(kioskBase.Position))
