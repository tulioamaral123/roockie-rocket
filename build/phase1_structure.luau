--[[
	NASA Space Adventure — Fase 1: estrutura geral
	Executar no Command Bar do Roblox Studio (modo Edit). É idempotente:
	apaga e recria Workspace.Map a cada execução.

	Convenções (ver spec.md §2 e proposta de arquitetura):
	- Topo de todos os pisos em Y = 0 (laje de Y -1 a 0).
	- Dimensões da spec = medidas internas; paredes por fora.
	- Divisórias centradas nos planos de fronteira (Z = 55, 90, 170, 210).
	- Aberturas com a seção do corredor, centradas em X = 0.
]]

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")

local C = {
	white = "#FFFFFF", lightGray = "#E7E9EA", midGray = "#AAB3BB", nasaBlue = "#244B70",
	space = "#080D20", darkBlue = "#101D3D", deepBlue = "#153D72",
	darkGray = "#555B60", metalGray = "#8A9298", paleGray = "#D5D7D8", safety = "#E5B52E",
}

local function folder(parent, name, class)
	local f = Instance.new(class or "Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Cria uma Part a partir dos limites mínimos/máximos (x0..x1, y0..y1, z0..z1)
local function box(parent, name, x0, x1, y0, y1, z0, z1, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Color = Color3.fromHex(color)
	p.Material = Enum.Material[material]
	p.Parent = parent
	return p
end

-- Parede transversal (plano XY) com abertura retangular a partir do piso
local function wallWithOpening(parent, name, z0, z1, x0, x1, top, ox0, ox1, otop, color, material)
	box(parent, name .. "_L", x0, ox0, -1, top, z0, z1, color, material)
	box(parent, name .. "_R", ox1, x1, -1, top, z0, z1, color, material)
	box(parent, name .. "_Lintel", ox0, ox1, otop, top, z0, z1, color, material)
end

-- Limpeza ----------------------------------------------------------------
local old = workspace:FindFirstChild("Map")
if old then old:Destroy() end
local defaultSpawn = workspace:FindFirstChild("SpawnLocation")
if defaultSpawn then defaultSpawn:Destroy() end
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	-- Topo do baseplate em Y = -1, para não coincidir com os pisos (Y = 0)
	baseplate.Position = Vector3.new(0, -1 - baseplate.Size.Y / 2, 0)
end

-- Hierarquia (spec §9) -----------------------------------------------------
local Map = folder(workspace, "Map", "Model")

local Base = folder(Map, "NASA_Base", "Model")
for _, n in { "Floor", "Walls", "Reception", "Furniture" } do folder(Base, n) end

local C1 = folder(Map, "Corridor_01", "Model")
for _, n in { "Floor", "Walls", "Doors", "Decorations" } do folder(C1, n) end

local Museum = folder(Map, "Space_Adventure", "Model")
for _, n in { "Floor", "Walls", "Dome", "Solar_System", "Astronaut_Exhibition", "Rocket_Exhibition",
	"Mars_Exhibition", "Science_Exhibition", "Screens" } do folder(Museum, n) end

local C2 = folder(Map, "Corridor_02", "Model")
for _, n in { "Floor", "Industrial_Structure", "Pipes", "Doors", "Windows" } do folder(C2, n) end

local Hangar = folder(Map, "Rocket_Hangar", "Model")
for _, n in { "Floor", "Structure", "Gates", "SLS_Rocket", "Launch_Platform", "Gantry",
	"Maintenance_Vehicles", "Observation_Room" } do folder(Hangar, n) end

for _, n in { "Lighting_Objects", "Atmosphere_Objects" } do
	local f = workspace:FindFirstChild(n) or folder(workspace, n)
	if n == "Lighting_Objects" then
		for _, s in { "Base", "Corridor_01", "Museum", "Corridor_02", "Hangar" } do
			if not f:FindFirstChild(s) then folder(f, s) end
		end
	end
end
if not RS:FindFirstChild("Assets") then folder(RS, "Assets") end
if not SSS:FindFirstChild("Map_Systems") then folder(SSS, "Map_Systems") end

-- 1. Base NASA: 70 × 55 × 24 (X -35..35, Z 0..55) -------------------------
box(Base.Floor, "Floor", -35, 35, -1, 0, 0, 55, C.lightGray, "Concrete")
box(Base.Walls, "Front_Wall", -36, 36, -1, 25, -1, 0, C.white, "SmoothPlastic")
box(Base.Walls, "Left_Wall", -36, -35, -1, 25, 0, 54.5, C.white, "SmoothPlastic")
box(Base.Walls, "Right_Wall", 35, 36, -1, 25, 0, 54.5, C.white, "SmoothPlastic")
wallWithOpening(Base.Walls, "Back_Wall", 54.5, 55.5, -36, 36, 25, -7, 7, 12, C.white, "SmoothPlastic")
box(Base.Walls, "Ceiling", -35, 35, 24, 25, 0, 54.5, C.white, "SmoothPlastic")

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Anchored = true
spawn.Size = Vector3.new(6, 0.2, 6)
spawn.CFrame = CFrame.new(0, 0.1, 12) -- personagem aparece em ~(0, 3, 12)
spawn.Color = Color3.fromHex(C.nasaBlue)
spawn.Material = Enum.Material.SmoothPlastic
spawn.TopSurface = Enum.SurfaceType.Smooth
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = Base

-- 2. Corredor 1: 14 × 35 × 12 (X -7..7, Z 55..90) ---------------------------
box(C1.Floor, "Floor", -7, 7, -1, 0, 55, 90, C.lightGray, "Concrete")
box(C1.Walls, "Left_Wall", -8, -7, -1, 13, 55.5, 89.5, C.white, "SmoothPlastic")
box(C1.Walls, "Right_Wall", 7, 8, -1, 13, 55.5, 89.5, C.white, "SmoothPlastic")
box(C1.Walls, "Ceiling", -7, 7, 12, 13, 55.5, 89.5, C.white, "SmoothPlastic")

-- 3. Museu: 90 × 80 (X -45..45, Z 90..170); salão até Y 18, cúpula até 42 (Fase 2)
box(Museum.Floor, "Floor", -45, 45, -1, 0, 90, 170, C.darkBlue, "Concrete")
wallWithOpening(Museum.Walls, "Front_Wall", 89.5, 90.5, -46, 46, 19, -7, 7, 12, C.darkBlue, "SmoothPlastic")
wallWithOpening(Museum.Walls, "Back_Wall", 169.5, 170.5, -46, 46, 19, -8, 8, 14, C.darkBlue, "SmoothPlastic")
box(Museum.Walls, "Left_Wall", -46, -45, -1, 19, 90.5, 169.5, C.darkBlue, "SmoothPlastic")
box(Museum.Walls, "Right_Wall", 45, 46, -1, 19, 90.5, 169.5, C.darkBlue, "SmoothPlastic")
-- Teto perimetral com vão quadrado de 68 × 68 para a cúpula (anel/cúpula na Fase 2)
box(Museum.Walls, "Roof_Front", -45, 45, 18, 19, 90.5, 96, C.space, "SmoothPlastic")
box(Museum.Walls, "Roof_Back", -45, 45, 18, 19, 164, 169.5, C.space, "SmoothPlastic")
box(Museum.Walls, "Roof_Left", -45, -34, 18, 19, 96, 164, C.space, "SmoothPlastic")
box(Museum.Walls, "Roof_Right", 34, 45, 18, 19, 96, 164, C.space, "SmoothPlastic")

-- 4. Corredor 2: 16 × 40 × 14 (X -8..8, Z 170..210) -------------------------
box(C2.Floor, "Floor", -8, 8, -1, 0, 170, 209, C.darkGray, "DiamondPlate")
box(C2.Industrial_Structure, "Left_Wall", -9, -8, -1, 15, 170.5, 208, C.metalGray, "Concrete")
box(C2.Industrial_Structure, "Right_Wall", 8, 9, -1, 15, 170.5, 208, C.metalGray, "Concrete")
box(C2.Industrial_Structure, "Ceiling", -8, 8, 14, 15, 170.5, 208, C.darkGray, "Metal")
-- Pórtico: o corredor 16 × 14 desemboca no vão 24 × 30 do hangar
wallWithOpening(C2.Industrial_Structure, "Hangar_Portal", 208, 209, -12, 12, 30, -8, 8, 14, C.darkGray, "Metal")
box(C2.Floor, "Gate_Threshold", -12, 12, -1, 0, 209, 210, C.safety, "DiamondPlate")

-- 5. Hangar SLS: 140 × 110 × 150 (X -70..70, Z 210..320) --------------------
box(Hangar.Floor, "Floor", -70, 70, -1, 0, 210, 320, C.metalGray, "Concrete")
wallWithOpening(Hangar.Structure, "Front_Wall", 209, 211, -72, 72, 152, -12, 12, 30, C.metalGray, "Metal")
box(Hangar.Structure, "Back_Wall", -72, 72, -1, 152, 319, 321, C.metalGray, "Metal")
box(Hangar.Structure, "Left_Wall", -72, -70, -1, 152, 211, 319, C.metalGray, "Metal")
box(Hangar.Structure, "Right_Wall", 70, 72, -1, 152, 211, 319, C.metalGray, "Metal")
box(Hangar.Structure, "Roof", -70, 70, 150, 152, 211, 319, C.darkGray, "Metal")

-- Workspace / Lighting (base; iluminação final na Fase 5) -------------------
workspace.StreamingEnabled = true
-- Lighting.Technology não é gravável por script: ajustar para "Future" manualmente
-- em Lighting > Technology no painel Properties.
Lighting.Ambient = Color3.fromRGB(70, 72, 80)

local count = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") then count += 1 end
end
return ("Fase 1 construída: %d peças em Workspace.Map"):format(count)
