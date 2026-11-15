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

-- 2. Scripts: código em build/systems/ (sincronizado pelo Rojo ou baixado pelo HTTP) ------
lib.installSystemScript("server", "AutomaticDoors")
lib.installSystemScript("client", "PlanetOrbits")

return "Fase 6 aplicada: porta automática + scripts AutomaticDoors (servidor) e PlanetOrbits (cliente)"
