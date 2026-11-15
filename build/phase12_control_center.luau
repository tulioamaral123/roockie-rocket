--[[
	NASA Space Adventure — Fase 12: Launch Control Center e caminhos de pedestres
	(spec-v3, Etapa 5 — parte B; §3.5, §8, §10, §11)

	1. LaunchControlCenter — no caminho principal do visitante, entre o Corredor 1 e o Corredor 2
	   (no lugar do antigo museu, que foi para o leste da recepção; Fase 14). É montado nas
	   coordenadas originais (X −150..−95, Z 250..320) e transladado por LCC_SHIFT = (101, 0, −155)
	   para X −49..6, Z 95..165.
	   · Architecture: o visitante atravessa em linha reta pelo eixo X = 0: porta sul (automática)
	     → corredor de fundo → saguão → porta norte (automática) → Corredor 2 → VAB. A Firing Room
	     fica à esquerda, pelo vão do saguão. Janelas na face norte, letreiros, degraus e luzes.
	   · Consoles: 4 fileiras em degraus (Y 0, 1, 2, 3) com 8 estações cada, voltadas para +Z,
	     racks de comunicação no fundo e o Main_Console (FutureInteraction = "StartOperation",
	     peça Interface_Anchor) no degrau mais alto.
	   · MainScreens: telão principal e dois telões laterais acima das janelas, mais dois
	     diagramas nas paredes laterais. Telemetria fictícia e estática (sem scripts).
	2. Visitor_Paths (X ≤ −82): do patamar da saída de pedestres do VAB (X −85..−82, Z 295..303)
	   pelo passeio X −105..−97 até a área de observação (X −140..−95, Z 640..720), com
	   arquibancada coberta, guarda-corpos, lunetas e placas voltadas para a plataforma.

	Nenhuma sequência de lançamento, contagem, prompt ou script de missão nesta fase.
	Idempotente: remove tudo o que tem BuildPhase = 12 antes de reconstruir.
]]

local lib = ...
local B = lib.builder(12)
local C = lib.C

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–10 antes")
B.clear(Map)

-- A Fase 10 substitui a lateral oeste da Fase 1 ao abrir a saída de pedestres.
-- Reaplica o acabamento nos extremos, sem tocar no vão Z296..302 nem nas folhas.
local westSegments = Map.VABHangar.Structure:FindFirstChild("Left_Wall_Segments")
if westSegments then
	for _, name in { "Left_Wall_A", "Left_Wall_B", "Left_Wall_Lintel" } do
		local p = westSegments:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			local y0 = p.Position.Y - p.Size.Y / 2
			local z0 = p.Name == "Left_Wall_A" and 210 or p.Position.Z - p.Size.Z / 2
			local z1 = p.Name == "Left_Wall_B" and 320 or p.Position.Z + p.Size.Z / 2
			p.Size = Vector3.new(p.Size.X, 151.98 - y0, z1 - z0)
			p.CFrame = CFrame.new(p.Position.X, (y0 + 151.98) / 2, (z0 + z1) / 2)
		end
	end
end

local N = Enum.NormalId
local DECOR = { collide = false }
local DECOR_NS = { collide = false, shadow = false }

local function hex(c) return Color3.fromHex(C[c] or c) end

-- Tela com SurfaceGui de telemetria: título, linhas de texto e barras opcionais
local function screen(part, face, title, lines, o)
	o = o or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = o.ppu or 100
	gui.LightInfluence = 0
	gui.Brightness = o.brightness or 1.2
	gui.MaxDistance = o.maxDist or 90
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = hex(o.bg or "#06101E")
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local accent = hex(o.accent or "#3CCB5A")
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0.16, 0)
	bar.BackgroundColor3 = accent
	bar.BackgroundTransparency = 0.55
	bar.BorderSizePixel = 0
	bar.Parent = bg
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(0.04, 0.01)
	t.Size = UDim2.fromScale(0.92, 0.14)
	t.Text = title
	t.TextScaled = true
	t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = bg
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromScale(0.04, 0.2)
	body.Size = UDim2.fromScale(0.92, o.bars and 0.5 or 0.76)
	body.Text = table.concat(lines, "\n")
	body.TextScaled = true
	body.FontFace = Font.fromEnum(Enum.Font.Code)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = accent
	body.Parent = bg
	if o.bars then
		for i, v in o.bars do
			local f = Instance.new("Frame")
			f.Position = UDim2.fromScale(0.04 + (i - 1) * 0.92 / #o.bars, 0.92 - 0.2 * v)
			f.Size = UDim2.fromScale(0.92 / #o.bars - 0.02, 0.2 * v)
			f.BackgroundColor3 = accent
			f.BorderSizePixel = 0
			f.Parent = bg
		end
	end
	return gui
end

-- Retângulo simples dentro de um diagrama (coordenadas em escala 0..1)
local function rect(parent, x, y, w, h, color, transp)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = hex(color)
	f.BackgroundTransparency = transp or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end
local function label(parent, x, y, w, h, text, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromScale(x, y)
	l.Size = UDim2.fromScale(w, h)
	l.Text = text
	l.TextScaled = true
	l.FontFace = font or Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	l.TextColor3 = hex(color or "white")
	l.Parent = parent
	return l
end
local function canvas(part, face, ppu)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = ppu or 30
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.Parent = part
	return rect(gui, 0, 0, 1, 1, "#06101E")
end

-- Tampos e corpos com pontas arredondadas, dentro do envelope original.
-- Pontas 0,03 acima/abaixo do miolo: 0,01 ainda cintilava nas faces de baixo.
local function rounded(parent, name, x0, x1, y0, y1, z0, z1, color, material)
	local radius = (z1 - z0) / 2
	local p = B.box(parent, name, x0 + radius, x1 - radius, y0, y1, z0, z1, color, material)
	for _, x in { x0 + radius, x1 - radius } do
		B.cyl(parent, name .. "_End", x, (z0 + z1) / 2, y0 - 0.03, y1 + 0.03, radius * 2, color, material)
	end
	return p
end

-- A verga sobe 0,5 no centro; as cunhas nunca entram na altura livre original.
local function header(parent, name, x0, x1, y0, y1, z0, z1, color, material)
	B.box(parent, name, x0, x1, y0 + 0.5, y1, z0, z1, color, material)
	-- Chanfro na profundidade da parede: uma única cunha contínua sob o miolo.
	local alongX = x1 - x0 > z1 - z0
	B.part(parent, name .. "_Chamfer", CFrame.new((x0 + x1) / 2, y0 + 0.25, (z0 + z1) / 2)
		* CFrame.Angles(0, alongX and 0 or math.pi / 2, 0),
		Vector3.new(alongX and x1 - x0 or z1 - z0, 0.5, alongX and z1 - z0 or x1 - x0), color, material, nil, "Wedge")
end

local function autoDoor(parent, name, center, radius, leaves)
	local door = B.group(parent, name)
	door:SetAttribute("AutoDoor", true)
	door:SetAttribute("SensorCenter", center)
	door:SetAttribute("SensorRadius", radius)
	for _, L in leaves do
		local leaf = B.group(door, L.name)
		local panel = B.box(leaf, "Panel", L.x0, L.x1, 0, 9.8, L.z0, L.z1, "paleGray", "Metal")
		local alongX = (L.x1 - L.x0) > (L.z1 - L.z0)
		if alongX then
			B.box(leaf, "Window", L.x0 + 0.7, L.x1 - 0.7, 4.5, 8.5, L.z0 - 0.05, L.z1 + 0.05, "glass", "Glass", { transparency = 0.4, collide = false })
			-- recuado 0,03 nas pontas da folha: sem faces coplanares com o painel
			B.box(leaf, "Kick_Plate", L.x0 + 0.03, L.x1 - 0.03, 0, 0.8, L.z0 - 0.05, L.z1 + 0.05, "nasaBlue", "Metal", DECOR)
		else
			B.box(leaf, "Window", L.x0 - 0.05, L.x1 + 0.05, 4.5, 8.5, L.z0 + 0.7, L.z1 - 0.7, "glass", "Glass", { transparency = 0.4, collide = false })
			B.box(leaf, "Kick_Plate", L.x0 - 0.05, L.x1 + 0.05, 0, 0.8, L.z0 + 0.03, L.z1 - 0.03, "nasaBlue", "Metal", DECOR)
		end
		leaf.PrimaryPart = panel
		leaf:SetAttribute("OpenOffset", L.offset)
	end
	return door
end

---------------------------------------------------------------------------------
-- 1. Launch Control Center
---------------------------------------------------------------------------------
local LX0, LX1, LZ0, LZ1 = -150, -95, 250, 320
local WALL_TOP, ROOF_Y = 30, 28
local FX1 = -108 -- face interna da parede entre Firing Room e saguão (parede X −108..−107)
local DOOR_Z0, DOOR_Z1 = 296, 302 -- vão entre o saguão e a Firing Room
local NDX0, NDX1 = -104, -98 -- portas sul e norte (eixo de passagem do visitante)
local DH = 10

local LCC = B.group(Map, "LaunchControlCenter")
local Arch = B.group(LCC, "Architecture")
local Consoles = B.group(LCC, "Consoles")
local Screens = B.group(LCC, "MainScreens")

-- fundação e teto
B.box(Arch, "Foundation", LX0, LX1, -1, 0, LZ0, LZ1, "midGray", "Concrete")
B.box(Arch, "Roof", LX0 + 1, LX1 - 1, ROOF_Y, ROOF_Y + 1, LZ0 + 1, LZ1 - 1, "darkGray", "Concrete")
B.box(Arch, "Roof_Unit", -140, -128, ROOF_Y + 1, ROOF_Y + 4, 262, 272, "metalGray", "Metal", DECOR)
B.box(Arch, "Roof_Unit", -124, -114, ROOF_Y + 1, ROOF_Y + 3, 262, 270, "metalGray", "Metal", DECOR)

local walls = B.group(Arch, "Walls")
local EXT = "lightGray"
-- sul: porta de entrada (X −104..−98), alinhada com a porta norte. O visitante atravessa o LCC
-- em linha reta (porta sul → corredor de fundo → saguão → porta norte) a caminho do VAB.
B.box(walls, "South_Wall", LX0 + 0.5, NDX0 - 0.5, 0, WALL_TOP, LZ0, LZ0 + 1, EXT, "Concrete")
B.box(walls, "South_Wall", NDX1 + 0.5, LX1 + 1.5, -1, WALL_TOP, LZ0, LZ0 + 1, EXT, "Concrete")
header(walls, "South_Lintel", NDX0 - 0.5, NDX1 + 0.5, DH, WALL_TOP, LZ0, LZ0 + 1, EXT, "Concrete")
-- oeste e leste (inteiras; a antiga porta leste foi fechada)
B.box(walls, "West_Wall", LX0, LX0 + 1, 0, WALL_TOP - 0.02, LZ0 + 0.5, LZ1 - 0.5, EXT, "Concrete")
B.box(walls, "East_Wall", LX1 - 1, LX1, 0, WALL_TOP, LZ0 + 1, LZ1 - 1, EXT, "Concrete")
-- norte: Firing Room com faixa de janelas (Y 4..14) voltada para a plataforma
-- Low/High terminam em FX1: o trecho FX1..FX1+1 é só da North_Wall_Lobby (sem sobreposição coplanar).
B.box(walls, "North_Wall_Low", LX0 + 0.5, FX1, 0, 4, LZ1 - 1, LZ1, EXT, "Concrete")
B.box(walls, "North_Wall_High", LX0 + 0.5, FX1, 14, WALL_TOP, LZ1 - 1, LZ1, EXT, "Concrete")
-- O vidro termina no Link_Return (X −110); jamba e retorno são opacos de face a face.
B.box(walls, "North_Window", LX0 + 1, FX1 - 2, 4, 14, LZ1 - 1, LZ1, "glass", "Glass", { transparency = 0.55 })
B.box(walls, "Window_Jamb", LX0 + 0.5, LX0 + 1, 4, 14, LZ1 - 0.5, LZ1, EXT, "Concrete")
B.box(walls, "Window_Jamb", FX1 - 1, FX1, 4, 14, LZ1 - 1, LZ1, EXT, "Concrete")
-- Último montante coincide com a parede esquerda da ligação C2 (X mundo −9..−8).
-- Assim a junta toca uma peça opaca em Z165, sem o vão de 0,3 do vidro recuado.
for _, x in { -142, -136, -130, -124, -118, -109.5 } do
	if x == -109.5 then
		B.box(walls, "Link_Return", x - 0.5, x + 0.5, 4, 14, LZ1 - 1, LZ1, "darkGray", "Metal")
	else
		B.cyl(walls, "Mullion", x, LZ1 - 0.5, 4, 14, 0.5, "darkGray", "Metal")
	end
end
-- norte: saguão, com a porta norte (X −104..−98)
B.box(walls, "North_Wall_Lobby", FX1, NDX0 - 0.5, 0, WALL_TOP, LZ1 - 1, LZ1, EXT, "Concrete")
B.box(walls, "North_Wall_Lobby", NDX1 + 0.5, LX1 + 2.5, -1, WALL_TOP, LZ1 - 1, LZ1, EXT, "Concrete")
header(walls, "North_Lintel", NDX0 - 0.5, NDX1 + 0.5, DH, WALL_TOP, LZ1 - 1, LZ1, EXT, "Concrete")
-- Os cantos dos retornos leste ficam em X mundo 7,5/8,5; a parede leste continua X 5..6.
for _, c in { { LX0 + 0.5, LZ0 + 0.5 }, { LX0 + 0.5, LZ1 - 0.5 },
	{ LX1 + 1.5, LZ0 + 0.5 }, { LX1 + 2.5, LZ1 - 0.5 } } do
	B.cyl(walls, "Rounded_Corner", c[1], c[2], -1.02, WALL_TOP + 0.02, 1, EXT, "Concrete")
end
for _, z in { LZ0 + 0.5, LZ1 - 0.5 } do
	for _, x in { NDX0 - 0.5, NDX1 + 0.5 } do
		B.cyl(walls, "Door_Jamb", x, z, 0, DH + 0.02, 1, EXT, "Concrete")
	end
end
-- faixa azul da fachada
B.box(walls, "Facade_Band", LX1, LX1 + 0.1, 24, 26, LZ0 + 1, LZ1 - 1, "nasaBlue", "SmoothPlastic", DECOR)
B.box(walls, "Facade_Band", LX0, LX1, 24, 26, LZ1, LZ1 + 0.1, "nasaBlue", "SmoothPlastic", DECOR)
-- interna: Firing Room ↔ saguão (vão aberto Z 296..302) e fundo do saguão
local INNER = "#2B313B"
B.box(walls, "Inner_Wall", FX1, FX1 + 1, 0, ROOF_Y, LZ0 + 1, DOOR_Z0 - 0.5, INNER, "SmoothPlastic")
B.box(walls, "Inner_Wall", FX1, FX1 + 1, 0, ROOF_Y, DOOR_Z1 + 0.5, LZ1 - 1, INNER, "SmoothPlastic")
header(walls, "Inner_Lintel", FX1, FX1 + 1, DH, ROOF_Y, DOOR_Z0 - 0.5, DOOR_Z1 + 0.5, INNER, "SmoothPlastic")
for _, z in { DOOR_Z0 - 0.5, DOOR_Z1 + 0.5 } do
	B.cyl(walls, "Firing_Room_Jamb", FX1 + 0.5, z, 0, DH + 0.02, 1, INNER, "SmoothPlastic")
end
-- fundo do saguão (Z 288..289) com passagem para o corredor de fundo, que leva à porta sul
B.box(walls, "Lobby_Back_Wall", FX1 + 1, NDX0 - 0.5, 0, ROOF_Y, 288, 289, "paleGray", "SmoothPlastic")
B.box(walls, "Lobby_Back_Wall", NDX1 + 0.5, LX1 - 1, 0, ROOF_Y, 288, 289, "paleGray", "SmoothPlastic")
header(walls, "Lobby_Back_Lintel", NDX0 - 0.5, NDX1 + 0.5, DH, ROOF_Y, 288, 289, "paleGray", "SmoothPlastic")
for _, x in { NDX0 - 0.5, NDX1 + 0.5 } do
	B.cyl(walls, "Lobby_Jamb", x, 288.5, 0, DH + 0.02, 1, "paleGray", "SmoothPlastic")
end
local frSign = B.box(walls, "Firing_Room_Sign", FX1 + 1, FX1 + 1.1, DH + 0.6, DH + 2.4, DOOR_Z0 - 1, DOOR_Z1 + 1, "space", "SmoothPlastic", DECOR)
B.sign(frSign, "FIRING ROOM 1", nil, { face = N.Right, titleColor = "lightBlue" })

-- revestimento interno da Firing Room (paredes escuras)
B.box(walls, "Interior_Lining", LX0 + 1, LX0 + 1.1, 0, 14, LZ0 + 1, LZ1 - 1, INNER, "SmoothPlastic", DECOR)
B.box(walls, "Interior_Lining", LX0 + 1, LX0 + 1.1, 14, ROOF_Y, LZ0 + 1, LZ1 - 1.1, INNER, "SmoothPlastic", DECOR)
B.box(walls, "Interior_Lining", LX0 + 1, FX1, 0, ROOF_Y, LZ0 + 1, LZ0 + 1.1, INNER, "SmoothPlastic", DECOR)
B.box(walls, "Interior_Lining", LX0 + 1, FX1, 14, ROOF_Y, LZ1 - 1.1, LZ1 - 1, INNER, "SmoothPlastic", DECOR)

-- Rodapés da Firing Room e do saguão; nenhuma peça atravessa um vão.
local skirts = B.group(walls, "Baseboards")
for _, t in { { LZ0 + 1.22, 277, 3 }, { 277, 286, 2 }, { 286, 295, 1 }, { 295, LZ1 - 1.12, 0 } } do
	local y = t[3] == 0 and 0.05 or t[3]
	B.box(skirts, "West", LX0 + 1.1, LX0 + 1.22, y, y + 0.45, t[1], t[2], INNER, "Metal", DECOR)
end
B.box(skirts, "South_Firing", LX0 + 1.1, FX1, 3, 3.45, LZ0 + 1.1, LZ0 + 1.22, INNER, "Metal", DECOR)
B.box(skirts, "North_Firing", LX0 + 1.1, FX1, 0.05, 0.5, LZ1 - 1.12, LZ1 - 1, INNER, "Metal", DECOR)
for _, t in { { LZ0 + 1.22, 277, 3 }, { 277, 286, 2 }, { 286, 295, 1 }, { 295, DOOR_Z0, 0 }, { DOOR_Z1, LZ1 - 1.12, 0 } } do
	local y = t[3] == 0 and 0.05 or t[3]
	B.box(skirts, "Firing_East", FX1 - 0.12, FX1, y, y + 0.45, t[1], t[2], INNER, "Metal", DECOR)
end
B.box(skirts, "Lobby_East", LX1 - 1.12, LX1 - 1, 0.05, 0.5, LZ0 + 1.12, LZ1 - 1.12, "midGray", "Metal", DECOR)
for _, r in { { LZ0 + 1.12, DOOR_Z0 }, { DOOR_Z1, LZ1 - 1.12 } } do
	B.box(skirts, "Lobby_West", FX1 + 1, FX1 + 1.12, 0.05, 0.5, r[1], r[2], "midGray", "Metal", DECOR)
end
for _, z in { LZ0 + 1, LZ1 - 1.12, 287.88, 289 } do
	for _, r in { { FX1 + 1.12, NDX0 }, { NDX1, LX1 - 1.12 } } do
		B.box(skirts, "Lobby_Return", r[1], r[2], 0.05, 0.5, z, z + 0.12, "midGray", "Metal", DECOR)
	end
end

-- degraus da Firing Room (fileiras em Y 0, 1, 2, 3; sobem em direção ao fundo, Z 251)
local floorG = B.group(Arch, "Tiers")
local CARPET = "#3A4458"
B.box(floorG, "Carpet_Front", LX0 + 1, FX1, 0, 0.05, 295, LZ1 - 1, CARPET, "Fabric", DECOR)
local TIERS = { { 1, 295 }, { 2, 286 }, { 3, 277 } }
for _, t in TIERS do
	B.box(floorG, "Tier_" .. t[1], LX0 + 1, FX1, t[1] - 1, t[1], LZ0 + 1, t[2], CARPET, "Fabric")
	B.box(floorG, "Tier_Edge", LX0 + 1, FX1, t[1] - 0.15, t[1] + 0.05, t[2] - 0.3, t[2] + 0.05, "safety", "SmoothPlastic", DECOR_NS)
end
-- saguão
B.box(floorG, "Lobby_Floor", FX1 + 1, LX1 - 1, 0, 0.05, 289, LZ1 - 1, "paleGray", "Marble", DECOR)
B.box(floorG, "Entry_Hall_Floor", FX1 + 1, LX1 - 1, 0, 0.05, LZ0 + 1, 288, "paleGray", "Marble", DECOR)

-- luzes internas (sem sombra): 4 na Firing Room, 1 no saguão
local lightsG = B.group(Arch, "Lighting")
for _, p in { { -140, 270 }, { -118, 270 }, { -140, 298 }, { -118, 298 } } do
	local lp = B.box(lightsG, "Ceiling_Light", p[1] - 4, p[1] + 4, ROOF_Y - 0.1, ROOF_Y, p[2] - 3, p[2] + 3, "#FFF4E0", "Neon", DECOR_NS)
	B.light(lp, "SurfaceLight", { Face = N.Bottom, Range = 26, Brightness = 0.9, Angle = 110, Shadows = false, Color = Color3.fromRGB(255, 236, 210) })
end
do
	local lp = B.box(lightsG, "Lobby_Light", -104, -98, ROOF_Y - 0.1, ROOF_Y, 300, 308, "white", "Neon", DECOR_NS)
	B.light(lp, "SurfaceLight", { Face = N.Bottom, Range = 28, Brightness = 1.6, Angle = 120, Shadows = false })
	local hp = B.box(lightsG, "Entry_Hall_Light", -104, -98, ROOF_Y - 0.1, ROOF_Y, 264, 276, "white", "Neon", DECOR_NS)
	B.light(hp, "SurfaceLight", { Face = N.Bottom, Range = 30, Brightness = 1.7, Angle = 120, Shadows = false })
	-- forro claro no saguão (o teto de concreto escuro deixava o poço de 28 de altura preto)
	B.box(lightsG, "Lobby_Ceiling", FX1 + 1, LX1 - 1, ROOF_Y - 0.05, ROOF_Y, LZ0 + 1, LZ1 - 1, "paleGray", "SmoothPlastic", DECOR_NS)
end

-- portas automáticas
local doorsG = B.group(Arch, "Doors")
local NDM = (NDX0 + NDX1) / 2
autoDoor(doorsG, "South_AutoDoor", Vector3.new(NDM, 3, LZ0 + 0.5), 9, {
	{ name = "Leaf_L", x0 = NDX0, x1 = NDM, z0 = LZ0 + 0.3, z1 = LZ0 + 0.7, offset = Vector3.new(-3, 0, 0) },
	{ name = "Leaf_R", x0 = NDM, x1 = NDX1, z0 = LZ0 + 0.3, z1 = LZ0 + 0.7, offset = Vector3.new(3, 0, 0) },
})
autoDoor(doorsG, "North_AutoDoor", Vector3.new(NDM, 3, LZ1 - 0.5), 9, {
	{ name = "Leaf_L", x0 = NDX0, x1 = NDM, z0 = LZ1 - 0.7, z1 = LZ1 - 0.3, offset = Vector3.new(-3, 0, 0) },
	{ name = "Leaf_R", x0 = NDM, x1 = NDX1, z0 = LZ1 - 0.7, z1 = LZ1 - 0.3, offset = Vector3.new(3, 0, 0) },
})

-- marquise e letreiros externos
local ext = B.group(Arch, "Exterior")
local southSign = B.box(ext, "LCC_Sign_South", NDX0 - 1.5, NDX1 + 1.5, DH + 0.2, DH + 1.8, LZ0 - 0.15, LZ0 - 0.05, "nasaBlue", "SmoothPlastic", DECOR)
B.sign(southSign, "LAUNCH CONTROL CENTER", nil, { face = N.Front, bg = "nasaBlue", titleColor = "white", ppu = 40 })
local eastSign = B.box(ext, "LCC_Sign_East", LX1, LX1 + 0.1, 14, 20, 284, 314, "nasaBlue", "SmoothPlastic", DECOR)
B.sign(eastSign, "LAUNCH CONTROL CENTER", nil, { face = N.Right, bg = "nasaBlue", titleColor = "white", ppu = 20 })
local northSign = B.box(ext, "LCC_Sign_North", -120, -96, 15, 20, LZ1, LZ1 + 0.1, "nasaBlue", "SmoothPlastic", DECOR)
B.sign(northSign, "LAUNCH CONTROL CENTER", nil, { face = N.Back, bg = "nasaBlue", titleColor = "white", ppu = 20 })

-- Placas na parede leste, fora dos futuros vãos do museu (Z mundo 113..125 e 151..163).
local lobbyInfo = B.box(walls, "Lobby_Info", -96.1, -96, 3, 8, 255, 265, "space", "SmoothPlastic", DECOR)
B.sign(lobbyInfo, "LAUNCH CONTROL CENTER",
	"Launch teams in the Firing Rooms monitor the rocket, the pad and the weather before every launch. Firing Room 1 is on your left.",
	{ face = N.Left, accent = "nasaBlue", titleScale = 0.22, maxBody = 30 })
local lobbyDir = B.box(walls, "Lobby_Directions", -96.1, -96, 6, 8.5, 291, 297, "space", "SmoothPlastic", DECOR)
B.sign(lobbyDir, "SLS HANGAR (VAB)  ↑", "North exit · industrial corridor", { face = N.Left, accent = "safety", titleScale = 0.4 })

---------------------------------------------------------------------------------
-- 1b. Consoles (4 fileiras × 8 estações, voltadas para +Z)
---------------------------------------------------------------------------------
local TELEMETRY = {
	{ "POWER", { "BUS A  28.1 V", "BUS B  28.0 V", "STATUS NOMINAL" }, "#3CCB5A" },
	{ "COMM", { "S-BAND  LOCK", "UHF     LOCK", "NET     GOOD" }, "#3CCB5A" },
	{ "LOX TANK", { "LEVEL  98.7 %", "PRESS  OK", "TEMP   -297 F" }, "#8ECDFB" },
	{ "LH2 TANK", { "LEVEL  99.1 %", "PRESS  OK", "TEMP   -423 F" }, "#8ECDFB" },
	{ "GUIDANCE", { "IMU    ALIGNED", "NAV    READY", "GO" }, "#3CCB5A" },
	{ "WEATHER", { "WIND   9 KT", "CEIL   OK", "LIGHTNING NONE" }, "#E5B52E" },
	{ "RANGE", { "AIRSPACE CLEAR", "SEA    CLEAR", "SAFETY GO" }, "#3CCB5A" },
	{ "PAD 39B", { "DELUGE  ARMED", "UMBILICALS ON", "ML     SECURED" }, "#E5B52E" },
	{ "ORION", { "CABIN  14.7 PSI", "O2     NOMINAL", "CREW   READY" }, "#8ECDFB" },
	{ "BOOSTERS", { "SRB L  READY", "SRB R  READY", "APU    STBY" }, "#E5B52E" },
}
local GROUPS = { { -144, -130 }, { -127, -113 } } -- dois blocos de 4 estações, corredor central X −130..−127
local ROWS = {
	{ name = "Row_1", y = 0, z0 = 300 },
	{ name = "Row_2", y = 1, z0 = 291 },
	{ name = "Row_3", y = 2, z0 = 282 },
	{ name = "Row_4", y = 3, z0 = 273 },
}
local CONSOLE = "#B8BEC6"
local tIndex = 0
local function station(parent, x0, x1, y, z0, z1)
	-- dois monitores na borda de trás, teclado e cadeira
	local w = x1 - x0
	for k = 0, 1 do
		local mx0 = x0 + 0.2 + k * (w - 0.4) / 2
		local mx1 = mx0 + (w - 0.4) / 2 - 0.1
		local mon = B.box(parent, "Monitor", mx0, mx1, y + 2.85, y + 3.85, z1 - 0.55, z1 - 0.4, "black", "SmoothPlastic", DECOR)
		tIndex += 1
		local T = TELEMETRY[(tIndex - 1) % #TELEMETRY + 1]
		screen(mon, N.Front, T[1], T[2], { accent = T[3], ppu = 90, maxDist = 60 })
	end
	B.box(parent, "Keyboard", x0 + 0.8, x1 - 0.8, y + 2.8, y + 2.88, z0 - 0.2, z0 + 0.4, "darkGray", "SmoothPlastic", DECOR)
	-- cadeira
	local cx = (x0 + x1) / 2
	local cz = z0 - 1.9
	local ch = B.group(parent, "Chair")
	B.cyl(ch, "Base", cx, cz, y, y + 0.2, 1.4, "black", "Metal", DECOR)
	B.cyl(ch, "Post", cx, cz, y + 0.2, y + 1.5, 0.25, "metalGray", "Metal", DECOR)
	B.cyl(ch, "Seat", cx, cz, y + 1.5, y + 1.8, 1.6, "nasaBlue", "Fabric")
	B.box(ch, "Back", cx - 0.75, cx + 0.75, y + 1.8, y + 3.6, cz - 1, cz - 0.8, "nasaBlue", "Fabric", DECOR)
end

for _, R in ROWS do
	local row = B.group(Consoles, R.name)
	local z0, z1 = R.z0, R.z0 + 2
	for _, g in GROUPS do
		rounded(row, "Console_Body", g[1], g[2], R.y, R.y + 2.6, z0, z1, CONSOLE, "SmoothPlastic")
		rounded(row, "Console_Top", g[1] - 0.1, g[2] + 0.1, R.y + 2.6, R.y + 2.8, z0 - 0.4, z1 + 0.1, "#3B4048", "SmoothPlastic")
		B.box(row, "Console_Stripe", g[1] + 1.25, g[2] - 1.25, R.y + 2.2, R.y + 2.4, z0 - 0.05, z0, "nasaBlue", "SmoothPlastic", DECOR)
		local w = (g[2] - g[1]) / 4
		for i = 0, 3 do
			local st = B.group(row, "Station")
			st:SetAttribute("FutureInteraction", "Station")
			station(st, g[1] + i * w, g[1] + (i + 1) * w, R.y, z0, z1)
		end
	end
end

-- console principal (diretor de lançamento), no degrau mais alto
do
	local Y, MZ0, MZ1, MX0, MX1 = 3, 260, 263, -134, -123
	local mc = B.group(Consoles, "Main_Console")
	mc:SetAttribute("FutureInteraction", "StartOperation")
	local desk = B.part(mc, "Desk", CFrame.new((MX0 + MX1) / 2, Y + 1.3, (MZ0 + MZ1) / 2) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(2.6, MX1 - MX0, MZ1 - MZ0), "#D5D9DE", "SmoothPlastic", nil, "Cylinder")
	rounded(mc, "Desk_Top", MX0 - 0.2, MX1 + 0.2, Y + 2.6, Y + 2.8, MZ0 - 0.5, MZ1 + 0.1, "#2A2E35", "SmoothPlastic")
	B.box(mc, "Desk_Stripe", MX0 + 1.8, MX1 - 1.8, Y + 2.1, Y + 2.4, MZ0 - 0.05, MZ0, "red", "SmoothPlastic", DECOR)
	mc.PrimaryPart = desk
	local MON = {
		{ "COUNTDOWN", { "T-  00:00:00", "STATUS  HOLD", "AWAITING START" }, "#E5B52E" },
		{ "LAUNCH STATUS", { "POWER     GO", "COMM      GO", "VEHICLE   GO", "PAD       GO" }, "#3CCB5A" },
		{ "RANGE / WX", { "RANGE     GO", "WEATHER   GO", "AREA    CLEAR" }, "#8ECDFB" },
	}
	for i, M in MON do
		local x0 = MX0 + 0.4 + (i - 1) * 3.5
		local mon = B.box(mc, "Monitor", x0, x0 + 3.2, Y + 2.9, Y + 4.9, MZ1 - 0.7, MZ1 - 0.5, "black", "SmoothPlastic", DECOR)
		screen(mon, N.Front, M[1], M[2], { accent = M[3], ppu = 70 })
	end
	-- espaço reservado para a interface futura de início de operação
	-- girada 90° em Y para que o texto da face Top fique legível para quem está sentado (olhando +Z)
	local anchor = B.part(mc, "Interface_Anchor", CFrame.new(-128.5, Y + 2.85, MZ0 + 0.6) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(1.8, 0.1, 4), "#0B1A30", "Glass", DECOR_NS)
	anchor:SetAttribute("FutureInteraction", "StartOperation")
	local ag = Instance.new("SurfaceGui")
	ag.Face = N.Top
	ag.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	ag.PixelsPerStud = 60
	ag.LightInfluence = 0
	ag.Parent = anchor
	rect(ag, 0, 0, 1, 1, "#0B1A30")
	label(rect(ag, 0.05, 0.1, 0.9, 0.8, "#153D72", 0.3), 0.05, 0.25, 0.9, 0.5, "START OPERATION · RESERVED", "lightBlue")
	local ch = B.group(mc, "Chair")
	B.cyl(ch, "Base", -128.5, 258.2, Y, Y + 0.2, 1.6, "black", "Metal", DECOR)
	B.cyl(ch, "Post", -128.5, 258.2, Y + 0.2, Y + 1.5, 0.3, "metalGray", "Metal", DECOR)
	B.cyl(ch, "Seat", -128.5, 258.2, Y + 1.5, Y + 1.85, 1.8, "red", "Fabric")
	B.box(ch, "Back", -129.3, -127.7, Y + 1.85, Y + 4.2, 256.9, 257.2, "red", "Fabric", DECOR)
	local tag = B.box(mc, "Name_Plate", -131, -126, Y + 1.2, Y + 2, MZ1, MZ1 + 0.05, "space", "SmoothPlastic", DECOR)
	B.sign(tag, "LAUNCH DIRECTOR", nil, { face = N.Back, titleColor = "safety" })
end

-- racks de comunicação no fundo (degrau Y 3)
do
	local racks = B.group(Consoles, "Comms_Racks")
	for _, x in { -148, -145, -142, -115, -112 } do
		-- 0,02 à frente do revestimento: o fundo não coincide com o do rodapé South_Firing
		B.box(racks, "Rack", x, x + 2.6, 3, 10, 251.12, 253.5, "#24282E", "Metal")
		for j = 0, 4 do
			local col = (j % 3 == 0) and "#3CCB5A" or ((j % 3 == 1) and "#E5B52E" or "#8ECDFB")
			B.box(racks, "Rack_Led", x + 0.4, x + 2.2, 4 + j * 1.2, 4.15 + j * 1.2, 253.5, 253.55, col, "Neon", DECOR_NS)
		end
	end
	local ant = B.box(racks, "Comms_Panel", -138, -132, 5, 9, 251.1, 251.3, "space", "SmoothPlastic", DECOR)
	screen(ant, N.Back, "COMMUNICATIONS", { "LOOP 1  LAUNCH CONDUCTOR", "LOOP 2  PAD OPS", "LOOP 3  RANGE", "LOOP 4  WEATHER" }, { accent = "#8ECDFB", ppu = 40 })
end

---------------------------------------------------------------------------------
-- 1c. Telões e diagramas
---------------------------------------------------------------------------------
local SZ0, SZ1 = LZ1 - 1.5, LZ1 - 1.1 -- telões presos à parede norte, acima das janelas
do
	local main = B.box(Screens, "Main_Screen", -138, -120, 15, 25.5, SZ0, SZ1, "black", "SmoothPlastic", DECOR)
	local f = canvas(main, N.Front, 24)
	rect(f, 0, 0, 1, 0.12, "#244B70")
	label(f, 0.02, 0.01, 0.96, 0.1, "LAUNCH COMPLEX 39B  ·  SLS / ORION  ·  SIMULATION", "white")
	label(f, 0.05, 0.16, 0.9, 0.22, "T-  00:00:00", "#E5B52E", Font.fromEnum(Enum.Font.Code))
	label(f, 0.05, 0.38, 0.9, 0.07, "COUNT STATUS: HOLD  ·  AWAITING LAUNCH DIRECTOR", "#E5B52E", Font.fromEnum(Enum.Font.Code))
	local items = { "POWER", "COMM", "VEHICLE", "PAD", "RANGE", "WEATHER" }
	for i, s in items do
		local col = (i - 1) % 3
		local rowi = math.floor((i - 1) / 3)
		local cell = rect(f, 0.05 + col * 0.31, 0.52 + rowi * 0.22, 0.28, 0.18, "#0E2A1A")
		label(cell, 0.05, 0.08, 0.9, 0.45, s, "white")
		label(cell, 0.05, 0.55, 0.9, 0.38, "NOMINAL", "#3CCB5A", Font.fromEnum(Enum.Font.Code))
	end
	-- telão lateral esquerdo: trajetória
	local left = B.box(Screens, "Side_Screen_Trajectory", LX0 + 1.1, -139.5, 16, 24.5, SZ0, SZ1, "black", "SmoothPlastic", DECOR)
	local lf = canvas(left, N.Front, 24)
	label(lf, 0.04, 0.02, 0.92, 0.1, "ASCENT TRAJECTORY", "#8ECDFB")
	rect(lf, 0.08, 0.88, 0.86, 0.01, "#397EC4")
	rect(lf, 0.08, 0.15, 0.01, 0.74, "#397EC4")
	for i = 0, 11 do
		local t = i / 11
		rect(lf, 0.1 + t * 0.8, 0.85 - (t ^ 0.6) * 0.62, 0.025, 0.025, "#E5B52E")
	end
	label(lf, 0.1, 0.9, 0.8, 0.08, "ALTITUDE vs DOWNRANGE (ILLUSTRATIVE)", "#AAB3BB", Font.fromEnum(Enum.Font.Code))
	-- telão lateral direito: clima e área
	local right = B.box(Screens, "Side_Screen_Weather", -117.5, FX1, 16, 24.5, SZ0, SZ1, "black", "SmoothPlastic", DECOR)
	local rf = canvas(right, N.Front, 24)
	label(rf, 0.04, 0.02, 0.92, 0.1, "WEATHER · RANGE", "#8ECDFB")
	local wx = { { "WIND", "9 KT  E" }, { "CEILING", "6000 FT" }, { "VISIBILITY", "7 MI" }, { "LIGHTNING", "NONE" }, { "UPPER WINDS", "GO" }, { "RANGE", "CLEAR" } }
	for i, w in wx do
		local y = 0.15 + (i - 1) * 0.135
		label(rf, 0.05, y, 0.5, 0.1, w[1], "white", Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)).TextXAlignment = Enum.TextXAlignment.Left
		label(rf, 0.55, y, 0.4, 0.1, w[2], "#3CCB5A", Font.fromEnum(Enum.Font.Code)).TextXAlignment = Enum.TextXAlignment.Right
	end
	-- moldura dos telões
	B.box(Screens, "Screen_Frame", LX0 + 1.1, -108, 14.4, 15, SZ0, SZ1, "darkGray", "Metal", DECOR)
	B.box(Screens, "Screen_Frame", LX0 + 1.1, -108, 25.5, 26.1, SZ0, SZ1, "darkGray", "Metal", DECOR)
end

-- diagramas nas paredes laterais
do
	-- parede oeste (voltado para +X): mapa do complexo
	local mapP = B.box(Screens, "Diagram_Complex_Map", LX0 + 1.1, LX0 + 1.3, 6, 16, 268, 288, "space", "SmoothPlastic", DECOR)
	local f = canvas(mapP, N.Right, 20)
	label(f, 0.04, 0.02, 0.92, 0.1, "LAUNCH COMPLEX 39 · SITE MAP", "#8ECDFB")
	-- esquemático com o norte (+Z) para cima: VAB embaixo, plataforma no alto, LCC e observação a oeste
	rect(f, 0.3, 0.7, 0.4, 0.2, "#AAB3BB") label(f, 0.3, 0.74, 0.4, 0.1, "VAB", "black")
	rect(f, 0.44, 0.22, 0.12, 0.48, "#B94C2B", 0.2) label(f, 0.38, 0.42, 0.24, 0.07, "CRAWLERWAY", "white")
	rect(f, 0.38, 0.12, 0.24, 0.12, "#397EC4") label(f, 0.38, 0.14, 0.24, 0.08, "PAD 39B", "white")
	rect(f, 0.1, 0.68, 0.14, 0.14, "#244B70") label(f, 0.07, 0.84, 0.2, 0.07, "LCC (YOU)", "#E5B52E")
	rect(f, 0.1, 0.14, 0.14, 0.12, "#3CCB5A", 0.3) label(f, 0.04, 0.27, 0.26, 0.07, "OBSERVATION", "#3CCB5A")
	-- parede leste da Firing Room (voltado para −X): diagrama do foguete
	local sls = B.box(Screens, "Diagram_SLS", FX1 - 0.2, FX1, 6, 18, 266, 282, "space", "SmoothPlastic", DECOR)
	local g = canvas(sls, N.Left, 20)
	label(g, 0.04, 0.02, 0.92, 0.08, "SLS BLOCK 1 · VEHICLE DIAGRAM", "#8ECDFB")
	rect(g, 0.44, 0.24, 0.12, 0.66, "#D9822B") label(g, 0.58, 0.5, 0.38, 0.06, "CORE STAGE", "white")
	rect(g, 0.33, 0.34, 0.08, 0.56, "#FFFFFF") rect(g, 0.59, 0.34, 0.08, 0.56, "#FFFFFF")
	label(g, 0.02, 0.6, 0.3, 0.06, "BOOSTERS", "white")
	rect(g, 0.46, 0.15, 0.08, 0.09, "#E7E9EA") label(g, 0.58, 0.16, 0.38, 0.06, "ORION", "white")
	rect(g, 0.48, 0.1, 0.04, 0.05, "#D33D32") label(g, 0.58, 0.09, 0.38, 0.06, "ABORT SYSTEM", "white")
	rect(g, 0.44, 0.9, 0.12, 0.04, "#555B60") label(g, 0.58, 0.88, 0.38, 0.06, "RS-25 ENGINES", "white")
end

-- O LCC é montado nas coordenadas originais acima e transladado para o lugar do antigo museu,
-- entre o Corredor 1 e o Corredor 2: X −49..6, Z 95..165, portas sul e norte no eixo X = 0.
local LCC_SHIFT = Vector3.new(101, 0, -155)
LCC:PivotTo(LCC:GetPivot() + LCC_SHIFT)
for _, d in LCC:GetDescendants() do
	if d:GetAttribute("AutoDoor") then
		d:SetAttribute("SensorCenter", d:GetAttribute("SensorCenter") + LCC_SHIFT)
	end
end

---------------------------------------------------------------------------------
-- 2. Caminhos de pedestres (Visitor_Paths)
---------------------------------------------------------------------------------
local VP = B.group(Map, "Visitor_Paths")
local WALK = "#C9C4B8"
local CURB = "#8F949A"

-- 2a. Patamar da saída do VAB → início do passeio (o LCC agora fica no caminho principal)
local p1 = B.group(VP, "VAB_Exit_Link")
B.box(p1, "Walkway_Connector", -85, -82, -1, 0, 295, 303, WALK, "Concrete") -- encosta no patamar (X −82)
B.box(p1, "Link", -97, -85, -1, 0, 295, 303, WALK, "Concrete")
-- 2b. Passeio até a área de observação (X −105..−97)
local p3 = B.group(VP, "Walk_to_Observation")
local PX0, PX1, PZ0, PZ1 = -105, -97, 295, 640
B.box(p3, "Walkway", PX0, PX1, -1, 0, PZ0, PZ1, WALK, "Concrete")
B.box(p3, "Curb", PX0 - 0.5, PX0, -1, 0.25, PZ0, PZ1, CURB, "Concrete", DECOR)
-- meio-fio leste começa depois da junção com o VAB_Exit_Link (Z 295..303), sem cruzar o caminho
B.box(p3, "Curb", PX1, PX1 + 0.5, -1, 0.25, 303, PZ1, CURB, "Concrete", DECOR)
for z = PZ0 + 20, PZ1 - 10, 20 do
	B.box(p3, "Expansion_Joint", PX0, PX1, 0, 0.05, z - 0.1, z + 0.1, "#9A958A", "SmoothPlastic", DECOR_NS)
end

-- postes de luz (lado oeste do passeio; poucas luzes, sem sombra)
local lamps = B.group(VP, "Lamp_Posts")
local function lamp(x, z, withLight, base)
	local L = B.group(lamps, "Lamp_Post")
	B.cyl(L, "Base", x, z, base or -1, 0.4, 1, "darkGray", "Metal")
	B.cyl(L, "Pole", x, z, 0.4, 12, 0.4, "darkGray", "Metal", DECOR)
	B.box(L, "Arm", x, x + 2, 11.7, 12, z - 0.15, z + 0.15, "darkGray", "Metal", DECOR)
	local head = B.box(L, "Head", x + 1.4, x + 2.6, 11.4, 11.7, z - 0.5, z + 0.5, "#FFF4E0", "Neon", DECOR_NS)
	if withLight then
		B.light(head, "PointLight", { Range = 18, Brightness = 0.9, Shadows = false, Color = Color3.fromRGB(255, 236, 205) })
	end
end
lamp(-86.5, 290, true, 0)
for z = 380, 620, 60 do lamp(PX0 - 1.5, z, true) end -- 5 postes: Z 380, 440, 500, 560, 620

-- sinalização de direção
local signs = B.group(VP, "Wayfinding")
-- axis "X": painel no plano YZ (faces Right/Left); axis "Z": plano XY (faces Front/Back)
-- posts: deslocamentos {dx, dz} dos postes em relação ao centro (padrão: um poste no centro)
local function signPost(name, x, z, axis, panels, base, posts)
	local s = B.group(signs, name)
	for _, o in posts or { { 0, 0 } } do
		B.cyl(s, "Post", x + o[1], z + o[2], base or 0, 8.6, 0.35, "darkGray", "Metal")
	end
	for _, P in panels do
		local part, fa, fb
		if axis == "X" then
			part = B.box(s, "Panel", x - 0.1, x + 0.1, P.y, P.y + 1.6, z - 2.6, z + 2.6, "space", "SmoothPlastic", DECOR)
			fa, fb = N.Right, N.Left
		else
			part = B.box(s, "Panel", x - 2.6, x + 2.6, P.y, P.y + 1.6, z - 0.1, z + 0.1, "space", "SmoothPlastic", DECOR)
			fa, fb = N.Front, N.Back
		end
		for _, side in { { P.a, fa }, { P.b, fb } } do
			if side[1] then
				B.sign(part, side[1][1], nil, { face = side[2], bg = side[1][2] or "nasaBlue", titleColor = "white", ppu = 40 })
			end
		end
	end
end
local GREEN = "#2E7D4F"
-- ao sair do VAB (olhando para −X): passeio da observação à frente, virando ao norte (+Z)
signPost("Sign_VAB_Exit", -86.5, 307, "X", {
	{ y = 6.6, a = { "↖  PAD OBSERVATION", GREEN } },
}, nil, { { -0.27, 0 } }) -- poste atrás da face Left (a placa só tem texto na face Right)
signPost("Sign_Midway", -95.5, 490, "Z", {
	{ y = 6.6, a = { "PAD OBSERVATION  ↑", GREEN }, b = { "VEHICLE ASSEMBLY BUILDING  ↑" } },
}, -1, { { -2.75, 0 }, { 2.75, 0 } }) -- dupla face: dois postes nas bordas, fora do texto
-- aviso da zona de exclusão (voltado para o leste, visto de quem anda pelo passeio)
for _, z in { 400, 560 } do
	local w = B.group(signs, "Exclusion_Notice")
	-- placa de dupla face: dois postes nas bordas, fora do texto
	for _, dz in { -1.75, 1.75 } do
		B.cyl(w, "Post", -96, z + dz, -1, 5, 0.3, "darkGray", "Metal")
	end
	local p = B.box(w, "Panel", -96.1, -95.9, 3, 5, z - 1.6, z + 1.6, "#B32D2D", "SmoothPlastic", DECOR)
	B.sign(p, "CRAWLERWAY — NO ENTRY", nil, { face = N.Left, bg = "#B32D2D", titleColor = "white", ppu = 40 })
	B.sign(p, "CRAWLERWAY — NO ENTRY", nil, { face = N.Right, bg = "#B32D2D", titleColor = "white", ppu = 40 })
end

-- 2d. Área de observação da plataforma (X −140..−95, Z 640..720), voltada para +X
local obs = B.group(VP, "Pad_Observation")
local OX0, OX1, OZ0, OZ1 = -140, -95, 640, 720
B.box(obs, "Deck", OX0, OX1, -1, 0, OZ0, OZ1, WALK, "Concrete")
B.box(obs, "Deck_Inlay", -110, -97, 0, 0.05, 650, 710, "#B9B3A6", "SmoothPlastic", DECOR_NS)
-- arquibancada: 5 degraus de 1 stud, subindo para −X
local stands = B.group(obs, "Grandstand")
for k = 1, 5 do
	local xf = -110 - 3 * (k - 1)
	B.box(stands, "Step_" .. k, -125, xf, k - 1, k, 650, 710, "#D5D7D8", "Concrete")
	B.box(stands, "Step_Edge", xf - 0.3, xf + 0.05, k - 0.12, k + 0.05, 649.95, 710.05, "safety", "SmoothPlastic", DECOR_NS)
end
-- cobertura sobre a arquibancada
for _, z in { 651, 680, 709 } do
	B.cyl(stands, "Roof_Column", -125.6, z, 0, 14, 0.8, "darkGray", "Metal")
end
-- cobertura só sobre os degraus altos (X −127..−117): não corta mais a vista da 39B
B.box(stands, "Roof", -127, -117, 14, 14.6, 648, 712, "white", "SmoothPlastic")
-- testeira envolve a ponta do telhado (0,05 para fora em X, Y e Z): sem faces coplanares
B.box(stands, "Roof_Fascia", -117.4, -116.95, 13.6, 14.65, 647.95, 712.05, "nasaBlue", "SmoothPlastic", DECOR)
-- guarda-corpos: frente (X −95.5, voltado para a plataforma), fundo, laterais
local rails = B.group(obs, "Railings")
local function rail(x0, x1, z0, z1, posts)
	for _, ry in { 1.8, 3.4 } do
		B.box(rails, "Rail", x0, x1, ry, ry + 0.25, z0, z1, "safety", "Metal")
	end
	for _, p in posts do
		B.cyl(rails, "Rail_Post", p[1], p[2], 0, 3.65, 0.24, "safety", "Metal")
	end
end
do
	local front = {}
	for z = OZ0 + 1, OZ1 - 1, 8 do table.insert(front, { -95.6, z }) end
	table.insert(front, { -95.6, OZ1 - 0.6 })
	rail(-95.72, -95.48, OZ0 + 0.4, OZ1 - 0.4, front)
	-- lado norte (Z 720) inteiro e lado sul (Z 640) com a abertura do passeio (X −105..−97)
	local north = {}
	for x = OX0 + 1, OX1 - 1, 8 do table.insert(north, { x, OZ1 - 0.6 }) end
	rail(OX0 + 0.4, -95.72, OZ1 - 0.72, OZ1 - 0.48, north)
	rail(OX0 + 0.4, PX0, OZ0 + 0.48, OZ0 + 0.72, { { OX0 + 1, OZ0 + 0.6 }, { -125, OZ0 + 0.6 }, { PX0 - 0.2, OZ0 + 0.6 } })
	rail(PX1, -95.72, OZ0 + 0.48, OZ0 + 0.72, { { PX1 + 0.2, OZ0 + 0.6 } })
	local west = {}
	for z = OZ0 + 1, OZ1 - 1, 10 do table.insert(west, { OX0 + 0.6, z }) end
	rail(OX0 + 0.48, OX0 + 0.72, OZ0 + 0.72, OZ1 - 0.72, west)
end
-- lunetas voltadas para a plataforma
for _, z in { 662, 680, 698 } do
	local v = B.group(obs, "Viewer")
	B.cyl(v, "Stand", -98, z, 0, 3.6, 0.35, "darkGray", "Metal")
	B.box(v, "Head", -98.6, -97.2, 3.6, 4.4, z - 0.4, z + 0.4, "nasaBlue", "Metal")
	B.cylBetween(v, "Lens", Vector3.new(-97.2, 4, z), Vector3.new(-96.7, 4, z), 0.55, "black", "Metal", DECOR)
end
-- luzes da área de observação (2)
for _, z in { 655, 705 } do
	local L = B.group(lamps, "Lamp_Post")
	-- no fundo do deck (X −137), fora da faixa de visão para a plataforma
	B.cyl(L, "Base", -137, z, 0, 0.4, 1, "darkGray", "Metal")
	B.cyl(L, "Pole", -137, z, 0.4, 10, 0.35, "darkGray", "Metal", DECOR)
	local head = B.box(L, "Head", -137.6, -136.4, 10, 10.4, z - 0.6, z + 0.6, "#FFF4E0", "Neon", DECOR_NS)
	B.light(head, "PointLight", { Range = 16, Brightness = 0.8, Shadows = false, Color = Color3.fromRGB(255, 236, 205) })
end
-- placas: portal de entrada (voltado para −Z, para quem chega) e painéis junto ao guarda-corpo
do
	local gate = B.group(obs, "Entrance_Arch")
	for _, x in { PX0 - 1, PX1 + 1 } do
		B.box(gate, "Arch_Post", x - 0.4, x + 0.4, 0, 11.05, OZ0 - 2.4, OZ0 - 1.6, "darkGray", "Metal")
	end
	local top = B.box(gate, "Arch_Sign", PX0 - 1, PX1 + 1, 8.5, 11, OZ0 - 2.2, OZ0 - 1.8, "nasaBlue", "SmoothPlastic", DECOR)
	B.sign(top, "PAD OBSERVATION", nil, { face = N.Front, bg = "nasaBlue", titleColor = "white", ppu = 30 })
	B.sign(top, "TO VEHICLE ASSEMBLY BUILDING", nil, { face = N.Back, bg = "nasaBlue", titleColor = "white", ppu = 30 })
end
local function lectern(z, title, body, accent)
	local l = B.group(obs, "Info_Panel")
	B.box(l, "Stand", -99.4, -98.6, 0, 2.6, z - 0.4, z + 0.4, "darkGray", "Metal")
	local p = B.part(l, "Panel", CFrame.new(-98.9, 3.4, z) * CFrame.Angles(0, 0, math.rad(-30)), Vector3.new(0.2, 2.2, 6), "space", "SmoothPlastic", DECOR)
	B.sign(p, title, body, { face = N.Left, accent = accent, titleScale = 0.26, maxBody = 30 })
end
lectern(671, "LAUNCH COMPLEX 39B",
	"Pad 39B launched Apollo 10 and Space Shuttle missions and now hosts the SLS and Orion. The Mobile Launcher's tower serves the rocket at the pad.",
	"lightBlue")
lectern(689, "SAFETY FIRST",
	"Spectators watch from a safe distance. Stay behind the rail and keep off the crawlerway at all times.",
	"safety")

---------------------------------------------------------------------------------
-- Resumo
---------------------------------------------------------------------------------
local parts, lights = 0, 0
for _, root in { LCC, VP } do
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then parts += 1 elseif d:IsA("Light") then lights += 1 end
	end
end
return string.format("Fase 12: Launch Control Center + caminhos de pedestres (%d peças, %d luzes)", parts, lights)
