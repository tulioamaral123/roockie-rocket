--[[
	NASA Space Adventure — Fase 10: VAB completo (spec-v3, Etapa 4)

	Tudo fora do envelope de transporte (X −34..34, Y 0..133, Z 230..320):

	1. Saída de pedestres na parede esquerda (X = −70, Z 296..302), com porta automática e
	   patamar externo no nível do piso do hangar (spec-v3 §3.5).
	2. Torres de plataformas de trabalho, uma de cada lado (X ±36..±46, Z 262..290), com seis
	   níveis (Y 30, 45, 60, 75, 90, 105). Cada nível tem deck fixo e uma plataforma retrátil
	   recolhida (Model com WorkPlatform = true e ExtendOffset) para o WorkPlatformController futuro.
	3. Elevador de serviço na torre esquerda: piso do hangar ↔ nível 60. Usa o mesmo sistema
	   do elevador da tripulação (CrewAccess): cabines Cab_*, ZoneOffset/ZoneSize, portas relativas.
	4. Segunda ponte rolante (Z 240), com trolley e gancho estacionados em X = −54.
	5. Equipamentos industriais: tubulações, painéis elétricos, bancadas, caixas técnicas,
	   dutos de ventilação, câmeras e barreiras.
	6. Iluminação das torres (6 SurfaceLights sem sombra).

	Executar depois das Fases 1–9 (o run_in_studio.luau já inclui esta fase). Idempotente.
]]

local lib = ...
local B = lib.builder(10)

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–9 antes")
B.clear(Map)

local Hangar = Map.VABHangar
local DECOR = { collide = false }
local DECOR_NS = { collide = false, shadow = false }
local N = Enum.NormalId

local function prompt(part, action, object, actionText, o)
	local p = Instance.new("ProximityPrompt")
	p.ObjectText = object
	p.ActionText = actionText
	p.HoldDuration = 0
	p.MaxActivationDistance = o and o.dist or 7
	p.RequiresLineOfSight = false
	p:SetAttribute("CrewAction", action)
	p:SetAttribute("BuildPhase", 10)
	p.Parent = part
	return p
end

---------------------------------------------------------------------------------
-- 1. Saída de pedestres (parede esquerda)
---------------------------------------------------------------------------------
local DZ0, DZ1, DH = 296, 302, 10
local oldWall = Hangar.Structure:FindFirstChild("Left_Wall")
if oldWall and oldWall:IsA("BasePart") and oldWall:GetAttribute("BuildPhase") == nil then
	oldWall:Destroy() -- parede inteira da Fase 1, substituída pelos trechos abaixo
end
local lw = B.group(Hangar.Structure, "Left_Wall_Segments")
B.box(lw, "Left_Wall_A", -72, -70, -1, 152, 211, DZ0, "metalGray", "Metal")
B.box(lw, "Left_Wall_B", -72, -70, -1, 152, DZ1, 319, "metalGray", "Metal")
B.box(lw, "Left_Wall_Lintel", -72, -70, DH, 152, DZ0, DZ1, "metalGray", "Metal")

local exit = B.group(Hangar.Structure, "Pedestrian_Exit")
B.box(exit, "Jamb", -70, -69.6, 0, DH + 0.4, DZ0 - 0.4, DZ0, "darkGray", "Metal")
B.box(exit, "Jamb", -70, -69.6, 0, DH + 0.4, DZ1, DZ1 + 0.4, "darkGray", "Metal")
B.box(exit, "Header", -70, -69.6, DH, DH + 0.4, DZ0 - 0.4, DZ1 + 0.4, "darkGray", "Metal")
local exitSign = B.box(exit, "Exit_Sign", -69.6, -69.5, DH + 0.8, DH + 2.2, DZ0, DZ1, "#2E9E4F", "SmoothPlastic", DECOR)
B.sign(exitSign, "EXIT — LAUNCH COMPLEX", nil, { face = N.Right, bg = "#2E9E4F", titleColor = "white" })
B.box(exit, "Landing", -82, -72, -1, 0, DZ0 - 2, DZ1 + 2, "midGray", "Concrete")
B.box(exit, "Landing_Stripe", -72.6, -72, 0, 0.05, DZ0 - 2, DZ1 + 2, "safety", "SmoothPlastic", DECOR)

local door = B.group(exit, "Exit_AutoDoor")
door:SetAttribute("AutoDoor", true)
door:SetAttribute("SensorCenter", Vector3.new(-71, 3, (DZ0 + DZ1) / 2))
door:SetAttribute("SensorRadius", 9)
for _, side in { -1, 1 } do
	local leaf = B.group(door, side < 0 and "Leaf_L" or "Leaf_R")
	local z0, z1 = (side < 0) and DZ0 or (DZ0 + DZ1) / 2, (side < 0) and (DZ0 + DZ1) / 2 or DZ1
	local panel = B.box(leaf, "Panel", -71.2, -70.8, 0, DH - 0.2, z0, z1, "paleGray", "Metal")
	B.box(leaf, "Window", -71.25, -70.75, 5, 8.5, z0 + 0.7, z1 - 0.7, "glass", "Glass", { transparency = 0.4, collide = false })
	B.box(leaf, "Kick_Plate", -71.25, -70.75, 0, 0.8, z0, z1, "safety", "Metal", DECOR)
	leaf.PrimaryPart = panel
	leaf:SetAttribute("OpenOffset", Vector3.new(0, 0, side * 3))
end

---------------------------------------------------------------------------------
-- 2. Torres de plataformas de trabalho
---------------------------------------------------------------------------------
local TZ0, TZ1, TOP = 262, 290, 112
local LEVELS = { 30, 45, 60, 75, 90, 105 }
local SHAFT = { x0 = -45.4, x1 = -40.2, z0 = 262, z1 = 268.4 } -- poço do elevador (torre esquerda)
local SERVICE_LEVEL = 60

local towers = B.group(Hangar, "Work_Platforms")
for _, S in { -1, 1 } do
	local xi, xo = S * 36, S * 46
	local t = B.group(towers, S < 0 and "Platform_Tower_L" or "Platform_Tower_R")
	-- colunas
	for _, x in { S * 36.4, S * 45.6 } do
		for _, z in { TZ0 + 0.4, (TZ0 + TZ1) / 2, TZ1 - 0.4 } do
			B.box(t, "Column", x - 0.4, x + 0.4, 0, TOP, z - 0.4, z + 0.4, "darkGray", "Metal")
		end
	end
	B.box(t, "Top_Beam", xi, xo, TOP, TOP + 0.8, TZ0, TZ0 + 0.8, "darkGray", "Metal")
	B.box(t, "Top_Beam", xi, xo, TOP, TOP + 0.8, TZ1 - 0.8, TZ1, "darkGray", "Metal")
	B.box(t, "Top_Beam", xi, xi + S * 0.8, TOP, TOP + 0.8, TZ0, TZ1, "darkGray", "Metal")
	B.box(t, "Top_Beam", xo - S * 0.8, xo, TOP, TOP + 0.8, TZ0, TZ1, "darkGray", "Metal")
	-- contraventamento na face externa
	local prevY = 0
	for _, y in { 30, 45, 60, 75, 90, 105, TOP } do
		B.beam(t, "Brace", Vector3.new(xo - S * 0.4, prevY, TZ0 + 0.4), Vector3.new(xo - S * 0.4, y, (TZ0 + TZ1) / 2), 0.3, 0.3, "metalGray", "Metal", DECOR)
		B.beam(t, "Brace", Vector3.new(xo - S * 0.4, prevY, TZ1 - 0.4), Vector3.new(xo - S * 0.4, y, (TZ0 + TZ1) / 2), 0.3, 0.3, "metalGray", "Metal", DECOR)
		prevY = y
	end
	for _, y in LEVELS do
		local lvl = B.group(t, "Level_" .. y)
		-- na torre esquerda, os níveis 30 e 45 deixam livre o poço do elevador
		local z0 = (S < 0 and y < SERVICE_LEVEL) and SHAFT.z1 or TZ0
		B.box(lvl, "Deck", xi, xo, y - 0.5, y, z0, TZ1, "darkGray", "DiamondPlate")
		B.box(lvl, "Edge_Beam", xi, xi + S * 0.6, y - 1.3, y - 0.5, z0, TZ1, "metalGray", "Metal")
		B.box(lvl, "Edge_Beam", xo - S * 0.6, xo, y - 1.3, y - 0.5, z0, TZ1, "metalGray", "Metal")
		-- guarda-corpos: lado do foguete, lado externo e pontas
		for _, x in { S * 36.2, S * 45.8 } do
			for _, ry in { y + 1.8, y + 3.4 } do
				B.box(lvl, "Rail", x - 0.12, x + 0.12, ry, ry + 0.25, z0, TZ1, "safety", "Metal")
			end
			for _, pz in { z0 + 0.3, (z0 + TZ1) / 2, TZ1 - 0.3 } do
				B.box(lvl, "Rail_Post", x - 0.12, x + 0.12, y, y + 3.65, pz - 0.12, pz + 0.12, "safety", "Metal")
			end
		end
		for _, z in { z0 + 0.15, TZ1 - 0.15 } do
			B.box(lvl, "Rail", xi, xo, y + 3.4, y + 3.65, z - 0.12, z + 0.12, "safety", "Metal")
		end
		-- plataforma retrátil recolhida sob o deck (estende em direção ao foguete)
		local wp = B.group(lvl, "Work_Platform")
		local slab = B.box(wp, "Slab", xi, xi + S * 4, y - 2.2, y - 1.6, TZ0 + 4, TZ1 - 4, "paleGray", "DiamondPlate")
		B.box(wp, "Safety_Edge", xi, xi + S * 0.3, y - 2.25, y - 1.55, TZ0 + 4, TZ1 - 4, "safety", "SmoothPlastic", DECOR)
		wp.PrimaryPart = slab
		wp:SetAttribute("WorkPlatform", true)
		wp:SetAttribute("ExtendOffset", Vector3.new(-S * 22, 0, 0)) -- estendida: borda a ±14 do eixo
	end
	-- iluminação: faixas sob os níveis 30, 60 e 90
	for _, y in { 30, 60, 90 } do
		local strip = B.box(t, "Light_Strip", S * 38, S * 44, y - 1.45, y - 1.35, 274, 278, "white", "Neon", DECOR_NS)
		B.light(strip, "SurfaceLight", { Face = N.Bottom, Range = 18, Brightness = 1.2, Angle = 120, Shadows = false })
	end
	-- placa voltada para o foguete
	local sign = B.box(t, "Sign", S * 35.9, S * 35.8, 16, 21, 270, 282, "space", "SmoothPlastic", DECOR)
	B.sign(sign, "WORK PLATFORMS", "Six levels give technicians access to every part of the SLS. The yellow-edged platforms extend toward the rocket during processing.",
		{ face = (S < 0) and N.Right or N.Left, accent = "safety", titleScale = 0.3 })
end

---------------------------------------------------------------------------------
-- 3. Elevador de serviço (torre esquerda): piso ↔ nível 60
---------------------------------------------------------------------------------
local elev = B.group(towers.Platform_Tower_L, "Service_Elevator")
local EX0, EX1 = SHAFT.x0, SHAFT.x1
local ZC0, ZC1 = 262.8, 267.6
local ZONE = Vector3.new(4.4, 7.4, ZC1 - ZC0 + 0.6)
local function cab(name, floorY)
	local c = B.group(elev, name)
	local y1 = floorY + 7.4
	local floor = B.box(c, "Floor", EX0, EX1, floorY - 0.5, floorY + 0.15, ZC0 - 0.4, ZC1 + 0.4, "darkGray", "DiamondPlate")
	c.PrimaryPart = floor
	c:SetAttribute("ZoneOffset", floor.CFrame:PointToObjectSpace(Vector3.new((EX0 + EX1) / 2, floorY + 3.7, (ZC0 + ZC1) / 2)))
	c:SetAttribute("ZoneSize", ZONE)
	B.box(c, "Wall_Side", EX0, EX0 + 0.6, floorY, y1, ZC0 - 0.4, ZC1 + 0.4, "metalGray", "Metal")
	B.box(c, "Wall_Side", EX1 - 0.6, EX1, floorY, y1, ZC0 - 0.4, ZC1 + 0.4, "metalGray", "Metal")
	B.box(c, "Wall_Back", EX0 + 0.6, EX1 - 0.6, floorY, y1, ZC0 - 0.4, ZC0, "metalGray", "Metal")
	B.box(c, "Roof", EX0, EX1, y1, y1 + 0.4, ZC0 - 0.4, ZC1 + 0.4, "metalGray", "Metal")
	local lp = B.box(c, "Cab_Light", EX0 + 1.6, EX1 - 1.6, y1 - 0.08, y1, ZC0 + 1.2, ZC1 - 1.2, "white", "Neon", DECOR_NS)
	B.light(lp, "SurfaceLight", { Face = N.Bottom, Brightness = 1.4, Range = 9, Shadows = false })
	local panel = B.box(c, "Call_Panel", EX1 - 0.67, EX1 - 0.6, floorY + 2.9, floorY + 4.4, 264.7, 265.7, "darkGray", "Metal")
	B.box(c, "Status_Lamp", EX1 - 0.68, EX1 - 0.59, floorY + 4.7, floorY + 5.1, 265, 265.4, "#3CCB5A", "Neon", DECOR_NS)
	local mid = (EX0 + EX1) / 2
	for _, side in { -1, 1 } do
		local x0, x1 = (side < 0) and (EX0 + 0.6) or mid, (side < 0) and mid or (EX1 - 0.6)
		local leaf = B.box(c, side < 0 and "Door_L" or "Door_R", x0, x1, floorY + 0.15, floorY + 7, ZC1 + 0.05, ZC1 + 0.35, "metalGray", "Metal")
		leaf:SetAttribute("OpenOffset", Vector3.new(side * (mid - EX0 - 0.6), 0, 0))
		B.box(c, "Door_Window", x0 + 0.5, x1 - 0.5, floorY + 4, floorY + 6, ZC1 + 0.02, ZC1 + 0.38, "glass", "Glass",
			{ collide = false, transparency = 0.3 }):SetAttribute("FollowDoor", leaf.Name)
	end
	return panel
end
local panelLow = cab("Cab_Floor", 0)
local panelTop = cab("Cab_Level60", SERVICE_LEVEL)
prompt(panelLow, "Elevator", "Service elevator", "Go up to platform level 60", { dist = 5 })
	:SetAttribute("FadeText", "Going up to the work platforms…")
prompt(panelTop, "Elevator", "Service elevator", "Go down to the hangar floor", { dist = 5 })
	:SetAttribute("FadeText", "Going down to the hangar floor…")
for _, y in { 0, SERVICE_LEVEL } do
	local tag = B.box(elev, "Sign", EX0 + 0.5, EX1 - 0.5, y + 7.5, y + 8.5, ZC1 + 0.4, ZC1 + 0.5, "space", "SmoothPlastic", DECOR)
	B.sign(tag, y == 0 and "SERVICE ELEVATOR · LEVEL 60" or "SERVICE ELEVATOR · FLOOR", nil, { face = N.Back, titleColor = "safety" })
end
local shaft = B.group(elev, "Shaft")
for _, px in { EX0 - 0.3, EX1 + 0.3 } do
	for _, pz in { SHAFT.z0 + 0.2, SHAFT.z1 - 0.2 } do
		B.box(shaft, "Post", px - 0.25, px + 0.25, 0, SERVICE_LEVEL + 8, pz - 0.25, pz + 0.25, "darkGray", "Metal")
	end
end
for y = 12, SERVICE_LEVEL - 4, 12 do
	B.box(shaft, "Band", EX0 - 0.55, EX1 + 0.55, y - 0.2, y + 0.2, SHAFT.z0 - 0.05, SHAFT.z0 + 0.45, "metalGray", "Metal")
end

---------------------------------------------------------------------------------
-- 4. Segunda ponte rolante (Z 240), estacionada em X = −54
---------------------------------------------------------------------------------
local crane2 = B.group(Hangar.Structure, "Bridge_Crane_2")
local CZ, PX = 240, -54
B.box(crane2, "Bridge_Girder", -66, 66, 136, 139, CZ - 2, CZ + 2, "safety", "Metal")
B.box(crane2, "Trolley", PX - 4, PX + 4, 133, 136, CZ - 3, CZ + 3, "darkGray", "Metal")
B.cyl(crane2, "Cable", PX, CZ, 131.5, 133, 0.3, "black", "Metal", DECOR)
B.box(crane2, "Hook_Block", PX - 1.2, PX + 1.2, 128.5, 131.5, CZ - 1, CZ + 1, "safety", "Metal", DECOR)

---------------------------------------------------------------------------------
-- 5. Equipamentos industriais
---------------------------------------------------------------------------------
local eq = B.group(Hangar, "Industrial_Equipment")
-- tubulações nas paredes (a direita para antes da escada da sala de observação, Z 277)
for _, S in { -1, 1 } do
	local x = S * 67.8
	local z1 = (S < 0) and 318 or 275
	for _, p in { { 20, 1.2, "safety" }, { 22.5, 0.9, "nasaBlue" }, { 25, 0.7, "white" } } do
		B.cylBetween(eq, "Pipe", Vector3.new(x, p[1], 213), Vector3.new(x, p[1], z1), p[2], p[3], "Metal", DECOR)
	end
	for _, z in { 240, 255 } do
		B.cylBetween(eq, "Pipe_Drop", Vector3.new(x, 0.3, z), Vector3.new(x, 20, z), 1.2, "safety", "Metal", DECOR)
		B.cyl(eq, "Valve_Base", x, z, 0, 0.6, 2, "darkGray", "Metal", DECOR)
	end
	-- painéis elétricos
	for _, z in { 216, 226.5 } do
		local face = S * 69
		B.box(eq, "Electrical_Panel", S * 70, face, 2, 7, z - 1.5, z + 1.5, "midGray", "Metal")
		B.box(eq, "Panel_Door_Line", face - S * 0.03, face - S * 0.06, 2.3, 6.7, z - 0.02, z + 0.02, "darkGray", "SmoothPlastic", DECOR)
		for i, col in { "#3CCB5A", "#E5B52E", "#D33D32" } do
			B.box(eq, "Indicator", face - S * 0.02, face - S * 0.12, 6.2, 6.5, z - 1.1 + i * 0.5, z - 0.8 + i * 0.5, col, "Neon", DECOR_NS)
		end
	end
	-- bancada com ferramentas
	local bx0, bx1 = S * 68.4, S * 65.4
	B.box(eq, "Workbench_Top", bx0, bx1, 3, 3.4, 228.5, 236, "metalGray", "Metal")
	for _, lx in { bx0 - S * 0.3, bx1 + S * 0.3 } do
		for _, lz in { 228.8, 235.7 } do
			B.box(eq, "Workbench_Leg", lx - 0.15, lx + 0.15, 0, 3, lz - 0.15, lz + 0.15, "darkGray", "Metal")
		end
	end
	B.box(eq, "Tool_Chest", bx0, bx0 - S * 1.6, 3.4, 5, 229, 231.5, "red", "Metal")
	B.box(eq, "Toolbox", bx1 + S * 0.4, bx1 + S * 1.6, 3.4, 4.2, 233, 235, "safety", "Metal", DECOR)
	B.box(eq, "Pegboard", S * 69.9, S * 69.7, 4.5, 8, 228.5, 236, "darkGray", "Metal", DECOR)
	-- dutos de ventilação junto ao teto
	B.box(eq, "Vent_Duct", S * 60, S * 64, 118, 122, 214, 318, "paleGray", "Metal", DECOR)
	for z = 224, 314, 18 do
		B.box(eq, "Vent_Grille", S * 60.5, S * 63.5, 117.9, 118, z - 1.5, z + 1.5, "darkGray", "Metal", DECOR)
	end
	-- câmeras de monitoramento nos pilares
	for _, z in { 244, 288 } do
		B.box(eq, "Camera_Body", S * 68.6, S * 67, 40, 41, z - 0.5, z + 0.5, "white", "SmoothPlastic", DECOR)
		B.box(eq, "Camera_Lens", S * 67, S * 66.8, 40.2, 40.8, z - 0.3, z + 0.3, "black", "Glass", DECOR)
		B.box(eq, "Camera_Led", S * 67.05, S * 66.95, 40.85, 40.95, z + 0.3, z + 0.4, "#D33D32", "Neon", DECOR_NS)
	end
end
-- caixas técnicas
for _, c in { { -64, -58, 270, 276 }, { 50, 56, 300, 306 } } do
	B.box(eq, "Crate", c[1], c[2], 0, 3, c[3], c[4], "#6B7A5A", "WoodPlanks")
	B.box(eq, "Crate", c[1] + 0.5, c[2] - 2.5, 3, 5.5, c[3] + 0.5, c[4] - 0.5, "#6B7A5A", "WoodPlanks")
	B.box(eq, "Crate_Label", c[1] + 1, c[2] - 1, 1, 2, c[3] - 0.05, c[3], "white", "SmoothPlastic", DECOR)
end
-- barreira em frente ao pé da torre direita
for _, z in { 262.5, 269.5, 276, 282.5, 289.5 } do
	B.box(eq, "Barrier_Post", 35.3, 35.7, 0, 3.4, z - 0.2, z + 0.2, "safety", "Metal")
end
for _, y in { 1.6, 3.1 } do
	B.box(eq, "Barrier_Rail", 35.35, 35.65, y, y + 0.3, 262.5, 289.5, "safety", "Metal")
end

local n = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("BuildPhase") == 10 then n += 1 end
end
return string.format("Fase 10: VAB completo (%d peças)", n)
