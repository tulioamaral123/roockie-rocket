--[[
	NASA Space Adventure — Fase 6: interatividade (spec §10)
	1. Portas automáticas de vidro na saída da recepção (spec §3.4 "Portas automáticas") e na
	   entrada da fachada (vão da Fase 2; o personagem passa por ela na cutscene de chegada).
	   Script de servidor: ServerScriptService/Map_Systems/AutomaticDoors
	2. Rotação lenta dos planetas do Sistema Solar (só visual, no cliente).
	   LocalScript: StarterPlayer/StarterPlayerScripts/PlanetOrbits
	Um script por sistema — nenhum script individual por objeto (spec §11).
]]

local lib = ...
local B = lib.builder(6)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–5 antes")
B.clear(Map)

-- 1. Folhas da porta automática (abertura de 14 × 12 em Z = 55) --------------------------
local door = B.group(Map.Reception.Walls, "Exit_AutoDoor")
door:SetAttribute("AutoDoor", true)
door:SetAttribute("SensorCenter", Vector3.new(0, 3, 55))
door:SetAttribute("SensorRadius", 13)
for _, side in { -1, 1 } do
	local leaf = B.group(door, side < 0 and "Leaf_L" or "Leaf_R")
	local x0, x1 = (side < 0) and -7 or 0, (side < 0) and 0 or 7
	local glass = B.box(leaf, "Glass", (side < 0) and x0 or 0.02, (side < 0) and -0.02 or x1, 0, 11.8, 54.85, 55.15, "glass", "Glass", { transparency = 0.45 })
	B.box(leaf, "Frame_Edge", side < 0 and -0.25 or 0, side < 0 and 0 or 0.25, 0, 11.82, 54.8, 55.2, "midGray", "Metal")
	B.box(leaf, "Handle_Strip", x0, x1, 5.6, 6, 54.78, 55.22, "nasaBlue", "SmoothPlastic", { collide = false })
	leaf.PrimaryPart = glass
	-- deslocamento de abertura: cada folha recolhe para dentro da parede
	leaf:SetAttribute("OpenOffset", Vector3.new(side * 6.8, 0, 0))
end

-- 1b. Porta de entrada na fachada de vidro (vão X −4..4, Y 0..10 em Z ≈ −0,5; Fase 2) ------------
local entrance = B.group(Map.Reception.Walls, "Entrance_AutoDoor")
entrance:SetAttribute("AutoDoor", true)
entrance:SetAttribute("SensorCenter", Vector3.new(0, 3, -0.5))
entrance:SetAttribute("SensorRadius", 11)
for _, side in { -1, 1 } do
	local leaf = B.group(entrance, side < 0 and "Leaf_L" or "Leaf_R")
	local x0, x1 = (side < 0) and -4 or 0.02, (side < 0) and -0.02 or 4
	local glass = B.box(leaf, "Glass", x0, x1, 0, 10, -0.65, -0.35, "glass", "Glass", { transparency = 0.45 })
	B.box(leaf, "Frame_Edge", side < 0 and -0.25 or 0, side < 0 and 0 or 0.25, 0, 10.02, -0.7, -0.3, "midGray", "Metal")
	B.box(leaf, "Handle_Strip", x0, x1, 4.6, 5, -0.72, -0.28, "nasaBlue", "SmoothPlastic", { collide = false })
	leaf.PrimaryPart = glass
	-- abre correndo para trás do vidro fixo ao lado
	leaf:SetAttribute("OpenOffset", Vector3.new(side * 3.9, 0, 0.6))
end

-- 2. Scripts: código em build/systems/ (sincronizado pelo Rojo ou baixado pelo HTTP) ------
lib.installSystemScript("server", "AutomaticDoors")
lib.installSystemScript("client", "PlanetOrbits")

return "Fase 6 aplicada: porta automática + scripts AutomaticDoors (servidor) e PlanetOrbits (cliente)"
