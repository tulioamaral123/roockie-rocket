--[[
	NASA Space Adventure — Fase 17: exposições do museu.
	Contrato: docs/museu-contrato.md; escala 0,7 m/stud. Só altera a própria raiz.
	Referências de forma/pintura: NASA 6901001, 9903033, 6862832,
	KSC-99pp1144, KSC-2012-6314, KSC-2013-2317 e KSC-2013-2877.
	Geometria própria em primitivas; nenhum modelo externo ou script embarcado.
]]
local lib = ...
local B = lib.builder(17)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1 e 2 antes")
B.clear(Map)

local CollectionService = game:GetService("CollectionService")
local V = Vector3.new
local CF = CFrame.new
local RAD = math.rad
local DECOR = { collide = false }
local DETAIL = { collide = false, shadow = false }
local Exhibits = B.group(Map, "SpaceMuseumExhibits")
-- Revisão 2: projeto (+X) → mundo (+Z), igual à Fase 16.
local MUSEUM_CF = CFrame.new(205, 0, 85) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(-136, 0, -27.5)
local PART_BUDGET = 3371 -- +15% sobre 2932; também dentro do teto aproximado de 3600.
local WHITE, BLACK, SILVER = "#EDEDE8", "#1B1D1F", "#B4B9BB"

local function model(parent, name, persistent)
	local m = B.group(parent, name)
	-- Só as raízes escolhem streaming; filhos herdam o comportamento do ancestral.
	if parent == Exhibits then
		m.ModelStreamingMode = persistent and Enum.ModelStreamingMode.Persistent or Enum.ModelStreamingMode.Atomic
	end
	return m
end

local function part(parent, name, cf, size, color, material, opts, shape)
	return B.part(parent, name, cf, size, color, material or "SmoothPlastic", opts or DECOR, shape)
end

local function anchor(parent, name, position)
	local p = part(parent, name, CF(position), V(0.2, 0.2, 0.2), BLACK, nil, DETAIL)
	p.Transparency = 1
	return p
end

local function exhibit(name, id, promptPosition, persistent)
	local m = model(Exhibits, name, persistent)
	m:SetAttribute("ExhibitId", id)
	CollectionService:AddTag(m, "Exhibit")
	anchor(m, "PromptAnchor", promptPosition)
	return m
end

local function component(p, id, worldPosition)
	local a = Instance.new("Attachment")
	a.Name = id
	a.Position = worldPosition and p.CFrame:PointToObjectSpace(worldPosition) or V(0, 0, 0)
	a:SetAttribute("BuildPhase", 17)
	a.Parent = p
	return a
end

-- Cada marcação verifica a normal da face no espaço do veículo.
local FACE_NORMALS = {
	[Enum.NormalId.Front] = V(0, 0, -1), [Enum.NormalId.Back] = V(0, 0, 1),
	[Enum.NormalId.Top] = V(0, 1, 0), [Enum.NormalId.Bottom] = V(0, -1, 0),
	[Enum.NormalId.Left] = V(-1, 0, 0), [Enum.NormalId.Right] = V(1, 0, 0),
}
local function markingFace(p, face, outward)
	face = face or Enum.NormalId.Front
	if outward then
		local normal = p.CFrame:VectorToWorldSpace(FACE_NORMALS[face])
		assert(normal:Dot(outward.Unit) > 0.99, "Marcação voltada para dentro: " .. p.Name)
	end
	return face
end

local function lettering(p, text, color, face, outward, rotation)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "VehicleMarking"
	gui.Face = markingFace(p, face, outward)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45
	gui.LightInfluence = 0
	gui.ZOffset = 0.03
	gui.Adornee = p
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.AutoLocalize = false
	label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	label.TextColor3 = Color3.fromHex(color)
	if rotation then
		-- Canvas girado: a linha ocupa o comprimento da peça, não sua largura.
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(p.Size.Y / p.Size.X, p.Size.X / p.Size.Y)
		label.Rotation = rotation
		-- 70 px / 45 px por stud: capitais Montserrat com cerca de 1,1 stud.
		label.TextScaled = false
		label.TextSize = 70
	end
	label.Parent = gui
	return gui
end

-- Marcação da bandeira, sem dependência de imagem/asset externo.
local function flag(p, outward)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "USFlag"
	gui.Face = markingFace(p, Enum.NormalId.Front, outward)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 70
	gui.LightInfluence = 0
	gui.ZOffset = 0.03
	gui.Adornee = p
	gui.Parent = p
	for i = 0, 12 do
		local stripe = Instance.new("Frame")
		stripe.BorderSizePixel = 0
		stripe.Position = UDim2.fromScale(0, i / 13)
		stripe.Size = UDim2.fromScale(1, 1 / 13 + 0.001)
		stripe.BackgroundColor3 = Color3.fromHex(i % 2 == 0 and "#AE2432" or "#F6F4E8")
		stripe.Parent = gui
	end
	local canton = Instance.new("Frame")
	canton.BorderSizePixel = 0
	canton.Size = UDim2.fromScale(0.4, 7 / 13)
	canton.BackgroundColor3 = Color3.fromHex("#233D65")
	canton.Parent = gui
	for row = 0, 8 do
		local count = row % 2 == 0 and 6 or 5
		for col = 1, count do
			local star = Instance.new("TextLabel")
			star.BackgroundTransparency = 1
			star.Size = UDim2.fromScale(0.12, 0.12)
			star.AnchorPoint = Vector2.new(0.5, 0.5)
			star.Position = UDim2.fromScale((col - (count == 6 and 0.5 or 0)) / 6, (row + 0.5) / 9)
			star.Text = "★"
			star.TextScaled = true
			star.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json")
			star.TextColor3 = Color3.new(1, 1, 1)
			star.Parent = canton
		end
	end
end

-- Placa arredondada em XZ, sem cantos em balanço nem CSG.
local function roundedPlate(parent, name, center, width, depth, height, radius, color, opts)
	local p = part(parent, name, center, V(width - 2 * radius, height, depth), color, "Metal", opts)
	-- Topo 0,04 (Cross) e 0,02 (cantos) abaixo da peça central: sem faces coplanares.
	part(parent, name .. "Cross", center * CF(0, -0.02, 0), V(width, height - 0.04, depth - 2 * radius), color, "Metal", opts)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(parent, name .. "Corner", center * CF(sx * (width / 2 - radius), -0.01, sz * (depth / 2 - radius)) * CFrame.Angles(0, 0, math.pi / 2), V(height - 0.02, radius * 2, radius * 2), color, "Metal", opts, "Cylinder")
		end
	end
	return p
end

-- Pedestal circular ou cápsula: permanece dentro do retângulo de projeto.
local function plinth(parent, x, z, width, depth, height, floor, cornerRadius)
	floor = floor or 0
	local p
	if cornerRadius then
		p = roundedPlate(parent, "Plinth", CF(x, floor + height / 2, z), width, depth, height, cornerRadius, "#303A44", {})
		roundedPlate(parent, "PlinthTop", CF(x, floor + height + 0.04, z), width - 0.15, depth - 0.15, 0.08, cornerRadius - 0.075, "#56616B", DETAIL)
	elseif width == depth then
		p = B.cyl(parent, "Plinth", x, z, floor, floor + height, width, "#303A44", "Metal", {})
		B.cyl(parent, "PlinthTop", x, z, floor + height, floor + height + 0.08, width - 0.15, "#56616B", "Metal", DETAIL)
	else
		local alongX = width > depth
		local diameter = math.min(width, depth)
		local span = math.abs(width - depth)
		local size = alongX and V(span, height, depth) or V(width, height, span)
		p = part(parent, "Plinth", CF(x, floor + height / 2, z), size, "#303A44", "Metal", {})
		part(parent, "PlinthTop", CF(x, floor + height + 0.04, z), alongX and V(span, 0.08, diameter - 0.15) or V(diameter - 0.15, 0.08, span), "#56616B", "Metal", DETAIL)
		for _, side in { -1, 1 } do
			local cx, cz = x + (alongX and side * span / 2 or 0), z + (alongX and 0 or side * span / 2)
			-- Extremos em alturas distintas (−0,02 / −0,04): os discos se sobrepõem quando span < diâmetro.
			local drop = side == -1 and 0.02 or 0.04
			B.cyl(parent, "PlinthEnd", cx, cz, floor, floor + height - drop, diameter, "#303A44", "Metal", {})
			B.cyl(parent, "PlinthTopEnd", cx, cz, floor + height - drop, floor + height + 0.08 - drop, diameter - 0.15, "#56616B", "Metal", DETAIL)
		end
	end
	return p
end

-- Moldura tubular com juntas esféricas; Board continua plano e vazio.
local function roundedFrame(parent, cf, width, height, name, color)
	local x, y = width / 2 + 0.12, height / 2 + 0.12
	for _, side in { -1, 1 } do
		B.cylBetween(parent, name, cf:PointToWorldSpace(V(-x, side * y, 0)), cf:PointToWorldSpace(V(x, side * y, 0)), 0.24, color or SILVER, "Metal", DETAIL)
		B.cylBetween(parent, name, cf:PointToWorldSpace(V(side * x, -y, 0)), cf:PointToWorldSpace(V(side * x, y, 0)), 0.24, color or SILVER, "Metal", DETAIL)
		for _, sy in { -1, 1 } do
			B.ball(parent, name .. "Joint", cf:PointToWorldSpace(V(side * x, sy * y, 0)), 0.24, color or SILVER, "Metal", DETAIL)
		end
	end
end

local function glassCase(parent, x, z, width, depth, bottom, top)
	-- Quatro folhas: a vitrine não vira um bloco translúcido sobre o objeto.
	for _, sx in { -1, 1 } do
		part(parent, "Glass", CF(x + sx * width / 2, (bottom + top) / 2, z), V(0.06, top - bottom, depth), "glass", "Glass", { transparency = 0.83, shadow = false })
	end
	for _, sz in { -1, 1 } do
		part(parent, "Glass", CF(x, (bottom + top) / 2, z + sz * depth / 2), V(width, top - bottom, 0.06), "glass", "Glass", { transparency = 0.83, shadow = false })
	end
	part(parent, "GlassTop", CF(x, top, z), V(width, 0.06, depth), "glass", "Glass", { transparency = 0.83, shadow = false })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.cyl(parent, "CaseFrame", x + sx * width / 2, z + sz * depth / 2, bottom, top, 0.10, SILVER, "Metal", DETAIL)
		end
	end
	for _, side in { -1, 1 } do
		B.cylBetween(parent, "CaseLidRim", V(x - width / 2, top, z + side * depth / 2), V(x + width / 2, top, z + side * depth / 2), 0.10, SILVER, "Metal", DETAIL)
		B.cylBetween(parent, "CaseLidRim", V(x + side * width / 2, top, z - depth / 2), V(x + side * width / 2, top, z + depth / 2), 0.10, SILVER, "Metal", DETAIL)
		for _, sz in { -1, 1 } do
			B.ball(parent, "CaseLidJoint", V(x + side * width / 2, top, z + sz * depth / 2), 0.14, SILVER, "Metal", DETAIL)
		end
	end
end

-- Pintura/cerâmica fosca usa SmoothPlastic; metal nu e mantas são explícitos.
-- Geometria axial em X; o mesmo bocal é instanciado nos cinco F-1.
local function axial(parent, name, x0, x1, radius, color, y, z, material)
	return part(parent, name, CF((x0 + x1) / 2, y or 22, z or 27.5), V(x1 - x0, 2 * radius, 2 * radius), color, material or "SmoothPlastic", DECOR, "Cylinder")
end

local function taperX(parent, name, x0, x1, r0, r1, slices, color, y, z, material)
	local first
	for i = 0, slices - 1 do
		local t = (i + 0.5) / slices
		local p = axial(parent, name, x0 + (x1 - x0) * i / slices, x0 + (x1 - x0) * (i + 1) / slices, r0 + (r1 - r0) * t, color, y, z, material)
		first = first or p
	end
	return first
end

local function bell(parent, name, cf, length, mouth, facets)
	local g = model(parent, name)
	-- aproximação: perfil parabólico em quatro faixas; casca vazada, não discos maciços.
	local profile = { { 0, 1 }, { 0.28, 0.86 }, { 0.56, 0.64 }, { 0.77, 0.39 }, { 1, 0.29 } }
	for k = 1, #profile - 1 do
		local x0, r0 = profile[k][1] * length, profile[k][2] * mouth
		local x1, r1 = profile[k + 1][1] * length, profile[k + 1][2] * mouth
		for j = 0, facets - 1 do
			local a = 2 * math.pi * (j + 0.5) / facets
			local p0, p1 = V(x0, r0 * math.cos(a), r0 * math.sin(a)), V(x1, r1 * math.cos(a), r1 * math.sin(a))
			local right = (p1 - p0).Unit
			local up = V(0, -math.sin(a), math.cos(a))
			part(g, "BellPanel", cf * CFrame.fromMatrix((p0 + p1) / 2, right, up, right:Cross(up)), V((p1 - p0).Magnitude + 0.03, 2 * math.max(r0, r1) * math.tan(math.pi / facets) + 0.025, 0.07), k == 1 and "#727775" or "#555B5B", "Metal", DETAIL)
		end
	end
	for _, t in { 0, 0.28, 0.56, 0.77 } do
		local r = mouth * (t == 0 and 1 or (t == 0.28 and 0.86 or (t == 0.56 and 0.64 or 0.39)))
		for j = 0, facets - 1 do
			local a, b = 2 * math.pi * j / facets, 2 * math.pi * (j + 1) / facets
			-- Seção alternada (0,08/0,05): as mitras de segmentos vizinhos não ficam coplanares.
			local ring = j % 2 == 0 and 0.08 or 0.05
			B.beam(g, "CoolingRing", cf:PointToWorldSpace(V(t * length, r * math.cos(a), r * math.sin(a))), cf:PointToWorldSpace(V(t * length, r * math.cos(b), r * math.sin(b))), ring, ring, SILVER, "Metal", DETAIL)
		end
	end
	local throat = part(g, "Throat", cf * CF(length, 0, 0), V(0.15, mouth * 0.58, mouth * 0.58), BLACK, "Metal", DETAIL, "Cylinder")
	part(g, "Turbopump", cf * CF(length + 0.55, mouth * 0.36, 0), V(length * 0.26, mouth * 0.8, mouth * 0.62), SILVER, "Metal", DETAIL, "Cylinder")
	for _, side in { -1, 1 } do
		B.cylBetween(g, "FeedPipe", cf:PointToWorldSpace(V(length * 0.62, side * mouth * 0.56, 0)), cf:PointToWorldSpace(V(length + 1.2, side * mouth * 0.4, 0)), mouth * 0.12, SILVER, "Metal", DETAIL)
	end
	g.PrimaryPart = throat
	return g, throat
end

local function ribs(parent, x0, x1, radius, count)
	for j = 0, count - 1 do
		local a = j * 2 * math.pi / count
		part(parent, "Corrugation", CF((x0 + x1) / 2, 22 + radius * math.cos(a), 27.5 + radius * math.sin(a)) * CFrame.Angles(a, 0, 0), V(x1 - x0, 0.06, 0.10), WHITE, "SmoothPlastic", DETAIL)
	end
end

local function rollPattern(parent, x0, x1, radius)
	-- aproximação: quadrantes de voo do Apollo 11 (~45°); o intertank fica branco, sem o T preto do 500F.
	for quadrant = 0, 3 do
		for j = 0, 4 do
			local a = RAD(quadrant * 90 + (j - 2) * 9)
			part(parent, "RollPattern", CF((x0 + x1) / 2, 22 + radius * math.cos(a), 27.5 + radius * math.sin(a)) * CFrame.Angles(a, 0, 0), V(x1 - x0, 0.045, radius * 0.159), BLACK, nil, DETAIL)
		end
	end
end

-- Dois WedgeParts por triângulo, evitando asas retangulares ou malhas externas.
local function triangle(parent, name, cf, a, b, c, thickness, color, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then
		c, a = a, c
	elseif ac:Dot(ac) > bc:Dot(bc) then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local back = bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	part(parent, name, cf * CFrame.fromMatrix((a + b) / 2, right, up, back), V(thickness, height, math.max(0.02, math.abs(ab:Dot(back)))), color, material or "SmoothPlastic", DETAIL, "Wedge")
	part(parent, name, cf * CFrame.fromMatrix((a + c) / 2, -right, up, -back), V(thickness, height, math.max(0.02, math.abs(ac:Dot(back)))), color, material or "SmoothPlastic", DETAIL, "Wedge")
end

--------------------------------------------------------------------------------
-- SATURN V: eixo Y22/Z27,5; bocais em X176, escape em X334.
-- O contrato soma 156,7 studs de estágios + 10 de vãos. Mantêm-se as medidas
-- S-IC/S-II/S-IVB/IU; a nave ocupa 25,3 (aproximação), fechando o envelope 158.
-- Berços pertencem exclusivamente à Fase 16.
--------------------------------------------------------------------------------
local saturn = exhibit("SaturnV", "saturn_v", V(181, 4, 17), true)
saturn:SetAttribute("MetersPerStud", 0.7)
saturn:SetAttribute("Axis", V(1, 0, 0))
saturn:SetAttribute("EnginePlane", V(176, 22, 27.5))
saturn:SetAttribute("EscapeTip", V(334, 22, 27.5))
local stageData = {
	{ "Stage_S_IC", "s_ic", 176, 236.1, 7.2 },
	{ "Stage_S_II", "s_ii", 238.6, 274.2, 7.2 },
	{ "Stage_S_IVB", "s_ivb", 276.7, 302.4, 4.8 },
	{ "Stage_IU", "iu", 304.9, 306.2, 4.55 },
	{ "Stage_Spacecraft", "spacecraft", 308.7, 334, 4.55 },
}
local stages = {}
for i, d in stageData do
	local g = model(saturn, d[1])
	g:SetAttribute("StageIndex", i)
	g:SetAttribute("Axis", V(1, 0, 0))
	g:SetAttribute("EnvelopeStart", d[3])
	g:SetAttribute("EnvelopeEnd", d[4])
	local p = anchor(g, "StageAxis", V((d[3] + d[4]) / 2, 22, 27.5))
	g.PrimaryPart = p
	component(p, d[2])
	local light = anchor(g, "ShowLight", V((d[3] + d[4]) / 2, 8, 27.5))
	B.light(light, "SpotLight", { Enabled = false, Face = Enum.NormalId.Top, Angle = 100, Range = 38, Brightness = 3, Color = Color3.fromRGB(255, 231, 195), Shadows = false })
	stages[i] = g
end
saturn.PrimaryPart = stages[1].PrimaryPart
local sic, sii, sivb, iu, craft = table.unpack(stages)
local f1Offsets = { { 0, 0 }, { -3.65, -3.65 }, { -3.65, 3.65 }, { 3.65, -3.65 }, { 3.65, 3.65 } }
for i, offset in f1Offsets do
	local _, throat = bell(sic, "F1_" .. i, CF(176.04, 22 + offset[1], 27.5 + offset[2]), 6.8, 2.7, 12)
	component(throat, "f1_" .. i, V(176.1, 22 + offset[1], 27.5 + offset[2]))
end
axial(sic, "ThrustStructure", 183.7, 185, 6.7, "#5E6262", nil, nil, "Metal")
axial(sic, "RP1Tank", 184.3, 206.5, 7.2, WHITE)
axial(sic, "Intertank", 206.5, 211.2, 7.23, WHITE)
axial(sic, "LOXTank", 211.2, 231.6, 7.2, WHITE)
axial(sic, "ForwardSkirt", 231.6, 236.1, 7.2, WHITE)
-- Emendas centradas na junta: as faces não coincidem com as tampas dos tanques.
for _, x in { 185, 198, 206.5, 211.2, 231.6 } do
	axial(sic, "TankSeam", x - 0.06, x + 0.06, 7.25, SILVER, nil, nil, "Metal")
end
axial(sic, "TankSeam", 235.8, 235.92, 7.25, SILVER, nil, nil, "Metal")
ribs(sic, 184.6, 196.5, 7.24, 40)
ribs(sic, 206.7, 210.9, 7.25, 40)
ribs(sic, 232, 235.8, 7.24, 40)
rollPattern(sic, 185, 197, 7.30)
-- Saia dianteira do S-IC branca no padrão de voo; a faixa pertence ao interestágio S-II.
for _, a in { 45, 135, 225, 315 } do
	local angle = RAD(a)
	local finCF = CF(189.5, 22, 27.5) * CFrame.Angles(angle, 0, 0)
	part(sic, "EngineFairing", finCF * CF(0, 7.2, 0) * CFrame.Angles(0, math.pi / 2, 0), V(2.5, 2.0, 9), WHITE, "SmoothPlastic", DECOR, "Wedge")
	triangle(sic, "SICFin", finCF, V(-4.6, 7.0, 0), V(4.6, 7.0, 0), V(-4.6, 11.2, 0), 0.16, SILVER, "Metal")
end
for _, zside in { -1, 1 } do
	local outward = V(0, 0, zside)
	-- Front = −Z local aponta para fora; topo de cada glifo aponta para +X.
	-- No lado +Z o canvas gira 180° em torno da normal e a ordem se inverte: os dois lados leem "USA".
	local faceCF = CFrame.fromMatrix(V(0, 22, 27.5 + zside * 7.35), V(0, -1, 0), V(-zside, 0, 0), -outward)
	for i, letter in { "U", "S", "A" } do
		local letterX = zside == -1 and 225.8 - (i - 1) * 3.4 or 219 + (i - 1) * 3.4
		local p = part(sic, "USAMarking", CF(letterX, faceCF.Y, faceCF.Z) * faceCF.Rotation, V(3.1, 2.6, 0.06), WHITE, nil, DETAIL)
		lettering(p, letter, "#BA2C2B", Enum.NormalId.Front, outward)
	end
	local p = part(sic, "FlagMarking", CF(212.5, 22, faceCF.Z) * faceCF.Rotation, V(4.5, 2.5, 0.06), WHITE, nil, DETAIL)
	flag(p, outward)
end
for _, a in { 30, 210 } do
	local r = RAD(a)
	part(sic, "CableRaceway", CF(211.0, 22 + 7.3 * math.cos(r), 27.5 + 7.3 * math.sin(r)), V(43, 0.26, 0.32), WHITE, "SmoothPlastic", DETAIL)
end
task.wait()

-- S-II: cinco J-2 visíveis no vão, saia corrugada e transição 14,4 → 9,6.
for i, offset in { { 0, 0 }, { -2.5, -2.5 }, { -2.5, 2.5 }, { 2.5, -2.5 }, { 2.5, 2.5 } } do
	local _, throat = bell(sii, "J2_" .. i, CF(238.65, 22 + offset[1], 27.5 + offset[2]), 3.1, 1.45, 10)
	component(throat, "j2_ii_" .. i)
end
axial(sii, "AftSkirt", 242.5, 247.5, 7.2, WHITE)
axial(sii, "HydrogenTank", 247.5, 268.7, 7.2, WHITE)
taperX(sii, "ForwardInterstage", 268.7, 274.2, 7.2, 4.8, 12, WHITE)
ribs(sii, 242.7, 247.3, 7.25, 40)
rollPattern(sii, 242.6, 247.4, 7.3)
for _, x in { 247.5, 257.5, 268.5 } do
	axial(sii, "Seam", x - 0.07, x + 0.07, 7.24, SILVER, nil, nil, "Metal")
end
local _, j2 = bell(sivb, "J2", CF(276.75, 22, 27.5), 3.5, 1.65, 10)
component(j2, "j2_ivb")
axial(sivb, "AftSkirt", 281.4, 285.0, 4.8, WHITE)
axial(sivb, "HydrogenTank", 285, 299.6, 4.8, WHITE)
axial(sivb, "ForwardSkirt", 299.6, 302.4, 4.8, WHITE)
ribs(sivb, 281.6, 284.9, 4.85, 32)
ribs(sivb, 299.8, 302.2, 4.85, 32)
rollPattern(sivb, 281.5, 284.9, 4.9)
axial(iu, "InstrumentRing", 304.9, 306.2, 4.55, BLACK)
for i = 0, 11 do
	local a = i * math.pi / 6
	part(iu, "InstrumentPanel", CF(305.55, 22 + 4.57 * math.cos(a), 27.5 + 4.57 * math.sin(a)) * CFrame.Angles(a, 0, 0), V(0.75, 0.08, 0.8), "#51594F", "SmoothPlastic", DETAIL)
end
-- aproximação: SLA fechado, SM e CM encurtados para absorver os quatro vãos.
taperX(craft, "SpacecraftLMAdapter", 308.7, 316.9, 4.55, 2.78, 16, WHITE)
axial(craft, "ServiceModule", 316.9, 322.4, 2.78, SILVER, nil, nil, "Foil")
for j = 0, 11 do
	local a = j * math.pi / 6
	part(craft, "SMRadiator", CF(319.6, 22 + 2.81 * math.cos(a), 27.5 + 2.81 * math.sin(a)) * CFrame.Angles(a, 0, 0), V(4.6, 0.07, 0.4), WHITE, "SmoothPlastic", DETAIL)
end
taperX(craft, "CommandModule", 322.4, 326.1, 2.78, 0.65, 18, SILVER, nil, nil, "Foil")
axial(craft, "DockingCover", 326.1, 326.4, 0.65, WHITE)
local lesAnchor = anchor(craft, "EscapeAxis", V(330, 22, 27.5))
component(lesAnchor, "les")
for _, sy in { -1, 1 } do
	for _, sz in { -1, 1 } do
		local p0 = V(325.4, 22 + sy * 0.95, 27.5 + sz * 0.95)
		local p1 = V(329.0, 22 + sy * 0.38, 27.5 + sz * 0.38)
		B.cylBetween(craft, "EscapeLeg", p0, p1, 0.12, WHITE, "Metal", DETAIL)
		B.cylBetween(craft, "EscapeDiagonal", p0, V(329, 22 - sy * 0.38, 27.5 + sz * 0.38), 0.08, WHITE, "Metal", DETAIL)
	end
end
axial(craft, "AbortMotor", 328.8, 332.8, 0.48, WHITE)
taperX(craft, "EscapeTip", 332.8, 334, 0.48, 0.02, 8, WHITE)
for i = 0, 3 do
	local a = i * math.pi / 2
	B.cylBetween(craft, "AbortNozzle", V(329, 22 + 0.35 * math.cos(a), 27.5 + 0.35 * math.sin(a)), V(328.5, 22 + 0.95 * math.cos(a), 27.5 + 0.95 * math.sin(a)), 0.2, BLACK, "Metal", DETAIL)
end
-- aproximação: conexões de abastecimento, válvulas e abraçadeiras nas saias.
for _, d in { { sic, 186, 196, 7.2 }, { sii, 243.2, 247.0, 7.2 }, { sivb, 281.7, 284.8, 4.8 } } do
	local g, x0, x1, radius = table.unpack(d)
	for _, degrees in { 225, 315 } do
		local a = RAD(degrees)
		local normal = V(0, math.cos(a), math.sin(a))
		local p0 = V(x0, 22, 27.5) + normal * (radius + 0.02)
		local p1 = V(x0 + 0.4, 22, 27.5) + normal * (radius + 0.32)
		local p2 = V(x1 - 0.4, 22, 27.5) + normal * (radius + 0.32)
		local p3 = V(x1, 22, 27.5) + normal * (radius + 0.02)
		B.cylBetween(g, "UmbilicalFeed", p0, p1, 0.14, SILVER, "Metal", DETAIL)
		B.cylBetween(g, "UmbilicalFeed", p1, p2, 0.14, SILVER, "Metal", DETAIL)
		B.cylBetween(g, "UmbilicalFeed", p2, p3, 0.14, SILVER, "Metal", DETAIL)
		part(g, "UmbilicalValve", CF(p2), V(0.25, 0.40, 0.40), "#A8ACA4", "Metal", DETAIL, "Cylinder")
		part(g, "UmbilicalClamp", CF(V((x0 + x1) / 2, 22, 27.5) + normal * (radius + 0.14)) * CFrame.Angles(a, 0, 0), V(0.12, 0.65, 0.18), WHITE, "SmoothPlastic", DETAIL)
	end
end
-- aproximação: escadas de inspeção presas ao casco por quatro afastadores.
for _, d in { { sic, 200 }, { sii, 251 } } do
	local g, x = table.unpack(d)
	for _, side in { -1, 1 } do
		B.cylBetween(g, "InspectionLadderRail", V(x + side * 0.55, 16.8, 20), V(x + side * 0.55, 22.1, 20), 0.10, "#D7AD42", "SmoothPlastic", DETAIL)
		for _, y in { 17.5, 21.5 } do
			local skinZ = 27.5 - math.sqrt(7.2 * 7.2 - (y - 22) * (y - 22))
			B.cylBetween(g, "LadderStandOff", V(x + side * 0.55, y, 20), V(x + side * 0.55, y, skinZ + 0.05), 0.12, "#D7AD42", "SmoothPlastic", DETAIL)
		end
	end
	for j = 0, 7 do
		B.cylBetween(g, "InspectionLadderRung", V(x - 0.55, 17 + j * 0.65, 20), V(x + 0.55, 17 + j * 0.65, 20), 0.10, "#D7AD42", "SmoothPlastic", DETAIL)
	end
end
for _, d in { { sii, 257, 7.2, 15.6 }, { sivb, 292, 4.8, 14 } } do
	for _, side in { -1, 1 } do
		local normal = V(0, 0, side)
		local cf = CFrame.fromMatrix(V(d[2], 22, 27.5 + side * (d[3] + 0.15)), V(0, -1, 0), V(-side, 0, 0), -normal)
		local p = part(d[1], "UnitedStatesMarking", cf, V(1.8, d[4], 0.05), WHITE, "SmoothPlastic", DETAIL)
		lettering(p, "UNITED STATES", "#BA2C2B", Enum.NormalId.Front, normal, 90)
	end
end
task.wait()

--------------------------------------------------------------------------------
-- DIORAMA + CONSOLE: frente em Z negativo; plateia na faixa Z−3..5.
--------------------------------------------------------------------------------
local diorama = model(Exhibits, "LaunchDiorama")
local pad = model(diorama, "Pad")
local padBase = plinth(pad, 308, 13, 23, 13, 0.8)
pad.PrimaryPart = padBase
diorama.PrimaryPart = padBase
part(pad, "LaunchDeck", CF(307, 1.585, 13), V(7, 1.53, 7), "#73787A", "Metal", {})
part(pad, "FlameTrench", CF(307, 0.88, 9.6), V(2.5, 0.08, 6.8), BLACK, nil, DETAIL)
for _, dx in { -1, 1 } do
	for _, dz in { -1, 1 } do
		part(pad, "TowerColumn", CF(312 + dx * 0.65, 5.5, 14 + dz * 0.65), V(0.12, 9.4, 0.12), "#B34E3A", "Metal", DETAIL)
	end
end
for y = 2, 10, 1 do
	part(pad, "TowerDeck", CF(312, y, 14), V(1.6, 0.09, 1.6), "#A7AAA7", "Metal", DETAIL)
	if y < 10 then
		B.beam(pad, "TowerBrace", V(311.35, y, 13.35), V(312.65, y + 0.9, 13.35), 0.07, 0.07, "#B34E3A", "Metal", DETAIL)
	end
end
for _, y in { 5, 7, 9 } do
	B.beam(pad, "Umbilical", V(311.3, y, 14), V(307.35, y, 13), 0.16, 0.16, "#A7AAA7", "Metal", DETAIL)
end
-- MiniRocket é exatamente 158/20 = 7,9 studs de altura, em um pivô próprio.
local mini = model(diorama, "MiniRocket")
local miniBase = anchor(mini, "LaunchAxis", V(307, 2.35, 13))
mini.PrimaryPart = miniBase
mini:SetAttribute("ScaleRatio", 1 / 20)
local miniCF = CF(307, 2.35, 13) * CFrame.Angles(0, 0, math.pi / 2)
local function miniCyl(name, a, b, diameter, color)
	return part(mini, name, miniCF * CF((a + b) / 40, 0, 0), V((b - a) / 20, diameter / 20, diameter / 20), color, nil, DETAIL, "Cylinder")
end
for _, d in { { 0, 60.1, 14.4 }, { 62.6, 98.2, 14.4 }, { 100.7, 126.4, 9.6 }, { 128.9, 130.2, 9.1 }, { 132.7, 146.4, 7.5 } } do
	miniCyl("WhiteStage", d[1], d[2], d[3], WHITE)
end
-- Faixas 0,045 stud mais largas que o estágio e ultrapassando as tampas: sem faces coplanares.
for _, d in { { 9, 18, 15.3 }, { 56, 60.5, 15.3 }, { 68, 72, 15.3 }, { 108, 110, 10.5 }, { 128.5, 130.6, 10.0 } } do
	miniCyl("RollBand", d[1], d[2], d[3], BLACK)
end
for i = 0, 11 do
	miniCyl("ApolloCone", 146.4 + i * 0.8, 147.2 + i * 0.8, 7.5 * (1 - i / 12), WHITE)
end
miniCyl("EscapeTower", 155.2, 158, 0.8, WHITE)
for _, d in f1Offsets do
	part(mini, "F1", miniCF * CF(0.17, d[1] / 20, d[2] / 20), V(0.34, 0.27, 0.27), "#555B5B", "Metal", DETAIL, "Cylinder")
end
for _, effect in { "Smoke", "Fire" } do
	local exhaust = anchor(mini, "Exhaust", V(307, 2.36, 13))
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = effect
	emitter.Enabled = false
	emitter.Texture = "rbxasset://textures/particles/" .. (effect == "Smoke" and "smoke_main.dds" or "fire_main.dds")
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Rate = effect == "Smoke" and 40 or 65
	emitter.Lifetime = NumberRange.new(effect == "Smoke" and 2 or 0.5, effect == "Smoke" and 4 or 1)
	emitter.Speed = NumberRange.new(2, effect == "Smoke" and 5 or 8)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.LightEmission = effect == "Fire" and 0.9 or 0
	emitter.Color = ColorSequence.new(effect == "Fire" and Color3.fromRGB(255, 180, 65) or Color3.fromRGB(170, 175, 180))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, effect == "Smoke" and 3 or 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Parent = exhaust
end
-- Afastado 0,6 do pé do berço do Saturn V (Fase 16) e dos postes da tela.
diorama:PivotTo(CF(0, 0, -0.6) * diorama:GetPivot())
local console = model(Exhibits, "LaunchConsole")
console.PrimaryPart = plinth(console, 294, 7.5, 7, 4, 2.4)
local deck = part(console, "ConsoleDeck", CF(294, 2.8, 7.5) * CFrame.Angles(RAD(15), 0, 0), V(3.04, 0.25, 4), "#53626C", "SmoothPlastic", {})
for _, side in { -1, 1 } do
	part(console, "ConsoleDeckEnd", deck.CFrame * CF(side * 1.5, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), V(0.21, 4, 4), "#53626C", "SmoothPlastic", {}, "Cylinder")
end
for row = 1, 3 do
	for col = 1, 8 do
		local lamp = part(console, "Indicator", deck.CFrame * CF(-2.8 + (col - 1) * 0.8, 0.17, -1.25 + (row - 1) * 0.8), V(0.3, 0.08, 0.25), "#41625B", "SmoothPlastic", DETAIL)
		CollectionService:AddTag(lamp, "ConsoleLight")
		lamp:SetAttribute("Order", (row - 1) * 8 + col)
	end
end
-- Screen.Front aponta para −Z, de frente à plateia, sem encobrir o Saturn V.
local screen = part(console, "Screen", CF(319, 5.7, 18.8), V(10, 6, 0.3), "#0B1822", nil, {})
for _, x in { 315.5, 322.5 } do
	part(console, "ScreenPost", CF(x, 1.9, 18.8), V(0.3, 3.8, 0.26), "#424E58", "Metal", {})
end
screen:SetAttribute("DisplayFace", "Front")
anchor(console, "ShowPromptAnchor", V(294, 3.8, 4.9))
local showCamera = anchor(console, "ShowCamera", V(300, 7, -16))
showCamera.CFrame = CFrame.lookAt(V(300, 7, -16), V(303, 13, 22))
task.wait()

--------------------------------------------------------------------------------
-- ATLANTIS: geometria local 53 × 34 × 25; rolagem lateral de 43,21°.
-- aproximação: seções, cockpit, asas e painéis térmicos em primitivas.
--------------------------------------------------------------------------------
local atlantis = exhibit("Atlantis", "atlantis", V(350, 4, 44), true)
atlantis:SetAttribute("RollDegrees", 43.21)
atlantis:SetAttribute("DesignDimensions", V(34, 25, 53))
local shuttleCF = CF(370, 18.5, 64.5) * CFrame.Angles(0, 0, RAD(43.21))
local function sp(parent, name, position, size, color, material, shape, rotation)
	return part(parent, name, shuttleCF * CF(position) * (rotation or CFrame.identity), size, color, material, DETAIL, shape)
end
local function sb(parent, name, a, b, width, height, color, material)
	return B.beam(parent, name, shuttleCF:PointToWorldSpace(a), shuttleCF:PointToWorldSpace(b), width, height, color, material or "Metal", DETAIL)
end

local hull = sp(atlantis, "PayloadBayFloor", V(0, -1.9, 3), V(8.8, 1.0, 31), BLACK, "SmoothPlastic")
atlantis.PrimaryPart = hull
component(hull, "tiles", shuttleCF:PointToWorldSpace(V(0, -3, 0)))
local crossSections = {
	{ -26.5, 0.16, 0.25 }, { -25, 1.6, 1.35 }, { -23, 2.9, 2.0 },
	{ -20, 4.0, 2.7 }, { -16, 4.8, 3.3 }, { -11, 4.8, 3.3 },
	{ -5, 4.8, 3.3 }, { 2, 4.8, 3.3 }, { 9, 4.8, 3.3 },
	{ 17, 4.8, 3.3 }, { 23, 4.6, 3.0 }, { 26.5, 3.3, 2.7 },
}
-- O nariz completo abaixo substitui os painéis inferiores de Z−26,5..−11.
for i = 6, #crossSections - 1 do
	local d0, d1 = crossSections[i], crossSections[i + 1]
	local z, rx, ry = (d0[1] + d1[1]) / 2, (d0[2] + d1[2]) / 2, (d0[3] + d1[3]) / 2
	for j = 0, 7 do
		local a, b = math.pi + j * math.pi / 8, math.pi + (j + 1) * math.pi / 8
		local p0, p1 = V(rx * math.cos(a), ry * math.sin(a), z), V(rx * math.cos(b), ry * math.sin(b), z)
		local right = (p1 - p0).Unit
		local back = V(0, 0, 1)
		local up = back:Cross(right)
		part(atlantis, "LowerHullTilePanel", shuttleCF * CFrame.fromMatrix((p0 + p1) / 2, right, up, back), V((p1 - p0).Magnitude + 0.04, 0.12, d1[1] - d0[1] + (j % 2 == 0 and 0.04 or 0.08)), j % 3 == 0 and "#25282A" or BLACK, "SmoothPlastic", DETAIL)
	end
end
-- aproximação: dez trechos contínuos sem tampas/discos entre seções.
-- As placas inclinadas acompanham o perfil elíptico até a seção cheia em Z−11.
-- O perfil é tangente ao corpo na junção (derivada do seno igual a zero).
for i = 0, 9 do
	local t0, t1 = i / 10, (i + 1) / 10
	local r0, r1 = math.sin(t0 * math.pi / 2), math.sin(t1 * math.pi / 2)
	local rx0, rx1 = 0.4 + 4.4 * r0, 0.4 + 4.4 * r1
	local ry0, ry1 = 0.4 + 2.9 * r0, 0.4 + 2.9 * r1
	local z0, z1 = -26.1 + 15.1 * t0, -26.1 + 15.1 * t1
	for j = 0, 9 do
		local a = (j + 0.5) * math.pi / 5
		local p0 = V(rx0 * math.cos(a), ry0 * math.sin(a), z0)
		local p1 = V(rx1 * math.cos(a), ry1 * math.sin(a), z1)
		local tangent = V(-(rx0 + rx1) * math.sin(a), (ry0 + ry1) * math.cos(a), 0).Unit
		local back = (p1 - p0).Unit
		local up = back:Cross(tangent).Unit
		local right = up:Cross(back).Unit
		local halfWidth = V(-rx1 * math.sin(a), ry1 * math.cos(a), 0).Magnitude * math.tan(math.pi / 10)
		local color = i == 0 and "#3F4345" or (j < 5 and WHITE or BLACK)
		part(atlantis, "ForwardFuselage", shuttleCF * CFrame.fromMatrix((p0 + p1) / 2, right, up, back), V(2 * halfWidth + 0.04, 0.08, (p1 - p0).Magnitude + (j % 2 == 0 and 0.06 or 0.10)), color, "SmoothPlastic", DETAIL)
	end
end
sp(atlantis, "NoseCap", V(0, 0, -25.6), V(1.8, 1.65, 1.8), "#3F4345", "SmoothPlastic", "Ball")
-- Base do wedge embutida no perfil; só a faixa de cabine emerge da pele.
local cockpit = sp(atlantis, "FlightDeck", V(0, 2.5, -16), V(7.3, 1.2, 6.2), WHITE, "SmoothPlastic", "Wedge", CFrame.Angles(0, math.pi, 0))
component(cockpit, "cockpit")
for _, side in { -1, 1 } do
	for i = 0, 2 do
		sp(atlantis, "CockpitWindow", V(side * (0.65 + i * 1.0), 2.7 - i * 0.12, -19.16 + i * 0.10), V(0.85, 0.7, 0.12), "#1D303A", "Glass", nil, CFrame.Angles(RAD(-22), RAD(side * -10), 0))
	end
	sp(atlantis, "CabinSideWindow", V(side * 3.67, 2.45, -18.4), V(0.08, 0.7, 1.1), "#152731", "Glass")
	sp(atlantis, "PayloadBaySill", V(side * 4.65, 0.6, 3.7), V(0.38, 1.8, 28.5), WHITE, "SmoothPlastic")
	for z = -9, 18, 3 do
		sp(atlantis, "BayFrame", V(side * 4.3, -0.1, z), V(0.16, 2.1, 0.18), SILVER, "Metal")
	end
	sp(atlantis, "OMS_Pod", V(side * 4.1, 2.0, 21), V(3.0, 3.7, 8), WHITE, "SmoothPlastic", "Ball")
end
for z = -9, 18, 3 do
	sp(atlantis, "BayCrossFrame", V(0, -1.3, z), V(8.2, 0.14, 0.16), SILVER, "Metal")
end
sp(atlantis, "ForwardBulkhead", V(0, 0.7, -10.6), V(8.9, 4.2, 0.25), WHITE, "SmoothPlastic")
sp(atlantis, "AftBulkhead", V(0, 0.7, 18.4), V(8.9, 4.2, 0.25), WHITE, "SmoothPlastic")
-- Sem malha TileJoint: a grade plana ficava pendurada sob o casco elíptico; o tom alternado dos painéis marca as telhas.
local wingsAnchor = anchor(atlantis, "WingAxis", shuttleCF:PointToWorldSpace(V(0, -2, 15)))
component(wingsAnchor, "wings")
for _, side in { -1, 1 } do
	local a, b, c, d = V(side * 4.3, -2.0, -10), V(side * 8.0, -2.0, 0), V(side * 17, -2.0, 20.2), V(side * 4.3, -2.0, 24)
	triangle(atlantis, "DeltaWing", shuttleCF, a, b, d, 0.5, WHITE)
	triangle(atlantis, "DeltaWing", shuttleCF, b, c, d, 0.5, WHITE)
	triangle(atlantis, "BlackWingUnderside", shuttleCF, a - V(0, 0.29, 0), b - V(0, 0.29, 0), d - V(0, 0.29, 0), 0.06, BLACK)
	triangle(atlantis, "BlackWingUnderside", shuttleCF, b - V(0, 0.29, 0), c - V(0, 0.29, 0), d - V(0, 0.29, 0), 0.06, BLACK)
	sb(atlantis, "CarbonLeadingEdge", a, b, 0.45, 0.45, "#3F4345", "SmoothPlastic")
	sb(atlantis, "CarbonLeadingEdge", b, c, 0.45, 0.45, "#3F4345", "SmoothPlastic")
	sb(atlantis, "ElevonSeam", V(side * 5, -1.72, 21.7), V(side * 14, -1.72, 20.9), 0.07, 0.04, BLACK)
	for z = 3, 19, 2 do
		local outer = 8 + 9 * z / 20.2
		sb(atlantis, "WingTileJoint", V(side * 5, -2.32, z), V(side * outer, -2.32, z), 0.025, 0.025, "#55585A")
	end
	local p = sp(atlantis, "WingMarking", V(side * 10, -1.69, 17), V(5.8, 0.04, 2.1), WHITE)
	lettering(p, side == -1 and "NASA" or "Atlantis", "#25282C", Enum.NormalId.Top, shuttleCF:VectorToWorldSpace(V(0, 1, 0)))
	local nameplate = sp(atlantis, "FuselageMarking", V(side * 4.91, -0.1, -6.8), V(0.05, 1.25, 5.5), WHITE)
	lettering(nameplate, "Atlantis", "#20262D", side == -1 and Enum.NormalId.Left or Enum.NormalId.Right, shuttleCF:VectorToWorldSpace(V(side, 0, 0)))
end
for _, side in { -1, 1 } do
	local badge = sp(atlantis, "NASAInsignia", V(side * 4.84, 0.1, 1), V(0.12, 1.8, 1.8), "#244B70", "SmoothPlastic", "Cylinder")
	lettering(badge, "NASA", "#FFFFFF", side == -1 and Enum.NormalId.Left or Enum.NormalId.Right, shuttleCF:VectorToWorldSpace(V(side, 0, 0)))
end
triangle(atlantis, "VerticalStabilizer", shuttleCF, V(0, 0.8, 12), V(0, 21.7, 24.7), V(0, 0.8, 26.4), 0.6, WHITE)
sb(atlantis, "TailLeadingEdge", V(0, 0.8, 12), V(0, 21.7, 24.7), 0.7, 0.7, "#3F4345", "SmoothPlastic")
sb(atlantis, "RudderSeam", V(0.34, 4.3, 24), V(0.34, 18.5, 24.7), 0.06, 0.06, BLACK)
-- aproximação: folhas abertas do leme/freio, articuladas ao bordo traseiro.
for _, side in { -1, 1 } do
	triangle(atlantis, "SplitRudderPanel", shuttleCF, V(side * 0.35, 5, 24.3), V(side * 0.35, 18.5, 24.9), V(side * 1.2, 5, 26.2), 0.10, WHITE)
	B.cylBetween(atlantis, "RudderHinge", shuttleCF:PointToWorldSpace(V(side * 0.35, 5, 24.3)), shuttleCF:PointToWorldSpace(V(side * 0.35, 18.5, 24.9)), 0.16, "#5B656A", "Metal", DETAIL)
	sb(atlantis, "BrakeActuator", V(side * 0.35, 7, 24.5), V(side * 0.82, 7, 25.4), 0.13, 0.13, SILVER)
end
component(hull, "tail", shuttleCF:PointToWorldSpace(V(0, 13, 23)))
local tailFlag = sp(atlantis, "TailFlag", V(-0.34, 11.8, 23), V(2.5, 1.4, 0.04), WHITE, nil, nil, CFrame.Angles(0, math.pi / 2, 0))
flag(tailFlag, shuttleCF:VectorToWorldSpace(V(-1, 0, 0)))
local enginesAnchor = anchor(atlantis, "EngineAxis", shuttleCF:PointToWorldSpace(V(0, 0, 26.5)))
component(enginesAnchor, "main_engines")
for i, d in { { 0, 1.1 }, { -2.05, -1.1 }, { 2.05, -1.1 } } do
	bell(atlantis, "SSME_" .. i, shuttleCF * CF(d[1], d[2], 26.46) * CFrame.Angles(0, math.pi / 2, 0), 2.5, 1.65, 10)
end
for _, side in { -1, 1 } do
	bell(atlantis, "OMS_Engine", shuttleCF * CF(side * 4.1, 3.0, 25.1) * CFrame.Angles(0, math.pi / 2, 0), 1.5, 0.7, 8)
end
-- Portas com pivô exatamente na dobradiça longitudinal, HingeOffset relativo a ele.
for _, side in { -1, 1 } do
	local door = model(atlantis, side == -1 and "PayloadDoor_L" or "PayloadDoor_R")
	local hingeCF = shuttleCF * CF(side * 4.65, 0.7, 3.8)
	local openAngle = -side * 135
	door:SetAttribute("HingeOffset", CFrame.identity)
	door:SetAttribute("OpenAngle", openAngle)
	door:SetAttribute("ClosedPivot", hingeCF)
	local hinge = anchor(door, "Hinge", hingeCF.Position)
	hinge.CFrame = hingeCF
	door.PrimaryPart = hinge
	for j = 0, 5 do
		local a = side == 1 and (j + 0.5) * math.pi / 12 or math.pi - (j + 0.5) * math.pi / 12
		local x, y = 4.65 * math.cos(a), 0.7 + 4.65 * math.sin(a)
		sp(door, "RadiatorPipe", V(x * 0.975, y - 0.13, 3.8), V(27.5, 0.07, 0.07), "#737F82", "Metal", "Cylinder", CFrame.Angles(0, math.pi / 2, 0))
		sp(door, "DoorShell", V(x, y, 3.8), V(1.25, 0.13, j % 2 == 0 and 28 or 28.04), WHITE, "SmoothPlastic", nil, CFrame.Angles(0, 0, a - math.pi / 2))
		for z = -8, 16, 4 do
			sp(door, "RadiatorPanel", V(x * 0.975, y - 0.1, z), V(1.08, 0.06, 3.7), "#D1D4CE", "SmoothPlastic", nil, CFrame.Angles(0, 0, a - math.pi / 2))
		end
	end
	for _, z in { -8, 3.8, 16 } do
		sp(door, "DoorHingeCollar", V(side * 4.65, 0.7, z), V(0.5, 0.4, 0.4), SILVER, "Metal", "Cylinder", CFrame.Angles(0, math.pi / 2, 0))
	end
	door:PivotTo(hingeCF * CFrame.Angles(0, 0, RAD(openAngle)))
end
-- Canadarm articulado, preso ao longeron esquerdo, com juntas e efetuador.
local armPoints = { V(-4.4, 1.0, -6), V(-7, 7, -5), V(-10, 13, 3), V(-13, 14, 11), V(-13, 13, 14) }
for i = 1, #armPoints - 1 do
	sb(atlantis, "CanadarmSegment", armPoints[i], armPoints[i + 1], 0.42, 0.42, WHITE, "SmoothPlastic")
	sp(atlantis, "CanadarmJoint", armPoints[i], V(0.8, 0.8, 0.8), "#5B6267", "Metal", "Ball")
end
local hand = sp(atlantis, "EndEffector", armPoints[#armPoints], V(0.8, 0.8, 1.0), SILVER, "Metal")
component(hand, "canadarm")
-- Pedestal próprio, em dois pontos de apoio sob a fuselagem inclinada.
for _, z in { -5, 16 } do
	local contact = shuttleCF:PointToWorldSpace(V(0, -3.0, z))
	plinth(atlantis, contact.X + 2.8, contact.Z, 7, 7, 0.7)
	part(atlantis, "SupportJoint", CF(contact) * CFrame.Angles(0, 0, math.pi / 2), V(1.7, 2.1, 2.1), SILVER, "Metal", DETAIL, "Cylinder")
	B.cylBetween(atlantis, "DisplaySupport", V(contact.X + 2.8, 0.7, contact.Z), contact, 1.4, "#525B63", "Metal", {})
	B.cylBetween(atlantis, "SupportBrace", V(contact.X + 5, 0.7, contact.Z), contact - V(0, 3, 0), 0.45, SILVER, "Metal", {})
end
task.wait()

--------------------------------------------------------------------------------
-- HUBBLE: tubo de ~19 studs, abertura escura, folhas solares e antenas.
--------------------------------------------------------------------------------
local hubble = exhibit("Hubble", "hubble", V(343, 4, 87))
local hx, hy, hz = 348, 12, 85
hubble.PrimaryPart = axial(hubble, "OpticalTube", hx - 9.5, hx + 9.5, 3.0, SILVER, hy, hz, "Foil")
component(hubble.PrimaryPart, "optics", V(hx - 9.5, hy, hz))
for _, dx in { -8.5, -2, 3, 8.7 } do
	axial(hubble, "TubeBand", hx + dx, hx + dx + 0.16, 3.07, "#DBDCD5", hy, hz, "Foil")
end
axial(hubble, "DarkAperture", hx - 9.58, hx - 9.49, 2.7, "#080E14", hy, hz)
part(hubble, "ApertureDoor", CF(hx - 10.0, hy + 3.6, hz) * CFrame.Angles(0, 0, RAD(-35)), V(0.15, 5.9, 5.9), SILVER, "Foil", DETAIL, "Cylinder")
for _, side in { -1, 1 } do
	B.beam(hubble, "SolarBoom", V(hx + 1, hy, hz), V(hx + 1, hy, hz + side * 8.5), 0.08, 0.08, SILVER, "Metal", DETAIL)
	local panel = part(hubble, "SolarArray", CF(hx + 1, hy, hz + side * 7), V(11.5, 0.12, 5.5), "#172E51", "Glass", DETAIL)
	panel.Transparency = 0
	panel.Reflectance = 0.15
	component(panel, side == -1 and "solar_l" or "solar_r")
	for dx = -4.8, 5, 1.2 do
		part(hubble, "SolarCellGrid", CF(hx + 1 + dx, hy + 0.08, hz + side * 7), V(0.03, 0.03, 5.5), "#7B8D9D", "Metal", DETAIL)
	end
	for dz = -2, 2, 1 do
		part(hubble, "SolarCellGrid", CF(hx + 1, hy + 0.08, hz + side * 7 + dz), V(11.5, 0.03, 0.025), "#7B8D9D", "Metal", DETAIL)
	end
	B.beam(hubble, "AntennaBoom", V(hx + 4, hy + 1, hz), V(hx + 5, hy + 5, hz + side * 2.5), 0.12, 0.12, WHITE, "Metal", DETAIL)
	part(hubble, "HighGainAntenna", CF(hx + 5, hy + 5, hz + side * 2.5) * CFrame.Angles(0, 0, math.pi / 2), V(0.15, 2.0, 2.0), WHITE, "SmoothPlastic", DETAIL, "Cylinder")
end
for _, dx in { -5.5, 5.5 } do
	plinth(hubble, hx + dx, hz, 3, 4, 0.5)
	B.cyl(hubble, "SupportCollar", hx + dx, hz, hy - 3.5, hy - 2.8, 1.0, SILVER, "Metal", DETAIL)
	B.cylBetween(hubble, "DisplaySupport", V(hx + dx, 0.5, hz), V(hx + dx, hy - 3, hz), 0.6, "#59616A", "Metal", {})
end

--------------------------------------------------------------------------------
-- MERCURY: dimensões menores em escala real; torre e detalhes aproximados.
--------------------------------------------------------------------------------
local function capsuleGeometry(parent, x, floor, z, scale, tower)
	-- aproximação: cápsula Mercury ~2,7 m × 1,9 m, sem a torre de escape.
	local shield = B.cyl(parent, "HeatShield", x, z, floor, floor + 0.3 * scale, 2.75 * scale, "#55483C", "SmoothPlastic", DECOR)
	for j = 0, 7 do
		local a, b = j * math.pi / 4, (j + 1) * math.pi / 4
		B.cylBetween(parent, "HeatShieldRim", V(x + 1.39 * scale * math.cos(a), floor + 0.14 * scale, z + 1.39 * scale * math.sin(a)), V(x + 1.39 * scale * math.cos(b), floor + 0.14 * scale, z + 1.39 * scale * math.sin(b)), 0.07 * scale, "#8C8274", "Metal", DETAIL)
	end
	B.cyl(parent, "AntennaMast", x, z, floor + 3.85 * scale, floor + 4.3 * scale, 0.06 * scale, SILVER, "Metal", DETAIL)
	for _, side in { -1, 1 } do
		B.cylBetween(parent, "AntennaWhip", V(x, floor + 4.15 * scale, z), V(x + side * 0.60 * scale, floor + 4.22 * scale, z), 0.025 * scale, SILVER, "Metal", DETAIL)
	end
	B.cone(parent, "PressureVessel", x, z, floor + 0.3 * scale, floor + 2.8 * scale, 2.7 * scale, 1.15 * scale, 18, "#343A3D", "Metal", DECOR)
	B.cyl(parent, "RecoveryCompartment", x, z, floor + 2.8 * scale, floor + 3.7 * scale, 1.13 * scale, BLACK, "Metal", DECOR)
	B.cone(parent, "AntennaFairing", x, z, floor + 3.7 * scale, floor + 4.1 * scale, 1.13 * scale, 0.4 * scale, 6, BLACK, "SmoothPlastic", DECOR)
	for i = 0, 19 do
		local a = i * math.pi / 10
		B.beam(parent, "CapsuleCorrugation", V(x + 1.3 * scale * math.cos(a), floor + 0.4 * scale, z + 1.3 * scale * math.sin(a)), V(x + 0.6 * scale * math.cos(a), floor + 2.7 * scale, z + 0.6 * scale * math.sin(a)), 0.03 * scale, 0.035 * scale, "#747A7B", "Metal", DETAIL)
	end
	local window = part(parent, "ObservationWindow", CF(x, floor + 2.0 * scale, z - 0.94 * scale) * CFrame.Angles(RAD(-18), 0, 0), V(0.42, 0.7, 0.08) * scale, "#7497AB", "Glass", DETAIL)
	for i = 0, 2 do
		local a = RAD(120 * i + 30)
		B.cylBetween(parent, "RetropackStrap", V(x + 1.4 * scale * math.cos(a), floor + 0.1 * scale, z + 1.4 * scale * math.sin(a)), V(x + 0.5 * scale * math.cos(a), floor - 0.3 * scale, z + 0.5 * scale * math.sin(a)), 0.08 * scale, SILVER, "Metal", DETAIL)
		B.cyl(parent, "Retrorocket", x + 0.43 * scale * math.cos(a), z + 0.43 * scale * math.sin(a), floor - 0.35 * scale, floor + 0.03 * scale, 0.4 * scale, "#9E9D8F", "Metal", DETAIL)
	end
	if tower then
		for i = 0, 2 do
			local a, b = RAD(i * 120), RAD((i + 1) * 120)
			local bottom = V(x + math.cos(a) * 0.72 * scale, floor + 3.1 * scale, z + math.sin(a) * 0.72 * scale)
			local top = V(x + math.cos(a) * 0.32 * scale, floor + 6.4 * scale, z + math.sin(a) * 0.32 * scale)
			B.cylBetween(parent, "EscapeTowerLeg", bottom, top, 0.08 * scale, "#B94A34", "SmoothPlastic", DETAIL)
			B.cylBetween(parent, "EscapeTowerBrace", bottom, V(x + math.cos(b) * 0.32 * scale, floor + 6.4 * scale, z + math.sin(b) * 0.32 * scale), 0.055 * scale, "#B94A34", "SmoothPlastic", DETAIL)
		end
		B.cyl(parent, "EscapeMotor", x, z, floor + 6.1 * scale, floor + 7.4 * scale, 0.58 * scale, "#B94A34", "SmoothPlastic", DETAIL)
		B.cone(parent, "EscapeNose", x, z, floor + 7.4 * scale, floor + 8.0 * scale, 0.58 * scale, 0.02, 6, "#B94A34", "SmoothPlastic", DETAIL)
	end
	return shield, window
end
local mercury = exhibit("MercuryCapsule", "mercury_capsule", V(163, 4, 73))
plinth(mercury, 163, 79, 7, 7, 1)
B.cyl(mercury, "Cradle", 163, 79, 1.03, 1.8, 1.2, SILVER, "Metal", DECOR)
local heatShield, mercuryWindow = capsuleGeometry(mercury, 163, 1.8, 79, 1, true)
mercury.PrimaryPart = heatShield
component(heatShield, "heat_shield")
component(mercuryWindow, "window")
component(heatShield, "parachute", V(163, 5.1, 79))
component(heatShield, "retrorockets", V(163, 1.55, 79))
local capsuleMarking = part(mercury, "UnitedStates", CF(163, 2.65, 77.77), V(1.4, 0.35, 0.04), "#343A3D", nil, DETAIL)
lettering(capsuleMarking, "UNITED STATES", "#EFEFE8", Enum.NormalId.Front, V(0, 0, -1))

local suit = exhibit("MercurySuit", "mercury_suit", V(184, 4, 74))
suit.PrimaryPart = plinth(suit, 184, 80, 6, 5, 1, nil, 0.15)
-- aproximação: figura de 2,60 studs; coordenadas abaixo relativas ao piso da vitrine.
local suitCF = CF(184, 1.08, 80)
local function su(name, pos, size, color, shape, rotation, material)
	return part(suit, name, suitCF * CF(pos) * (rotation or CFrame.identity), size, color or "#C9CCCD", material or "Foil", DETAIL, shape)
end
local vertical = CFrame.Angles(0, 0, math.pi / 2)
-- Cylinder tem comprimento em Size.X: após o giro, X vira a altura em Y.
-- Botas 0..0,26; pernas 0,22..1,18; quadris 1,03..1,29.
su("MannequinBase", V(0, 0.04, 0), V(0.08, 1.5, 0.9), "#525D63", "Cylinder", vertical, "Metal")
su("DisplayStem", V(0, 0.82, 0.20), V(1.56, 0.08, 0.08), SILVER, "Cylinder", vertical, "Metal")
for _, side in { -1, 1 } do
	su("Boot", V(side * 0.22, 0.13, -0.1), V(0.36, 0.26, 0.62), "#676E73", nil, nil, "SmoothPlastic")
	su("Leg", V(side * 0.22, 0.70, 0), V(0.96, 0.36, 0.39), "#C9CCCD", "Cylinder", vertical)
	su("Shoulder", V(side * 0.43, 1.81, 0), V(0.36, 0.36, 0.36), "#C9CCCD", "Ball")
	su("Arm", V(side * 0.53, 1.53, 0), V(0.86, 0.31, 0.33), "#C9CCCD", "Cylinder", vertical)
	su("Glove", V(side * 0.53, 1.02, -0.02), V(0.32, 0.34, 0.34), "#C9CCCD", "Ball")
	for y = 0.4, 0.9, 0.16 do
		su("SuitPleat", V(side * 0.22, y, 0), V(0.38, 0.035, 0.42), "#C9CCCD")
	end
end
su("HipSection", V(0, 1.16, 0), V(0.74, 0.26, 0.47), "#C9CCCD")
su("Torso", V(0, 1.51, 0), V(0.88, 0.96, 0.50), "#C9CCCD", "Ball")
su("Neck", V(0, 1.98, 0), V(0.24, 0.30, 0.30), "#C9CCCD", "Cylinder", vertical)
su("Harness", V(0, 1.5, -0.22), V(0.13, 0.58, 0.08), WHITE, nil, nil, "SmoothPlastic")
su("ChestFitting", V(0.24, 1.4, -0.25), V(0.18, 0.18, 0.18), BLACK, "Ball", nil, "Metal")
-- Tronco até 1,99; pescoço 1,86..2,10; capacete 1,86..2,60.
su("Helmet", V(0, 2.23, 0), V(0.74, 0.74, 0.74), "#C9CCCD", "Ball")
local visor = su("Visor", V(0, 2.23, -0.22), V(0.58, 0.5, 0.4), "#403E32", "Ball", nil, "Glass")
visor.Reflectance = 0.15
component(visor, "helmet")
glassCase(suit, 184, 80, 5.7, 4.7, 1.08, 4.5)

-- Painéis vazios: a face Front aponta para o visitante; memorial gira para +Z.
local function boardExhibit(name, id, x, y, z, width, height, floor, facePositiveZ)
	local back = facePositiveZ and -1 or 1
	local m = exhibit(name, id, V(x, (floor or 0) + 3.8, z - back * 3))
	local board = part(m, "Board", CF(x, y, z) * CFrame.Angles(0, facePositiveZ and math.pi or 0, 0), V(width, height, 0.18), "#172333", "Metal", {})
	board:SetAttribute("DisplayFace", "Front")
	m.PrimaryPart = board
	part(m, "BoardFrame", CF(x, y, z + back * 0.16), V(width + 0.20, height - 0.08, 0.16), "#454D53", "Metal", DETAIL)
	roundedFrame(m, board.CFrame * CF(0, 0, -0.02), width, height, "BoardRim", "#59666E")
	-- Painéis autossustentados junto da parede, sem depender da existência do salão.
	for _, side in { -1, 1 } do
		local bottom = floor or 0
		B.cyl(m, "BoardPost", x + side * width * 0.35, z + back * 0.2, bottom, y - height / 2, 0.16, "#454D53", "Metal", {})
	end
	return m
end
boardExhibit("SpaceRace", "space_race", 155, 5.6, 98.5, 13, 7.5)
-- 13 de largura (X 175..188 de projeto): livre da coluna RoundColumn do salão.
boardExhibit("MercurySeven", "mercury_seven", 181.5, 5.6, 98.5, 13, 7.5)
task.wait()

--------------------------------------------------------------------------------
-- JARDIM: Redstone (~36) e Atlas (~41), sem ultrapassar o teto Y72.
--------------------------------------------------------------------------------
for _, data in { { "MercuryRedstone", "mercury_redstone", 235, 36, false }, { "MercuryAtlas", "mercury_atlas", 290, 41, true } } do
	local name, id, x, height, atlas = table.unpack(data)
	local z, base = 127, 1
	local rocket = exhibit(name, id, V(x, 4, 119))
	rocket:SetAttribute("DesignHeight", height)
	plinth(rocket, x, z, atlas and 10 or 8, atlas and 10 or 8, base)
	local booster = model(rocket, "Booster")
	booster:SetAttribute("StageIndex", 1)
	local capsuleBase = base + height - 8
	local diameter = atlas and 4.35 or 2.55 -- aproximação: diâmetros da família Mercury.
	local body = B.cyl(booster, "Tank", x, z, base + 1.2, capsuleBase - (atlas and 4 or 0.2), diameter, atlas and "#C9CCCD" or WHITE, atlas and "Foil" or "SmoothPlastic", DECOR)
	booster.PrimaryPart = body
	rocket.PrimaryPart = body
	component(body, "booster")
	if atlas then
		B.cone(booster, "UpperAdapter", x, z, capsuleBase - 4, capsuleBase, diameter, 2.75, 14, SILVER, "Foil", DECOR)
		for _, y in { 3.0, 8, 17, 26, 29.5 } do
			B.cyl(booster, "StainlessSeam", x, z, base + y, base + y + 0.1, diameter + 0.06, "#7B8589", "Metal", DETAIL)
		end
		for _, side in { -1, 1 } do
			B.cone(booster, "BoosterEngineFairing", x + side * 2.1, z, base + 0.4, base + 5.5, 1.7, 0.4, 8, SILVER, "Foil", DECOR)
			B.cyl(booster, "Engine", x + side * 2.1, z, base + 0.03, base + 1.3, 1.15, BLACK, "Metal", DETAIL)
		end
		part(booster, "ExternalConduit", CF(x + 2.23, (base + capsuleBase) / 2, z), V(0.18, capsuleBase - base - 2, 0.18), "#757E82", "Metal", DETAIL)
	else
		B.cyl(booster, "AftBlackBand", x, z, base + 1.17, base + 3.5, diameter + 0.04, BLACK, "SmoothPlastic", DETAIL)
		B.cyl(booster, "ForwardBlackBand", x, z, capsuleBase - 3.2, capsuleBase - 2.0, diameter + 0.04, BLACK, "SmoothPlastic", DETAIL)
		for j = 0, 3 do
			local a = RAD(j * 90)
			part(booster, "RedstoneFin", CF(x, base + 2.31, z) * CFrame.Angles(0, a, 0) * CF(1.8, 0, 0), V(1.8, 4.5, 0.13), j % 2 == 0 and BLACK or WHITE, "SmoothPlastic", DETAIL, "Wedge")
			part(booster, "RollPattern", CF(x + 1.3 * math.sin(a), capsuleBase - 5.2, z + 1.3 * math.cos(a)) * CFrame.Angles(0, a, 0), V(0.65, 3.8, 0.035), BLACK, nil, DETAIL)
		end
	end
	local upper = model(rocket, "MercurySpacecraft")
	upper:SetAttribute("StageIndex", 2)
	local shield = capsuleGeometry(upper, x, capsuleBase, z, 1, true)
	upper.PrimaryPart = shield
	component(shield, "capsule")
	local marking = part(booster, "UnitedStates", CF(x, base + 14.0, z - diameter / 2 - 0.04), V(1.0, 11.5, 0.04), atlas and SILVER or WHITE, nil, DETAIL)
	lettering(marking, "U\nN\nI\nT\nE\nD\n\nS\nT\nA\nT\nE\nS", atlas and "#272D32" or "#202124", Enum.NormalId.Front, V(0, 0, -1))
	local p = part(booster, "Flag", CF(x, capsuleBase - (atlas and 8.6 or 7.7), z - diameter / 2 - 0.06), V(1.5, 0.85, 0.04), WHITE, nil, DETAIL)
	flag(p, V(0, 0, -1))
end

--------------------------------------------------------------------------------
-- APOLLO CM: escotilha aberta, interior simples visível, vitrine real em folhas.
--------------------------------------------------------------------------------
local apollo = exhibit("ApolloCommandModule", "apollo_cm", V(222, 4, 7))
plinth(apollo, 222, 14, 9, 9, 1.1, nil, 0.20)
local cmBase, cmHeight, cmR = 1.8, 3.6, 2.85 -- aproximação: envelope do CM sem SM.
local cmShield = B.cyl(apollo, "HeatShield", 222, 14, cmBase, cmBase + 0.3, cmR * 2, "#514337", "SmoothPlastic", DECOR)
apollo.PrimaryPart = cmShield
B.cyl(apollo, "DisplayMount", 222, 14, 1.18, cmBase, 1.4, "#7A8081", "Metal", DECOR)
for j = 0, 23 do
	local a = (j + 0.5) * math.pi / 12
	-- abertura voltada à plateia (−Z); permite olhar os assentos pelo hatch.
	if not (j >= 16 and j <= 19) then
		local p0 = V(222 + cmR * math.cos(a), cmBase + 0.3, 14 + cmR * math.sin(a))
		local p1 = V(222 + 0.7 * math.cos(a), cmBase + cmHeight, 14 + 0.7 * math.sin(a))
		local right, up = (p1 - p0).Unit, V(-math.sin(a), 0, math.cos(a))
		part(apollo, "CMHullPanel", CFrame.fromMatrix((p0 + p1) / 2, right, up, right:Cross(up)), V((p1 - p0).Magnitude, 0.76, 0.08), SILVER, "Foil", DETAIL)
	end
end
B.cyl(apollo, "DockingRing", 222, 14, cmBase + cmHeight, cmBase + cmHeight + 0.35, 1.45, BLACK, "Metal", DETAIL)
-- Borda do primeiro painel após o vão: j20, centro 307,5°, meia largura 0,38.
-- A aresta fica ~296,8° em Y3,4; a dobradiça segue a geratriz inclinada.
local hingeY, panelAngle = 3.4, RAD(307.5)
local cmSlope = (cmR - 0.7) / (cmHeight - 0.3)
local hingeRadius = cmR - cmSlope * (hingeY - cmBase - 0.3)
local tangent = V(-math.sin(panelAngle), 0, math.cos(panelAngle))
local hingeUp = V(-cmSlope * math.cos(panelAngle), 1, -cmSlope * math.sin(panelAngle)).Unit
local hingeBack = tangent:Cross(hingeUp).Unit
local hullEdge = V(222 + hingeRadius * math.cos(panelAngle), hingeY, 14 + hingeRadius * math.sin(panelAngle)) - tangent * 0.38
-- Calço físico de 0,22 deixa a folha e sua moldura livres da espessura do casco.
local hingeCF = CFrame.fromMatrix(hullEdge - hingeBack * 0.22, tangent, hingeUp, hingeBack)
local hatchCF = hingeCF * CFrame.Angles(0, RAD(-105), 0) * CF(-0.85, 0, 0)
local hatch = part(apollo, "OpenHatch", hatchCF, V(1.7, 2.2, 0.12), SILVER, "Foil", DETAIL)
-- A moldura fica dentro dos limites da folha, inclusive junto à dobradiça.
roundedFrame(apollo, hatch.CFrame * CF(0, 0, -0.07), 1.22, 1.72, "HatchRim", SILVER)
part(apollo, "HatchWindow", hatch.CFrame * CF(0, 0.35, -0.08), V(0.55, 0.45, 0.06), "#193441", "Glass", DETAIL)
for _, side in { -1, 1 } do
	local along = hingeUp * (side * 0.70)
	local pivot = hingeCF.Position + along
	B.cylBetween(apollo, "HatchHingeMount", hullEdge + along, pivot, 0.12, SILVER, "Metal", DETAIL)
	B.cylBetween(apollo, "HatchHinge", pivot - hingeUp * 0.25, pivot + hingeUp * 0.25, 0.16, SILVER, "Metal", DETAIL)
end
B.cylBetween(apollo, "HatchHandle", hatch.CFrame:PointToWorldSpace(V(-0.28, -0.42, -0.20)), hatch.CFrame:PointToWorldSpace(V(0.28, -0.42, -0.20)), 0.10, "#606A70", "Metal", DETAIL)
for _, side in { -1, 1 } do
	B.cylBetween(apollo, "HandleMount", hatch.CFrame:PointToWorldSpace(V(side * 0.28, -0.42, -0.20)), hatch.CFrame:PointToWorldSpace(V(side * 0.28, -0.42, -0.04)), 0.10, "#606A70", "Metal", DETAIL)
end
for _, side in { -1, 1 } do
	local pos = V(222 + side * 1.18, 3.85, 12.73)
	local windowCF = CFrame.lookAt(pos, pos + V(side * 0.68, 0.65, -0.73))
	part(apollo, "CMWindowFrame", windowCF, V(0.70, 0.63, 0.14), "#606A70", "Metal", DETAIL)
	part(apollo, "CMWindow", windowCF * CF(0, 0, -0.085), V(0.51, 0.45, 0.04), "#173541", "Glass", DETAIL)
end
for _, x in { 221, 222, 223 } do
	part(apollo, "CrewCouch", CF(x, 2.65, 14.1) * CFrame.Angles(RAD(-25), 0, 0), V(0.78, 1.3, 0.3), "#6A7777", "Fabric", DETAIL)
	part(apollo, "CouchRestraint", CF(x, 2.65, 13.9), V(0.12, 1.15, 0.04), "#D0C6AC", "Fabric", DETAIL)
end
local panel = part(apollo, "InstrumentPanel", CF(222, 3.8, 14.9) * CFrame.Angles(RAD(15), 0, 0), V(3, 1.3, 0.15), "#242C30", "SmoothPlastic", DETAIL)
for row = 0, 2 do
	for col = 0, 7 do
		part(apollo, "Instrument", panel.CFrame * CF(-1.25 + col * 0.35, -0.4 + row * 0.35, -0.11), V(0.16, 0.16, 0.04), col % 3 == 0 and "#A0AC8F" or "#5D686B", nil, DETAIL)
	end
end
component(hatch, "hatch")
component(cmShield, "heat_shield")
component(panel, "interior")
component(panel, "InteriorView", V(222, 3.4, 12.7))
glassCase(apollo, 222, 14, 8.6, 8.6, 1.18, 6.3)
local timeline = exhibit("Apollo11Timeline", "apollo11_timeline", V(250, 4, 42))
timeline.PrimaryPart = plinth(timeline, 249, 47, 49, 1.7, 0.6)
for i = 1, 6 do
	local x = 225.5 + (i - 0.5) * 7.8
	local p = part(timeline, "Board_" .. i, CF(x, 4.4, 47), V(7.4, 4.2, 0.16), "#172333", "Metal", {})
	p:SetAttribute("DisplayFace", "Front")
	roundedFrame(timeline, p.CFrame * CF(0, 0, -0.02), 7.4, 4.2, "TimelineRim", "#59666E")
	component(p, "step_" .. i)
	B.cyl(timeline, "BoardPost", x, 47.2, 0.1, 2.9, 0.16, "#626B70", "Metal", {})
end

--------------------------------------------------------------------------------
-- MEMORIAL: piso rebaixado em −3; painéis vazios e nenhum efeito de show.
--------------------------------------------------------------------------------
for _, d in { { "MemorialApollo1", "memorial_apollo1", 355 }, { "MemorialChallenger", "memorial_challenger", 373 }, { "MemorialColumbia", "memorial_columbia", 389 } } do
	boardExhibit(d[1], d[2], d[3], 1.8, -41.5, 12.5, 7.5, -3, true)
end

--------------------------------------------------------------------------------
-- MARTE: rover com comprimento real de 4,3 studs, seis rodas e rocker-bogie.
--------------------------------------------------------------------------------
local rover = exhibit("MarsRover", "mars_rover", V(307, 3.2, -15))
plinth(rover, 307, -25, 9, 8, 0.25)
-- Frente do veículo para +Z de projeto; PromptAnchor permanece no corredor +Z.
local roverCF = CF(307, 0.30, -25) -- rodas sobre o PlinthTopEnd (topo 0,29..0,31) * CFrame.Angles(0, math.pi, 0)
local function rp(name, pos, size, color, material, shape, rotation)
	return part(rover, name, roverCF * CF(pos) * (rotation or CFrame.identity), size, color, material, DETAIL, shape)
end
local body = rp("Chassis", V(0, 1.25, 0), V(2.6, 0.8, 3.2), "#D6CDB7", "Metal")
rover.PrimaryPart = body
rover:SetAttribute("VehicleLength", 4.3)
for _, side in { -1, 1 } do
	for _, z in { -1.65, 0, 1.65 } do
		local wheel = rp("Wheel", V(side * 1.75, 0.5, z), V(0.38, 1, 1), "#515557", "Metal", "Cylinder")
		rp("WheelRim", V(side * 1.96, 0.5, z), V(0.06, 0.82, 0.82), "#A7ADAC", "Metal", "Cylinder")
		rp("WheelHub", V(side * 2.0, 0.5, z), V(0.10, 0.32, 0.32), "#656E72", "Metal", "Cylinder")
		for spoke = 0, 2 do
			local a = spoke * 2 * math.pi / 3
			rp("WheelSpoke", V(side * 2.0, 0.5 + 0.24 * math.cos(a), z + 0.24 * math.sin(a)), V(0.04, 0.40, 0.06), "#5C6569", "Metal", nil, CFrame.Angles(a, 0, 0))
		end
		for j = 0, 7 do
			local a = j * math.pi / 4
			rp("WheelGrouser", V(side * 1.75, 0.5 + 0.5 * math.cos(a), z + 0.5 * math.sin(a)), V(0.4, 0.04, 0.08), "#9B9F9F", "Metal", nil, CFrame.Angles(a, 0, 0))
		end
		component(wheel, (side == -1 and "wheel_l_" or "wheel_r_") .. (z == -1.65 and "1" or (z == 0 and "2" or "3")))
		B.beam(rover, "Suspension", roverCF:PointToWorldSpace(V(side * 1.15, 1.2, 0)), roverCF:PointToWorldSpace(V(side * 1.75, 0.55, z)), 0.10, 0.10, SILVER, "Metal", DETAIL)
	end
end
rp("Deck", V(0, 1.7, 0), V(2.8, 0.12, 3.3), "#D9D2BF", "Metal")
rp("Mast", V(0.65, 2.35, -1), V(1.3, 0.16, 0.16), WHITE, "SmoothPlastic", "Cylinder", CFrame.Angles(0, 0, math.pi / 2))
rp("MastPanJoint", V(0.65, 2.83, -1), V(0.18, 0.35, 0.35), "#525D63", "Metal", "Cylinder", CFrame.Angles(0, 0, math.pi / 2))
local camera = rp("MastCamera", V(0.65, 3.0, -1.05), V(1, 0.4, 0.4), WHITE, "SmoothPlastic")
component(camera, "mast")
for _, x in { 0.4, 0.9 } do
	rp("CameraLensRim", V(x, 3.0, -1.26), V(0.07, 0.23, 0.23), "#727F83", "Metal", "Cylinder", CFrame.Angles(0, math.pi / 2, 0))
	rp("CameraLens", V(x, 3.0, -1.27), V(0.16, 0.16, 0.1), "#14242C", "Glass", "Cylinder", CFrame.Angles(0, math.pi / 2, 0))
end
rp("RTG", V(0, 1.8, 1.55), V(0.75, 0.65, 0.9), "#737976", "Metal")
for z = 1.24, 1.9, 0.12 do
	rp("RTGFin", V(0, 1.8, z), V(0.98, 0.8, 0.035), "#A7ABA6", "Metal")
end
B.beam(rover, "RoboticArm", roverCF:PointToWorldSpace(V(-0.8, 1.3, -1.4)), roverCF:PointToWorldSpace(V(-1.0, 0.95, -2.0)), 0.12, 0.12, WHITE, "Metal", DETAIL)
local drill = rp("ArmTurret", V(-1, 0.95, -1.98), V(0.36, 0.36, 0.34), "#7C8077", "Metal", "Ball")
component(drill, "arm")
rp("HighGainAntenna", V(-0.7, 2, 0.4), V(0.1, 0.85, 0.85), "#D5C6A1", "SmoothPlastic", "Cylinder", CFrame.Angles(0, 0, math.pi / 2))

--------------------------------------------------------------------------------
-- MODERNA: Orion com módulo europeu e SLS reduzido, explicitamente rotulado.
--------------------------------------------------------------------------------
local modern = exhibit("OrionSLS", "orion_sls", V(240, 4, -15))
modern.PrimaryPart = plinth(modern, 236, -27, 12, 12, 0.7)
local orion = model(modern, "Orion")
B.cyl(orion, "ServiceModule", 236, -27, 1.5, 5.4, 5.8, WHITE, "SmoothPlastic", DECOR)
for j = 0, 15 do
	local a = j * math.pi / 8
	part(orion, "ServiceRadiator", CF(236 + 2.94 * math.cos(a), 3.5, -27 + 2.94 * math.sin(a)) * CFrame.Angles(0, -a, 0), V(0.09, 3.4, 0.5), WHITE, "SmoothPlastic", DETAIL)
end
local orionShield = B.cyl(orion, "HeatShield", 236, -27, 5.4, 5.7, 7.15, "#675C4D", "SmoothPlastic", DECOR)
B.cone(orion, "CrewModule", 236, -27, 5.7, 9.6, 7.1, 2.5, 22, SILVER, "Foil", DECOR)
B.cyl(orion, "DockingAdapter", 236, -27, 9.6, 10.2, 2.45, WHITE, "SmoothPlastic", DECOR)
B.cyl(orion, "DisplayMount", 236, -27, 0.78, 1.5, 1.8, "#525D63", "Metal", DECOR)
orion.PrimaryPart = orionShield
local orionHatch = part(orion, "CrewHatch", CF(236, 7.2, -29.7) * CFrame.Angles(RAD(31), 0, 0), V(1.05, 1.25, 0.08), "#8F9B9E", "Foil", DETAIL)
roundedFrame(orion, orionHatch.CFrame * CF(0, 0, -0.05), 1.05, 1.25, "CrewHatchRim", SILVER)
for _, side in { -1, 1 } do
	local pos = V(236 + side * 1.32, 8.1, -28.72)
	part(orion, "CrewWindow", CFrame.lookAt(pos, pos + V(side * 0.61, 0.59, -0.79)), V(0.48, 0.35, 0.10), "#183C4B", "Glass", DETAIL)
end
for j = 0, 3 do
	local a = j * math.pi / 2
	for _, side in { -1, 1 } do
		local pos = V(236 + 3.0 * math.cos(a), 4.9 + side * 0.16, -27 + 3.0 * math.sin(a))
		B.cylBetween(orion, "RCSNozzle", pos, pos + V(0.28 * math.cos(a), side * 0.18, 0.28 * math.sin(a)), 0.20, "#565E60", "Metal", DETAIL)
	end
end
component(orionShield, "orion")
component(orionShield, "service_module", V(236, 3.5, -27))
for j = 0, 3 do
	local a = RAD(j * 90 + 45)
	local start = V(236 + 2.8 * math.cos(a), 3.8, -27 + 2.8 * math.sin(a))
	local endPoint = V(236 + 6.0 * math.cos(a), 4.2, -27 + 6.0 * math.sin(a))
	B.beam(orion, "SolarArrayBoom", start, endPoint, 0.15, 0.15, SILVER, "Metal", DETAIL)
	local panel = part(orion, "SolarArray", CF(endPoint) * CFrame.Angles(0, -a, 0), V(4.0, 0.1, 1.6), "#253B59", "Glass", DETAIL)
	panel.Transparency = 0
	panel.Reflectance = 0.15
end
-- Gira somente a nave Orion, com seus Attachments; pedestal, SLS e prompt não mudam.
local orionTurn = CF(236, 0, -27) * CFrame.Angles(0, math.pi, 0) * CF(-236, 0, 27)
orion:PivotTo(orionTurn * orion:GetPivot())

-- aproximação: SLS Block 1 a 1:8 (98 m / 0,7 / 8 = 17,5 studs).
local sls = model(modern, "SLS_ScaleModel")
sls:SetAttribute("ScaleRatio", 1 / 8)
plinth(sls, 258, -27, 7, 7, 0.7)
local sy, sx, sz = 0.78, 258, -27
local core = B.cyl(sls, "CoreStage", sx, sz, sy + 0.5, sy + 12.5, 1.85, "#C46A2B", "SmoothPlastic", DECOR)
sls.PrimaryPart = core
component(core, "sls")
for _, side in { -1, 1 } do
	B.cyl(sls, "SolidRocketBooster", sx + side * 1.55, sz, sy + 0.3, sy + 11.6, 0.7, WHITE, "SmoothPlastic", DETAIL)
	B.cone(sls, "BoosterNose", sx + side * 1.55, sz, sy + 11.6, sy + 12.6, 0.7, 0.05, 6, WHITE, "SmoothPlastic", DETAIL)
	for y = 2, 10, 2 do
		B.cyl(sls, "BoosterJoint", sx + side * 1.55, sz, sy + y, sy + y + 0.06, 0.73, "#62686A", "Metal", DETAIL)
	end
end
B.cone(sls, "LaunchVehicleAdapter", sx, sz, sy + 12.5, sy + 13.7, 1.85, 1.05, 8, WHITE, "SmoothPlastic", DETAIL)
B.cyl(sls, "UpperStage", sx, sz, sy + 13.7, sy + 15.4, 1.05, WHITE, "SmoothPlastic", DETAIL)
B.cone(sls, "Orion", sx, sz, sy + 15.4, sy + 16.2, 1.05, 0.3, 7, WHITE, "SmoothPlastic", DETAIL)
B.cyl(sls, "AbortTower", sx, sz, sy + 16.2, sy + 17.5, 0.18, WHITE, "SmoothPlastic", DETAIL)
local scaleLabel = part(sls, "ScaleLabel", CF(sx, 1.5, sz + 3.4), V(6.8, 1.2, 0.12), "#172333", "Metal", DETAIL)
lettering(scaleLabel, "SLS · SCALE MODEL 1:8", "#ECEDE5", Enum.NormalId.Back, V(0, 0, 1))
task.wait()

-- Uma transformação rígida única. HingeOffset/DesignDimensions permanecem locais.
for _, item in Exhibits:GetDescendants() do
	local closedPivot = item:GetAttribute("ClosedPivot")
	if closedPivot then item:SetAttribute("ClosedPivot", MUSEUM_CF * closedPivot) end
	for _, key in { "EnginePlane", "EscapeTip" } do
		local point = item:GetAttribute(key)
		if point then item:SetAttribute(key, MUSEUM_CF:PointToWorldSpace(point)) end
	end
	local axis = item:GetAttribute("Axis")
	if axis then item:SetAttribute("Axis", MUSEUM_CF:VectorToWorldSpace(axis)) end
	-- Escalares da coordenada longitudinal: X de projeto passa a Z do mundo.
	for _, key in { "EnvelopeStart", "EnvelopeEnd" } do
		local coordinate = item:GetAttribute(key)
		if coordinate then item:SetAttribute(key, MUSEUM_CF:PointToWorldSpace(V(coordinate, 22, 27.5)).Z) end
	end
end
Exhibits:PivotTo(MUSEUM_CF * Exhibits:GetPivot())
task.wait()

-- Orçamento e invariantes locais: erros claros antes de entregar aos sistemas.
local requiredComponents = {
	saturn_v = { "s_ic", "s_ii", "s_ivb", "iu", "spacecraft", "les", "f1_1", "f1_2", "f1_3", "f1_4", "f1_5", "j2_ii_1", "j2_ii_2", "j2_ii_3", "j2_ii_4", "j2_ii_5", "j2_ivb" },
	atlantis = { "main_engines", "tiles", "wings", "tail", "cockpit", "canadarm" },
	mercury_capsule = { "heat_shield", "window", "parachute", "retrorockets" },
	mercury_suit = {}, space_race = {}, mercury_seven = {}, apollo_cm = {},
	apollo11_timeline = {}, hubble = {}, memorial_apollo1 = {},
	memorial_challenger = {}, memorial_columbia = {}, mercury_redstone = {},
	mercury_atlas = {}, mars_rover = {}, orion_sls = {},
}
local foundIds = {}
local count, exhibitCount = 0, 0
for _, d in Exhibits:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
		assert(d.Anchored, "Peça solta: " .. d:GetFullName())
	elseif d:IsA("Model") and CollectionService:HasTag(d, "Exhibit") then
		exhibitCount += 1
		local id = d:GetAttribute("ExhibitId")
		assert(requiredComponents[id] and not foundIds[id], "ExhibitId inválido/repetido: " .. d.Name)
		foundIds[id] = true
		assert(d.PrimaryPart and d:FindFirstChild("PromptAnchor"), "Exposição incompleta: " .. d.Name)
		local attachments = {}
		for _, item in d:GetDescendants() do
			if item:IsA("Attachment") then attachments[item.Name] = true end
		end
		for _, name in requiredComponents[id] do
			assert(attachments[name], "Componente ausente: " .. id .. "/" .. name)
		end
	end
end
assert(exhibitCount == 16, "Fase 17 exige as 16 exposições da demo")
Exhibits:SetAttribute("PartCount", count)
Exhibits:SetAttribute("ExhibitCount", exhibitCount)
if count > PART_BUDGET then
	warn(("Fase 17 excedeu o orçamento: %d peças (referência %d); construção mantida."):format(count, PART_BUDGET))
end
return ("Fase 17 construída: %d exposições, %d peças; Saturn V X205/Y22, Z125..283; Atlantis 43,21°."):format(exhibitCount, count)
