--[[
	NASA Space Adventure — Fase 4: decoração e sinalização
	Recepção (balcão, telas, área de espera, painel institucional), quadros e placas dos corredores,
	tubulações do Corredor 2, estrutura/veículos/marcações do hangar, console da sala de observação.
]]

local lib = ...
local B = lib.builder(4)
local Map = workspace:FindFirstChild("Map")
assert(Map, "Execute as Fases 1–3 antes")
B.clear(Map)

local Base, C1, Museum, C2, Hangar =
	Map.NASA_Base, Map.Corridor_01, Map.Space_Adventure, Map.Corridor_02, Map.Rocket_Hangar
local DECOR = { collide = false }
local FLOOR_MARK = { collide = false, shadow = false }
local N = Enum.NormalId

local function panel(parent, x0, x1, y0, y1, z0, z1, face, title, body, opts)
	local p = B.box(parent, "Sign", x0, x1, y0, y1, z0, z1, "space", "SmoothPlastic", DECOR)
	opts = opts or {}
	opts.face = face
	B.sign(p, title, body, opts)
	return p
end

-- Quadro "artístico" feito só com UI (sem assets externos): gradiente + planeta + legenda
local function artwork(part, face, title, caption, planetColor, top, bottom)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.Parent = gui
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromHex(top), Color3.fromHex(bottom))
	grad.Rotation = 90
	grad.Parent = bg
	local rng = Random.new(#title)
	for _ = 1, 40 do
		local s = Instance.new("Frame")
		local px = rng:NextInteger(2, 4)
		s.Size = UDim2.fromOffset(px, px)
		s.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber() * 0.7)
		s.BackgroundColor3 = Color3.new(1, 1, 1)
		s.BackgroundTransparency = rng:NextNumber(0, 0.5)
		s.BorderSizePixel = 0
		s.Parent = bg
	end
	local planet = Instance.new("Frame")
	planet.AnchorPoint = Vector2.new(0.5, 0.5)
	planet.Position = UDim2.fromScale(0.62, 0.5)
	planet.Size = UDim2.fromScale(0.55, 0.55)
	planet.BackgroundColor3 = Color3.fromHex(planetColor)
	planet.BorderSizePixel = 0
	planet.Parent = bg
	Instance.new("UIAspectRatioConstraint").Parent = planet
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = planet
	local shade = Instance.new("UIGradient")
	shade.Transparency = NumberSequence.new(0, 0.6)
	shade.Rotation = 35
	shade.Parent = planet
	for i, txt in { title, caption } do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.06, i == 1 and 0.72 or 0.86)
		t.Size = UDim2.fromScale(0.88, i == 1 and 0.13 or 0.08)
		t.Text = txt
		t.TextScaled = true
		t.Font = i == 1 and Enum.Font.GothamBlack or Enum.Font.GothamMedium
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Parent = bg
	end
end

---------------------------------------------------------------------------------
-- 1. BASE NASA — recepção (spec §3.2–3.4)
---------------------------------------------------------------------------------
local rec, furn = Base.Reception, Base.Furniture

-- Painel institucional suspenso (0, 8, 3), voltado para o spawn
local inst = B.box(rec, "Institutional_Panel", -12, 12, 4.5, 11.5, 2.7, 3.3, "nasaBlue", "SmoothPlastic")
B.sign(inst, "NASA SPACE ADVENTURE", "Explore  •  Discover  •  Inspire",
	{ face = N.Back, bg = "nasaBlue", accent = "red", titleColor = "white", bodyColor = "lightGray", titleScale = 0.45, maxBody = 70, ppu = 40 })
for _, x in { -10, 10 } do
	B.cyl(rec, "Hanger_Cable", x, 3, 11.5, 24, 0.12, "midGray", "Metal", DECOR)
end

-- Balcão de recepção (-20, 0, 15), atendimento voltado para o centro do saguão
local desk = B.group(rec, "Reception_Desk")
B.box(desk, "Front", -16.6, -16, 0, 3.8, 9, 21, "white", "SmoothPlastic")
B.box(desk, "Accent", -16.1, -15.95, 2.4, 2.9, 9, 21, "red", "SmoothPlastic", DECOR)
B.box(desk, "Return_N", -22, -16, 0, 3.8, 20.4, 21, "white", "SmoothPlastic")
B.box(desk, "Return_S", -22, -16, 0, 3.8, 9, 9.6, "white", "SmoothPlastic")
B.box(desk, "Counter_Top", -17.4, -15.7, 3.8, 4.1, 8.8, 21.2, "lightGray", "SmoothPlastic")
B.box(desk, "Work_Surface", -21, -16.6, 2.6, 2.8, 9.6, 20.4, "midGray", "SmoothPlastic")
for _, z in { 12, 18 } do
	B.box(desk, "Monitor", -17.5, -17.3, 2.9, 4.4, z - 1.1, z + 1.1, "black", "SmoothPlastic")
	B.box(desk, "Monitor_Stand", -17.7, -17.3, 2.8, 2.9, z - 0.4, z + 0.4, "darkGray", "Metal")
	B.box(desk, "Keyboard", -18.6, -17.9, 2.8, 2.9, z - 0.8, z + 0.8, "darkGray", "SmoothPlastic", DECOR)
	-- cadeira do atendente
	B.cyl(desk, "Chair_Base", -19.8, z, 0, 1.6, 0.4, "darkGray", "Metal")
	B.box(desk, "Chair_Seat", -20.6, -19, 1.6, 2, z - 0.8, z + 0.8, "nasaBlue", "Fabric")
	B.box(desk, "Chair_Back", -21, -20.6, 2, 3.6, z - 0.8, z + 0.8, "nasaBlue", "Fabric")
end
panel(rec, -34.95, -34.75, 7, 13, 7, 23, N.Right, "RECEPTION", "Welcome to the NASA Space Adventure base",
	{ bg = "white", titleColor = "nasaBlue", bodyColor = "darkGray", accent = "red", titleScale = 0.45, maxBody = 50 })

-- Telas informativas (22, 4, 15)
local info = B.group(rec, "Info_Screens")
B.box(info, "Display_Wall", 22, 22.6, 0, 8, 9, 21, "white", "SmoothPlastic")
panel(info, 21.85, 22, 2.5, 6.8, 9.5, 14.7, N.Left, "WELCOME, EXPLORER",
	"Your mission: visit the Space Adventure Museum, then reach the SLS hangar.", { accent = "red" })
panel(info, 21.85, 22, 2.5, 6.8, 15.3, 20.5, N.Left, "YOUR ROUTE",
	"1  Reception\n2  Space Adventure Museum\n3  Industrial corridor\n4  SLS Hangar", { accent = "midBlue" })

-- Área de espera (15, 0, 35)
local function sofa(parent, x0, x1, z0, z1, backAtLowZ)
	local g = B.group(parent, "Sofa")
	B.box(g, "Seat", x0, x1, 0, 1.6, z0, z1, "nasaBlue", "Fabric")
	if backAtLowZ then
		B.box(g, "Back", x0, x1, 1.6, 3.6, z0, z0 + 0.8, "nasaBlue", "Fabric")
	else
		B.box(g, "Back", x0, x1, 1.6, 3.6, z1 - 0.8, z1, "nasaBlue", "Fabric")
	end
	B.box(g, "Arm", x0 - 0.6, x0, 0, 2.4, z0, z1, "nasaBlue", "Fabric")
	B.box(g, "Arm", x1, x1 + 0.6, 0, 2.4, z0, z1, "nasaBlue", "Fabric")
end
sofa(furn, 11, 19, 29.5, 32.5, true)
sofa(furn, 11, 19, 37.5, 40.5, false)
B.box(furn, "Table_Base", 14, 16, 0, 1.2, 34.5, 35.5, "midGray", "Metal")
B.box(furn, "Table_Top", 13, 17, 1.2, 1.4, 33.6, 36.4, "glass", "Glass", { transparency = 0.4 })

local function plant(parent, x, z)
	local g = B.group(parent, "Plant")
	B.cyl(g, "Pot", x, z, 0, 2.2, 2, "white", "SmoothPlastic")
	B.ball(g, "Foliage", Vector3.new(x, 3.6, z), 3, "#3E7B3A", "Grass", DECOR)
end
for _, p in { { 8, 29 }, { 22, 41 }, { -31, 51 }, { 31, 51 }, { -31, 4 }, { 31, 4 } } do
	plant(furn, p[1], p[2])
end

-- Faixa vermelha de destaque nas paredes e guia de piso até a saída
B.box(rec, "Accent_Stripe_L", -35, -34.9, 2.8, 3.2, 0.5, 54, "red", "SmoothPlastic", DECOR)
B.box(rec, "Accent_Stripe_R", 34.9, 35, 2.8, 3.2, 0.5, 54, "red", "SmoothPlastic", DECOR)
B.box(rec, "Floor_Guide", -0.5, 0.5, 0, 0.05, 15.5, 53.8, "nasaBlue", "SmoothPlastic", FLOOR_MARK)
panel(rec, -7, 7, 13.4, 15.8, 53.6, 53.8, N.Front, "SPACE ADVENTURE MUSEUM", "This way to the exhibition",
	{ bg = "nasaBlue", titleColor = "white", bodyColor = "lightBlue", accent = "red", titleScale = 0.42 })

---------------------------------------------------------------------------------
-- 2. CORREDOR 1 — quadros e sinalização direcional (spec §4.2)
---------------------------------------------------------------------------------
local deco1 = C1.Decorations
local arts = {
	{ side = -1, z0 = 70.3, z1 = 74.7, title = "ARTEMIS", cap = "Returning to the Moon", color = "#CFCFCF", top = "#0B1028", bottom = "#2A3F7A" },
	{ side = 1, z0 = 70.3, z1 = 74.7, title = "APOLLO 11", cap = "First Moon landing, 1969", color = "#B8B8B8", top = "#05070F", bottom = "#1D2340" },
	{ side = -1, z0 = 55.8, z1 = 59.7, title = "EARTH", cap = "Our home planet from orbit", color = "#2E6FD6", top = "#03050C", bottom = "#122452" },
	{ side = 1, z0 = 55.8, z1 = 59.7, title = "MARS", cap = "The Red Planet", color = "#C1440E", top = "#120604", bottom = "#4A1A0C" },
}
for _, a in arts do
	local x0, x1 = (a.side < 0) and -6.98 or 6.83, (a.side < 0) and -6.83 or 6.98
	local frame = B.box(deco1, "Artwork_Frame", x0, x1, 3.3, 8.7, a.z0 - 0.2, a.z1 + 0.2, "darkGray", "Metal", DECOR)
	local face = (a.side < 0) and N.Right or N.Left
	local canvasX0, canvasX1 = (a.side < 0) and -6.83 or 6.78, (a.side < 0) and -6.78 or 6.83
	local canvas = B.box(deco1, "Artwork", canvasX0, canvasX1, 3.5, 8.5, a.z0, a.z1, "space", "SmoothPlastic", DECOR)
	artwork(canvas, face, a.title, a.cap, a.color, a.top, a.bottom)
	local _ = frame
end
panel(deco1, -4, 4, 9.3, 11.2, 61.9, 62.1, N.Front, "MUSEUM AHEAD", nil, { bg = "nasaBlue", titleColor = "white" })

---------------------------------------------------------------------------------
-- 3. CORREDOR 2 — linguagem industrial (spec §6.2)
---------------------------------------------------------------------------------
local pipes, ind = C2.Pipes, C2.Industrial_Structure
for _, sx in { -1, 1 } do
	B.cylBetween(pipes, "Pipe", Vector3.new(sx * 7.3, 10.6, 171), Vector3.new(sx * 7.3, 10.6, 207.5), 0.9, sx < 0 and "rust" or "metalGray", "Metal", DECOR)
	B.cylBetween(pipes, "Pipe", Vector3.new(sx * 7.4, 11.9, 171), Vector3.new(sx * 7.4, 11.9, 207.5), 0.6, sx < 0 and "safety" or "darkGray", "Metal", DECOR)
	for z = 180, 205, 8 do
		B.box(pipes, "Bracket", sx * 7.95, sx * 6.7, 10, 12.4, z - 0.15, z + 0.15, "darkGray", "Metal", DECOR)
	end
	B.box(ind, "Hazard_Floor", sx * 7.1, sx * 7.6, 0, 0.05, 171, 208, "safety", "SmoothPlastic", FLOOR_MARK)
end
B.box(pipes, "Duct", -3, 3, 12.2, 13.6, 178, 207.5, "metalGray", "Metal", DECOR)
for _, z in { 186, 197 } do
	B.box(ind, "Frame_Column", -8, -7.2, 0, 14, z - 0.4, z + 0.4, "darkGray", "Metal")
	B.box(ind, "Frame_Column", 7.2, 8, 0, 14, z - 0.4, z + 0.4, "darkGray", "Metal")
	B.box(ind, "Frame_Header", -8, 8, 13.6, 14, z - 0.4, z + 0.4, "darkGray", "Metal")
end
panel(ind, -7.95, -7.8, 5, 8.5, 189, 195, N.Right, "RESTRICTED AREA", "Authorized personnel only",
	{ bg = "black", accent = "safety", titleColor = "safety", bodyColor = "white", titleScale = 0.4 })
panel(ind, 7.8, 7.95, 5, 8.5, 199, 205, N.Left, "HANGAR ACCESS", "SLS vehicle assembly area ahead",
	{ bg = "black", accent = "safety", titleColor = "safety", bodyColor = "white", titleScale = 0.4 })

---------------------------------------------------------------------------------
-- 4. HANGAR — estrutura aparente, veículos, marcações, console (spec §7.2)
---------------------------------------------------------------------------------
local hs = Hangar.Structure
local TRUSS_Z = { 222, 244, 266, 288, 310 }
for _, z in TRUSS_Z do
	for _, sx in { -1, 1 } do
		B.box(hs, "Pilaster", sx * 70, sx * 68.6, 0, 150, z - 1, z + 1, "darkGray", "Metal")
	end
	B.box(hs, "Roof_Truss", -68.6, 68.6, 143, 146, z - 0.8, z + 0.8, "darkGray", "Metal")
end
-- ponte rolante
local crane = B.group(hs, "Bridge_Crane")
for _, sx in { -1, 1 } do
	B.box(crane, "Runway", sx * 68.6, sx * 66, 138, 140, 212, 318, "darkGray", "Metal")
end
B.box(crane, "Bridge_Girder", -66, 66, 136, 139, 283, 287, "safety", "Metal")
B.box(crane, "Trolley", -4, 4, 133, 136, 282, 288, "darkGray", "Metal")
B.cyl(crane, "Cable", 0, 285, 131.5, 133, 0.3, "black", "Metal", DECOR)
B.box(crane, "Hook_Block", -1.2, 1.2, 128.5, 131.5, 284, 286, "safety", "Metal", DECOR)

-- marcações de piso
local marks = B.group(Hangar.Floor, "Floor_Markings")
B.box(marks, "Line", -27, 27, 0, 0.05, 239.4, 240, "safety", "SmoothPlastic", FLOOR_MARK)
B.box(marks, "Line", -27, 27, 0, 0.05, 290, 290.6, "safety", "SmoothPlastic", FLOOR_MARK)
B.box(marks, "Line", -27.6, -27, 0, 0.05, 239.4, 290.6, "safety", "SmoothPlastic", FLOOR_MARK)
B.box(marks, "Line", 27, 27.6, 0, 0.05, 239.4, 290.6, "safety", "SmoothPlastic", FLOOR_MARK)
for _, x in { -12.6, 12 } do
	B.box(marks, "Walkway_Line", x, x + 0.6, 0, 0.05, 213.5, 239.4, "white", "SmoothPlastic", FLOOR_MARK)
end

-- faixa "SPACE LAUNCH SYSTEM" na parede dos fundos
panel(hs, -30, 30, 106, 122, 318.7, 318.9, N.Front, "SPACE LAUNCH SYSTEM", nil,
	{ bg = "darkGray", titleColor = "white", accent = "safety", ppu = 8 })

-- veículos de manutenção
local veh = Hangar.Maintenance_Vehicles
local function wheel(parent, x, y, z, d, w)
	B.part(parent, "Wheel", CFrame.new(x, y, z), Vector3.new(w or 0.8, d, d), "black", "SmoothPlastic", nil, "Cylinder")
end
do -- caminhão utilitário
	local t = B.group(veh, "Utility_Truck")
	B.box(t, "Chassis", -48, -42, 0.8, 1.6, 228, 242, "darkGray", "Metal")
	B.box(t, "Cab", -48, -42, 1.6, 6, 238, 242, "safety", "SmoothPlastic")
	B.box(t, "Windshield", -47.6, -42.4, 3.8, 5.6, 242, 242.1, "glass", "Glass", { transparency = 0.3, collide = false })
	B.box(t, "Cargo_Box", -48, -42, 1.6, 5.5, 228, 237.6, "metalGray", "Metal")
	for _, z in { 230.5, 239.5 } do
		wheel(t, -48.3, 1, z, 2)
		wheel(t, -41.7, 1, z, 2)
	end
end
do -- plataforma elevatória (tesoura)
	local s = B.group(veh, "Scissor_Lift")
	B.box(s, "Base", 42, 48, 0.6, 1.6, 282, 288, "safety", "Metal")
	for _, x in { 42.3, 47.7 } do
		for _, zz in { 282.6, 287.4 } do wheel(s, x, 0.6, zz, 1.2, 0.5) end
		B.beam(s, "Scissor", Vector3.new(x, 1.6, 282.4), Vector3.new(x, 10, 287.6), 0.3, 0.3, "darkGray", "Metal")
		B.beam(s, "Scissor", Vector3.new(x, 1.6, 287.6), Vector3.new(x, 10, 282.4), 0.3, 0.3, "darkGray", "Metal")
	end
	B.box(s, "Platform", 42, 48, 10, 10.5, 282, 288, "darkGray", "DiamondPlate")
	B.box(s, "Rail", 42, 48, 10.5, 11.6, 281.9, 282.1, "safety", "Metal")
	B.box(s, "Rail", 42, 48, 10.5, 11.6, 287.9, 288.1, "safety", "Metal")
	B.box(s, "Rail", 41.9, 42.1, 10.5, 11.6, 282, 288, "safety", "Metal")
	B.box(s, "Rail", 47.9, 48.1, 10.5, 11.6, 282, 288, "safety", "Metal")
end
do -- trator de reboque
	local t = B.group(veh, "Tow_Tractor")
	B.box(t, "Body", -53, -48, 0.8, 2.8, 292, 297, "white", "SmoothPlastic")
	B.box(t, "Stripe", -53.05, -47.95, 2.2, 2.5, 292, 297, "red", "SmoothPlastic", DECOR)
	for _, p in { { -52.8, 292.3 }, { -48.2, 292.3 }, { -52.8, 296.7 }, { -48.2, 296.7 } } do
		B.box(t, "Roof_Post", p[1] - 0.15, p[1] + 0.15, 2.8, 5.4, p[2] - 0.15, p[2] + 0.15, "darkGray", "Metal")
	end
	B.box(t, "Roof", -53.2, -47.8, 5.4, 5.7, 292, 297, "darkGray", "Metal")
	for _, z in { 293, 296 } do
		wheel(t, -53.3, 0.8, z, 1.6, 0.6)
		wheel(t, -47.7, 0.8, z, 1.6, 0.6)
	end
end
do -- caixas de equipamento
	local c = B.group(veh, "Equipment_Crates")
	B.box(c, "Crate", -60, -55, 0, 4, 300, 305, "rust", "WoodPlanks")
	B.box(c, "Crate", -60, -56, 4, 7, 300.5, 304.5, "metalGray", "Metal")
	B.box(c, "Crate", -54, -50, 0, 3, 302, 306, "darkGray", "Metal")
end

-- console da sala de observação + placa de acesso
local obs = Hangar.Observation_Room
local console = B.group(obs, "Console")
B.box(console, "Desk", 45.2, 47.2, 35, 37.4, 241, 259, "darkGray", "Metal")
for i, z in { 244.5, 250, 255.5 } do
	local scr = B.part(console, "Screen", CFrame.new(46.6, 38.6, z) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.2, 2, 4), "black", "SmoothPlastic", DECOR)
	local titles = { "SLS STATUS", "ORION", "HANGAR" }
	local bodies = { "Core stage  •  Boosters  •  Upper stage", "Crew module ready for inspection", "Vehicle assembly in progress" }
	B.sign(scr, titles[i], bodies[i], { face = N.Right, accent = "safety", titleColor = "safety", maxBody = 30 })
end
panel(obs, 61.85, 62, 1, 4.5, 300, 308, N.Left, "OBSERVATION DECK", "Stairs to the elevated viewing room",
	{ bg = "black", accent = "safety", titleColor = "safety", titleScale = 0.42 })

local count = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") then count += 1 end
end
return ("Fase 4 construída. Peças no Map: %d"):format(count)
