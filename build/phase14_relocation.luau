--[[
	NASA Space Adventure — Fase 14: museu ao leste da recepção e ligações do LCC

	O museu (planetário, Fases 1–6) saiu do caminho principal: o Launch Control Center ocupa
	agora o lugar dele, entre o Corredor 1 e o Corredor 2 (Fase 12). Esta fase:

	1. Move o museu inteiro por uma transformação rígida (giro de 90° + translação): o salão
	   vai de X −45..45, Z 90..170 para X 50..130, Z −17,5..72,5, com a entrada (antes voltada
	   para o Corredor 1) voltada para a recepção. Movidos: NASAComplex.CapeCanaveralMuseum,
	   Lighting_Objects.Museum e a placa da entrada (Corridor_01.Decorations.Museum_Sign).
	   Os planetas guardam OrbitCenter (absoluto) e OrbitAngle (graus): o centro é transformado
	   e o ângulo perde 90°, para o script PlanetOrbits continuar certo.
	2. Fecha a abertura dos fundos do museu (que dava para o Corredor 2).
	3. Abre a parede leste da recepção (X 35..36, vão Z 20,5..34,5, 12 de altura) e cria o
	   corredor do museu (X 36..50,5, 14 × 12, com faixas de vidro como o Corredor 1).
	4. Liga o Corredor 1 à porta sul do LCC (Z 89,5..95) e a porta norte do LCC ao Corredor 2
	   (Z 165..170,5).

	Idempotente: cada peça movida recebe o atributo MovedByPhase14 e não é movida de novo;
	peças recriadas pelas Fases 1–6 chegam sem a marca e são movidas na próxima execução.
	As peças criadas aqui têm BuildPhase = 14 e são recriadas a cada execução.
	Executar depois das Fases 1–13 (o run_in_studio.luau já inclui esta fase).
]]

local lib = ...
local B = lib.builder(14)

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–13 antes")
B.clear(Map)

local Museum = Map.CapeCanaveralMuseum
local Reception = Map.Reception
local C1 = Map.Corridors.Corridor_01
local DECOR = { collide = false }
local DECOR_NS = { collide = false, shadow = false }
local GLASS = { transparency = 0.55, shadow = false }
local N = Enum.NormalId

---------------------------------------------------------------------------------
-- 1. Transformação do museu
---------------------------------------------------------------------------------
local OLD_CENTER = Vector3.new(0, 0, 130)
local NEW_CENTER = Vector3.new(90, 0, 27.5)
local ROT_DEG = 90
local T = CFrame.new(NEW_CENTER) * CFrame.Angles(0, math.rad(ROT_DEG), 0) * CFrame.new(-OLD_CENTER)
local TAG = "MovedByPhase14"

local moved, planets = 0, 0
local function movePart(p)
	if p:GetAttribute(TAG) then return end
	p.CFrame = T * p.CFrame
	p:SetAttribute(TAG, true)
	moved += 1
end
local function moveTree(root)
	if not root then return end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			movePart(d)
		elseif d:GetAttribute("OrbitCenter") and not d:GetAttribute(TAG) then
			-- planeta (Model com atributos de órbita): centro absoluto e ângulo em graus
			d:SetAttribute("OrbitCenter", T * d:GetAttribute("OrbitCenter"))
			d:SetAttribute("OrbitAngle", (d:GetAttribute("OrbitAngle") or 0) - ROT_DEG)
			d:SetAttribute(TAG, true)
			planets += 1
		end
	end
end
-- Os backdrops da Fase 3 são fixos (não pertencem ao conjunto de transporte).
-- Ajuste nas coordenadas de projeto ANTES do giro; não toca nenhum veículo da Fase 9.
local mars = Museum:FindFirstChild("Mars_Exhibition")
local function alignBackdrop(name, x0, x1, z0, z1)
	local p = mars and mars:FindFirstChild(name)
	if not p or p:GetAttribute(TAG) then return end
	p.Size = Vector3.new(x1 - x0, p.Size.Y, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, p.Position.Y, (z0 + z1) / 2)
end
-- W encosta em X −45; S encosta em Z 90,5 e termina na face de W (sem cruzar).
alignBackdrop("Backdrop_W", -45, -44.8, 90.5, 111)
alignBackdrop("Backdrop_S", -44.8, -24, 90.5, 90.7)

moveTree(Museum)

---------------------------------------------------------------------------------
-- 1b. Astronaut_Exhibition: liberar a porta sul do planetário
---------------------------------------------------------------------------------
-- A exposição é uma Folder: selecionamos somente a estátua do meio, pelo pedestal
-- mais próximo de X=90, e movemos cada BasePart em coordenadas finais.
local astronautFolder = Museum:FindFirstChild("Astronaut_Exhibition")
local ASTRONAUT_TAG = "AstronautMiddleRelocatedPhase14"
local ASTRONAUT_TARGET = Vector3.new(115, 0, 20)

local function bounds(parts)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, d in parts do
		if d:IsA("BasePart") then
			local half = d.Size * 0.5
			local cf = d.CFrame
			local ext = Vector3.new(
				math.abs(cf.RightVector.X) * half.X + math.abs(cf.UpVector.X) * half.Y + math.abs(cf.LookVector.X) * half.Z,
				math.abs(cf.RightVector.Y) * half.X + math.abs(cf.UpVector.Y) * half.Y + math.abs(cf.LookVector.Y) * half.Z,
				math.abs(cf.RightVector.Z) * half.X + math.abs(cf.UpVector.Z) * half.Y + math.abs(cf.LookVector.Z) * half.Z
			)
			local p = cf.Position
			minV = Vector3.new(math.min(minV.X, p.X - ext.X), math.min(minV.Y, p.Y - ext.Y), math.min(minV.Z, p.Z - ext.Z))
			maxV = Vector3.new(math.max(maxV.X, p.X + ext.X), math.max(maxV.Y, p.Y + ext.Y), math.max(maxV.Z, p.Z + ext.Z))
		end
	end
	return minV, maxV
end

local function partsOf(root)
	local parts = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then table.insert(parts, d) end
	end
	return parts
end

local function overlaps(aMin, aMax, bMin, bMax)
	return aMin.X < bMax.X and aMax.X > bMin.X
		and aMin.Y < bMax.Y and aMax.Y > bMin.Y
		and aMin.Z < bMax.Z and aMax.Z > bMin.Z
end

if astronautFolder then
	local selected = {}
	local function addPart(part)
		for _, existing in selected do
			if existing == part then return end
		end
		table.insert(selected, part)
	end
	if astronautFolder:GetAttribute(ASTRONAUT_TAG) then
		for _, d in astronautFolder:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute(ASTRONAUT_TAG) then addPart(d) end
		end
	else
		local pedestals = {}
		for _, d in astronautFolder:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Pedestal" then table.insert(pedestals, d) end
		end
		assert(#pedestals >= 3, "Astronaut_Exhibition precisa de três pedestais")
		local middlePedestal = pedestals[1]
		for _, pedestal in pedestals do
			if math.abs(pedestal.Position.X - 90) < math.abs(middlePedestal.Position.X - 90) then
				middlePedestal = pedestal
			end
		end
		local center = middlePedestal.Position
		for _, d in astronautFolder:GetDescendants() do
			if d:IsA("BasePart") then
				local nearPedestal = math.abs(d.Position.X - center.X) <= 3
				-- o painel de fundo (Wall_Panel) fica: só a estátua e o pedestal mudam de lugar
				local isDisplayPiece = d.Name == "Pedestal" or d.Name == "Pedestal_Glow"
				local parent = d.Parent
				local isAstronaut = false
				while parent and parent ~= astronautFolder do
					if parent.Name == "Astronaut" then isAstronaut = true break end
					parent = parent.Parent
				end
				if nearPedestal and (isDisplayPiece or isAstronaut) then addPart(d) end
			end
		end
		assert(#selected > 0, "não foi encontrada a estátua central de Astronaut_Exhibition")
	end

	local occupied = {
		Museum:FindFirstChild("Mars_Exhibition"),
		Museum:FindFirstChild("Rocket_Exhibition"),
		Museum:FindFirstChild("Science_Exhibition"),
		Museum:FindFirstChild("Solar_System"),
		Museum:FindFirstChild("Walls"),
		Museum:FindFirstChild("Dome"),
	}
	local function hitsRect(aMin, aMax, x0, x1, z0, z1)
		return aMin.X < x1 and aMax.X > x0 and aMin.Z < z1 and aMax.Z > z0
	end
	local function canPlace()
		local aMin, aMax = bounds(selected)
		-- Margem de 1 stud dentro das paredes do planetário.
		if aMin.X < 50.5 or aMax.X > 129.5 or aMin.Z < -17.5 or aMax.Z > 72.5 then return false end
		-- Porta sul e caminho oeste → centro (faixa central Z=27,5).
		if hitsRect(aMin, aMax, 82, 98, 54, 73) then return false end
		if hitsRect(aMin, aMax, 50.5, 100, 23, 32) then return false end
		-- peça a peça: a caixa de um grupo inteiro (paredes, cúpula) cobre o planetário todo
		for _, other in occupied do
			if other then
				for _, part in partsOf(other) do
					if part.CanCollide or part.Transparency < 0.9 then
						local bMin, bMax = bounds({ part })
						if overlaps(aMin, aMax, bMin, bMax) then return false end
					end
				end
			end
		end
		return true
	end

	if not astronautFolder:GetAttribute(ASTRONAUT_TAG) then
		local middlePedestal
		for _, part in selected do
			if not middlePedestal and part.Name == "Pedestal" then middlePedestal = part end
		end
		assert(middlePedestal, "a seleção central precisa conter o pedestal")
		local pedestalCenter = middlePedestal.Position
		local originalCFrames = {}
		for _, part in selected do originalCFrames[part] = part.CFrame end
		local candidates = {
			ASTRONAUT_TARGET,
			Vector3.new(110, 0, 12), Vector3.new(110, 0, 40),
			Vector3.new(120, 0, 12), Vector3.new(120, 0, 40),
			Vector3.new(105, 0, 12), Vector3.new(105, 0, 40),
		}
		local placedAt
		for _, target in candidates do
			if not placedAt then
				-- Só X/Z: o alvo tem Y 0, e mover o centro do pedestal até Y 0 o deixava meio enterrado
				local delta = Vector3.new(target.X - pedestalCenter.X, 0, target.Z - pedestalCenter.Z)
				for _, part in selected do part.CFrame = originalCFrames[part] + delta end
				if canPlace() then
					placedAt = target
				end
			end
		end
		assert(placedAt, "não foi encontrada posição livre para Astronaut_Exhibition")
		astronautFolder:SetAttribute(ASTRONAUT_TAG, true)
		astronautFolder:SetAttribute("AstronautRelocationTarget", placedAt)
		for _, part in selected do part:SetAttribute(ASTRONAUT_TAG, true) end
	end
	assert(canPlace(), "Astronaut_Exhibition ficou em posição inválida após a relocalização")
end

local LO = workspace:FindFirstChild("Lighting_Objects")
moveTree(LO and LO:FindFirstChild("Museum"))
local entranceSign = C1:FindFirstChild("Decorations") and C1.Decorations:FindFirstChild("Museum_Sign")
if entranceSign then movePart(entranceSign) end

-- peça construída nas coordenadas originais do museu e levada pela mesma transformação
local function boxT(parent, name, x0, x1, y0, y1, z0, z1, color, material, o)
	local p = B.box(parent, name, x0, x1, y0, y1, z0, z1, color, material, o)
	p.CFrame = T * p.CFrame
	return p
end

---------------------------------------------------------------------------------
-- 2. Fundos do museu fechados (vão X −8..8, até Y 14, na parede Z 169,5..170,5)
---------------------------------------------------------------------------------
local seal = B.group(Museum, "Back_Seal")
boxT(seal, "Wall_Patch", -8, 8, -1, 14, 169.5, 170.5, "darkBlue", "SmoothPlastic")

---------------------------------------------------------------------------------
-- 3. Recepção ↔ museu
---------------------------------------------------------------------------------
local OZ0, OZ1, OH = 20.5, 34.5, 12 -- vão na parede leste da recepção
local walls = Reception.Walls
local oldRight = walls:FindFirstChild("Right_Wall")
if oldRight and oldRight:IsA("BasePart") and oldRight:GetAttribute("BuildPhase") == nil then
	oldRight:Destroy() -- parede inteira da Fase 1, substituída pelos trechos abaixo
end
local rw = B.group(walls, "Right_Wall_Segments")
B.box(rw, "Right_Wall_A", 35, 36, -1, 24.98, -0.5, OZ0 - 0.5, "white", "SmoothPlastic")
B.box(rw, "Right_Wall_B", 35, 36, -1, 24.98, OZ1 + 0.5, 55, "white", "SmoothPlastic")
B.box(rw, "Right_Wall_Lintel", 35, 36, OH, 24.98, OZ0 - 0.5, OZ1 + 0.5, "white", "SmoothPlastic")
-- Batentes semicirculares: a extremidade curva é tangente ao limite do vão.
for _, z in { OZ0 - 0.5, OZ1 + 0.5 } do
	B.cyl(rw, "Museum_Jamb", 35.5, z, -1, OH + 0.02, 1, "white", "SmoothPlastic")
end
-- faixa decorativa da Fase 4 interrompida no vão
local desk = Reception:FindFirstChild("Front_Desk")
local stripe = desk and desk:FindFirstChild("Accent_Stripe_R")
if stripe and stripe:IsA("BasePart") then
	local y0, y1 = stripe.Position.Y - stripe.Size.Y / 2, stripe.Position.Y + stripe.Size.Y / 2
	local x0, x1 = stripe.Position.X - stripe.Size.X / 2, stripe.Position.X + stripe.Size.X / 2
	local z0, z1 = stripe.Position.Z - stripe.Size.Z / 2, stripe.Position.Z + stripe.Size.Z / 2
	local hex = "#" .. stripe.Color:ToHex()
	-- termina na tangente dos batentes (Z OZ0−0,5 / OZ1+0,5), como os rodapés: antes avançava
	-- 0,5 sobre o vão, solta na frente da curva do batente
	B.box(rw, "Accent_Stripe_A", x0, x1, y0, y1, z0, OZ0 - 0.5, hex, stripe.Material.Name, DECOR_NS)
	B.box(rw, "Accent_Stripe_B", x0, x1, y0, y1, OZ1 + 0.5, z1, hex, stripe.Material.Name, DECOR_NS)
	-- a original fica escondida (não apagada), para a divisão poder ser refeita em toda execução
	stripe.Transparency = 1
end
local recSign = B.box(rw, "Museum_Direction", 34.85, 34.95, OH + 0.6, OH + 2.6, OZ0 + 0.5, OZ1 - 0.5, "space", "SmoothPlastic", DECOR)
B.sign(recSign, "SPACE ADVENTURE MUSEUM", "Planetarium and space exploration exhibits", { face = N.Left, accent = "midBlue", titleScale = 0.42 })

-- corredor do museu (X 36..50,5), no estilo do Corredor 1
local mc = B.group(Map.Corridors, "Corridor_Museum")
local MX0, MX1 = 36, 49.5 -- face externa do planetário (Z original 89,5)
B.box(mc, "Floor", MX0, MX1 + 0.5, -1, 0, OZ0, OZ1, "lightGray", "Concrete")
B.box(mc, "Ceiling", MX0, MX1, OH, OH + 1, OZ0 - 1, OZ1 + 1, "white", "SmoothPlastic")
for _, side in { { OZ0 - 1, OZ0 }, { OZ1, OZ1 + 1 } } do
	B.box(mc, "Base_Band", MX0, MX1, -1, 3, side[1], side[2], "white", "SmoothPlastic")
	B.box(mc, "Top_Band", MX0, MX1, 9, OH, side[1], side[2], "white", "SmoothPlastic")
	B.box(mc, "Post", MX0, MX0 + 1.5, 3, 9, side[1], side[2], "white", "SmoothPlastic")
	B.box(mc, "Post", MX1 - 1.5, MX1, 3, 9, side[1], side[2], "white", "SmoothPlastic")
	local zm = (side[1] + side[2]) / 2
	B.box(mc, "Glass", MX0 + 1.5, MX1 - 1.5, 3, 9, zm - 0.15, zm + 0.15, "glass", "Glass", GLASS)
end
for _, z in { OZ0, OZ1 - 0.12 } do
	B.box(mc, "Baseboard", MX0 - 0.5, MX1 - 0.12, 0, 0.45, z, z + 0.12, "midGray", "Metal", DECOR)
end
local strip = B.box(mc, "Light_Strip", MX0 + 1, MX1 - 2, OH - 0.15, OH, 27, 28, "white", "Neon", DECOR_NS)
B.light(strip, "SurfaceLight", { Face = N.Bottom, Range = 13, Brightness = 1.3, Angle = 130, Shadows = false })

---------------------------------------------------------------------------------
-- 4. Ligações do LCC (no eixo X = 0)
---------------------------------------------------------------------------------
local links = B.group(Map.Corridors, "LCC_Links")
-- C1: junta em T à esquerda em Z95; canto à direita em (7,5; 95,5).
B.box(links, "C1_Floor", -7, 7, -1, 0, 89.5, 95, "lightGray", "Concrete")
-- Esquerda termina na face sul do LCC (Z95); direita no eixo do canto (Z95,5), que o
-- cilindro arredonda. Antes as duas iam a Z96 e duplicavam a face Z96 da South_Wall.
B.box(links, "C1_Wall", -8, -7, -1, 13, 89.5, 95, "white", "SmoothPlastic")
B.box(links, "C1_Wall", 7, 8, -1, 13, 89.5, 95.5, "white", "SmoothPlastic")
B.box(links, "C1_Ceiling", -7, 7, 12, 13, 89.5, 95, "white", "SmoothPlastic")
-- C2: junta em T à esquerda em Z165; canto à direita em (8,5; 164,5).
B.box(links, "C2_Floor", -8, 8, -1, 0, 165, 170.5, "darkGray", "DiamondPlate")
B.box(links, "C2_Wall", -9, -8, -1, 15, 165, 170.5, "metalGray", "Concrete")
B.box(links, "C2_Wall", 8, 9, -1, 15, 164.5, 170.5, "metalGray", "Concrete")
B.box(links, "C2_Ceiling", -8, 8, 14, 15, 165, 170.5, "darkGray", "Metal")

local n = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("BuildPhase") == 14 then n += 1 end
end
return string.format("Fase 14: museu movido (%d peças nesta execução, %d planetas), %d peças de ligação", moved, planets, n)
