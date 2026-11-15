--[[
	NASA Space Adventure — Fase 24: ambientação externa (docs/paisagismo-spec.md).

	Em NASAComplex.Landscape (pasta compartilhada com a Fase 23, sem BuildPhase):
	- EntranceLandscape: estrada de acesso (Z ≈ −110), praça diante da entrada da recepção
	  (que fica voltada para −Z), calçada até a estrada, faixa de pedestres, ponto de desembarque,
	  bancos, postes e canteiros; placas em inglês.
	- Parking: estacionamento de visitantes a oeste da praça (2 fileiras, vagas acessíveis junto
	  ao caminho), alguns carros decorativos fora das vagas acessíveis.
	- MuseumGardens: canteiros ao sul do planetário, deixando livre a porta em X ≈ 60.
	- Lake: lago decorativo a oeste (água opaca em discos, areia, borda de pedras com colisão:
	  não se entra na água), mirante de madeira ligado ao estacionamento por um caminho.
	- OuterVegetation: tufos de arbustos baixos na grama (sem colisão).
	- Nuvens nativas (Terrain.Clouds) leves e espaçadas.
	As áreas usadas aqui estão reservadas na Fase 23 (não recebem árvores sorteadas).
	Superfícies finas sobre a grama (topo da grama em Y −1): estrada/estacionamento −0,8,
	calçadas/praça −0,75, areia −0,9, água −0,85 (sem z-fighting nem degraus altos).
]]

local lib = ...
local B = lib.builder(24)
local Map = workspace:WaitForChild("NASAComplex")
B.clear(Map)

local Landscape = Map:FindFirstChild("Landscape")
if not Landscape then
	Landscape = Instance.new("Folder")
	Landscape.Name = "Landscape"
	Landscape.Parent = Map
end
local Entrance = B.group(Landscape, "EntranceLandscape", "Folder")
local Parking = B.group(Landscape, "Parking", "Folder")
local Gardens = B.group(Landscape, "MuseumGardens", "Folder")
local Lake = B.group(Landscape, "Lake", "Folder")
local Outer = B.group(Landscape, "OuterVegetation", "Folder")

local rng = Random.new(2424)
local ASPHALT, CONCRETE, PAINT, YELLOW = "#3B3E43", "#C9C5BC", "#F2F2EE", "#E8C547"
local CURB, SOIL, WOOD = "#B7B2A8", "#5A4632", "#8A6A48"
local SHRUB, SHRUB2, SHRUB3 = "#4B7A3A", "#3F6B32", "#5E8C45"
local FLOWERS = { "#E8C547", "#D9534F", "#F2F2EE", "#B784D9", "#F08A3C" }
local DECOR = { collide = false }

local ROAD_TOP, PATH_TOP = -0.8, -0.75

-- laje fina com o topo em top
local function slab(parent, name, x0, x1, z0, z1, top, color, material, o)
	return B.box(parent, name, x0, x1, top - 0.2, top, z0, z1, color, material, o)
end
-- marca de pintura (sem colisão)
local function paint(parent, x0, x1, z0, z1, top, color)
	return B.box(parent, "Marking", x0, x1, top, top + 0.03, z0, z1, color, "SmoothPlastic", DECOR)
end
-- faixa de chão entre dois pontos (caminho em diagonal)
local function strip(parent, name, p0, p1, width, top, color, material)
	local a, b = Vector3.new(p0.X, top - 0.1, p0.Z), Vector3.new(p1.X, top - 0.1, p1.Z)
	return B.part(parent, name, CFrame.lookAt((a + b) / 2, b), Vector3.new(width, 0.2, (b - a).Magnitude), color, material)
end

local function lamp(parent, x, z, top)
	B.cyl(parent, "LampPost", x, z, top, top + 12, 0.45, "darkGray", "Metal")
	local head = B.box(parent, "LampHead", x - 0.8, x + 0.8, top + 12, top + 12.6, z - 0.8, z + 0.8, "#F4EBD0", "Neon", { shadow = false })
	B.light(head, "PointLight", { Range = 20, Brightness = 1.1, Color = Color3.fromHex("FFE2B0"), Shadows = false })
end

local function bench(parent, x, z, yaw, top)
	local cf = CFrame.new(x, top, z) * CFrame.Angles(0, yaw, 0)
	B.part(parent, "BenchSeat", cf * CFrame.new(0, 1.8, 0), Vector3.new(6, 0.4, 1.8), WOOD, "Wood")
	B.part(parent, "BenchBack", cf * CFrame.new(0, 2.9, 0.8) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(6, 1.6, 0.3), WOOD, "Wood")
	for _, dx in { -2.5, 2.5 } do
		B.part(parent, "BenchLeg", cf * CFrame.new(dx, 0.8, 0), Vector3.new(0.4, 1.6, 1.6), "darkGray", "Metal")
	end
end

local function shrubClump(parent, x, z, s, ground)
	local y = ground or -1
	local n = rng:NextInteger(2, 3)
	for i = 1, n do
		local d = rng:NextNumber(2.2, 3.6) * s
		local off = Vector3.new(rng:NextNumber(-1.6, 1.6) * s, 0, rng:NextNumber(-1.6, 1.6) * s)
		local colors = { SHRUB, SHRUB2, SHRUB3 }
		B.ball(parent, "Shrub", Vector3.new(x, y + d * 0.35, z) + off, d, colors[(i % 3) + 1], "Grass", DECOR)
	end
end

local function planter(parent, cx, cz, w, d, top)
	top = top or -1
	local h = 0.9
	local x0, x1, z0, z1 = cx - w / 2, cx + w / 2, cz - d / 2, cz + d / 2
	-- borda de concreto (4 lados) com colisão; terra e plantas por dentro sem colisão
	B.box(parent, "PlanterCurb", x0, x1, top, top + h, z0, z0 + 0.6, CURB, "Concrete")
	B.box(parent, "PlanterCurb", x0, x1, top, top + h, z1 - 0.6, z1, CURB, "Concrete")
	B.box(parent, "PlanterCurb", x0, x0 + 0.6, top, top + h, z0 + 0.6, z1 - 0.6, CURB, "Concrete")
	B.box(parent, "PlanterCurb", x1 - 0.6, x1, top, top + h, z0 + 0.6, z1 - 0.6, CURB, "Concrete")
	B.box(parent, "PlanterSoil", x0 + 0.6, x1 - 0.6, top, top + h - 0.15, z0 + 0.6, z1 - 0.6, SOIL, "Ground", DECOR)
	local count = math.max(2, math.floor(w * d / 30))
	for _ = 1, count do
		local px, pz = rng:NextNumber(x0 + 1.6, x1 - 1.6), rng:NextNumber(z0 + 1.6, z1 - 1.6)
		if rng:NextNumber() < 0.55 then
			B.ball(parent, "Shrub", Vector3.new(px, top + h + 0.6, pz), rng:NextNumber(1.8, 2.6), SHRUB, "Grass", DECOR)
		else
			B.ball(parent, "Flowers", Vector3.new(px, top + h + 0.25, pz), rng:NextNumber(0.9, 1.3), FLOWERS[rng:NextInteger(1, #FLOWERS)], "SmoothPlastic", DECOR)
		end
	end
end

local function signPost(parent, x, z, yaw, text, top, w)
	w = w or 10
	local cf = CFrame.new(x, top, z) * CFrame.Angles(0, yaw, 0)
	for _, dx in { -w / 2 + 0.5, w / 2 - 0.5 } do
		B.part(parent, "SignPost", cf * CFrame.new(dx, 2, 0), Vector3.new(0.4, 4, 0.4), "darkGray", "Metal")
	end
	local board = B.part(parent, "SignBoard", cf * CFrame.new(0, 4.6, 0), Vector3.new(w, 2.2, 0.3), "nasaBlue", "SmoothPlastic")
	B.sign(board, text, nil, { bg = "nasaBlue", titleColor = "white" })
	B.sign(board, text, nil, { bg = "nasaBlue", titleColor = "white", face = Enum.NormalId.Back })
	return board
end

---------------------------------------------------------------------------------
-- 1. Estrada de acesso, praça, calçadas e desembarque (EntranceLandscape)
---------------------------------------------------------------------------------
local ROAD_Z0, ROAD_Z1 = -121, -99
slab(Entrance, "AccessRoad", -500, 500, ROAD_Z0, ROAD_Z1, ROAD_TOP, ASPHALT, "Asphalt")
paint(Entrance, -500, 500, ROAD_Z0 + 0.6, ROAD_Z0 + 1, ROAD_TOP, PAINT)
paint(Entrance, -500, 500, ROAD_Z1 - 1, ROAD_Z1 - 0.6, ROAD_TOP, PAINT)
for x = -496, 496, 16 do
	if math.abs(x) > 8 then -- sem tracejado sobre a faixa de pedestres
		paint(Entrance, x, x + 8, -110.3, -109.7, ROAD_TOP, YELLOW)
	end
end
-- faixa de pedestres (zebra) em X −5..5
for z = ROAD_Z0 + 1.5, ROAD_Z1 - 2.5, 2.5 do
	paint(Entrance, -5, 5, z, z + 1.3, ROAD_TOP, PAINT)
end
-- praça diante da entrada e calçada até a estrada
slab(Entrance, "EntrancePlaza", -24, 24, -44, -6, PATH_TOP, CONCRETE, "Concrete")
slab(Entrance, "Sidewalk", -5, 5, ROAD_Z1, -44, PATH_TOP, CONCRETE, "Concrete")
-- desembarque do outro lado da estrada
slab(Entrance, "DropOff", -24, 24, -137, ROAD_Z0, PATH_TOP, CONCRETE, "Concrete")
bench(Entrance, -14, -133, 0, PATH_TOP)
bench(Entrance, 14, -133, 0, PATH_TOP)
signPost(Entrance, 0, -135.5, 0, "VISITOR DROP-OFF", PATH_TOP, 12)
-- bancos e canteiros na praça (laterais, longe da porta)
bench(Entrance, -20.5, -26, math.rad(-90), PATH_TOP)
bench(Entrance, 20.5, -26, math.rad(90), PATH_TOP)
planter(Entrance, -16, -38, 10, 6, PATH_TOP)
planter(Entrance, 16, -38, 10, 6, PATH_TOP)
planter(Entrance, -32, -18, 8, 20, -1)
planter(Entrance, 32, -18, 8, 20, -1)
signPost(Entrance, 0, -48, 0, "VISITOR ENTRANCE", PATH_TOP, 12)
for _, p in { { -22, -8 }, { 22, -8 }, { -22, -42 }, { 22, -42 }, { -7, -70 }, { 7, -95 }, { -26, -128 }, { 26, -128 } } do
	lamp(Entrance, p[1], p[2], PATH_TOP)
end

---------------------------------------------------------------------------------
-- 2. Estacionamento de visitantes (Parking)
---------------------------------------------------------------------------------
local LX0, LX1, LZ0, LZ1 = -160, -40, -97, -28
slab(Parking, "ParkingLot", LX0, LX1, LZ0, LZ1, ROAD_TOP, ASPHALT, "Asphalt")
slab(Parking, "Driveway", -112, -92, ROAD_Z1, LZ0, ROAD_TOP, ASPHALT, "Asphalt")
-- calçada do estacionamento até a praça (o lado das vagas acessíveis)
slab(Parking, "ParkingWalk", LX1, -24, -50, -40, PATH_TOP, CONCRETE, "Concrete")
-- vagas: fileira sul (Z −97..−81) e norte (Z −44..−28), 9 de largura, separadas por linhas
local SPOT_W = 9
local spots = {}
for i = 0, 12 do
	local x = LX0 + 2 + i * SPOT_W
	if x <= LX1 - 2 then
		paint(Parking, x - 0.15, x + 0.15, -97, -81, ROAD_TOP, PAINT)
		paint(Parking, x - 0.15, x + 0.15, -44, -28, ROAD_TOP, PAINT)
		if x + SPOT_W <= LX1 - 2 then
			table.insert(spots, { x = x + SPOT_W / 2, z = -89, row = "S" })
			table.insert(spots, { x = x + SPOT_W / 2, z = -36, row = "N" })
		end
	end
end
-- vagas acessíveis: as duas da fileira norte mais perto da calçada (leste)
table.sort(spots, function(a, b) return a.x > b.x end)
local accessible = {}
local nAcc = 0
for _, s in spots do
	if s.row == "N" and nAcc < 2 then
		nAcc += 1
		accessible[s] = true
		paint(Parking, s.x - SPOT_W / 2 + 0.4, s.x + SPOT_W / 2 - 0.4, -43.5, -28.5, ROAD_TOP + 0.005, "#2F6DB5")
		-- símbolo simples: círculo branco (cabeça) e barra (cadeira) no centro da vaga
		B.part(Parking, "Marking", CFrame.new(s.x, ROAD_TOP + 0.05, -36) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.05, 3.2, 3.2), PAINT, "SmoothPlastic", DECOR, "Cylinder")
	end
end
signPost(Parking, LX1 - SPOT_W, -26, 0, "ACCESSIBLE PARKING", ROAD_TOP, 9)
signPost(Parking, -102, -96.5, 0, "VISITOR PARKING", ROAD_TOP, 11)
for _, p in { { -150, -62 }, { -100, -62 }, { -50, -62 } } do
	lamp(Parking, p[1], p[2], ROAD_TOP)
end
-- carros decorativos (fora das vagas acessíveis)
local CAR_COLORS = { "#C0392B", "#2C3E50", "#ECF0F1", "#7F8C8D", "#2471A3", "#D4AC0D" }
local free = {}
for _, s in spots do
	if not accessible[s] then table.insert(free, s) end
end
for i = 1, 6 do
	local s = table.remove(free, rng:NextInteger(1, #free))
	local nose = s.row == "S" and 1 or -1
	local cf = CFrame.new(s.x, ROAD_TOP, s.z) * CFrame.Angles(0, nose > 0 and 0 or math.pi, 0)
	local car = B.group(Parking, "Car")
	B.part(car, "Body", cf * CFrame.new(0, 1.3, 0), Vector3.new(5.2, 1.6, 10), CAR_COLORS[i], "SmoothPlastic")
	B.part(car, "Cabin", cf * CFrame.new(0, 2.7, 0.6), Vector3.new(4.6, 1.3, 5.2), "#1E2A33", "Glass")
	for _, w in { { -2.4, -3.2 }, { 2.4, -3.2 }, { -2.4, 3.2 }, { 2.4, 3.2 } } do
		B.part(car, "Wheel", cf * CFrame.new(w[1], 0.75, w[2]), Vector3.new(0.7, 1.6, 1.6), "black", "SmoothPlastic", nil, "Cylinder")
	end
end

---------------------------------------------------------------------------------
-- 3. Jardins do planetário (MuseumGardens): ao sul da fachada, porta em X ≈ 60 livre
---------------------------------------------------------------------------------
for _, g in { { 80, -22, 16 }, { 102, -22, 16 }, { 124, -22, 14 } } do
	planter(Gardens, g[1], g[2], g[3], 6, -1)
end
for _, x in { 70, 91, 113 } do
	shrubClump(Gardens, x, -30, 1)
end

---------------------------------------------------------------------------------
-- 4. Lago a oeste (Lake): água decorativa, areia, pedras na margem, mirante
---------------------------------------------------------------------------------
local LC = Vector3.new(-232, 0, 15)
local DISCS = { { 0, 0, 30 }, { 22, 10, 20 }, { -20, -12, 22 }, { 8, -22, 18 }, { -10, 24, 18 } }
local function disc(name, cx, cz, r, top, color, material, o)
	local t = 0.1
	return B.part(Lake, name, CFrame.new(cx, top - t / 2, cz) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(t, r * 2, r * 2), color, material, o, "Cylinder")
end
for _, d in DISCS do
	disc("Sand", LC.X + d[1], LC.Z + d[2], d[3] + 5, -0.9, "#CDBB8A", "Sand")
end
for _, d in DISCS do
	local w = disc("Water", LC.X + d[1], LC.Z + d[2], d[3], -0.85, "#2F6E8E", "SmoothPlastic")
	w.Reflectance = 0.15
end
-- mirante: deck de madeira entrando no lago pelo leste (Z 21..29), com guarda-corpo
local DECK_Z0, DECK_Z1, DECK_X0, DECK_X1 = 21, 29, -206, -183
slab(Lake, "OverlookDeck", DECK_X0, DECK_X1, DECK_Z0, DECK_Z1, -0.5, WOOD, "WoodPlanks")
for _, z in { DECK_Z0 + 0.2, DECK_Z1 - 0.2 } do
	B.box(Lake, "DeckRail", DECK_X0, DECK_X1 - 4, 2.2, 2.6, z - 0.15, z + 0.15, WOOD, "Wood")
	for x = DECK_X0 + 0.5, DECK_X1 - 4, 4 do
		B.box(Lake, "DeckPost", x - 0.2, x + 0.2, -0.5, 2.6, z - 0.2, z + 0.2, WOOD, "Wood")
	end
end
B.box(Lake, "DeckRail", DECK_X0, DECK_X0 + 0.3, 2.2, 2.6, DECK_Z0, DECK_Z1, WOOD, "Wood")
-- laterais e ponta fechadas por colisores invisíveis (12 de altura, até a ponta em terra): não se passa nem se pula para a água
for _, z in { DECK_Z0, DECK_Z1 - 0.3 } do
	B.box(Lake, "DeckBarrier", DECK_X0, DECK_X1, -0.5, 12, z, z + 0.3, WOOD, "Wood", { transparency = 1 })
end
B.box(Lake, "DeckRailLow", DECK_X0, DECK_X0 + 0.3, -0.5, 12, DECK_Z0, DECK_Z1, WOOD, "Wood", { transparency = 1 })
signPost(Lake, DECK_X1 + 3, DECK_Z1 + 3, math.rad(90), "LAKE OVERLOOK", -1, 9)
bench(Lake, DECK_X1 + 5, DECK_Z0 - 4, math.rad(90), -1)
-- caminho do estacionamento (canto oeste) até o mirante
strip(Lake, "LakePath", Vector3.new(-160, 0, -45), Vector3.new(DECK_X1 + 1, 0, (DECK_Z0 + DECK_Z1) / 2), 6, PATH_TOP, CONCRETE, "Concrete")
-- pedras na margem (com colisão: ninguém entra na água), menos onde o deck encosta
local function insideOther(px, pz, skip)
	for j, d in DISCS do
		if j ~= skip and (Vector2.new(px, pz) - Vector2.new(LC.X + d[1], LC.Z + d[2])).Magnitude < d[3] + 1.5 then return true end
	end
	return false
end
local ROCK = { "#8C8B86", "#76756F", "#9E9A90" }
for j, d in DISCS do
	local r = d[3] + 1.6
	local n = math.ceil(2 * math.pi * r / 3.4)
	for k = 1, n do
		local a = (k / n) * math.pi * 2
		local px, pz = LC.X + d[1] + math.cos(a) * r, LC.Z + d[2] + math.sin(a) * r
		local nearDeck = pz > DECK_Z0 - 3 and pz < DECK_Z1 + 3 and px > DECK_X0 - 2
		local onDeck = pz > DECK_Z0 - 0.6 and pz < DECK_Z1 + 0.6 and px > DECK_X0 - 2
		if not insideOther(px, pz, j) and not nearDeck then
			local size = rng:NextNumber(3.4, 4.6)
			B.ball(Lake, "ShoreRock", Vector3.new(px, -1 + size * 0.28, pz), size, ROCK[rng:NextInteger(1, 3)], "Slate")
		elseif not insideOther(px, pz, j) and not onDeck then
			-- junto às laterais do deck: pedra fixa (sem sorteio), fecha a margem até a madeira
			B.ball(Lake, "ShoreRock", Vector3.new(px, -1 + 4 * 0.28, pz), 4, ROCK[1], "Slate")
		end
		-- as pedras são baixas (dá para subir nelas): barreira invisível de 14 de altura na margem
		-- (mais alta que um pulo dado de cima da pedra)
		if not insideOther(px, pz, j) and not onDeck then
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
			local at = Vector3.new(px, 6, pz)
			B.part(Lake, "ShoreBarrier", CFrame.lookAt(at, at + tangent), Vector3.new(0.6, 14, 2 * math.pi * r / n + 0.6), ROCK[1], "SmoothPlastic", { transparency = 1, shadow = false })
		end
	end
end
-- juncos e arbustos na margem (sem colisão)
for k = 1, 22 do
	local d = DISCS[rng:NextInteger(1, #DISCS)]
	local a = rng:NextNumber(0, math.pi * 2)
	local r = d[3] + rng:NextNumber(3.5, 6)
	local px, pz = LC.X + d[1] + math.cos(a) * r, LC.Z + d[2] + math.sin(a) * r
	if not insideOther(px, pz, nil) and not (pz > DECK_Z0 - 4 and pz < DECK_Z1 + 4 and px > DECK_X0 - 2) then
		if k % 2 == 0 then
			shrubClump(Lake, px, pz, 0.8)
		else
			for _ = 1, 3 do
				local h = rng:NextNumber(2.5, 4)
				B.part(Lake, "Reed", CFrame.new(px + rng:NextNumber(-0.8, 0.8), -1 + h / 2, pz + rng:NextNumber(-0.8, 0.8)) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-8, 8))), Vector3.new(0.25, h, 0.25), "#6E7F3A", "Grass", DECOR)
			end
		end
	end
end

---------------------------------------------------------------------------------
-- 5. Vegetação baixa nas bordas (OuterVegetation): tufos de arbustos na grama livre
---------------------------------------------------------------------------------
local grounds = {}
for _, n in { "Baseplate", "Baseplate_East", "Baseplate_South", "Baseplate_North" } do
	local g = workspace:FindFirstChild(n)
	if g then table.insert(grounds, g) end
end
local RESERVED = {
	{ -100, 145, 300, 900 }, -- complexo de lançamento e rota do crawler
	{ -160, 145, 600, 900 }, -- visão da área de observação
	{ -520, 520, -140, -20 }, -- estrada, estacionamento, praça, desembarque
	{ -300, -160, -56, 86 }, -- lago
	{ -200, -130, -80, 40 }, -- caminho do lago
}
local down = RaycastParams.new()
down.FilterType = Enum.RaycastFilterType.Exclude
down.FilterDescendantsInstances = { Outer }
local clear = OverlapParams.new()
clear.FilterType = Enum.RaycastFilterType.Exclude
clear.FilterDescendantsInstances = grounds
clear.RespectCanCollide = false
local placed, tries = 0, 0
while placed < 40 and tries < 2000 do
	tries += 1
	local x, z = rng:NextNumber(-300, 430), rng:NextNumber(-180, 600)
	local ok = true
	for _, r in RESERVED do
		if x >= r[1] and x <= r[2] and z >= r[3] and z <= r[4] then ok = false break end
	end
	if ok then
		local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -320, 0), down)
		if hit and table.find(grounds, hit.Instance)
			and #workspace:GetPartBoundsInBox(CFrame.new(x, 2, z), Vector3.new(12, 6, 12), clear) == 0 then
			shrubClump(Outer, x, z, rng:NextNumber(0.8, 1.2))
			placed += 1
		end
	end
end

---------------------------------------------------------------------------------
-- 6. Nuvens nativas, leves e espaçadas (a iluminação de dia da Fase 5 continua igual)
---------------------------------------------------------------------------------
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover = 0.5
clouds.Density = 0.3
clouds.Color = Color3.fromRGB(255, 255, 255)
clouds.Enabled = true
clouds.Parent = workspace.Terrain

local parts = 0
for _, f in { Entrance, Parking, Gardens, Lake, Outer } do
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") then parts += 1 end
	end
end
return string.format("Fase 24: entrada, estacionamento (%d vagas, %d acessíveis), jardins, lago e %d arbustos; %d peças", #spots, nAcc, placed, parts)
