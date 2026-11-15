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

-- Coordenadas locais da cabine: X ±18, Z ±24, piso Y 0 e teto Y 14.
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
marker(mercury, "Bounds", 0, 7, 0, 36, 14, 48)
local spawns = B.group(mercury, "Spawns", "Folder")
for i, p in { { -5, -13 }, { 5, -13 }, { -5, -7 }, { 5, -7 } } do
	marker(spawns, "Spawn" .. i, p[1], 3, p[2], 1, 1, 1, CFrame.Angles(0, math.pi, 0))
end

---------------------------------------------------------------------------------
-- 2. Cabine fechada: vidros ocupam vãos reais, sem parede opaca por trás
---------------------------------------------------------------------------------
local shell = B.group(mercury, "Cabin")
local windows = B.group(mercury, "Windows", "Folder")
part(shell, "Floor", 0, -0.5, 0, 37, 1, 49, "darkGray", "Metal")
part(shell, "Ceiling", 0, 14.5, 0, 37, 1, 49, CREAM, "Metal")
part(shell, "RearBulkhead", 0, 7, -24.5, 37, 14, 1, CREAM, "Metal")
part(shell, "FrontSill", 0, 2, 24.5, 37, 4, 1, "midGray", "Metal")
part(shell, "FrontHeader", 0, 13, 24.5, 37, 2, 1, CREAM, "Metal")
for _, x in { -15.25, 15.25 } do
	part(shell, "FrontCheek", x, 8, 24.5, 6.5, 8, 1, CREAM, "Metal")
end
part(windows, "Front", 0, 8, 24.5, 24, 8, 1, "glass", "Glass", { transparency = 0.35 })
for _, side in { -1, 1 } do
	local x = side * 18.5
	part(shell, "SideSill", x, 2, 0, 1, 4, 48, "midGray", "Metal")
	part(shell, "SideHeader", x, 12.5, 0, 1, 3, 48, CREAM, "Metal")
	for _, z in { -15.5, 15.5 } do
		part(shell, "SideBulkhead", x, 7.5, z, 1, 7, 17, CREAM, "Metal")
	end
	part(windows, side == -1 and "Left" or "Right", x, 7.5, 0, 1, 7, 14, "glass", "Glass", { transparency = 0.35 })
	-- Molduras ficam nas bordas do vidro; nenhum montante cruza o campo de mira.
	for _, z in { -7.2, 7.2 } do
		part(shell, "WindowFrame", side * 17.94, 7.5, z, 0.12, 7.4, 0.3, "metalGray", "Metal", DECOR)
	end
	for _, y in { 3.85, 11.15 } do
		part(shell, "WindowFrame", side * 17.94, y, 0, 0.12, 0.3, 14.7, "metalGray", "Metal", DECOR)
	end
	-- Nervuras, painéis de serviço, cabos e rebites: fora do volume livre central.
	for _, z in { -22, -11, 11, 22 } do
		part(shell, "PressureRib", side * 17.8, 7, z, 0.25, 14, 0.3, "metalGray", "Metal", DECOR)
		part(shell, "ServicePanel", side * 17.65, 7, z, 0.12, 3.5, 3.2, "darkGray", "Metal", DECOR)
		for _, dy in { -1.4, 1.4 } do
			for _, dz in { -1.25, 1.25 } do
				part(shell, "Rivet", side * 17.55, 7 + dy, z + dz, 0.15, 0.15, 0.15, "metalGray", "Metal", DECOR, nil, "Ball")
			end
		end
	end
	for _, y in { 1.0, 1.35, 12.7 } do
		B.cylBetween(shell, "CableRun", BASE:PointToWorldSpace(Vector3.new(side * 17.6, y, -23)),
			BASE:PointToWorldSpace(Vector3.new(side * 17.6, y, 23)), 0.16, "black", "SmoothPlastic", DECOR)
	end
end
for _, x in { -12.2, 12.2 } do
	part(shell, "FrontWindowFrame", x, 8, 23.94, 0.3, 8.4, 0.12, "metalGray", "Metal", DECOR)
end
for _, y in { 3.85, 12.15 } do
	part(shell, "FrontWindowFrame", 0, y, 23.94, 24.7, 0.3, 0.12, "metalGray", "Metal", DECOR)
end
for _, z in { -23, -12, 0, 12, 23 } do
	part(shell, "CeilingRib", 0, 13.85, z, 36, 0.3, 0.35, "metalGray", "Metal", DECOR)
end
-- Faixas pintadas, sem ressaltos nem obstáculos entre as estações.
for _, x in { -7, 7 } do
	part(shell, "WalkwayStripe", x, 0.012, 0, 0.12, 0.02, 42, "safety", "SmoothPlastic", DECOR)
end

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
local frontCF = BASE * CFrame.new(0, 0, 21.5)
console(stations, "FlightPanel", frontCF, 22)
label(stations, "01  /  ATTITUDE CONTROL", frontCF * CFrame.new(0, 4.65, -1.02), 10, 0.65)
-- Periscópio ao lado do campo panorâmico principal.
part(stations, "Periscope", 14.5, 6, 21.8, 1.4, 3, 1.2, "darkGray", "Metal")
part(stations, "PeriscopeLens", 14.5, 5.8, 21.15, 1, 0.7, 0.1, "glass", "Glass", { transparency = 0.3 })
local prep = part(stations, "PrepConsole", -13, 3.5, -17, 4, 1.2, 1.8, "nasaBlue", "Metal")
part(stations, "PrepStand", -13, 1.45, -17, 2.8, 2.9, 1.4, "darkGray", "Metal")
label(stations, "MISSION PREPARATION", prep.CFrame * CFrame.new(0, 0, -0.94), 3.6, 0.8)
local exit = part(stations, "Exit", 12, 4.5, -23.85, 7, 9, 0.3, "darkGray", "Metal")
label(stations, "RETURN TO LCC", exit.CFrame * CFrame.new(0, 1.7, 0.2) * CFrame.Angles(0, math.pi, 0), 5.8, 0.8)
part(stations, "HatchWheel", 12, 4, -23.5, 2, 2, 0.2, "metalGray", "Metal", DECOR, nil, "Ball")

local nav = B.group(stations, "NavTable")
local navCF = BASE * CFrame.new(-13.5, 0, 2)
B.part(nav, "Tabletop", navCF * CFrame.new(0, 3.25, 0), Vector3.new(6, 0.4, 7), CREAM, "Metal")
for _, x in { -2.4, 2.4 } do
	for _, z in { -2.7, 2.7 } do
		B.part(nav, "TableLeg", navCF * CFrame.new(x, 1.5, z), Vector3.new(0.3, 3, 0.3), "metalGray", "Metal")
	end
end
B.part(nav, "ClipboardBacking", navCF * CFrame.new(0, 3.52, 0), Vector3.new(2.8, 0.12, 3.8), "rust", "Wood", DECOR)
-- A face Top fica livre: o código é responsabilidade do cliente.
B.part(nav, "Clipboard", navCF * CFrame.new(0, 3.63, 0), Vector3.new(2.5, 0.1, 3.5), "#F5EED8", "SmoothPlastic", DECOR)
B.part(nav, "Clip", navCF * CFrame.new(0, 3.74, -1.65), Vector3.new(0.8, 0.13, 0.22), "metalGray", "Metal", DECOR)
label(nav, "02  /  NAVIGATION", navCF * CFrame.new(0, 2.6, -3.56), 5.6, 0.65)

local radio = B.group(stations, "Radio")
local radioCF = BASE * CFrame.new(15, 0, -12) * CFrame.Angles(0, math.pi / 2, 0)
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
local reentryCF = BASE * CFrame.new(0, 0, -21) * CFrame.Angles(0, math.pi, 0)
console(reentry, "RetropackCabinet", reentryCF, 13)
for _, button in { { "RetainButtonA", -4, GREEN }, { "RetainButtonB", 4, GREEN }, { "EjectButton", 0, "red" } } do
	B.part(reentry, button[1], reentryCF * CFrame.new(button[2], 3.5, -1.4), Vector3.new(1, 1, 0.4), button[3], "SmoothPlastic")
	label(reentry, button[1] == "EjectButton" and "EJECT CAPSULE" or "HOLD RETROPACK",
		reentryCF * CFrame.new(button[2], 2.6, -1.3), 3.7, 0.5)
end
label(reentry, "03  /  RETROPACK", reentryCF * CFrame.new(0, 4.7, -1), 11, 0.65)

---------------------------------------------------------------------------------
-- 4. Luzes de cabine e alvos externos: linhas de mira a partir do piso + 5
---------------------------------------------------------------------------------
local lights = B.group(mercury, "Lights", "Folder")
for i, p in { { -10, -15 }, { 10, -15 }, { -10, 12 }, { 10, 12 } } do
	local lamp = part(lights, "CabinLight" .. i, p[1], 13.4, p[2], 3, 0.3, 1.5, "#FFF0D2", "Neon", DECOR)
	B.light(lamp, "PointLight", { Brightness = 1.8, Range = 30, Color = Color3.fromRGB(255, 235, 205), Shadows = false })
end
local exterior = B.group(mercury, "Exterior", "Folder")
local points = B.group(exterior, "AlignPoints", "Folder")
-- Frontal: 51,5 studs além do vidro; laterais: 53,5. Olhos em (±4,5,18)
-- e (±10,5,0) atravessam somente os vidros, acima dos consoles/mesa.
for i, p in { { -8, 7, 76 }, { 8, 7, 76 }, { -72, 7, 0 }, { 72, 7, 0 } } do
	part(points, "Point" .. i, p[1], p[2], p[3], 4, 4, 4, "red", "Neon", DECOR, nil, "Ball")
end
local plasma = B.group(exterior, "PlasmaEmitters", "Folder")
for i, p in { { -8, 4, 26 }, { 8, 4, 26 }, { -20, 4, -4 }, { -20, 4, 4 }, { 20, 4, -4 }, { 20, 4, 4 } } do
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
