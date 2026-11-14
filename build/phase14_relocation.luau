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
moveTree(Museum)
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
B.box(rw, "Right_Wall_A", 35, 36, -1, 25, 0, OZ0, "white", "SmoothPlastic")
B.box(rw, "Right_Wall_B", 35, 36, -1, 25, OZ1, 54.5, "white", "SmoothPlastic")
B.box(rw, "Right_Wall_Lintel", 35, 36, OH, 25, OZ0, OZ1, "white", "SmoothPlastic")
-- faixa decorativa da Fase 4 interrompida no vão
local desk = Reception:FindFirstChild("Front_Desk")
local stripe = desk and desk:FindFirstChild("Accent_Stripe_R")
if stripe and stripe:IsA("BasePart") then
	local y0, y1 = stripe.Position.Y - stripe.Size.Y / 2, stripe.Position.Y + stripe.Size.Y / 2
	local x0, x1 = stripe.Position.X - stripe.Size.X / 2, stripe.Position.X + stripe.Size.X / 2
	local z0, z1 = stripe.Position.Z - stripe.Size.Z / 2, stripe.Position.Z + stripe.Size.Z / 2
	local hex = "#" .. stripe.Color:ToHex()
	B.box(rw, "Accent_Stripe_A", x0, x1, y0, y1, z0, OZ0, hex, stripe.Material.Name, DECOR_NS)
	B.box(rw, "Accent_Stripe_B", x0, x1, y0, y1, OZ1, z1, hex, stripe.Material.Name, DECOR_NS)
	-- a original fica escondida (não apagada), para a divisão poder ser refeita em toda execução
	stripe.Transparency = 1
end
local recSign = B.box(rw, "Museum_Direction", 34.85, 34.95, OH + 0.6, OH + 2.6, OZ0 + 0.5, OZ1 - 0.5, "space", "SmoothPlastic", DECOR)
B.sign(recSign, "SPACE ADVENTURE MUSEUM  →", "Planetarium and space exploration exhibits", { face = N.Left, accent = "midBlue", titleScale = 0.42 })

-- corredor do museu (X 36..50,5), no estilo do Corredor 1
local mc = B.group(Map.Corridors, "Corridor_Museum")
local MX0, MX1 = 36, 50.5
B.box(mc, "Floor", MX0, MX1, -1, 0, OZ0, OZ1, "lightGray", "Concrete")
B.box(mc, "Ceiling", MX0, MX1, OH, OH + 1, OZ0 - 1, OZ1 + 1, "white", "SmoothPlastic")
for _, side in { { OZ0 - 1, OZ0 }, { OZ1, OZ1 + 1 } } do
	B.box(mc, "Base_Band", MX0, MX1 - 1, -1, 3, side[1], side[2], "white", "SmoothPlastic")
	B.box(mc, "Top_Band", MX0, MX1 - 1, 9, OH, side[1], side[2], "white", "SmoothPlastic")
	B.box(mc, "Post", MX0, MX0 + 1.5, 3, 9, side[1], side[2], "white", "SmoothPlastic")
	B.box(mc, "Post", MX1 - 2.5, MX1 - 1, 3, 9, side[1], side[2], "white", "SmoothPlastic")
	local zm = (side[1] + side[2]) / 2
	B.box(mc, "Glass", MX0 + 1.5, MX1 - 2.5, 3, 9, zm - 0.15, zm + 0.15, "glass", "Glass", GLASS)
end
local strip = B.box(mc, "Light_Strip", MX0 + 1, MX1 - 2, OH - 0.15, OH, 27, 28, "white", "Neon", DECOR_NS)
B.light(strip, "SurfaceLight", { Face = N.Bottom, Range = 13, Brightness = 1.3, Angle = 130, Shadows = false })

---------------------------------------------------------------------------------
-- 4. Ligações do LCC (no eixo X = 0)
---------------------------------------------------------------------------------
local links = B.group(Map.Corridors, "LCC_Links")
-- Corredor 1 (termina em Z 89,5; 14 × 12) → porta sul do LCC (Z 95)
B.box(links, "C1_Floor", -7, 7, -1, 0, 89.5, 95, "lightGray", "Concrete")
B.box(links, "C1_Wall", -8, -7, -1, 13, 89.5, 95, "white", "SmoothPlastic")
B.box(links, "C1_Wall", 7, 8, -1, 13, 89.5, 95, "white", "SmoothPlastic")
B.box(links, "C1_Ceiling", -7, 7, 12, 13, 89.5, 95, "white", "SmoothPlastic")
-- porta norte do LCC (Z 165) → Corredor 2 (começa em Z 170,5; 16 × 14)
B.box(links, "C2_Floor", -8, 8, -1, 0, 165, 170, "darkGray", "DiamondPlate")
B.box(links, "C2_Wall", -9, -8, -1, 15, 165, 170.5, "metalGray", "Concrete")
B.box(links, "C2_Wall", 8, 9, -1, 15, 165, 170.5, "metalGray", "Concrete")
B.box(links, "C2_Ceiling", -8, 8, 14, 15, 165, 170.5, "darkGray", "Metal")

local n = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("BuildPhase") == 14 then n += 1 end
end
return string.format("Fase 14: museu movido (%d peças nesta execução, %d planetas), %d peças de ligação", moved, planets, n)
