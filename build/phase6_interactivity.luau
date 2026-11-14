--[[
	NASA Space Adventure — Fase 6: interatividade (spec §10)
	1. Portas automáticas de vidro na saída da recepção (spec §3.4 "Portas automáticas").
	   Script de servidor: ServerScriptService/Map_Systems/AutomaticDoors
	2. Rotação lenta dos planetas do Sistema Solar (só visual, no cliente).
	   LocalScript: StarterPlayer/StarterPlayerScripts/PlanetOrbits
	Um script por sistema — nenhum script individual por objeto (spec §11).
]]

local lib = ...
local B = lib.builder(6)
local Map = workspace:FindFirstChild("Map")
assert(Map, "Execute as Fases 1–5 antes")
B.clear(Map)

-- 1. Folhas da porta automática (abertura de 14 × 12 em Z = 55) --------------------------
local door = B.group(Map.NASA_Base.Walls, "Exit_AutoDoor")
door:SetAttribute("AutoDoor", true)
door:SetAttribute("SensorCenter", Vector3.new(0, 3, 55))
door:SetAttribute("SensorRadius", 13)
for _, side in { -1, 1 } do
	local leaf = B.group(door, side < 0 and "Leaf_L" or "Leaf_R")
	local x0, x1 = (side < 0) and -7 or 0, (side < 0) and 0 or 7
	local glass = B.box(leaf, "Glass", x0, x1, 0, 11.8, 54.85, 55.15, "glass", "Glass", { transparency = 0.45 })
	B.box(leaf, "Frame_Edge", side < 0 and -0.25 or 0, side < 0 and 0 or 0.25, 0, 11.8, 54.8, 55.2, "midGray", "Metal")
	B.box(leaf, "Handle_Strip", x0, x1, 5.6, 6, 54.78, 55.22, "nasaBlue", "SmoothPlastic", { collide = false })
	leaf.PrimaryPart = glass
	-- deslocamento de abertura: cada folha recolhe para dentro da parede
	leaf:SetAttribute("OpenOffset", Vector3.new(side * 6.8, 0, 0))
end

-- 2. Scripts --------------------------------------------------------------------------------
local SSS = game:GetService("ServerScriptService")
local systems = SSS:FindFirstChild("Map_Systems") or Instance.new("Folder", SSS)
systems.Name = "Map_Systems"
local sps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function putScript(class, parent, name, source)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local s = Instance.new(class)
	s.Name = name
	s.Source = source
	s.Parent = parent
	return s
end

putScript("Script", systems, "AutomaticDoors", [==[
-- Portas automáticas (NASA Space Adventure, Fase 6)
-- Abre qualquer Model com o atributo AutoDoor = true quando um jogador entra no raio do sensor.
-- Cada folha é um Model filho com o atributo OpenOffset (Vector3).
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local map = workspace:WaitForChild("Map")
local INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local doors = {}

local function register(model)
	if doors[model] or not model:IsA("Model") or not model:GetAttribute("AutoDoor") then return end
	local leaves = {}
	for _, leaf in model:GetChildren() do
		local offset = leaf:IsA("Model") and leaf:GetAttribute("OpenOffset")
		if offset then
			local closed = leaf:GetPivot()
			local value = Instance.new("CFrameValue")
			value.Value = closed
			value.Changed:Connect(function(cf) leaf:PivotTo(cf) end)
			table.insert(leaves, { value = value, closed = closed, open = closed + offset })
		end
	end
	doors[model] = {
		leaves = leaves,
		isOpen = false,
		center = model:GetAttribute("SensorCenter") or model:GetPivot().Position,
		radius = model:GetAttribute("SensorRadius") or 12,
	}
end

for _, d in map:GetDescendants() do register(d) end
map.DescendantAdded:Connect(function(d) task.defer(register, d) end)

while true do
	for model, door in doors do
		if not model.Parent then
			doors[model] = nil
			continue
		end
		local near = false
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - door.center).Magnitude <= door.radius then
				near = true
				break
			end
		end
		if near ~= door.isOpen then
			door.isOpen = near
			for _, leaf in door.leaves do
				TweenService:Create(leaf.value, INFO, { Value = near and leaf.open or leaf.closed }):Play()
			end
		end
	end
	task.wait(0.15)
end
]==])

putScript("LocalScript", sps, "PlanetOrbits", [==[
-- Rotação lenta dos planetas (NASA Space Adventure, Fase 6)
-- Efeito apenas visual no cliente. Lê os atributos OrbitRadius, OrbitAngle (graus),
-- OrbitSpeed (graus/s) e OrbitCenter de cada Model em Space_Adventure/Solar_System.
local RunService = game:GetService("RunService")

local solar = workspace:WaitForChild("Map"):WaitForChild("Space_Adventure"):WaitForChild("Solar_System")
local planets = {}

local function track(m)
	if m:IsA("Model") and m:GetAttribute("OrbitRadius") then planets[m] = true end
end
for _, c in solar:GetChildren() do track(c) end
solar.ChildAdded:Connect(track)
solar.ChildRemoved:Connect(function(c) planets[c] = nil end)

local start = os.clock()
RunService.RenderStepped:Connect(function()
	local t = os.clock() - start
	for m in planets do
		local body = m.PrimaryPart
		if body and m.Parent then
			local r = m:GetAttribute("OrbitRadius")
			local a = math.rad(m:GetAttribute("OrbitAngle") + m:GetAttribute("OrbitSpeed") * t)
			local c = m:GetAttribute("OrbitCenter")
			local target = Vector3.new(c.X + r * math.cos(a), c.Y, c.Z + r * math.sin(a))
			m:PivotTo(m:GetPivot() + (target - body.Position))
		end
	end
end)
]==])

return "Fase 6 aplicada: porta automática + scripts AutomaticDoors (servidor) e PlanetOrbits (cliente)"
