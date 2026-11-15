--[[
	NASA Space Adventure — Fase 8: acesso da tripulação (pedido do usuário, após as 7 fases da spec)
	Percurso: vestiário fixo no piso do VAB (trajes espaciais brancos) → escada do lançador
	          → elevador da torre esquerda → braço de acesso + White Room → escotilha
	          → cabine da Orion (4 assentos).

	Tudo o que acompanha o lançador é relativo (spec-v3 §5.4 e §12): as zonas do elevador ficam
	no atributo ZoneOffset de cada cabine (relativo ao piso, PrimaryPart), as portas abrem em
	relação à cabine e as escotilhas apontam para peças de referência (ObjectValue TargetRef →
	Exit_Point na White Room, Entry_Point na cabine). Assim o acesso continua funcionando
	quando o conjunto de transporte se move (Fase 9).

	A cabine da Orion em escala de foguete tem só 3,5 studs de altura, pequena demais para um
	personagem. Por isso o interior é um modelo em escala humana colocado sob o hangar (Y ≈ −60):
	16 lados, Ø 32 no piso, 15 de altura. A escotilha teleporta o jogador para dentro e de volta.

	Scripts:
	- ServerScriptService/Map_Systems/CrewAccess (Script): trata os ProximityPrompts com o atributo
	  CrewAction = "Suit" | "Elevator" | "Teleport" | "Sit"; move as portas do elevador.
	- StarterPlayer/StarterPlayerScripts/CrewClient (LocalScript): tela escura nas transições e
	  texto do prompt do traje.
	- ReplicatedStorage/CrewFade (RemoteEvent): servidor → cliente, "out"/"in".
	Nada de lançamento, combustível ou missões (spec §14).
]]

local lib = ...
local B = lib.builder(8)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–6 antes")
B.clear(Map)

local Hangar = Map.VABHangar
local DECOR = { collide = false }
local DECOR_NS = { collide = false, shadow = false }
local HIDDEN = { collide = false, shadow = false, transparency = 1 }

local DECK = 10.1          -- topo da chapa do lançador móvel
local RZ = 265             -- eixo do foguete
local TOP = 111.5          -- piso do braço de acesso (topo do módulo de serviço)

local root = B.group(Hangar, "Crew_Access")

local function prompt(part, action, object, actionText, o)
	local p = Instance.new("ProximityPrompt")
	p.ObjectText = object
	p.ActionText = actionText
	p.HoldDuration = o and o.hold or 0
	p.MaxActivationDistance = o and o.dist or 7
	p.RequiresLineOfSight = false
	p:SetAttribute("CrewAction", action)
	p:SetAttribute("BuildPhase", 8)
	p.Parent = part
	return p
end

---------------------------------------------------------------------------------
-- 1. Vestiário (sala fixa no piso do VAB, à esquerda do lançador; spec-v3 §6.2)
--    Interior X −60..−36,5, Z 244..258, Y 0..13, fora do envelope (X ≥ −34) e da torre
--    de plataformas (Z ≥ 262). Ampliado para a câmera em terceira pessoa caber no celular
--    (antes 10 × 10 × 9,3). Entrada pela face −Z (lado do portão frontal, vão X −44..−38);
--    porta da face +X (Z 248,5..253,5) dá para a escada do lançador. Armários na parede do fundo.
---------------------------------------------------------------------------------
local room = B.group(Hangar, "CrewSuitUpRoom") -- sala fixa do VAB (spec-v3 §11)
-- Paredes e teto em reboco (Plaster): reduz o branco estourado de 46% para 36% da imagem
-- (comparação medida em docs/materials).
local RX0, RX1, RZ0, RZ1, RH = -60, -36.5, 244, 258, 13
local EX0, EX1 = -44, -38          -- vão de entrada (face −Z)
local DZ0, DZ1 = 248.5, 253.5      -- porta para o lançador (face +X)
B.box(room, "Floor_Mat", RX0, RX1, 0, 0.1, RZ0, RZ1, "lightGray", "SmoothPlastic")
B.box(room, "Wall_Back", RX0 - 0.4, RX0, 0, RH, RZ0 - 0.4, RZ1 + 0.4, "white", "Plaster")
B.box(room, "Wall_Entrance", RX0, EX0, 0, RH, RZ0 - 0.4, RZ0, "white", "Plaster")
B.box(room, "Wall_Entrance", EX1, RX1, 0, RH, RZ0 - 0.4, RZ0, "white", "Plaster")
B.box(room, "Lintel", EX0, EX1, 11, RH, RZ0 - 0.4, RZ0, "white", "SmoothPlastic")
B.box(room, "Wall_End", RX0, RX1, 0, RH, RZ1, RZ1 + 0.4, "white", "Plaster")
-- frente (X −36,5): mureta + vidro, com a porta para o lançador
for _, zz in { { RZ0 - 0.4, DZ0 }, { DZ1, RZ1 + 0.4 } } do
	B.box(room, "Front_Base", RX1, RX1 + 0.4, 0, 3.6, zz[1], zz[2], "white", "SmoothPlastic")
	B.box(room, "Front_Glass", RX1 + 0.1, RX1 + 0.3, 3.6, RH, zz[1], zz[2], "glass", "Glass", { transparency = 0.5 })
end
B.box(room, "Lintel", RX1, RX1 + 0.4, 11, RH, DZ0, DZ1, "white", "SmoothPlastic")
-- faixa em dois trechos (não atravessa o vão da porta), 0,02 acima da mureta e além das pontas
for _, zz in { { RZ0 - 0.42, DZ0 }, { DZ1, RZ1 + 0.42 } } do
	B.box(room, "Accent_Stripe", RX1 - 0.05, RX1 + 0.45, 3.2, 3.62, zz[1], zz[2], "nasaBlue", "SmoothPlastic", DECOR)
end
B.box(room, "Roof", RX0 - 0.6, RX1 + 0.6, RH, RH + 0.4, RZ0 - 0.6, RZ1 + 0.6, "white", "Plaster")
for _, lx in { { -55, -50 }, { -46, -41 } } do
	local panel = B.box(room, "Ceiling_Light", lx[1], lx[2], RH - 0.1, RH, 248, 254, "white", "Neon", DECOR_NS)
	B.light(panel, "SurfaceLight", { Face = Enum.NormalId.Bottom, Brightness = 1.5, Range = 16, Angle = 120, Shadows = false })
end

-- placas
local s1 = B.box(room, "Sign_Entrance", EX0, EX1, 11.4, 12.8, RZ0 - 0.6, RZ0 - 0.4, "space", "SmoothPlastic", DECOR)
B.sign(s1, "CREW SUIT-UP ROOM", nil, { face = Enum.NormalId.Front, titleColor = "white", accent = "orange" })
local s2 = B.box(room, "Sign_Suits", RX0, RX0 + 0.1, 8.4, 11.6, RZ0 + 1, RZ1 - 1, "space", "SmoothPlastic", DECOR)
B.sign(s2, "NASA CREW SPACESUITS",
	"Every crew member suits up here before launch. Put on your NASA spacesuit, then climb the mobile launcher stairs and take the crew elevator.",
	{ face = Enum.NormalId.Right, accent = "orange", titleScale = 0.32 })
local s3 = B.box(room, "Sign_Launcher", RX1 + 0.45, RX1 + 0.55, 11.4, 12.8, DZ0, DZ1, "space", "SmoothPlastic", DECOR)
B.sign(s3, "TO MOBILE LAUNCHER", nil, { face = Enum.NormalId.Right, titleColor = "safety" })
-- a porta dá para a lateral do patamar; o pé da escada fica em Z 234 (à esquerda de quem sai)
local s4 = B.box(room, "Sign_Stairs", RX1 - 0.08, RX1 - 0.02, 11.4, 12.8, DZ0, DZ1, "space", "SmoothPlastic", DECOR)
B.sign(s4, "← LAUNCHER STAIRS", nil, { face = Enum.NormalId.Left, titleColor = "safety" })
-- faixa de piso fixa no VAB: da porta até o pé da escada (X < −30, fora da escada do conjunto)
B.box(room, "Stairs_Guide", RX1 + 0.4, -31, 0, 0.06, 250.5, 251.5, "lightBlue", "SmoothPlastic", DECOR)
B.box(room, "Stairs_Guide", -32, -31, 0, 0.06, 232, 250.5, "lightBlue", "SmoothPlastic", DECOR)
B.box(room, "Stairs_Guide", -31, -27, 0, 0.06, 232, 233, "lightBlue", "SmoothPlastic", DECOR)

-- 4 armários com trajes, na parede do fundo (frente voltada para +X)
local LX0, LX1 = RX0 + 0.4, RX0 + 2.4   -- −59,6..−57,6
for i, cz in { 247, 249.9, 252.8, 255.7 } do
	local lk = B.group(room, "Suit_Locker_" .. i)
	B.box(lk, "Side", LX0, LX1, 0, 6.8, cz - 1.1, cz - 1.0, "nasaBlue", "Metal")
	B.box(lk, "Side", LX0, LX1, 0, 6.8, cz + 1.0, cz + 1.1, "nasaBlue", "Metal")
	B.box(lk, "Top", LX0, LX1, 6.8, 7.0, cz - 1.1, cz + 1.1, "nasaBlue", "Metal")
	B.box(lk, "Base", LX0, LX1, 0, 0.7, cz - 1.0, cz + 1.0, "darkGray", "Metal")
	B.box(lk, "Back", LX0, LX0 + 0.15, 0.7, 6.8, cz - 1.0, cz + 1.0, "midGray", "Metal", DECOR)
	-- traje pendurado (decorativo)
	B.box(lk, "Suit_Torso", LX0 + 0.7, LX0 + 1.3, 3.5, 5.5, cz - 0.7, cz + 0.7, "lightGray", "Fabric", DECOR)
	B.box(lk, "Suit_Leg", LX0 + 0.75, LX0 + 1.25, 1.1, 3.5, cz - 0.65, cz - 0.08, "lightGray", "Fabric", DECOR)
	B.box(lk, "Suit_Leg", LX0 + 0.75, LX0 + 1.25, 1.1, 3.5, cz + 0.08, cz + 0.65, "lightGray", "Fabric", DECOR)
	B.box(lk, "Suit_Arm", LX0 + 0.75, LX0 + 1.2, 3.2, 5.4, cz - 0.95, cz - 0.72, "lightGray", "Fabric", DECOR)
	B.box(lk, "Suit_Arm", LX0 + 0.75, LX0 + 1.2, 3.2, 5.4, cz + 0.72, cz + 0.95, "lightGray", "Fabric", DECOR)
	B.box(lk, "Suit_Patch", LX0 + 1.29, LX0 + 1.33, 4.7, 5.1, cz - 0.5, cz - 0.1, "nasaBlue", "SmoothPlastic", DECOR)
	B.box(lk, "Boot", LX0 + 0.7, LX0 + 1.4, 0.7, 1.1, cz - 0.65, cz + 0.65, "black", "SmoothPlastic", DECOR)
	B.ball(lk, "Helmet", Vector3.new(LX0 + 0.9, 6.15, cz), 1.25, "white", "SmoothPlastic", DECOR)
	B.ball(lk, "Helmet_Visor", Vector3.new(LX0 + 1.15, 6.1, cz), 1.0, "black", "Glass", { collide = false, reflectance = 0.4 })
	local tag = B.box(lk, "Name_Tag", LX1 - 0.05, LX1 + 0.05, 6.85, 7.35, cz - 0.9, cz + 0.9, "space", "SmoothPlastic", DECOR)
	B.sign(tag, "CREW " .. i, nil, { face = Enum.NormalId.Right, titleColor = "white", ppu = 80 })
	local pp = B.box(lk, "Prompt_Point", LX1 - 0.1, LX1, 1.9, 4.9, cz - 0.9, cz + 0.9, "white", "SmoothPlastic", HIDDEN)
	prompt(pp, "Suit", "NASA spacesuit", "Put on / take off", { hold = 0.4, dist = 6 })
end
B.box(room, "Bench", -44, -38, 0, 1.6, RZ1 - 1.6, RZ1 - 0.3, "metalGray", "Metal")

---------------------------------------------------------------------------------
-- 2. Elevador da tripulação (frente da torre esquerda, X −24..−15, Z 254,1..262)
--    Cabine de baixo no deck (Y 10.1) e de cima no braço de acesso (Y 111.5).
--    Cabines ampliadas (interior 7,8 × 7,1 × 8,4) para caberem 4 tripulantes + a Ana.
--    Os ocupantes são levados entre as duas preservando a posição relativa.
---------------------------------------------------------------------------------
local elev = B.group(root, "Crew_Elevator")
local CX0, CX1 = -24, -15          -- faces externas das paredes laterais (X); deck vai até X −24
local WT = 0.6                     -- espessura das paredes
local XI0, XI1 = CX0 + WT, CX1 - WT -- interior (X)
local CXC = (CX0 + CX1) / 2
local ZC0, ZC1 = 254.5, 261.6       -- interior das cabines (Z)
local CH = 8.4                      -- altura interna
local zoneCenter = function(floorY) return Vector3.new(CXC, floorY + CH / 2, (ZC0 + ZC1) / 2) end
local ZONE = Vector3.new(XI1 - XI0 - 0.2, CH, ZC1 - ZC0 + 0.6)

local function cab(name, floorY, doorAtLowZ)
	local c = B.group(elev, name)
	local y1 = floorY + CH
	local floor = B.box(c, "Floor", CX0, CX1, floorY - 0.5, floorY + 0.15, ZC0 - 0.4, ZC1 + 0.4, "darkGray", "DiamondPlate")
	-- referência da cabine: zona de passageiros relativa ao piso (acompanha o lançador)
	c.PrimaryPart = floor
	c:SetAttribute("ZoneOffset", floor.CFrame:PointToObjectSpace(zoneCenter(floorY)))
	c:SetAttribute("ZoneSize", ZONE)
	-- paredes apoiadas no topo do piso (floorY + 0,15): sem faces coplanares com o piso
	B.box(c, "Wall_Side", CX0, XI0, floorY + 0.15, y1, ZC0 - 0.4, ZC1 + 0.4, "metalGray", "Metal")
	B.box(c, "Wall_Side", XI1, CX1, floorY + 0.15, y1, ZC0 - 0.4, ZC1 + 0.4, "metalGray", "Metal")
	if doorAtLowZ then
		B.box(c, "Wall_Back", XI0, XI1, floorY + 0.15, y1, ZC1, ZC1 + 0.4, "metalGray", "Metal")
	else
		B.box(c, "Wall_Back", XI0, XI1, floorY + 0.15, y1, ZC0 - 0.4, ZC0, "metalGray", "Metal")
	end
	B.box(c, "Roof", CX0, CX1, y1, y1 + 0.4, ZC0 - 0.4, ZC1 + 0.4, "metalGray", "Metal")
	local lp = B.box(c, "Cab_Light", CXC - 2, CXC + 2, y1 - 0.08, y1, ZC0 + 1.5, ZC1 - 1.5, "white", "Neon", DECOR_NS)
	B.light(lp, "SurfaceLight", { Face = Enum.NormalId.Bottom, Brightness = 1.6, Range = 11, Shadows = false })
	-- corrimão nas três paredes internas (detalhe; sem colisão)
	B.box(c, "Handrail", XI1 - 0.15, XI1 - 0.05, floorY + 3.2, floorY + 3.35, ZC0 + 0.6, ZC1 - 0.6, "metalGray", "Metal", DECOR)
	B.box(c, "Handrail", XI0 + 0.05, XI0 + 0.15, floorY + 3.2, floorY + 3.35, ZC0 + 0.6, ZC1 - 0.6, "metalGray", "Metal", DECOR)
	local pz = (ZC0 + ZC1) / 2
	local panelP = B.box(c, "Call_Panel", XI1 - 0.05, XI1 + 0.02, floorY + 2.9, floorY + 4.4, pz - 0.5, pz + 0.5, "darkGray", "Metal")
	local lamp = B.box(c, "Status_Lamp", XI1 - 0.06, XI1 + 0.03, floorY + 4.7, floorY + 5.1, pz - 0.2, pz + 0.2, "#3CCB5A", "Neon", DECOR_NS)
	-- portas deslizantes (montadas fechadas; o script abre ao iniciar e fecha durante a viagem)
	local dz0 = doorAtLowZ and (ZC0 - 0.35) or (ZC1 + 0.05)
	local half = (XI1 - XI0) / 2
	for _, side in { -1, 1 } do
		local x0, x1 = (side < 0) and XI0 or CXC, (side < 0) and CXC or XI1
		local leaf = B.box(c, side < 0 and "Door_L" or "Door_R", x0, x1, floorY + 0.15, floorY + CH - 0.4, dz0, dz0 + 0.3, "metalGray", "Metal")
		leaf:SetAttribute("OpenOffset", Vector3.new(side * half, 0, 0))
		B.box(c, "Door_Window", x0 + 0.8, x1 - 0.8, floorY + 4.4, floorY + 6.8, dz0 - 0.03, dz0 + 0.33, "glass", "Glass",
			{ collide = false, transparency = 0.3 }):SetAttribute("FollowDoor", leaf.Name)
	end
	return c, panelP
end
local _, panelLow = cab("Cab_Lower", DECK, true)
local _, panelTop = cab("Cab_Upper", TOP, false)
-- cada painel leva quem está na própria cabine até a outra cabine do mesmo elevador
local pl = prompt(panelLow, "Elevator", "Crew elevator", "Go up to the access arm", { dist = 6 })
pl:SetAttribute("FadeText", "Going up to the crew access arm…")
local pt = prompt(panelTop, "Elevator", "Crew elevator", "Go down to the launcher", { dist = 6 })
pt:SetAttribute("FadeText", "Going down to the mobile launcher…")
local tag = B.box(elev, "Sign_Cab_Upper", CXC - 2, CXC + 2, TOP + 6.4, TOP + 7.6, ZC0 + 0.01, ZC0 + 0.1, "space", "SmoothPlastic", DECOR)
B.sign(tag, "CREW ACCESS ARM", nil, { face = Enum.NormalId.Back, titleColor = "safety" })

-- poço: pilares de canto e cintas horizontais entre as cabines
local shaft = B.group(elev, "Shaft")
local SH = TOP + 9                  -- topo do poço (acima do teto da cabine de cima)
local PZ0, PZ1 = ZC0 - 0.9, ZC0 - 0.4 -- pilares da frente
local QZ0, QZ1 = ZC1 + 0.42, ZC1 + 0.52 -- pilares do fundo (encostados na torre)
for _, px in { { CX0 - 0.5, CX0 }, { CX1, CX1 + 0.5 } } do
	for _, pz in { { PZ0, PZ1 }, { QZ0, QZ1 } } do
		B.box(shaft, "Post", px[1], px[2], DECK, SH, pz[1], pz[2], "darkGray", "Metal")
	end
end
for y = 22, 106, 12 do
	-- cintas 0,02 mais largas que os pilares; as laterais começam atrás da cinta frontal
	B.box(shaft, "Band", CX0 - 0.52, CX1 + 0.52, y - 0.25, y + 0.25, PZ0 - 0.02, PZ1 + 0.02, "metalGray", "Metal")
	B.box(shaft, "Band", CX0 - 0.52, CX0 + 0.02, y - 0.25, y + 0.25, PZ1 + 0.02, QZ1 + 0.02, "metalGray", "Metal")
	B.box(shaft, "Band", CX1 - 0.02, CX1 + 0.52, y - 0.25, y + 0.25, PZ1 + 0.02, QZ1 + 0.02, "metalGray", "Metal")
end
B.box(shaft, "Counterweight_Rail", CX0 - 0.4, CX0 - 0.1, DECK, TOP, (ZC0 + ZC1) / 2 - 0.15, (ZC0 + ZC1) / 2 + 0.15, "safety", "Metal", DECOR)

---------------------------------------------------------------------------------
-- 3. Plataforma final: topo da torre esquerda + braço de acesso (passarela) + White Room
--    Topo da torre com a largura da cabine (X −24..−15) e passarela de 6 de largura.
---------------------------------------------------------------------------------
local arm = B.group(root, "Crew_Access_Arm")
local AW = 3                        -- meia largura da passarela (Z RZ ± 3)
-- prolongamento das colunas da torre esquerda (topo original em Y 105)
for _, cx in { -22.6, -17.4 } do
	for _, cz in { 262.4, 267.6 } do
		B.box(arm, "Column_Ext", cx - 0.4, cx + 0.4, 105, SH, cz - 0.4, cz + 0.4, "darkGray", "Metal")
	end
end
-- deck do topo da torre (encosta na cabine de cima e na passarela) e guarda-corpos
B.box(arm, "Tower_Deck", CX0, CX1, TOP - 0.5, TOP, 262.02, 267.98, "darkGray", "DiamondPlate")
B.box(arm, "Rail", CX0, CX0 + 0.2, TOP, TOP + 1.2, 262.02, 267.98, "safety", "Metal")
B.box(arm, "Rail", CX0 + 0.2, CX1, TOP, TOP + 1.2, 267.78, 267.98, "safety", "Metal")
B.box(arm, "Roof", CX0 - 0.6, CX1 + 0.6, SH, SH + 0.4, PZ0 - 0.2, 268.2, "metalGray", "Metal")
-- passarela (braço de acesso)
B.box(arm, "Arm_Deck", CX1, -3.2, TOP - 0.5, TOP, RZ - AW, RZ + AW, "darkGray", "DiamondPlate")
for _, z in { RZ - AW + 0.25, RZ + AW - 0.25 } do
	B.box(arm, "Arm_Beam", CX1, -3.4, TOP - 1.2, TOP - 0.5, z - 0.2, z + 0.2, "metalGray", "Metal")
	B.beam(arm, "Arm_Brace", Vector3.new(-17.4, 105.2, z), Vector3.new(-9, TOP - 1.2, z), 0.35, 0.35, "metalGray", "Metal", DECOR)
end
for _, z in { RZ - AW, RZ + AW } do
	B.box(arm, "Arm_Rail", CX1, -6.5, TOP, TOP + 1.1, z - 0.1, z + 0.1, "safety", "Metal")
	-- corrimão intermediário e rodapé (detalhe; sem colisão)
	B.box(arm, "Arm_Rail_Mid", CX1, -6.5, TOP + 0.55, TOP + 0.65, z - 0.08, z + 0.08, "safety", "Metal", DECOR)
end
for x = CX1 + 2, -7, 3 do
	for _, z in { RZ - AW, RZ + AW } do
		B.box(arm, "Arm_Rail_Post", x - 0.08, x + 0.08, TOP, TOP + 1.1, z - 0.12, z + 0.12, "safety", "Metal", DECOR)
	end
end
-- White Room (X −6.5..−3.2), aberta para o lado da cápsula, com a largura da passarela
local wr = B.group(arm, "White_Room")
local WY1 = TOP + 7
local WD = AW - 1                   -- meia largura do vão da porta
B.box(wr, "Wall", -6.5, -3.2, TOP, WY1, RZ - AW - 0.3, RZ - AW, "white", "SmoothPlastic")
B.box(wr, "Wall", -6.5, -3.2, TOP, WY1, RZ + AW, RZ + AW + 0.3, "white", "SmoothPlastic")
B.box(wr, "Wall_Door", -6.5, -6.2, TOP, WY1, RZ - AW, RZ - WD, "white", "SmoothPlastic")
B.box(wr, "Wall_Door", -6.5, -6.2, TOP, WY1, RZ + WD, RZ + AW, "white", "SmoothPlastic")
B.box(wr, "Lintel", -6.5, -6.2, TOP + 6.4, WY1, RZ - WD, RZ + WD, "white", "SmoothPlastic")
local wroof = B.box(wr, "Roof", -6.7, -3.2, WY1, WY1 + 0.3, RZ - AW - 0.5, RZ + AW + 0.5, "white", "SmoothPlastic")
B.light(wroof, "SurfaceLight", { Face = Enum.NormalId.Bottom, Brightness = 1.2, Range = 10, Shadows = false })
local ws = B.box(wr, "Sign", -6, -3.6, TOP + 4.8, TOP + 6, RZ - AW, RZ - AW + 0.1, "space", "SmoothPlastic", DECOR)
B.sign(ws, "ORION CREW HATCH", nil, { face = Enum.NormalId.Back, titleColor = "white", accent = "orange" })

-- escotilha externa na cápsula (lado −X do módulo da tripulação)
local hatch = B.box(arm, "Orion_Hatch", -2.88, -2.76, TOP + 0.1, TOP + 2.4, RZ - 0.8, RZ + 0.8, "darkGray", "Metal")
B.box(arm, "Hatch_Window", -2.92, -2.86, TOP + 1.3, TOP + 2.0, RZ - 0.3, RZ + 0.3, "space", "Glass", { collide = false, reflectance = 0.3 })

---------------------------------------------------------------------------------
-- 4. Interior da Orion em escala humana (sob o hangar, centro (0, −60, 265))
--    Cabine de 16 lados: Ø 32 no piso, Ø 19 no teto, 15 de altura.
--    +X = console/janelas (frente); −X = escotilha; ±Z = laterais.
---------------------------------------------------------------------------------
local cabin = B.group(Map, "OrionInterior") -- interior em escala humana (spec-v3 §11)
local CO = Vector3.new(0, -60, RZ)
local N, R0, R1, H = 16, 16, 9.5, 15
local ap0, ap1 = R0 * math.cos(math.pi / N), R1 * math.cos(math.pi / N)
local function Y(h) return CO.Y + h end

-- referencial na face interna da parede k, à altura h do piso, deslocado d para dentro.
-- eixo X = tangente, Y = subindo pela parede, Z = para dentro (face Back voltada para o interior).
local function wallCF(k, h, d)
	local a = k * 2 * math.pi / N
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local tan = Vector3.new(-math.sin(a), 0, math.cos(a))
	local bottom = CO + out * ap0
	local up = ((CO + out * ap1 + Vector3.new(0, H, 0)) - bottom).Unit
	local inward = tan:Cross(up)
	local p = bottom + up * (h / up.Y) + inward * (d or 0)
	return CFrame.fromMatrix(p, tan, up)
end
local IN = Enum.NormalId.Back

-- casco
local shellM = B.group(cabin, "Shell")
local L = math.sqrt(H * H + (ap0 - ap1) ^ 2)
local W = 2 * ap0 * math.tan(math.pi / N) + 0.4
for k = 0, N - 1 do
	B.part(shellM, "Wall_Panel", wallCF(k, H / 2, -0.25), Vector3.new(W, L, 0.5), (k % 2 == 0) and "paleGray" or "lightGray", "SmoothPlastic")
	-- frisos horizontais (aparência de painéis acolchoados)
	B.part(shellM, "Wall_Trim", wallCF(k, 2.2, 0.05), Vector3.new(W - 0.6, 0.25, 0.1), "midGray", "SmoothPlastic", DECOR_NS)
	B.part(shellM, "Wall_Trim", wallCF(k, 12.5, 0.05), Vector3.new(W * 0.6, 0.25, 0.1), "midGray", "SmoothPlastic", DECOR_NS)
end
B.cyl(shellM, "Floor", CO.X, CO.Z, Y(-1), Y(0), 2 * R0 + 0.6, "metalGray", "Metal")
B.cyl(shellM, "Ceiling", CO.X, CO.Z, Y(H), Y(H + 0.5), 2 * R1 + 0.6, "white", "SmoothPlastic")
B.ring(shellM, "Floor_Ring", CO + Vector3.new(0, 0.05, 0), 13, 0.5, 0.1, "nasaBlue", "SmoothPlastic", DECOR_NS)
-- túnel de acoplamento no teto
B.cyl(shellM, "Docking_Tunnel", CO.X, CO.Z, Y(H - 0.2), Y(H), 4.2, "darkGray", "Metal", DECOR_NS)
B.cyl(shellM, "Docking_Hatch", CO.X, CO.Z, Y(H - 0.3), Y(H - 0.2), 3.2, "metalGray", "Metal", DECOR_NS)
-- iluminação: anel de LEDs + 2 pontos
B.ring(shellM, "Light_Ring", CO + Vector3.new(0, H - 0.1, 0), 7, 0.5, 0.15, "white", "Neon", DECOR_NS)
for _, x in { -5, 5 } do
	local lp = B.box(shellM, "Light_Source", x - 0.3, x + 0.3, Y(H - 0.4), Y(H - 0.1), RZ - 0.3, RZ + 0.3, "white", "Neon", DECOR_NS)
	B.light(lp, "PointLight", { Brightness = 1.2, Range = 26, Color = Color3.fromRGB(255, 244, 228), Shadows = false })
end

-- janelas (frente, parte superior) com céu estrelado
local function starView(part)
	local g = Instance.new("SurfaceGui")
	g.Face = IN
	g.LightInfluence = 0
	g.Brightness = 1.2
	g.Parent = part
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.fromHex(lib.C.deepBlue), Color3.fromHex(lib.C.space))
	grad.Parent = f
	local rng = Random.new(#part:GetFullName())
	for _ = 1, 14 do
		local s = Instance.new("Frame")
		local sz = rng:NextInteger(2, 5)
		s.Size = UDim2.fromOffset(sz, sz)
		s.Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95))
		s.BackgroundColor3 = Color3.new(1, 1, 1)
		s.BorderSizePixel = 0
		s.Parent = f
	end
end
for _, k in { 15, 0, 1, 2, 14 } do
	local w = B.part(cabin, "Window", wallCF(k, 10.4, 0.1), Vector3.new(2.4, 2.4, 0.15), "space", "SmoothPlastic", DECOR_NS)
	starView(w)
	B.part(cabin, "Window_Frame", wallCF(k, 10.4, 0.04), Vector3.new(3.0, 3.0, 0.1), "darkGray", "Metal", DECOR)
end

-- console com 3 telas (o cockpit da Orion usa três unidades de display)
local con = B.group(cabin, "Console")
B.box(con, "Console_Desk", 10.6, 12.8, Y(0), Y(3.4), RZ - 5.5, RZ + 5.5, "darkGray", "Metal")
B.box(con, "Console_Top", 10.3, 12.8, Y(3.4), Y(3.6), RZ - 5.6, RZ + 5.6, "black", "Metal")
local DU = {
	{ "DU 1 · FLIGHT", "ATTITUDE  HOLD\nALTITUDE  0 KM\nVEHICLE   ON PAD" },
	{ "DU 2 · SYSTEMS", "CABIN PRESSURE  14.7 PSI\nOXYGEN  21 %\nPOWER   NOMINAL" },
	{ "DU 3 · CREW", "CDR · PLT · MS1 · MS2\nSUITS   CHECK\nCOMM    LOOP 1" },
}
for i, dz in { -3.6, 0, 3.6 } do
	local pos = Vector3.new(11.7, Y(5.4), RZ + dz)
	local scr = B.part(con, "Display_Unit_" .. i, CFrame.lookAt(pos, pos + Vector3.new(-1, 0.35, 0)),
		Vector3.new(3.3, 2.3, 0.2), "black", "SmoothPlastic")
	B.sign(scr, DU[i][1], DU[i][2], { face = Enum.NormalId.Front, bg = "space", accent = "midBlue", titleScale = 0.25, brightness = 1.4, ppu = 100 })
end
-- controladores manuais (rotação e translação) diante do comandante e do piloto
for _, z in { RZ - 3.2, RZ + 3.2 } do
	B.box(con, "Hand_Controller_Base", 10.4, 11.2, Y(3.6), Y(3.8), z - 0.4, z + 0.4, "black", "Metal", DECOR)
	B.cyl(con, "Hand_Controller", 10.8, z, Y(3.8), Y(4.6), 0.3, "darkGray", "Metal", DECOR)
end
-- painéis de chaves nas laterais da frente
local SW = { [2] = { "POWER", "BUS A  ON\nBUS B  ON\nBATTERY  98 %" }, [14] = { "LIFE SUPPORT", "CO2 SCRUB  ON\nFANS  AUTO\nTEMP  22 °C" } }
for k, t in SW do
	local pnl = B.part(cabin, "Switch_Panel", wallCF(k, 5.4, 0.08), Vector3.new(3.6, 2.4, 0.12), "black", "SmoothPlastic", DECOR)
	B.sign(pnl, t[1], t[2], { face = IN, bg = "darkBlue", accent = "safety", titleScale = 0.28, brightness = 1.2 })
end

-- plataforma da fileira de trás + degrau
B.box(cabin, "Rear_Platform", -1.6, 3.4, Y(0), Y(1.2), RZ - 6.5, RZ + 6.5, "darkGray", "DiamondPlate")
B.box(cabin, "Rear_Step", -2.6, -1.6, Y(0), Y(0.6), RZ - 4.5, RZ + 4.5, "darkGray", "DiamondPlate")
B.box(cabin, "Platform_Edge", -1.65, -1.55, Y(0.6), Y(1.25), RZ - 6.5, RZ + 6.5, "safety", "SmoothPlastic", DECOR_NS)

-- 4 assentos reclinados voltados para o console (+X)
local seats = B.group(cabin, "Crew_Seats")
local SEATS = {
	{ "CDR", 6.4, 0, RZ - 3.2 }, { "PLT", 6.4, 0, RZ + 3.2 },
	{ "MS1", 1.4, 1.2, RZ - 3.2 }, { "MS2", 1.4, 1.2, RZ + 3.2 },
}
for _, s in SEATS do
	local label, x, fy, z = s[1], s[2], s[3], s[4]
	local g = B.group(seats, "Seat_" .. label)
	local base = Vector3.new(x, Y(fy + 1.5), z)
	local scf = CFrame.lookAt(base, base + Vector3.xAxis) * CFrame.Angles(math.rad(18), 0, 0)
	local seat = Instance.new("Seat")
	seat.Name = "Seat"
	seat.Anchored = true
	seat.Size = Vector3.new(2.4, 0.8, 2.4)
	seat.CFrame = scf
	seat.Color = Color3.fromHex(lib.C.darkGray)
	seat.Material = Enum.Material.Fabric
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat:SetAttribute("BuildPhase", 8)
	seat.Parent = g
	local back = B.part(g, "Seat_Back", scf * CFrame.new(0, 1.8, 1.35) * CFrame.Angles(math.rad(12), 0, 0),
		Vector3.new(2.36, 3.4, 0.4), "black", "Fabric")
	B.sign(back, label, nil, { face = Enum.NormalId.Back, bg = "nasaBlue", titleColor = "white", ppu = 60 })
	B.part(g, "Headrest", scf * CFrame.new(0, 3.75, 1.85) * CFrame.Angles(math.rad(12), 0, 0),
		Vector3.new(1.4, 0.8, 0.5), "darkGray", "Fabric", DECOR)
	for _, ax in { -1.35, 1.35 } do
		B.part(g, "Armrest", scf * CFrame.new(ax, 0.6, 0.1), Vector3.new(0.3, 0.3, 2.2), "metalGray", "Metal", DECOR)
	end
	B.box(g, "Pedestal", x - 0.5, x + 0.5, Y(fy), Y(fy + 1.1), z - 0.5, z + 0.5, "metalGray", "Metal")
	prompt(seat, "Sit", label .. " seat", "Take seat", { dist = 7 })
end

-- área de trás: escotilha, placa, banheiro, estiva e bolsas de carga
local ihatch = B.part(cabin, "Inner_Hatch", wallCF(N / 2, 3.6, 0.18), Vector3.new(4.2, 6.8, 0.35), "darkGray", "Metal")
B.part(cabin, "Inner_Hatch_Ring", wallCF(N / 2, 3.6, 0.1), Vector3.new(5, 7.6, 0.2), "safety", "Metal", DECOR)
B.part(cabin, "Inner_Hatch_Window", wallCF(N / 2, 5.3, 0.38), Vector3.new(1.1, 1.1, 0.06), "space", "Glass", { collide = false, reflectance = 0.3 })
local exitSign = B.part(cabin, "Exit_Sign", wallCF(N / 2, 8.2, 0.06), Vector3.new(3.4, 0.9, 0.1), "space", "SmoothPlastic", DECOR)
B.sign(exitSign, "HATCH · EXIT", nil, { face = IN, titleColor = "#3CCB5A" })
local plaque = B.part(cabin, "Info_Plaque", wallCF(N / 2 - 1, 6, 0.06), Vector3.new(4.4, 2.6, 0.1), "space", "SmoothPlastic", DECOR)
B.sign(plaque, "ORION CREW MODULE",
	"Orion carries up to four astronauts on Artemis missions. Commander and pilot sit up front, facing three display units.",
	{ face = IN, accent = "orange", titleScale = 0.26 })

-- compartimento de higiene (a Orion tem um banheiro fechado)
local hyg = B.group(cabin, "Hygiene_Bay")
B.box(hyg, "Wall", -6.4, -6, Y(0), Y(7), RZ - 11, RZ - 6.4, "white", "SmoothPlastic")
B.box(hyg, "Wall", -11, -6, Y(0), Y(7), RZ - 6.4, RZ - 6, "white", "SmoothPlastic")
B.box(hyg, "Roof", -11, -6, Y(7), Y(7.3), RZ - 11, RZ - 6, "white", "SmoothPlastic")
local hdoor = B.box(hyg, "Door", -6.05, -5.95, Y(0.2), Y(6), RZ - 9.6, RZ - 7.4, "midGray", "SmoothPlastic", DECOR)
B.sign(hdoor, "HYGIENE BAY", nil, { face = Enum.NormalId.Right, bg = "midGray", titleColor = "space", ppu = 40 })

-- estiva lateral e bolsas de carga
for _, k in { 5, 11 } do
	local st = B.part(cabin, "Stowage_Lockers", wallCF(k, 3.2, 0.2), Vector3.new(5.4, 4.2, 0.4), "white", "SmoothPlastic")
	B.sign(st, "STOWAGE", "FOOD · WATER\nMEDICAL KIT", { face = IN, bg = "lightGray", titleColor = "nasaBlue", bodyColor = "darkGray", titleScale = 0.35 })
end
local cargo = B.group(cabin, "Cargo_Bags")
for i, b in { { -9.5, -7, 0, 2.2 }, { -9.3, -7.2, 2.2, 4.2 }, { -6.8, -4.6, 0, 1.8 } } do
	B.box(cargo, "Cargo_Bag", b[1], b[2], Y(b[3]), Y(b[4]), RZ + 6.2, RZ + 9, "white", "Fabric")
	B.box(cargo, "Strap", b[1] - 0.03, b[2] + 0.03, Y(b[3] + 0.4), Y(b[3] + 0.7), RZ + 6.17, RZ + 9.03, "nasaBlue", "Fabric", DECOR_NS)
end
-- corrimãos amarelos nas laterais
for _, k in { 3, 4, 12, 13 } do
	B.part(cabin, "Handrail", wallCF(k, 8, 0.45), Vector3.new(4.5, 0.25, 0.25), "safety", "Metal", DECOR)
end

-- teleportes da escotilha
local ENTRY = CFrame.lookAt(Vector3.new(-10.5, Y(3), RZ), Vector3.new(0, Y(3), RZ))
local EXIT = CFrame.lookAt(Vector3.new(-5, TOP + 3, RZ), Vector3.new(-17, TOP + 3, RZ))
-- destinos como peças de referência: a saída fica na White Room e acompanha o lançador
local entryPoint = B.part(cabin, "Entry_Point", ENTRY, Vector3.one, "white", "SmoothPlastic", HIDDEN)
local exitPoint = B.part(wr, "Exit_Point", EXIT, Vector3.one, "white", "SmoothPlastic", HIDDEN)
local function targetRef(p, part)
	local v = Instance.new("ObjectValue")
	v.Name = "TargetRef"
	v.Value = part
	v:SetAttribute("BuildPhase", 8)
	v.Parent = p
end
local hp = prompt(hatch, "Teleport", "Orion", "Board", { dist = 8 })
targetRef(hp, entryPoint)
hp:SetAttribute("FadeText", "Boarding Orion…")
local ip = prompt(ihatch, "Teleport", "Orion hatch", "Exit to the access arm", { dist = 9 })
targetRef(ip, exitPoint)
ip:SetAttribute("FadeText", "Leaving Orion…")

---------------------------------------------------------------------------------
-- 5. Scripts: CrewAccess (servidor) + CrewClient (cliente) + RemoteEvent CrewFade
---------------------------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local oldRe = RS:FindFirstChild("CrewFade")
if oldRe then oldRe:Destroy() end
local re = Instance.new("RemoteEvent")
re.Name = "CrewFade"
re:SetAttribute("BuildPhase", 8)
re.Parent = RS

-- Código em build/systems/ (sincronizado pelo Rojo ou baixado pelo HTTP)
lib.installSystemScript("server", "CrewAccess")
lib.installSystemScript("client", "CrewClient")

return "Fase 8 aplicada: vestiário, elevador com portas, braço de acesso, cabine ampliada da Orion + scripts CrewAccess e CrewClient"
