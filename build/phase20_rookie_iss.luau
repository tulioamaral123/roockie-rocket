--[[
	NASA Space Adventure — Fase 20: ISS da Rookie Rocket.
	Contrato: docs/rookie-contrato.md (regras comuns + ISS).
	Só geometria própria, luzes e emissores desligados; sistemas vêm da Fase 21.
	Coordenadas abaixo são locais a (3000, 1200, 0), sem mover a raiz compartilhada.
]]
local lib = ...
local B = lib.builder(20)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1 e 2 antes")
B.clear(Map)

-- Não marcar esta pasta com BuildPhase: ela também pertence à Fase 19.
local root = Map:FindFirstChild("RookieRocket")
if not root then
	root = Instance.new("Folder")
	root.Name = "RookieRocket"
	root.Parent = Map
end
assert(root:IsA("Folder"), "NASAComplex.RookieRocket deve ser Folder")

local V, CF, RAD = Vector3.new, CFrame.new, math.rad
local BASE = CF(3000, 1200, 0)
local DECOR = { collide = false, shadow = false }
local HIDDEN = { collide = false, shadow = false, transparency = 1 }
local GLASS = { transparency = 0.35 }
local iss = B.group(root, "ISS")
iss.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

local function part(parent, name, cf, size, color, material, opts, shape)
	return B.part(parent, name, BASE * cf, size, color or "lightGray", material or "SmoothPlastic", opts, shape)
end

local function box(parent, name, x0, x1, y0, y1, z0, z1, color, material, opts)
	return B.box(parent, name, 3000 + x0, 3000 + x1, 1200 + y0, 1200 + y1, z0, z1, color or "lightGray", material, opts)
end

local function marker(parent, name, cf, size)
	return part(parent, name, cf, size or V(1, 1, 1), "black", nil, HIDDEN)
end

local function beam(parent, name, a, b, diameter, color)
	return B.cylBetween(parent, name, BASE:PointToWorldSpace(a), BASE:PointToWorldSpace(b), diameter, color or "metalGray", "Metal", DECOR)
end

local function sign(parent, name, cf, size, title, body)
	local plate = part(parent, name, cf, size, "nasaBlue", "Metal", DECOR)
	B.sign(plate, title, body, { bg = "nasaBlue", titleColor = "white", bodyColor = "lightGray" })
	return plate
end

local origin = marker(iss, "Origin", CF())
iss.PrimaryPart = origin
local spawns = B.group(iss, "Spawns", "Folder")
for i = 1, 4 do
	marker(spawns, "Spawn" .. i, CF(-6 + (i - 1) * 4, 3, -16) * CFrame.Angles(0, math.pi, 0))
end
marker(iss, "Bounds", CF(10, 6, -2), V(58, 24, 110))

local habitat = B.group(iss, "Habitat")
local adjacent = B.group(iss, "AdjacentModule")
local cupola = B.group(iss, "Cupola")
local airlock = B.group(iss, "Airlock")
local stations = B.group(iss, "Stations", "Folder")
local exterior = B.group(iss, "Exterior", "Folder")
local lights = B.group(iss, "Lights", "Folder")

--------------------------------------------------------------------------------
-- Casco fechado: piso Y0, teto Y16; ligações sem soleira e vão livre 10 × 12.
--------------------------------------------------------------------------------
box(habitat, "Floor", -18, 18, -0.8, 0, -24, 24, "paleGray", "Metal")
box(habitat, "Ceiling", -18.6, 18.6, 16, 16.8, -24.6, 24.6)
box(habitat, "PortWall", -18.6, -18, 0, 16, -24.6, 24.6)
box(habitat, "StarboardAftWall", 18, 18.6, 0, 16, 10, 24.6)
box(habitat, "StarboardForwardWall", 18, 18.6, 0, 16, -24.6, -10)
box(habitat, "AirlockLintel", 18, 18.6, 12, 16, -10, 10)
-- Ligação frontal à Cupola, corredor de 12 studs de largura.
for _, side in { -1, 1 } do
	local x0, x1 = side == -1 and -18 or 6, side == -1 and -6 or 18
	box(habitat, "CupolaBulkhead", x0, x1, 0, 16, -24.6, -24)
	local ax0, ax1 = side == -1 and -18 or 5, side == -1 and -5 or 18
	box(adjacent, "HatchBulkhead", ax0, ax1, 0, 16, 23.6, 24.4)
end
box(habitat, "CupolaLintel", -6, 6, 12, 16, -24.6, -24)
box(adjacent, "HatchLintel", -5, 5, 12, 16, 23.6, 24.4)
box(adjacent, "Floor", -18, 18, -0.8, 0, 24, 52)
box(adjacent, "Ceiling", -18.6, 18.6, 16, 16.8, 24, 52.6)
box(adjacent, "PortWall", -18.6, -18, 0, 16, 24, 52.6)
box(adjacent, "StarboardWall", 18, 18.6, 0, 16, 24, 52.6)
box(adjacent, "EndWall", -18.6, 18.6, 0, 16, 52, 52.6)

-- Racks rasos deixam mais de 24 studs livres no eixo central.
local function rack(parent, cf, index)
	part(parent, "RackFrame", cf, V(2, 13, 6.6), "metalGray", "Metal")
	for row = 0, 3 do
		local panelCF = cf * CF(-1.08, -4.5 + row * 3, 0)
		part(parent, "RackPanel", panelCF, V(0.16, 2.7, 6.2), row % 2 == 0 and "white" or "paleGray", "Metal", DECOR)
		for _, z in { -2.3, 2.3 } do
			part(parent, "RackHandle", panelCF * CF(-0.28, 0, z), V(0.18, 1.25, 0.16), "nasaBlue", "Metal", DECOR)
			for _, y in { -0.55, 0.55 } do
				part(parent, "HandleMount", panelCF * CF(-0.14, y, z), V(0.3, 0.12, 0.18), "metalGray", "Metal", DECOR)
			end
		end
		if row == 2 then
			part(parent, "RackScreen", panelCF * CF(-0.11, 0, 0), V(0.06, 1.5, 2.6), "darkBlue", "SmoothPlastic", DECOR)
			for line = 0, 2 do
				part(parent, "ScreenTelemetry", panelCF * CF(-0.15, -0.45 + line * 0.4, 0), V(0.03, 0.07, 1.7 - line * 0.3), "lightBlue", "Neon", DECOR)
			end
		end
	end
	local p = part(parent, "RackLabel", cf * CF(-1.18, 6, 0) * CFrame.Angles(0, math.pi / 2, 0), V(4.5, 0.55, 0.06), "nasaBlue", nil, DECOR)
	B.sign(p, "SYSTEM RACK " .. index, nil, { titleColor = "white", bg = "nasaBlue" })
end
for i, z in { -19, -3, 7, 19 } do
	rack(habitat, CF(-16.8, 7, z) * CFrame.Angles(0, math.pi, 0), i)
end
for i, z in { -19, 19 } do
	rack(habitat, CF(16.8, 7, z), i + 4)
end
for i, x in { -16.8, 16.8 } do
	rack(adjacent, CF(x, 7, 36) * CFrame.Angles(0, i == 1 and math.pi or 0, 0), i + 6)
end
for _, x in { -14, 14 } do
	beam(habitat, "OverheadCable", V(x, 14.6, -23), V(x, 14.6, 23), 0.22, "darkGray")
	beam(adjacent, "OverheadCable", V(x, 14.6, 25), V(x, 14.6, 51), 0.22, "nasaBlue")
	for z = -20, 20, 8 do
		part(habitat, "CableClamp", CF(x, 14.6, z), V(0.55, 0.55, 0.2), "metalGray", "Metal", DECOR)
		part(habitat, "FloorGuide", CF(x, 0.03, z), V(0.12, 0.04, 5), "nasaBlue", nil, DECOR)
	end
end

local prep = part(stations, "PrepConsole", CF(-8, 3.5, -10), V(5, 2, 3), "nasaBlue", "Metal")
part(habitat, "PrepPedestal", CF(-8, 1.25, -10), V(3, 2.5, 2), "metalGray", "Metal")
part(habitat, "PrepDisplay", CF(-8, 4.55, -10) * CFrame.Angles(RAD(-18), 0, 0), V(4.3, 0.14, 2.1), "darkBlue", nil, DECOR)
B.sign(prep, "MISSION PREPARATION", nil, { bg = "nasaBlue", titleColor = "white" })
local exit = part(stations, "Exit", CF(-10, 5, 51.5), V(7, 10, 0.7), "midGray", "Metal")
B.sign(exit, "RETURN TO MISSION BRIEFING", nil, { titleColor = "white", bg = "nasaBlue" })
local toolbox = part(stations, "Toolbox", CF(10, 2, 14), V(4.5, 3, 2.5), "orange", "Metal")
part(habitat, "ToolboxHandle", CF(10, 3.8, 14), V(2, 0.2, 0.35), "black", "Metal", DECOR)
B.sign(toolbox, "EPOXY GAUZE", nil, { bg = "orangeDark", titleColor = "white" })

local hatch = B.group(stations, "AdjacentHatch")
-- A folha desliza para o nicho lateral; nenhum detalhe solto fica sobre ela.
part(hatch, "Door", CF(11, 6, 24), V(10, 12, 0.6), "midGray", "Metal")
marker(hatch, "DoorClosedPose", CF(0, 6, 24))
marker(hatch, "Prompt", CF(6, 4, 22.7))
for _, x in { -5.3, 5.3 } do
	part(adjacent, "HatchJamb", CF(x, 6, 24), V(0.5, 12, 1), "metalGray", "Metal")
end
part(adjacent, "DoorTrack", CF(5.5, 12.5, 24), V(22, 0.4, 1), "metalGray", "Metal", DECOR)
sign(habitat, "AdjacentLabel", CF(0, 14, 23.4), V(10, 1.4, 0.1), "ADJACENT MODULE")

--------------------------------------------------------------------------------
-- Cupola nadir: uma janela circular e seis trapezoidais inclinadas para a Terra.
-- Vidros retangulares recebem máscaras triangulares opacas; continuam Parts.
-- A grelha fina no nível Y0 mantém a circulação sem degraus sobre o observatório.
--------------------------------------------------------------------------------
box(cupola, "Ceiling", -14.6, 14.6, 14, 14.8, -56.6, -24.6)
box(cupola, "PortWall", -14.6, -14, -0.8, 14, -56.6, -24)
box(cupola, "StarboardWall", 14, 14.6, -0.8, 14, -56.6, -24)
box(cupola, "EndWall", -14.6, 14.6, -0.8, 14, -56.6, -56)
for _, side in { -1, 1 } do
	box(cupola, "EntryWall", side == -1 and -14 or 6, side == -1 and -6 or 14, 0, 14, -24.6, -24)
end
box(cupola, "EntryLintel", -6, 6, 12, 14, -24.6, -24)
box(cupola, "ForwardDeck", -14, 14, -0.8, 0, -29, -24)
box(cupola, "AftDeck", -14, 14, -0.8, 0, -56, -51)
box(cupola, "PortDeck", -14, -10, -0.8, 0, -51, -29)
box(cupola, "StarboardDeck", 10, 14, -0.8, 0, -51, -29)
-- Saias fecham o encontro entre o piso plano e o vidro rebaixado.
box(cupola, "PortWindowSkirt", -10.3, -10, -4.5, 0, -51, -29, "metalGray", "Metal")
box(cupola, "StarboardWindowSkirt", 10, 10.3, -4.5, 0, -51, -29, "metalGray", "Metal")
box(cupola, "ForwardWindowSkirt", -10, 10, -4.5, 0, -29, -28.7, "metalGray", "Metal")
box(cupola, "AftWindowSkirt", -10, 10, -4.5, 0, -51.3, -51, "metalGray", "Metal")
local windows = B.group(cupola, "Windows", "Folder")
part(windows, "CentralWindow", CF(0, -4.15, -40) * CFrame.Angles(0, 0, math.pi / 2), V(0.3, 12, 12), "glass", "Glass", GLASS, "Cylinder")
-- Hexágono interno de apótema 5, externo de apótema 13: bordas coincidentes.
local inner, outer = 5, 13
local innerWidth, outerWidth = 2 * inner / math.sqrt(3), 2 * outer / math.sqrt(3)
local slopeLength = math.sqrt((outer - inner) ^ 2 + 4 ^ 2)
for i = 1, 6 do
	local a = (i - 1) * math.pi / 3
	local radial, tangent = V(math.sin(a), 0, math.cos(a)), V(math.cos(a), 0, -math.sin(a))
	local upSlope = (radial * (outer - inner) + V(0, 4, 0)).Unit
	local normal = tangent:Cross(upSlope).Unit
	local center = V(0, -2, -40) + radial * ((inner + outer) / 2)
	local paneCF = CFrame.fromMatrix(center, tangent, upSlope, normal)
	part(windows, "Window" .. i, paneCF, V(outerWidth, slopeLength, 0.3), "glass", "Glass", GLASS)
	-- Wedge local: hipotenusa delimita o trapézio; espessura transversal ao vidro.
	local maskWidth = (outerWidth - innerWidth) / 2
	for _, side in { -1, 1 } do
		local maskCF = paneCF * CF(side * (outerWidth / 2 - maskWidth / 2), 0, 0)
		local maskUp = -tangent * side
		local maskBack = -upSlope
		local maskRight = maskUp:Cross(maskBack)
		part(cupola, "WindowCornerMask", CFrame.fromMatrix(maskCF.Position, maskRight, maskUp, maskBack), V(0.4, maskWidth, slopeLength), "paleGray", "Metal", nil, "Wedge")
	end
	local p0 = center - tangent * innerWidth / 2 - upSlope * slopeLength / 2
	local p1 = center - tangent * outerWidth / 2 + upSlope * slopeLength / 2
	beam(cupola, "WindowRib", p0, p1, 0.22, "metalGray")
	beam(cupola, "OuterWindowRim", center + upSlope * slopeLength / 2 - tangent * outerWidth / 2, center + upSlope * slopeLength / 2 + tangent * outerWidth / 2, 0.25)
end
-- As próprias sete peças de vidro fecham o casco; grelha só sustenta a caminhada.
for x = -9.75, 9.75, 0.75 do
	part(cupola, "ObservationGrating", CF(x, -0.15, -40), V(0.12, 0.3, 22), "metalGray", "Metal")
end
for _, z in { -50.5, -40, -29.5 } do
	part(cupola, "GratingCrossbar", CF(0, -0.24, z), V(20, 0.12, 0.16), "darkGray", "Metal")
end
local canadarmConsole = part(stations, "CanadarmConsole", CF(0, 3.4, -29), V(6, 1.5, 2.4), "nasaBlue", "Metal")
part(cupola, "ConsolePedestal", CF(0, 1.3, -29), V(3, 2.6, 1.7), "metalGray", "Metal")
for _, x in { -2, 2 } do
	beam(cupola, "JoystickStem", V(x, 4.15, -29), V(x, 4.95, -29.2), 0.18, "black")
	part(cupola, "JoystickGrip", CF(x, 5, -29.2), V(0.45, 0.55, 0.45), "black", "SmoothPlastic", DECOR, "Ball")
end
part(cupola, "CanadarmScreen", CF(0, 4.2, -29), V(2.3, 0.12, 1.8), "lightBlue", "Neon", DECOR)
B.sign(canadarmConsole, "CANADARM CONTROL", nil, { bg = "nasaBlue", titleColor = "white" })
sign(cupola, "CupolaLabel", CF(0, 11, -55.5), V(9, 1.5, 0.1), "CUPOLA", "EARTH OBSERVATION")

--------------------------------------------------------------------------------
-- Airlock: acesso pelo vão lateral; escotilha na face externa da câmara.
--------------------------------------------------------------------------------
box(airlock, "Floor", 18, 38, -0.8, 0, -10, 10, "midGray", "Metal")
box(airlock, "Ceiling", 18, 38.6, 12, 12.8, -10.6, 10.6)
box(airlock, "ForwardWall", 18, 38.6, 0, 12, -10.6, -10)
box(airlock, "AftWall", 18, 38.6, 0, 12, 10, 10.6)
box(airlock, "HatchWallForward", 38, 38.6, 0, 12, -10, -4)
box(airlock, "HatchWallAft", 38, 38.6, 0, 12, 4, 10)
box(airlock, "HatchLintel", 38, 38.6, 10, 12, -4, 4)
part(airlock, "InnerHatch", CF(38, 5, 0), V(0.7, 10, 8), "midGray", "Metal")
marker(airlock, "EvaStart", CF(46, 5, 0) * CFrame.Angles(0, -math.pi / 2, 0))
marker(airlock, "EvaReturn", CF(30, 3, 0) * CFrame.Angles(0, math.pi / 2, 0))
marker(exterior, "TetherAnchor", CF(39, 7, -4))
for _, z in { -4.5, 4.5 } do
	beam(airlock, "ExteriorGrabRail", V(39.3, 2, z), V(39.3, 9, z), 0.2, "safety")
	beam(airlock, "InteriorGrabRail", V(36.7, 2, z), V(36.7, 9, z), 0.2, "safety")
end
sign(airlock, "AirlockLabel", CF(29, 9, 9.5), V(8, 1.5, 0.1), "AIRLOCK", "EVA ACCESS")

-- Corredor aberto de EVA: todos os alvos ficam fora do casco e das placas solares.
marker(exterior, "EvaBounds", CF(70, 7, 0), V(68, 44, 64))
local cables = B.group(exterior, "Cables", "Folder")
local pulleys = B.group(exterior, "Pulleys", "Folder")
for i, z in { -12, 12 } do
	part(cables, "Cable" .. i, CF(53, 6, z) * CFrame.Angles(RAD(15), 0, RAD(i == 1 and -20 or 20)), V(0.6, 0.6, 6), "darkGray", "Metal", DECOR)
	part(pulleys, "Pulley" .. i, CF(80, 9, z), V(0.5, 4, 4), "#54E878", "Neon", DECOR, "Cylinder")
	part(exterior, "PulleyHub", CF(80.3, 9, z), V(0.2, 1.1, 1.1), "darkGray", "Metal", DECOR, "Cylinder")
end

--------------------------------------------------------------------------------
-- Unity / Zarya abaixo e à frente da Cupola, no campo de visão nadir.
--------------------------------------------------------------------------------
local function orbitalModule(name, center, length, diameter, color)
	local m = B.group(exterior, name)
	local body = part(m, "PressureHull", CF(center) * CFrame.Angles(0, math.pi / 2, 0), V(length, diameter, diameter), color, "Metal", DECOR, "Cylinder")
	m.PrimaryPart = body
	-- O pivot local do cilindro não deve introduzir 90° na animação de acoplamento.
	body.PivotOffset = CFrame.Angles(0, -math.pi / 2, 0)
	for _, dz in { -length / 2, length / 2 } do
		part(m, "DockingCollar", CF(center + V(0, 0, dz)) * CFrame.Angles(0, math.pi / 2, 0), V(1.2, diameter + 1.2, diameter + 1.2), "metalGray", "Metal", DECOR, "Cylinder")
		part(m, "DockingFace", CF(center + V(0, 0, dz * 1.03)) * CFrame.Angles(0, math.pi / 2, 0), V(0.2, diameter * 0.65, diameter * 0.65), "darkGray", "Metal", DECOR, "Cylinder")
	end
	for dz = -length / 2 + 2, length / 2 - 2, 4 do
		part(m, "HullBand", CF(center + V(0, 0, dz)) * CFrame.Angles(0, math.pi / 2, 0), V(0.15, diameter + 0.15, diameter + 0.15), "paleGray", "Metal", DECOR, "Cylinder")
	end
	for _, dx in { -diameter * 0.36, diameter * 0.36 } do
		beam(m, "ServiceConduit", center + V(dx, diameter * 0.36, -length / 2 + 1), center + V(dx, diameter * 0.36, length / 2 - 1), 0.28, "gold")
	end
	return m
end
orbitalModule("Unity", V(-9, -24, -54), 18, 11, "white")
local dockedCF = CF(-9, -24, -78)
marker(exterior, "ZaryaDockedPose", dockedCF)
local zarya = orbitalModule("Zarya", V(-9, -24, -78), 28, 10, "paleGray")
-- Geometria inteira, inclusive colares e cabos, acompanha o pivot do Model.
zarya:PivotTo(BASE * dockedCF * CF(0, 0, -6) * CFrame.Angles(0, RAD(12), 0))

local solar = B.group(exterior, "SolarPanels")
for _, side in { -1, 1 } do
	beam(solar, "ArrayBoom", V(-9, -20, -61), V(-9 + side * 58, -20, -61), 0.8)
	for bank = 0, 1 do
		local x, z = -9 + side * 37, -69 + bank * 18
		part(solar, "ArrayFrame", CF(x, -20, z), V(40, 0.45, 15), "gold", "Metal", DECOR)
		for col = 0, 9 do
			for row = 0, 2 do
				part(solar, "PhotovoltaicCell", CF(x - 18 + col * 4, -19.72, z - 5 + row * 5), V(3.8, 0.12, 4.7), col % 2 == 0 and "darkBlue" or "deepBlue", "SmoothPlastic", DECOR)
			end
		end
	end
end
local arm = B.group(exterior, "Canadarm")
local armPoints = { V(12, -10, -37), V(17, -15, -47), V(8, -17, -59), V(-2, -20, -67) }
for i = 1, #armPoints - 1 do
	beam(arm, "ArmSegment", armPoints[i], armPoints[i + 1], 1.2, "white")
	part(arm, "Joint", CF(armPoints[i]), V(2, 2, 2), "midGray", "Metal", DECOR, "Ball")
end
part(arm, "EndEffector", CF(armPoints[#armPoints]), V(2.4, 2.4, 2.4), "black", "Metal", DECOR, "Ball")

local earth = part(exterior, "Earth", CF(0, -1200, -40), V(1900, 1900, 1900), "#247EC0", "Neon", DECOR, "Ball")
-- Manchas próprias na calota visível, sem dependência de decals ou assets externos.
local earthDetail = B.group(exterior, "EarthDetail")
for i = 0, 13 do
	local a = i * 2.39996
	local x, z = math.cos(a) * (100 + i * 25), math.sin(a) * (100 + i * 25)
	local y = -1200 + math.sqrt(950 ^ 2 - x ^ 2 - z ^ 2)
	local pos = V(x, y, z - 40)
	local normal = (pos - V(0, -1200, -40)).Unit
	local patchCF = CFrame.lookAt(pos, pos + normal) * CFrame.Angles(-math.pi / 2, 0, 0)
	part(earthDetail, "CloudBank", patchCF * CF(0, 7, 0), V(130 + i * 3, 14, 48), "white", "Neon", { collide = false, shadow = false, transparency = 0.25 }, "Ball")
	if i % 3 == 0 then
		part(earthDetail, "LandMass", patchCF, V(170, 10, 100), "#488A78", "Neon", DECOR, "Ball")
	end
end
earth:SetAttribute("VisualOnly", true)

--------------------------------------------------------------------------------
-- Fugas em quatro paredes distintas; Front aponta do ar para dentro da parede.
--------------------------------------------------------------------------------
local leaks = B.group(iss, "LeakSpots", "Folder")
local leakData = {
	{ V(-17.95, 5, -11), V(-1, 0, 0) },
	{ V(17.95, 5, 13), V(1, 0, 0) },
	{ V(-10, 5, 23.55), V(0, 0, 1) },
	{ V(17.95, 5, -18), V(1, 0, 0) }, -- no habitat (o furo fica do lado de quem fecha a escotilha)
}
for i, data in leakData do
	local spot = marker(leaks, "Spot" .. i, CFrame.lookAt(data[1], data[1] + data[2]), V(0.15, 0.15, 0.15))
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AirLeak"
	emitter.Enabled = false
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Color = ColorSequence.new(Color3.fromHex("#E8F7FF"))
	emitter.LightEmission = 0.65
	emitter.Size = NumberSequence.new(0.035)
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.2, 0.35)
	emitter.Speed = NumberRange.new(2, 4)
	emitter.Rate = 28
	emitter.SpreadAngle = Vector2.new(5, 5)
	-- Origem a ~0,7 stud da parede; deslocamento termina dentro do casco.
	spot.CFrame = spot.CFrame * CF(0, 0, 0.65)
	emitter:SetAttribute("BuildPhase", 20)
	emitter.Parent = spot
end

for i, position in { V(0, 14.8, -12), V(0, 14.8, 12), V(0, 14.8, 38), V(0, 12.8, -42), V(28, 10.8, 0) } do
	local fixture = part(lights, "CabinLight" .. i, CF(position), V(5, 0.2, 1.2), "white", "Neon", DECOR)
	B.light(fixture, "PointLight", { Brightness = 1.5, Range = 30, Color = Color3.fromHex("#EAF4FF"), Shadows = false })
end

-- Conferência do contrato também executada no Studio antes de instalar os sistemas.
local required = {
	"Origin", "Bounds", "Spawns/Spawn1", "Spawns/Spawn2", "Spawns/Spawn3", "Spawns/Spawn4",
	"Stations/PrepConsole", "Stations/Exit", "Stations/CanadarmConsole", "Stations/Toolbox",
	"Stations/AdjacentHatch/Door", "Stations/AdjacentHatch/DoorClosedPose", "Stations/AdjacentHatch/Prompt",
	"Airlock/InnerHatch", "Airlock/EvaStart", "Airlock/EvaReturn", "Exterior/Unity", "Exterior/Zarya",
	"Exterior/ZaryaDockedPose", "Exterior/SolarPanels", "Exterior/Canadarm", "Exterior/Earth",
	"Exterior/EvaBounds", "Exterior/TetherAnchor", "Exterior/Cables/Cable1", "Exterior/Cables/Cable2",
	"Exterior/Pulleys/Pulley1", "Exterior/Pulleys/Pulley2", "LeakSpots/Spot1", "LeakSpots/Spot2",
	"LeakSpots/Spot3", "LeakSpots/Spot4", "Lights/CabinLight1",
}
for _, path in required do
	local node = iss
	for segment in string.gmatch(path, "[^/]+") do
		node = node:FindFirstChild(segment)
		assert(node, "Contrato ISS: ausente " .. path)
	end
end
assert(#windows:GetChildren() == 7, "Cupola deve ter exatamente sete janelas")
local count = 0
for _, item in iss:GetDescendants() do
	if item:IsA("BasePart") then
		count += 1
		assert(item.Anchored and item:GetAttribute("BuildPhase") == 20, "Peça ISS sem fase/ancoragem: " .. item.Name)
	end
end
assert(count <= 1500, "ISS excedeu orçamento de 1500 peças")
iss:SetAttribute("PartCount", count)
return ("Fase 20 construída: ISS em (3000, 1200, 0), %d peças, Cupola com sete janelas; testar Fase 21/EVA no Studio."):format(count)
