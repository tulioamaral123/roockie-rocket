--[[
	NASA Space Adventure — Fase 2: arquitetura
	(cúpula do museu, fachada e portas, janelas, portões do hangar, sala de observação)

	Executar no Command Bar do Studio (modo Edit) DEPOIS de phase1_structure.luau.
	Idempotente: remove tudo marcado com o atributo BuildPhase = 2 e as peças da
	Fase 1 que esta fase substitui, e recria.
]]

local C = {
	white = "#FFFFFF", lightGray = "#E7E9EA", midGray = "#AAB3BB", nasaBlue = "#244B70",
	space = "#080D20", darkBlue = "#101D3D", deepBlue = "#153D72", midBlue = "#397EC4", lightBlue = "#8ECDFB",
	darkGray = "#555B60", metalGray = "#8A9298", paleGray = "#D5D7D8", safety = "#E5B52E", glass = "#CFE8F7",
}
local GLASS = { transparency = 0.55, shadow = false }
local DECOR = { collide = false }

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute phase1_structure.luau antes")
local Base, C1, Museum, C2, Hangar =
	Map.Reception, Map.Corridors.Corridor_01, Map.CapeCanaveralMuseum, Map.Corridors.Corridor_02, Map.VABHangar

-- Idempotência ---------------------------------------------------------------
local old = {}
for _, d in Map:GetDescendants() do
	if d:GetAttribute("BuildPhase") == 2 then table.insert(old, d) end
end
for _, d in old do d:Destroy() end

local replaced = {
	{ Base.Walls, "Front_Wall" },
	{ C1.Walls, "Left_Wall" }, { C1.Walls, "Right_Wall" },
	{ Museum.Walls, "Front_Wall_L" }, { Museum.Walls, "Front_Wall_R" }, { Museum.Walls, "Front_Wall_Lintel" },
	{ Museum.Walls, "Roof_Front" }, { Museum.Walls, "Roof_Back" }, { Museum.Walls, "Roof_Left" }, { Museum.Walls, "Roof_Right" },
	{ Hangar.Structure, "Back_Wall" },
}
for _, r in replaced do
	local inst = r[1]:FindFirstChild(r[2])
	if inst then inst:Destroy() end
end

-- Helpers ----------------------------------------------------------------------
local function finish(p, parent, name, color, material, o)
	o = o or {}
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = Color3.fromHex(color)
	p.Material = Enum.Material[material]
	if o.transparency then p.Transparency = o.transparency end
	if o.shadow == false then p.CastShadow = false end
	if o.collide == false then
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
	end
	p:SetAttribute("BuildPhase", 2)
	p.Parent = parent
	return p
end

local function box(parent, name, x0, x1, y0, y1, z0, z1, color, material, o)
	local p = Instance.new("Part")
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	return finish(p, parent, name, color, material, o)
end

local function oriented(parent, name, cf, size, color, material, o)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	return finish(p, parent, name, color, material, o)
end

local function wallWithOpening(parent, name, z0, z1, x0, x1, top, ox0, ox1, otop, color, material)
	box(parent, name .. "_L", x0, ox0, -1, top, z0, z1, color, material)
	box(parent, name .. "_R", ox1, x1, -1, top, z0, z1, color, material)
	box(parent, name .. "_Lintel", ox0, ox1, otop, top, z0, z1, color, material)
end

local function group(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("BuildPhase", 2)
	m.Parent = parent
	return m
end

-- 1. Base NASA: fachada de vidro na entrada + moldura da saída --------------------
local facade = group(Base.Walls, "Front_Facade")
wallWithOpening(facade, "Front_Wall", -1, 0, -36, 36, 25, -20, 20, 16, C.white, "SmoothPlastic")
box(facade, "Glass", -20, 20, -1, 16, -0.7, -0.3, C.glass, "Glass", GLASS)
for _, x in { -12, -4, 4, 12 } do
	box(facade, "Mullion", x - 0.3, x + 0.3, -1, 16, -0.9, -0.1, C.midGray, "Metal")
end
box(facade, "Transom", -20, 20, 10, 10.6, -0.9, -0.1, C.midGray, "Metal")
box(facade, "Entrance_Canopy", -8, 8, 11, 11.8, -6, -1, C.nasaBlue, "SmoothPlastic")

local exitFrame = group(Base.Walls, "Exit_Frame")
box(exitFrame, "Jamb_L", -8, -7, 0, 12, 53.8, 54.5, C.nasaBlue, "SmoothPlastic")
box(exitFrame, "Jamb_R", 7, 8, 0, 12, 53.8, 54.5, C.nasaBlue, "SmoothPlastic")
box(exitFrame, "Header", -8, 8, 12, 13, 53.8, 54.5, C.nasaBlue, "SmoothPlastic")

-- 2. Corredor 1: paredes com trechos de vidro -------------------------------------
for _, s in { -1, 1 } do
	local x0, x1 = (s < 0) and -8 or 7, (s < 0) and -7 or 8
	local side = group(C1.Walls, (s < 0) and "Left_Wall" or "Right_Wall")
	box(side, "Base_Band", x0, x1, -1, 3, 55.5, 89.5, C.white, "SmoothPlastic")
	box(side, "Top_Band", x0, x1, 9, 13, 55.5, 89.5, C.white, "SmoothPlastic")
	for _, r in { { 55.5, 60 }, { 70, 75 }, { 85, 89.5 } } do
		box(side, "Post", x0, x1, 3, 9, r[1], r[2], C.white, "SmoothPlastic")
	end
	local xm = (x0 + x1) / 2
	for _, r in { { 60, 70 }, { 75, 85 } } do
		box(side, "Glass", xm - 0.15, xm + 0.15, 3, 9, r[1], r[2], C.glass, "Glass", GLASS)
	end
end

-- 3. Museu: portal de entrada com letreiro ------------------------------------------
local entrance = group(Museum.Walls, "Front_Wall")
wallWithOpening(entrance, "Front_Wall", 89.5, 90.5, -46, 46, 19, -6, 6, 9, C.darkBlue, "SmoothPlastic")
box(entrance, "Trim_L", -6.3, -6, 0, 9, 89.2, 89.5, C.midBlue, "Neon", DECOR)
box(entrance, "Trim_R", 6, 6.3, 0, 9, 89.2, 89.5, C.midBlue, "Neon", DECOR)
box(entrance, "Trim_Top", -6.3, 6.3, 9, 9.3, 89.2, 89.5, C.midBlue, "Neon", DECOR)

local sign = box(C1.Decorations, "Museum_Sign", -6.8, 6.8, 9.5, 11.8, 89.2, 89.5, C.space, "SmoothPlastic", DECOR)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front -- face −Z, voltada para quem vem do Corredor 1
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 60
gui.LightInfluence = 0
gui.Parent = sign
local function label(text, y, h, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(0.03, y)
	t.Size = UDim2.fromScale(0.94, h)
	t.Text = text
	t.TextScaled = true
	t.FontFace = font
	t.TextColor3 = Color3.fromHex(color)
	t.Parent = gui
end
label("SPACE ADVENTURE", 0.06, 0.56, Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy), C.lightBlue)
label("EXPLORE THE UNIVERSE", 0.66, 0.26, Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium), C.white)

-- Moldura industrial na saída do museu (transição para o Corredor 2)
local exitM = group(Museum.Walls, "Exit_Frame")
box(exitM, "Jamb_L", -9.5, -8, 0, 14, 168.8, 169.5, C.darkGray, "Metal")
box(exitM, "Jamb_R", 8, 9.5, 0, 14, 168.8, 169.5, C.darkGray, "Metal")
box(exitM, "Header", -9.5, 9.5, 14, 15.5, 168.8, 169.5, C.darkGray, "Metal")
box(exitM, "Hazard", -8, 8, 14.3, 15.2, 168.6, 168.8, C.safety, "SmoothPlastic", DECOR)

-- 4. Museu: cúpula de planetário (polígono de 16 lados, Y 18 → 42) --------------------
local CX, CZ = 0, 130
local SPRING, APEX, RB = 18, 42, 34
local R = (RB ^ 2 + (APEX - SPRING) ^ 2) / (2 * (APEX - SPRING))
local CY = APEX - R
local N = 16
local HALF = math.pi / N
local rings = { math.asin((SPRING - CY) / R), math.rad(40), math.rad(61), math.rad(82) }

local function ringPoint(a, theta, apothem)
	local r = R * math.cos(a)
	if apothem then r *= math.cos(HALF) end
	return Vector3.new(CX + r * math.cos(theta), CY + R * math.sin(a), CZ + r * math.sin(theta))
end
local function chord(a) return 2 * R * math.cos(a) * math.sin(HALF) end
local function tangent(theta) return Vector3.new(-math.sin(theta), 0, math.cos(theta)) end

local shell = group(Museum.Dome, "Dome_Shell")
local TH = 0.8
for i = 1, 3 do
	for j = 0, N - 1 do
		local th = (j + 0.5) * 2 * HALF
		local t = tangent(th)
		local p1, p2 = ringPoint(rings[i], th, true), ringPoint(rings[i + 1], th, true)
		local up = (p2 - p1).Unit
		local out = up:Cross(t)
		local pos = (p1 + p2) / 2 + out * (TH / 2)
		oriented(shell, "Panel", CFrame.fromMatrix(pos, t, up),
			Vector3.new(chord(rings[i]), (p2 - p1).Magnitude, TH), C.darkBlue, "SmoothPlastic")
	end
end

local ribs = group(Museum.Dome, "Ribs")
for j = 0, N - 1 do
	local th = j * 2 * HALF
	local t = tangent(th)
	for i = 1, 3 do
		local p1, p2 = ringPoint(rings[i], th, false), ringPoint(rings[i + 1], th, false)
		local up = (p2 - p1).Unit
		local out = up:Cross(t)
		oriented(ribs, "Rib", CFrame.fromMatrix((p1 + p2) / 2 - out * 0.2, t, up),
			Vector3.new(1.4, (p2 - p1).Magnitude + 0.6, 1.2), C.metalGray, "Metal")
	end
	-- anel de base (na borda do polígono, logo abaixo do teto do salão)
	local thc = (j + 0.5) * 2 * HALF
	local radial = Vector3.new(math.cos(thc), 0, math.sin(thc))
	local p = ringPoint(rings[1], thc, true) - radial * 0.3
	oriented(ribs, "Base_Ring", CFrame.fromMatrix(p, tangent(thc), Vector3.yAxis),
		Vector3.new(chord(rings[1]) + 0.6, 1.4, 1.4), C.metalGray, "Metal")
end

local topY = CY + R * math.sin(rings[4])
local rTop = R * math.cos(rings[4])
local oculus = oriented(Museum.Dome, "Oculus", CFrame.new(CX, topY + 0.4, CZ) * CFrame.Angles(0, 0, math.rad(90)),
	Vector3.new(0.8, rTop * 2 + 2, rTop * 2 + 2), C.deepBlue, "SmoothPlastic")
oculus.Shape = Enum.PartType.Cylinder

-- Teto do salão com furo circular para a cúpula (CSG)
local apothem0 = R * math.cos(rings[1]) * math.cos(HALF)
local slab = Instance.new("Part")
slab.Anchored = true
slab.Size = Vector3.new(90, 1, 79)
slab.CFrame = CFrame.new(0, 18.5, 130)
local hole = Instance.new("Part")
hole.Anchored = true
hole.Shape = Enum.PartType.Cylinder
hole.Size = Vector3.new(3, apothem0 * 2, apothem0 * 2)
hole.CFrame = CFrame.new(CX, 18.5, CZ) * CFrame.Angles(0, 0, math.rad(90))
slab.Parent = workspace -- a API de CSG exige peças ligadas ao DataModel
hole.Parent = workspace
local okRoof, roof = pcall(function() return slab:SubtractAsync({ hole }) end)
slab:Destroy()
hole:Destroy()
assert(okRoof, "CSG do teto falhou: " .. tostring(roof))
roof.UsePartColor = true
finish(roof, Museum.Walls, "Roof", C.space, "SmoothPlastic")

-- 5. Corredor 2: porta industrial deslizante (aberta) -------------------------------
local door = group(C2.Doors, "Sliding_Door")
box(door, "Jamb_L", -8, -6.5, 0, 14, 175, 177, C.darkGray, "Metal")
box(door, "Jamb_R", 6.5, 8, 0, 14, 175, 177, C.darkGray, "Metal")
box(door, "Header", -6.5, 6.5, 12, 14, 175, 177, C.darkGray, "Metal")
box(door, "Hazard_Front", -6.5, 6.5, 12.3, 13.7, 174.8, 175, C.safety, "SmoothPlastic", DECOR)
box(door, "Hazard_Back", -6.5, 6.5, 12.3, 13.7, 177, 177.2, C.safety, "SmoothPlastic", DECOR)
box(door, "Leaf_L", -7.9, -5.5, 0, 12, 177.2, 177.6, C.metalGray, "DiamondPlate")
box(door, "Leaf_R", 5.5, 7.9, 0, 12, 177.2, 177.6, C.metalGray, "DiamondPlate")

-- 6. Hangar: portão frontal 24 × 30 (aberto, folhas segmentadas recolhidas) -----------
local fg = group(Hangar.Gates, "Front_Gate")
box(fg, "Jamb_L", -14, -12, 0, 32, 211, 212.5, C.darkGray, "Metal")
box(fg, "Jamb_R", 12, 14, 0, 32, 211, 212.5, C.darkGray, "Metal")
box(fg, "Header", -14, 14, 30, 32, 211, 212.5, C.darkGray, "Metal")
box(fg, "Track_Beam", -28, 28, 32, 33.5, 211, 213.5, C.darkGray, "Metal")
box(fg, "Hazard_L", -13.7, -12.3, 0, 30, 212.5, 212.7, C.safety, "SmoothPlastic", DECOR)
box(fg, "Hazard_R", 12.3, 13.7, 0, 30, 212.5, 212.7, C.safety, "SmoothPlastic", DECOR)
for _, side in { { -26, -14 }, { 14, 26 } } do
	for k = 0, 2 do
		box(fg, "Leaf_Segment", side[1], side[2], k * 10, k * 10 + 9.85, 212.5, 213.5, C.paleGray, "Metal")
	end
end

-- 7. Hangar: portão dos fundos 80 × 140 (fechado) -------------------------------------
-- Saída do conjunto de transporte (spec-v3 §3.2): envelope de 68 × 134 passa com folga.
local backWall = group(Hangar.Structure, "Back_Wall")
wallWithOpening(backWall, "Back_Wall", 319, 321, -72, 72, 152, -40, 40, 140, C.metalGray, "Metal")
local bg = group(Hangar.Gates, "Maintenance_Gate")
for k = 0, 6 do
	local z0 = (k % 2 == 0) and 319.2 or 319.7
	box(bg, "Segment_" .. (k + 1), -40, 40, (k == 0) and -1 or k * 20, (k + 1) * 20, z0, z0 + 1, C.paleGray, "Metal")
end
box(bg, "Jamb_L", -42, -40, 0, 142, 317.5, 319, C.darkGray, "Metal")
box(bg, "Jamb_R", 40, 42, 0, 142, 317.5, 319, C.darkGray, "Metal")
box(bg, "Header", -42, 42, 140, 142, 317.5, 319, C.darkGray, "Metal")
box(bg, "Hazard_Band", -40, 40, 0, 3, 318.9, 319.2, C.safety, "SmoothPlastic", DECOR)

-- 8. Hangar: sala de observação elevada (~(45, 35, 250)) + escada --------------------
local obs = Hangar.Observation_Room
local room = group(obs, "Room")
box(room, "Floor", 44, 70, 34, 35, 238, 262, C.darkGray, "DiamondPlate")
box(room, "Ceiling", 44, 70, 45, 46, 238, 262, C.darkGray, "Metal")
-- janela voltada para o foguete (face X = 44)
box(room, "Kick_Plate", 44, 44.6, 35, 36, 238, 262, C.metalGray, "Metal")
box(room, "Top_Beam", 44, 44.6, 44.4, 45, 238, 262, C.metalGray, "Metal")
box(room, "Window", 44.15, 44.45, 36, 44.4, 238, 262, C.glass, "Glass", GLASS)
for _, z in { 244, 250, 256 } do
	box(room, "Mullion", 44, 44.6, 36, 44.4, z - 0.3, z + 0.3, C.metalGray, "Metal")
end
-- janela voltada para o portão frontal (face Z = 238)
box(room, "Kick_Plate_Front", 44.6, 70, 35, 36, 238, 238.6, C.metalGray, "Metal")
box(room, "Top_Beam_Front", 44.6, 70, 44.4, 45, 238, 238.6, C.metalGray, "Metal")
box(room, "Window_Front", 44.6, 70, 36, 44.4, 238.15, 238.45, C.glass, "Glass", GLASS)
for _, x in { 53, 62 } do
	box(room, "Mullion", x - 0.3, x + 0.3, 36, 44.4, 238, 238.6, C.metalGray, "Metal")
end
-- parede dos fundos com porta para a passarela
box(room, "Back_Wall_L", 44, 63, 35, 45, 261.6, 262, C.metalGray, "Metal")
box(room, "Back_Wall_R", 69, 70, 35, 45, 261.6, 262, C.metalGray, "Metal")
box(room, "Back_Wall_Header", 63, 69, 43, 45, 261.6, 262, C.metalGray, "Metal")
-- estrutura de apoio
for _, z in { { 239, 240.5 }, { 259.5, 261 } } do
	box(room, "Column", 45, 46.5, 0, 34, z[1], z[2], C.darkGray, "Metal")
	box(room, "Beam", 44, 70, 33, 34, z[1], z[2], C.darkGray, "Metal")
end

local walkway = group(obs, "Walkway")
box(walkway, "Deck", 62, 70, 34, 35, 262, 277, C.darkGray, "DiamondPlate")
box(walkway, "Rail", 62, 62.3, 35, 38.5, 262, 277, C.metalGray, "Metal")
box(walkway, "Column", 62, 63.5, 0, 34, 269.5, 271, C.darkGray, "Metal")

local stairs = group(obs, "Stairs")
for i = 1, 35 do
	box(stairs, "Step", 62, 70, 0, i, 312 - i, 313 - i, C.darkGray, "DiamondPlate")
end
do
	-- corrimão inclinado acompanhando a linha dos degraus (Z 312, Y 1) → (Z 278, Y 35)
	local up = Vector3.new(0, 1, 1).Unit
	local mid = Vector3.new(62.15, 18, 295) + up * 1.75
	oriented(stairs, "Rail", CFrame.fromMatrix(mid, Vector3.xAxis, up),
		Vector3.new(0.3, 3.5, 34 * math.sqrt(2) + 2), C.metalGray, "Metal")
end

local count = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") then count += 1 end
end
return ("Fase 2 construída. Peças no Map: %d (cúpula: R=%.2f, CY=%.2f, topo=%.2f)"):format(count, R, CY, topY + 0.8)
