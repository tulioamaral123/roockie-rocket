--[[
	NASA Space Adventure — Fase 3: elementos principais
	SLS + plataforma + torres de serviço (hangar); sistema solar e zonas de exposição (museu).
	Executar depois das Fases 1 e 2. Recebe a lib (build/lib.luau) como argumento.
]]

local lib = ...
local B = lib.builder(3)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1 e 2 antes")
B.clear(Map)

local Museum, Hangar = Map.CapeCanaveralMuseum, Map.VABHangar
local DECOR = { collide = false }
local DECOR_NS = { collide = false, shadow = false }

---------------------------------------------------------------------------------
-- SLS Block 1 (spec §7.3). Unidade interna: 1 = 1 stud na escala do hangar (117 de altura).
-- s = fator de escala (1 no hangar; ~0,12 na miniatura do museu).
---------------------------------------------------------------------------------
local function buildSLS(parent, name, ox, oy, oz, s, o)
	local m = B.group(parent, name)
	local g = {
		Orion = B.group(m, "Orion_Capsule"),
		LAS = B.group(m, "Launch_Abort_System"),
		Upper = B.group(m, "Upper_Stage"),
		Core = B.group(m, "Core_Stage"),
		BoostL = B.group(m, "Booster_L"),
		BoostR = B.group(m, "Booster_R"),
		Engines = B.group(m, "RS25_Engines"),
	}
	local function Y(v) return oy + v * s end
	local function D(v) return math.max(v * s, 0.05) end
	local function cyl(grp, n, x, z, y0, y1, dia, color, mat)
		return B.cyl(grp, n, ox + x * s, oz + z * s, Y(y0), Y(y1), D(dia), color, mat, o)
	end
	local function cone(grp, n, y0, y1, d0, d1, slices, color, mat, x, z)
		B.cone(grp, n, ox + (x or 0) * s, oz + (z or 0) * s, Y(y0), Y(y1), D(d0), D(d1), slices, color, mat, o)
	end

	-- 6. Motores RS-25 (4)
	for _, p in { { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } } do
		cone(g.Engines, "RS25_Nozzle", 0.5, 4, 2.6, 1.4, 3, "black", "Metal", p[1], p[2])
	end
	cyl(g.Engines, "Engine_Section", 0, 0, 3.8, 5, 9.4, "darkGray", "Metal")

	-- 4. Estágio central laranja
	local core = cyl(g.Core, "Core_Tank", 0, 0, 5, 80, 10, "orange", "Metal")
	cyl(g.Core, "Intertank", 0, 0, 64, 69, 10.15, "orangeDark", "Metal")
	cyl(g.Core, "Forward_Skirt", 0, 0, 79, 80, 10.15, "orangeDark", "Metal")
	cyl(g.Core, "LOX_Feedline", 0, -5.3, 8, 66, 0.8, "orangeDark", "Metal")

	-- 5. Dois propulsores laterais
	for _, sx in { -8, 8 } do
		local grp = (sx < 0) and g.BoostL or g.BoostR
		cone(grp, "Aft_Skirt", 0, 4, 6.4, 5, 2, "white", "SmoothPlastic", sx, 0)
		cyl(grp, "Booster_Case", sx, 0, 4, 66, 5, "white", "SmoothPlastic")
		for _, jy in { 16, 28, 40, 52 } do
			cyl(grp, "Segment_Joint", sx, 0, jy, jy + 0.6, 5.2, "metalGray", "Metal")
		end
		cone(grp, "Nose_Cone", 66, 72, 5, 1, 4, "white", "SmoothPlastic", sx, 0)
		local dir = (sx < 0) and -1 or 1
		for _, by in { 8, 60 } do
			B.box(grp, "Attach_Strut", ox + dir * 4.9 * s, ox + dir * 5.6 * s, Y(by), Y(by + 1),
				oz - 0.4 * s, oz + 0.4 * s, "darkGray", "Metal", o)
		end
	end

	-- 3. Estágio superior (adaptador LVSA + ICPS)
	cone(g.Upper, "LVSA_Adapter", 80, 88, 10, 6, 4, "paleGray", "SmoothPlastic")
	cyl(g.Upper, "ICPS", 0, 0, 88, 96, 6, "white", "SmoothPlastic")
	cyl(g.Upper, "ICPS_Band", 0, 0, 92, 93, 6.1, "metalGray", "Metal")

	-- 1. Cápsula Orion (módulo de serviço + módulo da tripulação)
	cyl(g.Orion, "Service_Module", 0, 0, 96, 101, 6, "paleGray", "Metal")
	cone(g.Orion, "Crew_Module", 101, 104.5, 6, 3, 3, "paleGray", "Metal")

	-- 2. Sistema de escape (carenagem + torre)
	cone(g.LAS, "LAS_Fairing", 104.5, 108, 3.2, 1.4, 3, "white", "SmoothPlastic")
	cyl(g.LAS, "LAS_Tower", 0, 0, 108, 115, 1.4, "white", "SmoothPlastic")
	cyl(g.LAS, "Abort_Motor", 0, 0, 110, 111.5, 2, "darkGray", "Metal")
	cone(g.LAS, "LAS_Tip", 115, 117, 1.2, 0.3, 2, "white", "SmoothPlastic")

	m.PrimaryPart = core
	return m
end

---------------------------------------------------------------------------------
-- HANGAR
---------------------------------------------------------------------------------
local ROCKET_Z = 265
local DECK_TOP = 10

-- Plataforma de montagem (lançador móvel) --------------------------------------
local plat = B.group(Hangar.Launch_Platform, "Mobile_Launcher")
for _, x in { -18, 18 } do
	for _, z in { 250, 265, 280 } do
		B.box(plat, "Pedestal", x - 2, x + 2, 0, 3, z - 2, z + 2, "darkGray", "Metal")
	end
end
B.box(plat, "Deck", -24, 24, 3, DECK_TOP, 245, 285, "darkGray", "Metal")
B.box(plat, "Deck_Plate", -23.5, 23.5, DECK_TOP, DECK_TOP + 0.1, 245.5, 284.5, "metalGray", "DiamondPlate")
-- faixas de segurança nas bordas
B.box(plat, "Edge_Stripe", -24, 24, 6, 7, 244.9, 245, "safety", "SmoothPlastic", DECOR)
B.box(plat, "Edge_Stripe", -24, 24, 6, 7, 285, 285.1, "safety", "SmoothPlastic", DECOR)
B.box(plat, "Edge_Stripe", -24.1, -24, 6, 7, 245, 285, "safety", "SmoothPlastic", DECOR)
B.box(plat, "Edge_Stripe", 24, 24.1, 6, 7, 245, 285, "safety", "SmoothPlastic", DECOR)
-- escada de acesso ao deck (frente, lado esquerdo do eixo para não cobrir o foguete)
local platStairs = B.group(plat, "Access_Stairs")
for i = 1, 10 do
	local top = math.min(i, 10.1)
	B.box(platStairs, "Step", -22, -16, 0, top, 245 - (11 - i), 245 - (10 - i), "darkGray", "DiamondPlate")
end
-- bases de fixação sob os propulsores
for _, x in { -8, 8 } do
	B.box(plat, "Holddown_Post", x - 3.6, x + 3.6, DECK_TOP + 0.1, DECK_TOP + 0.5, ROCKET_Z - 3.6, ROCKET_Z + 3.6, "black", "Metal")
end

-- Foguete -------------------------------------------------------------------------
local sls = buildSLS(Hangar.SLS_Rocket, "SLS_Block1", 0, DECK_TOP + 0.5, ROCKET_Z, 1)

-- Torres de serviço (X ≈ ±20) ---------------------------------------------------------
local TOWER_TOP = 104
for _, sx in { -1, 1 } do
	local x = sx * 20
	local tower = B.group(Hangar.Gantry, (sx < 0) and "Service_Tower_L" or "Service_Tower_R")
	local z0, z1 = ROCKET_Z - 2.6, ROCKET_Z + 2.6
	for _, cx in { x - 2.6, x + 2.6 } do
		for _, cz in { z0, z1 } do
			B.box(tower, "Column", cx - 0.4, cx + 0.4, DECK_TOP, TOWER_TOP, cz - 0.4, cz + 0.4, "darkGray", "Metal")
		end
	end
	local prevY = DECK_TOP
	for k = 1, 8 do
		local y = DECK_TOP + k * (TOWER_TOP - DECK_TOP) / 8
		for _, cz in { z0, z1 } do
			B.box(tower, "Beam", x - 3, x + 3, y - 0.35, y + 0.35, cz - 0.3, cz + 0.3, "metalGray", "Metal")
		end
		for _, cx in { x - 2.6, x + 2.6 } do
			B.box(tower, "Beam", cx - 0.3, cx + 0.3, y - 0.35, y + 0.35, z0, z1, "metalGray", "Metal")
		end
		-- contraventamento em X na face voltada para a entrada
		B.beam(tower, "Brace", Vector3.new(x - 2.6, prevY, z0), Vector3.new(x + 2.6, y, z0), 0.3, 0.3, "metalGray", "Metal", DECOR)
		B.beam(tower, "Brace", Vector3.new(x + 2.6, prevY, z0), Vector3.new(x - 2.6, y, z0), 0.3, 0.3, "metalGray", "Metal", DECOR)
		prevY = y
	end
	B.box(tower, "Top_Cap", x - 3, x + 3, TOWER_TOP, TOWER_TOP + 1, z0 - 0.4, z1 + 0.4, "metalGray", "Metal")

	-- escada de marinheiro (TrussPart) na face externa
	local truss = Instance.new("TrussPart")
	truss.Name = "Ladder"
	truss.Anchored = true
	truss.Size = Vector3.new(2, TOWER_TOP - DECK_TOP, 2)
	truss.CFrame = CFrame.new(x + sx * 4, (DECK_TOP + TOWER_TOP) / 2, ROCKET_Z)
	truss.Color = Color3.fromHex(lib.C.safety)
	truss.Material = Enum.Material.Metal
	truss:SetAttribute("BuildPhase", 3)
	truss.Parent = tower

	-- plataformas e passarelas até o foguete
	for _, arm in { { y = 40, to = 10.6 }, { y = 60, to = 10.6 }, { y = 100, to = 3.1 } } do
		B.box(tower, "Deck", x - 2.6, x + 2.6, arm.y - 0.5, arm.y, z0, z1, "darkGray", "DiamondPlate")
		local xi, xt = sx * 17, sx * arm.to
		B.box(tower, "Arm_Deck", xi, xt, arm.y - 0.5, arm.y, ROCKET_Z - 1.5, ROCKET_Z + 1.5, "darkGray", "DiamondPlate")
		B.box(tower, "Arm_Rail", xi, xt, arm.y, arm.y + 1.1, ROCKET_Z - 1.6, ROCKET_Z - 1.4, "safety", "Metal")
		B.box(tower, "Arm_Rail", xi, xt, arm.y, arm.y + 1.1, ROCKET_Z + 1.4, ROCKET_Z + 1.6, "safety", "Metal")
		if arm.y == 100 then
			B.box(tower, "White_Room", sx * 3.1, sx * 6, arm.y, arm.y + 3.6, ROCKET_Z - 1.8, ROCKET_Z + 1.8, "white", "SmoothPlastic", DECOR)
		end
	end
end

---------------------------------------------------------------------------------
-- MUSEU
---------------------------------------------------------------------------------
local CX, CZ = 0, 130

-- Placa em pedestal, inclinada, voltada para um ponto
local function plaque(parent, x, z, tx, tz, title, body, w)
	w = w or 5
	local g = B.group(parent, "Plaque")
	B.part(g, "Post", CFrame.lookAt(Vector3.new(x, 1.3, z), Vector3.new(tx, 1.3, tz)), Vector3.new(0.5, 2.6, 0.5), "darkGray", "Metal")
	local panel = B.part(g, "Panel", CFrame.lookAt(Vector3.new(x, 3.6, z), Vector3.new(tx, 3.6, tz)) * CFrame.Angles(math.rad(20), 0, 0),
		Vector3.new(w, 3, 0.25), "space", "SmoothPlastic", DECOR)
	B.sign(panel, title, body, { accent = "midBlue", ppu = 60 })
	return g
end

-- Painel de parede (face: NormalId voltada para o salão)
local function wallPanel(parent, x0, x1, y0, y1, z0, z1, face, title, body, opts)
	local p = B.box(parent, "Wall_Panel", x0, x1, y0, y1, z0, z1, "space", "SmoothPlastic", DECOR)
	opts = opts or {}
	opts.face = face
	opts.accent = opts.accent or "midBlue"
	B.sign(p, title, body, opts)
	return p
end

-- A. Sistema Solar --------------------------------------------------------------------
local solar = Museum.Solar_System
local dais = B.group(solar, "Dais")
B.cyl(dais, "Platform", CX, CZ, 0, 0.4, 14, "deepBlue", "SmoothPlastic")
B.ring(dais, "Glow_Ring", Vector3.new(CX, 0.45, CZ), 6.8, 0.3, 0.1, "midBlue", "Neon", DECOR_NS)

local sun = B.ball(solar, "Sun", Vector3.new(CX, 24, CZ), 10, "#FFB547", "Neon", DECOR_NS)
sun:SetAttribute("IsSun", true)

local planets = {
	-- nome, diâmetro, raio da órbita, altura, ângulo inicial, cor, velocidade (graus/s)
	{ "Mercury", 1.2, 8, 22, 30, "#9C9C9C", 12 },
	{ "Venus", 2.0, 10.5, 25, 150, "#E3C07B", 9 },
	{ "Earth", 2.2, 13, 20, 260, "#2E6FD6", 7 },
	{ "Mars", 1.6, 15.5, 27, 80, "#C1440E", 5.5 },
	{ "Jupiter", 5.0, 19.5, 23, 200, "#D8A876", 3.5 },
	{ "Saturn", 4.2, 23.5, 28, 320, "#E6CF8B", 2.6 },
	{ "Uranus", 3.0, 27, 21, 120, "#9FE3E8", 1.8 },
	{ "Neptune", 2.9, 30, 17, 20, "#3D5EF2", 1.3 },
}
for _, p in planets do
	local name, dia, r, y, ang, color, speed = table.unpack(p)
	local orbit = B.ring(solar, "Orbit_" .. name, Vector3.new(CX, y, CZ), r, 0.12, 0.06, "midBlue", "Neon", DECOR_NS)
	orbit.Transparency = 0.35
	local model = B.group(solar, "Planet_" .. name)
	local a = math.rad(ang)
	local pos = Vector3.new(CX + r * math.cos(a), y, CZ + r * math.sin(a))
	local body = B.ball(model, name, pos, dia, color, "SmoothPlastic", DECOR)
	model.PrimaryPart = body
	if name == "Earth" then
		B.ball(model, "Moon", pos + Vector3.new(1.8, 0.6, 0), 0.6, "#C8C8C8", "Slate", DECOR)
	elseif name == "Saturn" then
		local ring = B.ring(model, "Rings", pos, 3.4, 1.8, 0.1, "#CDB98A", "SmoothPlastic", DECOR_NS)
		ring.Transparency = 0.15
		ring.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(25), 0, 0) * CFrame.Angles(0, 0, math.pi / 2)
	elseif name == "Jupiter" then
		for _, dy in { -0.9, 0.6 } do
			B.cyl(model, "Band", pos.X, pos.Z, pos.Y + dy - 0.2, pos.Y + dy + 0.2, 5.02 * math.cos(math.asin(dy / 2.5)), "#B07F53", "SmoothPlastic", DECOR)
		end
	end
	model:SetAttribute("OrbitRadius", r)
	model:SetAttribute("OrbitAngle", ang)
	model:SetAttribute("OrbitSpeed", speed)
	model:SetAttribute("OrbitCenter", Vector3.new(CX, y, CZ))
end
plaque(solar, 9, 114, CX, CZ - 40, "THE SOLAR SYSTEM",
	"Eight planets orbit the Sun. Sizes and distances in this exhibit are not to scale.")

-- B. Exploração humana (lado oeste) ------------------------------------------------------
local function astronaut(parent, cf, scale, suit, accent)
	local g = B.group(parent, "Astronaut")
	local function p(n, off, size, color, mat, shape, o)
		return B.part(g, n, cf * CFrame.new(off * scale), size * scale, color, mat, o, shape)
	end
	for _, sx in { -0.55, 0.55 } do
		p("Leg", Vector3.new(sx, 1.4, 0), Vector3.new(0.9, 2.4, 0.95), suit, "Fabric")
		p("Boot", Vector3.new(sx, 0.3, -0.1), Vector3.new(1, 0.6, 1.25), "darkGray", "SmoothPlastic")
		p("Arm", Vector3.new(sx * 2.7, 3.7, 0), Vector3.new(0.8, 2.4, 0.9), suit, "Fabric")
		p("Glove", Vector3.new(sx * 2.7, 2.3, 0), Vector3.new(0.85, 0.85, 0.85), "midGray", "SmoothPlastic", "Ball")
		p("Arm_Stripe", Vector3.new(sx * 2.7, 4.3, 0), Vector3.new(0.85, 0.3, 0.95), accent, "SmoothPlastic", nil, DECOR)
	end
	p("Torso", Vector3.new(0, 3.8, 0), Vector3.new(2.3, 2.5, 1.4), suit, "Fabric")
	p("Backpack", Vector3.new(0, 3.9, 1.15), Vector3.new(2.1, 2.7, 1.0), "white", "SmoothPlastic")
	p("Chest_Unit", Vector3.new(0, 3.5, -0.85), Vector3.new(1.3, 0.7, 0.4), accent, "SmoothPlastic", nil, DECOR)
	p("Helmet", Vector3.new(0, 5.75, 0), Vector3.new(1.9, 1.9, 1.9), "white", "SmoothPlastic", "Ball")
	local visor = p("Visor", Vector3.new(0, 5.75, -0.3), Vector3.new(1.55, 1.55, 1.55), "gold", "Metal", "Ball", DECOR)
	visor.Reflectance = 0.35
	return g
end

local human = Museum.Astronaut_Exhibition
local suits = {
	{ z = 116, suit = "white", accent = "red", title = "APOLLO (1961-1972)",
		body = "On July 20, 1969, Apollo 11 landed the first humans on the Moon." },
	{ z = 130, suit = "#E8742A", accent = "nasaBlue", title = "SPACE SHUTTLE (1981-2011)",
		body = "135 missions launched satellites, helped build the ISS and carried crews to orbit." },
	{ z = 144, suit = "white", accent = "midBlue", title = "ARTEMIS",
		body = "Artemis aims to return astronauts to the Moon and prepare for missions to Mars." },
}
for _, s in suits do
	local x = -39
	B.cyl(human, "Pedestal", x, s.z, 0, 1.2, 4.4, "midGray", "SmoothPlastic")
	B.ring(human, "Pedestal_Glow", Vector3.new(x, 1.25, s.z), 2.1, 0.15, 0.05, "midBlue", "Neon", DECOR_NS)
	astronaut(human, CFrame.lookAt(Vector3.new(x, 1.2, s.z), Vector3.new(CX, 1.2, s.z)), 1.2, s.suit, s.accent)
	wallPanel(human, -44.95, -44.75, 3, 9, s.z - 4.5, s.z + 4.5, Enum.NormalId.Right, s.title, s.body)
end
-- vitrine de capacete e equipamentos
local case = B.group(human, "Equipment_Case")
B.box(case, "Base", -43, -37, 0, 2.6, 148, 152, "darkGray", "SmoothPlastic")
B.box(case, "Glass", -43, -37, 2.6, 6, 148, 152, "glass", "Glass", { transparency = 0.7, shadow = false })
B.ball(case, "Helmet", Vector3.new(-40.8, 3.6, 150), 1.9, "white", "SmoothPlastic", DECOR)
local cv = B.ball(case, "Visor", Vector3.new(-40.8, 3.6, 149.7), 1.55, "gold", "Metal", DECOR)
cv.Reflectance = 0.35
B.ball(case, "Glove", Vector3.new(-38.8, 3.0, 150.3), 0.9, "white", "SmoothPlastic", DECOR)

-- Atividade extraveicular (canto noroeste)
local eva = B.group(human, "EVA_Scene")
B.box(eva, "ISS_Truss", -43, -27, 11, 13, 159, 161, "metalGray", "Metal", DECOR)
for _, x in { -41, -35, -29 } do
	B.box(eva, "Truss_Frame", x - 0.3, x + 0.3, 10.8, 13.2, 158.8, 161.2, "darkGray", "Metal", DECOR)
end
B.box(eva, "Solar_Array", -43, -33, 12.8, 13, 161, 168, "#1D2C5A", "SmoothPlastic", DECOR)
local evaCF = CFrame.new(-34, 6.5, 156) * CFrame.Angles(math.rad(25), math.rad(150), math.rad(-15))
astronaut(eva, evaCF, 1.1, "white", "red")
B.cylBetween(eva, "Tether", (evaCF * CFrame.new(0, 4, 1.2)).Position, Vector3.new(-33, 11, 159.5), 0.12, "safety", "SmoothPlastic", DECOR)
for _, part in eva:GetDescendants() do
	if part:IsA("BasePart") then part.CanCollide = false end
end
plaque(eva, -25, 157, CX, CZ, "SPACEWALKS", "Astronauts perform spacewalks (EVAs) to build, repair and upgrade the International Space Station.")

-- C. Foguetes e espaçonaves (lado leste) ------------------------------------------------
local rockets = Museum.Rocket_Exhibition
local MINI = 14 / 117 -- SLS em miniatura com 14 studs (mesma escala do Saturn V)
B.cyl(rockets, "Pedestal_SLS", 39, 118, 0, 1.2, 5.5, "midGray", "SmoothPlastic")
buildSLS(rockets, "SLS_Miniature", 39, 1.2, 118, MINI, DECOR)

local function buildSaturnV(parent, ox, oy, oz, s)
	local m = B.group(parent, "SaturnV_Miniature")
	local function cyl(n, y0, y1, d, color) B.cyl(m, n, ox, oz, oy + y0 * s, oy + y1 * s, d * s, color, "SmoothPlastic", DECOR) end
	local function cone(n, y0, y1, d0, d1, k) B.cone(m, n, ox, oz, oy + y0 * s, oy + y1 * s, d0 * s, d1 * s, k, "white", "SmoothPlastic", DECOR) end
	cyl("S-IC", 0, 42, 10.1, "white")
	cyl("S-IC_Band", 4, 9, 10.2, "black")
	cyl("S-IC_Band", 34, 37, 10.2, "black")
	cyl("S-II", 42, 67, 10.1, "white")
	cyl("Interstage_Band", 42, 46, 10.2, "black")
	cone("S-II_Taper", 67, 70, 10.1, 6.6, 2)
	cyl("S-IVB", 70, 88, 6.6, "white")
	cyl("Instrument_Unit", 88, 89, 6.7, "black")
	cone("SLA", 89, 97, 6.6, 3.9, 3)
	cyl("Service_Module", 97, 101, 3.9, "paleGray")
	cone("Command_Module", 101, 104.5, 3.9, 1, 2)
	cyl("Escape_Tower", 104.5, 110.6, 0.6, "rust")
	for _, a in { 45, 135, 225, 315 } do
		local r = math.rad(a)
		B.part(m, "Fin", CFrame.new(ox + math.cos(r) * 5.8 * s, oy + 3 * s, oz + math.sin(r) * 5.8 * s) * CFrame.Angles(0, -r, 0),
			Vector3.new(2.4 * s, 6 * s, 0.4 * s), "white", "SmoothPlastic", DECOR)
	end
	return m
end
B.cyl(rockets, "Pedestal_SaturnV", 39, 142, 0, 1.2, 5.5, "midGray", "SmoothPlastic")
buildSaturnV(rockets, 39, 1.2, 142, 14 / 98)

local orion = B.group(rockets, "Orion_Capsule_Display")
B.cyl(orion, "Pedestal", 33, 130, 0, 1, 7, "midGray", "SmoothPlastic")
B.cyl(orion, "Heat_Shield", 33, 130, 1, 1.5, 5.2, "#5A3A22", "SmoothPlastic")
B.cone(orion, "Crew_Module", 33, 130, 1.5, 5.1, 5, 2, 12, "paleGray", "Metal")
B.cyl(orion, "Docking_Hatch", 33, 130, 5.1, 5.6, 1.3, "darkGray", "Metal")

wallPanel(rockets, 44.75, 44.95, 3, 9, 113.5, 122.5, Enum.NormalId.Left, "SLS",
	"NASA's Space Launch System (Block 1) is about 98 m tall. It launched Artemis I in 2022.")
wallPanel(rockets, 44.75, 44.95, 3, 9, 125.5, 134.5, Enum.NormalId.Left, "ORION",
	"Orion is the spacecraft designed to carry astronauts beyond low Earth orbit.")
wallPanel(rockets, 44.75, 44.95, 3, 9, 137.5, 146.5, Enum.NormalId.Left, "SATURN V",
	"At 110.6 m tall, Saturn V launched the Apollo missions to the Moon.")

-- D. Exploração planetária: Marte (canto sudoeste) ----------------------------------------
local mars = Museum.Mars_Exhibition
B.box(mars, "Ground", -44.5, -24, 0, 0.6, 91, 111, "#B5532B", "Sand")
B.box(mars, "Curb", -24.3, -24, 0, 0.9, 91, 111, "darkGray", "Metal")
B.box(mars, "Curb", -44.5, -24, 0, 0.9, 110.7, 111, "darkGray", "Metal")
B.box(mars, "Backdrop_W", -44.95, -44.75, 0.6, 14, 91, 111, "#7A2E18", "SmoothPlastic", DECOR)
B.box(mars, "Backdrop_S", -44.5, -24, 0.6, 14, 90.55, 90.75, "#7A2E18", "SmoothPlastic", DECOR)
local rocks = {
	{ -43.3, 92.3, 1.6 }, { -40.5, 108, 1.6 }, { -27, 94, 1.4 }, { -30, 108.5, 2 }, { -43, 101, 1.8 },
	{ -36, 93.5, 1.2 }, { -26.5, 103, 1 }, { -38, 109, 1.3 },
}
for i, r in rocks do
	B.part(mars, "Rock", CFrame.new(r[1], 0.6 + r[3] * 0.3, r[2]) * CFrame.Angles(i, i * 2, i * 0.5),
		Vector3.new(r[3] * 1.3, r[3] * 0.8, r[3]), "#8E3B1F", "Rock")
end
-- Rover (inspirado nos rovers de 6 rodas)
local rover = B.group(mars, "Rover")
local RX, RY, RZ = -34, 0.6, 101
for _, wx in { -1.9, 1.9 } do
	for _, wz in { -1.7, 0, 1.7 } do
		B.part(rover, "Wheel", CFrame.new(RX + wx, RY + 0.65, RZ + wz), Vector3.new(0.8, 1.3, 1.3), "darkGray", "SmoothPlastic", nil, "Cylinder")
	end
	B.box(rover, "Rocker", RX + wx - 0.15, RX + wx + 0.15, RY + 1.3, RY + 1.6, RZ - 1.9, RZ + 1.9, "metalGray", "Metal")
end
B.box(rover, "Body", RX - 1.4, RX + 1.4, RY + 1.6, RY + 2.8, RZ - 2, RZ + 2, "paleGray", "Metal")
B.box(rover, "Deck", RX - 1.5, RX + 1.5, RY + 2.8, RY + 3, RZ - 2.1, RZ + 2.1, "#C9B79C", "SmoothPlastic")
B.cyl(rover, "Mast", RX + 0.9, RZ - 1.6, RY + 3, RY + 5.6, 0.3, "white", "SmoothPlastic")
B.box(rover, "Camera_Head", RX + 0.4, RX + 1.4, RY + 5.6, RY + 6.2, RZ - 2, RZ - 1.4, "white", "SmoothPlastic")
B.part(rover, "RTG", CFrame.new(RX, RY + 3, RZ + 2.5) * CFrame.Angles(math.rad(-35), 0, 0), Vector3.new(0.9, 1.8, 0.9), "darkGray", "Metal")
B.beam(rover, "Arm", Vector3.new(RX - 0.8, RY + 2.4, RZ - 2), Vector3.new(RX - 0.8, RY + 1.6, RZ - 4), 0.25, 0.25, "white", "Metal")
B.ball(rover, "Arm_Turret", Vector3.new(RX - 0.8, RY + 1.5, RZ - 4.1), 0.6, "darkGray", "Metal")
B.part(rover, "Antenna", CFrame.new(RX - 0.8, RY + 3.3, RZ + 0.8) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.1, 1, 1), "white", "SmoothPlastic", nil, "Cylinder")
-- Sonda pousada (lander com painéis solares circulares)
local lander = B.group(mars, "Lander")
local LX, LZ = -40.5, 95.5
for _, a in { 0, 120, 240 } do
	local r = math.rad(a)
	B.beam(lander, "Leg", Vector3.new(LX + math.cos(r) * 1.6, 0.6, LZ + math.sin(r) * 1.6), Vector3.new(LX + math.cos(r) * 0.8, 1.6, LZ + math.sin(r) * 0.8), 0.2, 0.2, "metalGray", "Metal")
end
B.cyl(lander, "Deck", LX, LZ, 1.6, 2.2, 2.4, "paleGray", "Metal")
for _, sx in { -2.4, 2.4 } do
	B.cyl(lander, "Solar_Panel", LX + sx, LZ, 2.05, 2.15, 2.2, "#1D2C5A", "SmoothPlastic")
end
B.ball(lander, "Seismometer_Dome", Vector3.new(LX, 2.4, LZ - 1.8), 0.9, "white", "SmoothPlastic")
plaque(mars, -23.5, 112.8, CX, CZ, "EXPLORING MARS",
	"Robotic rovers such as Curiosity (2012) and Perseverance (2021) study Mars and search for signs of ancient life.")

-- E. Ciência e descobertas (canto sudeste) -------------------------------------------------
local sci = Museum.Science_Exhibition
local sat = B.group(sci, "Space_Telescope")
local SP = Vector3.new(33, 11, 100)
B.cylBetween(sat, "Tube", SP + Vector3.new(-3.5, 0, 0), SP + Vector3.new(3.5, 0, 0), 2.6, "paleGray", "Metal", DECOR)
B.cylBetween(sat, "Aperture_Door", SP + Vector3.new(3.5, 0, 0), SP + Vector3.new(3.8, 0, 0), 2.7, "darkGray", "Metal", DECOR)
for _, sz in { -1, 1 } do
	B.box(sat, "Solar_Panel", SP.X - 3, SP.X + 2, SP.Y - 0.05, SP.Y + 0.05, SP.Z + sz * 1.6, SP.Z + sz * 4.4, "#1D2C5A", "SmoothPlastic", DECOR)
end
B.box(sat, "Antenna_Boom", SP.X - 0.1, SP.X + 0.1, SP.Y - 2.6, SP.Y - 1.3, SP.Z - 0.1, SP.Z + 0.1, "white", "Metal", DECOR)
for _, dx in { -2, 2 } do
	B.cylBetween(sat, "Cable", SP + Vector3.new(dx, 1.3, 0), Vector3.new(SP.X + dx, 18, SP.Z), 0.08, "midGray", "Metal", DECOR)
end
-- espelho segmentado (inspirado no James Webb) sobre protetor solar
local jw = B.group(sci, "Segmented_Mirror")
B.cyl(jw, "Pedestal", 38, 107, 0, 1.2, 6, "midGray", "SmoothPlastic")
for i, layer in { "#B9A6C9", "#D9D2E0", "#B9A6C9" } do
	B.box(jw, "Sunshield", 34.5, 41.5, 1.2 + i * 0.25, 1.35 + i * 0.25, 104.5, 109.5, layer, "Foil", DECOR)
end
local mc = CFrame.new(38, 5, 107) * CFrame.Angles(math.rad(-25), math.rad(180), 0)
local hex = { { 0, 0 } }
for k = 0, 5 do
	local a = math.rad(60 * k + 30)
	table.insert(hex, { math.cos(a) * 1.55, math.sin(a) * 1.55 })
end
for _, h in hex do
	B.part(jw, "Mirror_Segment", mc * CFrame.new(h[1], h[2], 0) * CFrame.Angles(0, math.pi / 2, 0),
		Vector3.new(0.15, 1.5, 1.5), "gold", "Metal", { reflectance = 0.3 }, "Cylinder")
end
B.box(jw, "Mirror_Support", 37.8, 38.2, 2, 5, 106.8, 107.2, "darkGray", "Metal")
-- telescópio refrator em tripé
local scope = B.group(sci, "Telescope")
local TP = Vector3.new(27, 4.2, 96)
for _, a in { 0, 120, 240 } do
	local r = math.rad(a)
	B.beam(scope, "Tripod_Leg", TP, Vector3.new(TP.X + math.cos(r) * 1.6, 0, TP.Z + math.sin(r) * 1.6), 0.2, 0.2, "darkGray", "Metal")
end
B.box(scope, "Mount", TP.X - 0.4, TP.X + 0.4, TP.Y, TP.Y + 0.6, TP.Z - 0.4, TP.Z + 0.4, "darkGray", "Metal")
B.cylBetween(scope, "Tube", TP + Vector3.new(-1, 0.4, 1.2), TP + Vector3.new(1.4, 2.8, -1.6), 0.8, "white", "SmoothPlastic")
plaque(sci, 23.5, 112.8, CX, CZ, "OBSERVING THE UNIVERSE",
	"Space telescopes such as Hubble (1990) and James Webb (2021) reveal distant galaxies and the birth of stars.")

-- Lua em destaque + linha do tempo (canto nordeste) -----------------------------------------
local moon = B.group(solar, "Moon_Globe")
B.cyl(moon, "Pedestal", 36, 160, 0, 1, 5, "midGray", "SmoothPlastic")
B.cyl(moon, "Stand", 36, 160, 1, 2.2, 1.2, "darkGray", "Metal")
B.ball(moon, "Moon", Vector3.new(36, 5.6, 160), 7, "#BDBDBD", "Slate")
plaque(moon, 26.5, 152, CX, CZ, "THE MOON", "Earth's only natural satellite orbits about 384,400 km away. Twelve astronauts have walked on its surface.")

local screens = Museum.Screens
wallPanel(screens, 11, 31, 3, 10, 169.25, 169.45, Enum.NormalId.Front, "MISSION TIMELINE",
	"1957 Sputnik 1  •  1961 First human in space  •  1969 Apollo 11  •  1990 Hubble  •  1998 ISS  •  2012 Curiosity  •  2021 James Webb  •  2022 Artemis I",
	{ titleScale = 0.2, maxBody = 46, ppu = 40 })

local count = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") then count += 1 end
end
return ("Fase 3 construída. Peças no Map: %d. SLS topo em Y=%.1f"):format(count, DECK_TOP + 0.5 + 117)
