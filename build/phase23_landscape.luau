--[[
	NASA Space Adventure — Fase 23: paisagismo (árvores do lado de fora).

	Palmeiras sabal e carvalhos (vegetação típica da Flórida, onde fica o Kennedy Space Center)
	espalhados pela grama (Baseplate, Fase 1/16), em NASAComplex.Landscape.Trees.
	Posições sorteadas com semente fixa (mesmo resultado a cada reconstrução) e aceitas só quando:
	- o chão no ponto é grama (o primeiro toque de um raio vindo de cima é uma Baseplate):
	  fora de prédios, pisos, caminhos e estacionamentos;
	- a caixa da árvore (com folga) não encosta em nenhuma peça do mapa nem em outra árvore;
	- fica fora das zonas reservadas: complexo de lançamento e rota do crawler (validações do
	  CLAUDE.md), visão da área de observação para a plataforma 39B e eixo de chegada da recepção.
	Tronco com colisão (não se atravessa); copa sem colisão nem consulta (a câmera passa).
]]

local lib = ...
local B = lib.builder(23)
local Map = workspace:WaitForChild("NASAComplex")
B.clear(Map)

local Landscape = Map:FindFirstChild("Landscape") or B.group(Map, "Landscape", "Folder")
local Trees = B.group(Landscape, "Trees", "Folder")

local rng = Random.new(2323)
local TRUNK, TRUNK_DARK = "#7A6650", "#5E4B39"
local PALM_LEAF, PALM_LEAF2 = "#4F7F3A", "#3F6B30"
local OAK_LEAF, OAK_LEAF2 = "#3E6B34", "#4A7A3C"
local LEAF = { collide = false }

---------------------------------------------------------------------------------
-- Modelos
---------------------------------------------------------------------------------

-- Palmeira sabal: tronco levemente inclinado em 3 segmentos, coroa de folhas em leque
local function palm(pos, s, yaw)
	local m = B.group(Trees, "SabalPalm")
	local lean = CFrame.Angles(math.rad(rng:NextNumber(-6, 6)), yaw, math.rad(rng:NextNumber(-6, 6)))
	local h = 18 * s
	local base = CFrame.new(pos) * lean
	local p0 = pos
	for i = 1, 3 do
		local p1 = (base * CFrame.new(0, h * i / 3, 0)).Position
		B.cylBetween(m, "Trunk", p0, p1, (1.5 - i * 0.12) * s, i == 1 and TRUNK_DARK or TRUNK, "Wood")
		p0 = p1
	end
	local top = p0
	B.ball(m, "Crown", top, 2.2 * s, PALM_LEAF2, "Grass", LEAF)
	local n = 8
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local droop = math.rad(rng:NextNumber(15, 35))
		local len = rng:NextNumber(6.5, 8.5) * s
		-- folha: lâmina fina que sai da coroa e cai para fora
		local cf = CFrame.new(top) * CFrame.Angles(0, a, 0) * CFrame.Angles(-droop, 0, 0) * CFrame.new(0, 0, -len / 2)
		B.part(m, "Frond", cf, Vector3.new(2.4 * s, 0.25, len), i % 2 == 0 and PALM_LEAF or PALM_LEAF2, "Grass", LEAF)
	end
	m.PrimaryPart = m:FindFirstChild("Trunk")
	return m
end

-- Carvalho: tronco curto e copa larga de 4 esferas
local function oak(pos, s, yaw)
	local m = B.group(Trees, "LiveOak")
	local h = 7 * s
	B.cyl(m, "Trunk", pos.X, pos.Z, pos.Y, pos.Y + h + 2 * s, 2 * s, TRUNK_DARK, "Wood")
	local c = pos + Vector3.new(0, h + 4 * s, 0)
	local rot = CFrame.Angles(0, yaw, 0)
	B.ball(m, "Canopy", c, 11 * s, OAK_LEAF, "Grass", LEAF)
	for i, off in { Vector3.new(4, -1, 1), Vector3.new(-3.5, -0.5, 2.5), Vector3.new(0.5, 1.5, -3.5) } do
		B.ball(m, "Canopy", c + rot:VectorToWorldSpace(off * s), (7 + i) * s, i % 2 == 0 and OAK_LEAF2 or OAK_LEAF, "Grass", LEAF)
	end
	m.PrimaryPart = m:FindFirstChild("Trunk")
	return m
end

---------------------------------------------------------------------------------
-- Onde pode
---------------------------------------------------------------------------------

local grounds = {}
for _, n in { "Baseplate", "Baseplate_East", "Baseplate_South", "Baseplate_North" } do
	local g = workspace:FindFirstChild(n)
	if g then table.insert(grounds, g) end
end

-- zonas reservadas (X0, X1, Z0, Z1)
local RESERVED = {
	{ -100, 145, 300, 900 }, -- complexo de lançamento, crawlerway, estacionamento do crawler, 39B
	{ -160, 145, 600, 900 }, -- visão da área de observação para a plataforma
	{ -30, 30, -200, 0 }, -- eixo de chegada da recepção (spawn e entrada)
}
local function reserved(x, z)
	for _, r in RESERVED do
		if x >= r[1] and x <= r[2] and z >= r[3] and z <= r[4] then return true end
	end
	return false
end

local down = RaycastParams.new()
down.FilterType = Enum.RaycastFilterType.Exclude
down.FilterDescendantsInstances = { Trees }
local function onGrass(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -320, 0), down)
	return hit and table.find(grounds, hit.Instance) ~= nil and hit.Position.Y or nil
end

local clear = OverlapParams.new()
clear.FilterType = Enum.RaycastFilterType.Exclude
clear.FilterDescendantsInstances = grounds
clear.RespectCanCollide = false
local function free(x, y, z, r)
	-- caixa da árvore com folga (6 studs além da copa), de um pouco acima do chão até 32 de altura
	local size = Vector3.new(r * 2 + 12, 32, r * 2 + 12)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(x, y + 16.5, z), size, clear)
	return #parts == 0
end

---------------------------------------------------------------------------------
-- Sorteio
---------------------------------------------------------------------------------

local MAX_TREES = 70
local placed = {}
local tries = 0
local X0, X1, Z0, Z1 = -260, 430, -140, 760
while #placed < MAX_TREES and tries < 4000 do
	tries += 1
	local x, z = rng:NextNumber(X0, X1), rng:NextNumber(Z0, Z1)
	if not reserved(x, z) then
		local y = onGrass(x, z)
		local isPalm = rng:NextNumber() < 0.6
		local s = rng:NextNumber(0.85, 1.25)
		local r = (isPalm and 8 or 9) * s
		local near = false
		for _, p in placed do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(x, 0, z)).Magnitude < 16 then near = true break end
		end
		if y and not near and free(x, y, z, r) then
			local pos = Vector3.new(x, y, z)
			local yaw = rng:NextNumber(0, math.pi * 2)
			if isPalm then palm(pos, s, yaw) else oak(pos, s, yaw) end
			table.insert(placed, pos)
		end
	end
	if tries % 200 == 0 then task.wait() end
end

local parts = 0
for _, d in Trees:GetDescendants() do
	if d:IsA("BasePart") then parts += 1 end
end
return string.format("Fase 23: %d árvores (%d peças) em %d tentativas", #placed, parts, tries)
