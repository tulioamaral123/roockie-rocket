--[[
	NASA Space Adventure — Fase 16: salão do museu, Revisão 2
	Contrato: docs/museu-contrato.md, seção Revisão 2 (prevalece sobre o restante).
	Toda arquitetura é construída no referencial de projeto e recebe MUSEUM_CF
	uma única vez no fim. Ligações e substitutos de paredes nascem em coordenadas
	de mundo e são convertidos para projeto antes de entrarem em SpaceMuseumHall.
	ExitDirection recebe somente a rotação; zonas, consultas e raios acompanham o giro.

	Idempotência: restaura propriedades Hall16Original* dos originais externos,
	incluindo o fechamento leste da revisão 1, e B.clear(Map) remove só a Fase 16.
	Abre a face sul real do planetário e dois vãos na parede leste do LCC por geometria,
	sem alterar telas, consoles, LCC_Links, lib, Lighting ou SpaceMuseumExhibits.
	Se as Fases 12/14 forem reconstruídas, reexecutar a Fase 16 depois delas.

	Baseplate: reúne as cinco Parts da divisão antiga pelos limites externos reais
	quando o fosso mudou; então divide no retângulo transformado do memorial.
	MemorialSplit + posição/tamanho do fundo garantem idempotência no destino novo.
	As cinco Parts de terreno são irmãs no workspace, sem BuildPhase. Sem CSG.
	Cantos, pilares, montantes, balcão, totem e pedestais arredondados; passagens com
	batentes cilíndricos e chanfros. Preserva o passe de iluminação da revisão 1.
	Orçamento: até 580 peças (505 + 15%, arredondado para baixo), 60 luzes, 3 sombras.
]]

local lib = ...
local B = lib.builder(16)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–14 antes")

local MUSEUM_CF = CFrame.new(205, 0, 85) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(-136, 0, -27.5)
local planetarium = Map:FindFirstChild("CapeCanaveralMuseum")
local walls = planetarium and planetarium:FindFirstChild("Walls")
local LCC = Map:FindFirstChild("LaunchControlCenter")
assert(walls and LCC, "Fase 16: execute as Fases 12 e 14 antes")

-- Restaura também as peças ocultadas pela revisão 1. Nunca move originais externos.
for _, p in Map:GetDescendants() do
	if p:IsA("BasePart") and p:GetAttribute("Hall16OriginalSize") then
		p.Size = p:GetAttribute("Hall16OriginalSize")
		local cf = p:GetAttribute("Hall16OriginalCFrame")
		if typeof(cf) == "CFrame" then p.CFrame = cf end
		for _, prop in { "Transparency", "CanCollide", "CanQuery", "CanTouch" } do
			p[prop] = p:GetAttribute("Hall16Original" .. prop)
		end
	end
end

local function worldBounds(p)
	local r, u, f = p.CFrame.RightVector, p.CFrame.UpVector, p.CFrame.LookVector
	local x, y, z = p.Size.X / 2, p.Size.Y / 2, p.Size.Z / 2
	local e = Vector3.new(math.abs(r.X) * x + math.abs(u.X) * y + math.abs(f.X) * z,
		math.abs(r.Y) * x + math.abs(u.Y) * y + math.abs(f.Y) * z,
		math.abs(r.Z) * x + math.abs(u.Z) * y + math.abs(f.Z) * z)
	return p.Position - e, p.Position + e
end

local function setBounds(p, lo, hi)
	p.Size = hi - lo
	p.CFrame = CFrame.new((lo + hi) / 2)
end

local memorialY = -3
local baseplate = workspace:FindFirstChild("Baseplate")
assert(baseplate and baseplate:IsA("BasePart"), "Fase 16: workspace.Baseplate deve existir e ser BasePart")
local groundNames = { "Baseplate_East", "Baseplate_South", "Baseplate_North", "Baseplate_Pit" }
local ra = MUSEUM_CF * Vector3.new(344.5, -4, -45.5)
local rb = MUSEUM_CF * Vector3.new(400.5, -4, -4.5)
local pitX0, pitX1 = math.min(ra.X, rb.X), math.max(ra.X, rb.X)
local pitZ0, pitZ1 = math.min(ra.Z, rb.Z), math.max(ra.Z, rb.Z)

local function plainBaseplate(source, name)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Locked = true
	p.Material = source.Material
	p.MaterialVariant = source.MaterialVariant
	p.Color = source.Color
	p.Transparency = source.Transparency
	p.Reflectance = source.Reflectance
	p.CastShadow = source.CastShadow
	p.CanCollide = source.CanCollide
	p.CanQuery = source.CanQuery
	p.CanTouch = source.CanTouch
	p.TopSurface = source.TopSurface
	p.BottomSurface = source.BottomSurface
	return p
end

-- Reconstitui a caixa inteira antes de mudar um fosso antigo de lugar.
local oldGround = { baseplate }
local samePit = false
if baseplate:GetAttribute("MemorialSplit") then
	for _, name in groundNames do
		local p = workspace:FindFirstChild(name)
		assert(p and p:IsA("Part"), "Fase 16: divisão incompleta da Baseplate: " .. name)
		table.insert(oldGround, p)
	end
	local lo, hi = worldBounds(workspace.Baseplate_Pit)
	samePit = math.abs(lo.X - pitX0) < 0.01 and math.abs(hi.X - pitX1) < 0.01
		and math.abs(lo.Z - pitZ0) < 0.01 and math.abs(hi.Z - pitZ1) < 0.01 and math.abs(hi.Y + 4) < 0.01
end
if not samePit and (baseplate:GetAttribute("MemorialSplit")
	or (baseplate:IsA("UnionOperation") and baseplate:GetAttribute("MemorialCut"))) then
	local lo, hi = worldBounds(baseplate)
	for _, p in oldGround do
		local a, b = worldBounds(p)
		lo = Vector3.new(math.min(lo.X, a.X), math.min(lo.Y, a.Y), math.min(lo.Z, a.Z))
		hi = Vector3.new(math.max(hi.X, b.X), math.max(hi.Y, b.Y), math.max(hi.Z, b.Z))
	end
	local whole = plainBaseplate(baseplate, "Baseplate")
	setBounds(whole, lo, hi)
	for name, value in baseplate:GetAttributes() do
		if name ~= "BuildPhase" and name ~= "MemorialCut" and name ~= "MemorialSplit" then whole:SetAttribute(name, value) end
	end
	for _, child in baseplate:GetChildren() do child.Parent = whole end
	whole.Parent = workspace
	for _, p in oldGround do p:Destroy() end
	baseplate = whole
end
if not samePit then
	assert(baseplate:IsA("Part"), "Fase 16: Baseplate não dividida deve ser Part")
	local lo, hi = worldBounds(baseplate)
	local x0, x1, z0, z1 = pitX0, pitX1, pitZ0, pitZ1
	assert(lo.X < x0 and hi.X > x1 and lo.Z < z0 and hi.Z > z1 and lo.Y < -4 and hi.Y > -4,
		"Fase 16: Baseplate não contém o fosso transformado")
	for _, name in groundNames do assert(not workspace:FindFirstChild(name), "Fase 16: nome de terreno ocupado: " .. name) end
	local function piece(name, xa, xb, ya, yb, za, zb)
		local p = plainBaseplate(baseplate, name)
		setBounds(p, Vector3.new(xa, ya, za), Vector3.new(xb, yb, zb))
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				local copy = child:Clone()
				copy.Parent = p
			end
		end
		return p
	end
	local east = piece("Baseplate_East", x1, hi.X, lo.Y, hi.Y, lo.Z, hi.Z)
	local south = piece("Baseplate_South", x0, x1, lo.Y, hi.Y, lo.Z, z0)
	local north = piece("Baseplate_North", x0, x1, lo.Y, hi.Y, z1, hi.Z)
	local pit = piece("Baseplate_Pit", x0, x1, lo.Y, -4, z0, z1)
	baseplate.Anchored = true
	baseplate.Locked = true
	baseplate.Shape = Enum.PartType.Block
	baseplate:SetAttribute("BuildPhase", nil)
	baseplate:SetAttribute("MemorialCut", nil)
	setBounds(baseplate, lo, Vector3.new(x0, hi.Y, hi.Z))
	for _, p in { east, south, north, pit } do p.Parent = workspace end
	pit:SetAttribute("MemorialSplit", true)
	baseplate:SetAttribute("MemorialSplit", true)
end

B.clear(Map)
local Hall = B.group(Map, "SpaceMuseumHall")
local Shell = B.group(Hall, "Shell")
Shell.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local CS = game:GetService("CollectionService")
local N = Enum.NormalId
local DECOR = { collide = false }
local DETAIL = { collide = false, shadow = false }
local GLASS = { transparency = 0.72, shadow = false }
local STEEL = "#69727A"
local WALL = "#4A525B"
local FLOOR = "#8A8D8E"
local NAVY = "#182A3C"
local ORANGE = "#C58245"
local WHITE = Color3.fromRGB(242, 239, 230)
local WARM = Color3.fromRGB(255, 217, 168)

local function group(name)
	local m = B.group(Hall, name)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return m
end

local function sign(part, title, body, face)
	return B.sign(part, title, body, {
		face = face or N.Front,
		bg = NAVY,
		accent = ORANGE,
		titleColor = "white",
		bodyColor = "#D6DADD",
		ppu = 32,
		maxBody = 32,
		titleScale = 0.36,
	})
end

local function light(part, class, props)
	props.Shadows = props.Shadows == true
	props.Color = props.Color or WHITE
	return B.light(part, class, props)
end

-- O Front local aponta ao alvo; evita depender da orientação padrão dos spots.
local function aimedSpot(parent, name, position, target, range, brightness, angle, color, shadows)
	local p = B.part(parent, name, CFrame.lookAt(position, target), Vector3.new(1.2, 0.45, 0.8), "#444D54", "Metal", DETAIL)
	light(p, "SpotLight", { Face = N.Front, Range = range, Brightness = brightness, Angle = angle,
		Color = color, Shadows = shadows })
	return p
end

-- Caixa arredondada por duas pontas cilíndricas, sem CSG. Retorna o núcleo
-- para manter PrimaryPart, placas e nomes usados pelos sistemas.
local function capsule(parent, name, x0, x1, y0, y1, z0, z1, color, material, opts)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local p
	if x1 - x0 >= z1 - z0 then
		local r = (z1 - z0) / 2
		p = B.box(parent, name, x0 + r, x1 - r, y0, y1, z0, z1, color, material, opts)
		for _, x in { x0 + r, x1 - r } do B.cyl(parent, name .. "_End", x, cz, y0, y1, r * 2, color, material, opts) end
	else
		local r = (x1 - x0) / 2
		p = B.box(parent, name, x0, x1, y0, y1, z0 + r, z1 - r, color, material, opts)
		for _, z in { z0 + r, z1 - r } do B.cyl(parent, name .. "_End", cx, z, y0, y1, r * 2, color, material, opts) end
	end
	return p
end

-- Geometria autorada no mundo também pertence a Hall, portanto recebe a inversa
-- agora e exatamente um PivotTo no fim, junto com os objetos de projeto.
local function inProject(p)
	p.CFrame = MUSEUM_CF:ToObjectSpace(p.CFrame)
	return p
end
local function wbox(...) return inProject(B.box(...)) end
local function wcyl(...) return inProject(B.cyl(...)) end
local function wpart(...) return inProject(B.part(...)) end

local Links = group("MuseumLinks")
Links.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local Openings = B.group(Links, "WallReplacements")
local worldRoutes = {}
local function conceal(p)
	if p:GetAttribute("Hall16OriginalSize") == nil then
		p:SetAttribute("Hall16OriginalSize", p.Size)
		for _, prop in { "Transparency", "CanCollide", "CanQuery", "CanTouch" } do
			p:SetAttribute("Hall16Original" .. prop, p[prop])
		end
	end
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = Vector3.new(0.05, 0.05, 0.05)
end

-- Subtrai só vãos retangulares das paredes detectadas, conservando as faces
-- externas e internas exatas, inclusive revestimentos. Nenhum CSG ou destruição.
local lccWallSegments = {}
local function openWall(p, normalAxis, cuts, height)
	local lo, hi = worldBounds(p)
	local tang0 = normalAxis == "X" and lo.Z or lo.X
	local tang1 = normalAxis == "X" and hi.Z or hi.X
	local spans = {}
	for _, cut in cuts do
		local a, b = math.max(tang0, cut[1]), math.min(tang1, cut[2])
		if b > a and hi.Y > 0 and lo.Y < height then table.insert(spans, { a, b }) end
	end
	if #spans == 0 then return false end
	table.sort(spans, function(a, b) return a[1] < b[1] end)
	local color, material = "#" .. p.Color:ToHex(), p.Material.Name
	local options = { transparency = p.Transparency, shadow = p.CastShadow, collide = p.CanCollide }
	local function segment(a, b, y0, y1)
		if b - a < 0.01 or y1 - y0 < 0.01 then return end
		local q
		if normalAxis == "X" then
			q = wbox(Openings, "WallSegment", lo.X, hi.X, y0, y1, a, b, color, material, options)
			if p:IsDescendantOf(LCC) then
				table.insert(lccWallSegments, { lo = Vector3.new(lo.X, y0, a), hi = Vector3.new(hi.X, y1, b), source = p })
			end
		else
			q = wbox(Openings, "WallSegment", a, b, y0, y1, lo.Z, hi.Z, color, material, options)
		end
		q.MaterialVariant = p.MaterialVariant
		q.CanCollide, q.CanQuery, q.CanTouch = p.CanCollide, p.CanQuery, p.CanTouch
	end
	local cursor = tang0
	for _, span in spans do
		segment(cursor, span[1], lo.Y, hi.Y)
		segment(span[1], span[2], math.max(height + 0.04, lo.Y), hi.Y)
		-- A soleira cobre a faixa inferior, sem duas superfícies coplanares em Y 0.
		segment(span[1], span[2], lo.Y, math.min(-0.05, hi.Y))
		cursor = span[2]
	end
	segment(cursor, tang1, lo.Y, hi.Y)
	conceal(p)
	return true
end

-- Portal no mundo: batentes fora da largura útil e chanfros nas duas quinas
-- superiores. A parte mais baixa do chanfro continua a pelo menos 11 studs.
local function portal(parent, name, x, z, axis, width, height)
	local g = B.group(parent, name)
	local rotate = axis == "X" and CFrame.new() or CFrame.Angles(0, math.pi / 2, 0)
	for _, side in { -1, 1 } do
		local dx = axis == "X" and 0 or side * (width / 2 + 0.5)
		local dz = axis == "X" and side * (width / 2 + 0.5) or 0
		wcyl(g, "RoundJamb", x + dx, z + dz, 0, height + 1, 1, STEEL, "Metal")
		local localCF = CFrame.new(0, height - 0.25, side * (width / 2 - 0.25))
		local flip = side < 0 and CFrame.Angles(math.pi, 0, 0) or CFrame.Angles(0, 0, math.pi)
		wpart(g, "Chamfer", CFrame.new(x, 0, z) * rotate * localCF * flip,
			Vector3.new(1, 0.5, 0.5), STEEL, "Metal", DETAIL, "Wedge")
	end
	wpart(g, "Lintel", CFrame.new(x, height + 0.5, z) * rotate,
		Vector3.new(1.1, 1.1, width + 1), STEEL, "Metal", DECOR)
end

---------------------------------------------------------------------------------
-- 1. Galeria do planetário + dois corredores LCC; originais restaurados acima
---------------------------------------------------------------------------------
local southWall, southLo, southHi
for _, p in walls:GetDescendants() do
	if p:IsA("Part") and p.Shape == Enum.PartType.Block then
		local lo, hi = worldBounds(p)
		if hi.Z - lo.Z < 2 and hi.X - lo.X > 40 and hi.Y - lo.Y > 16
			and lo.X < 84 and hi.X > 96 and lo.Z > 50 and hi.Z < 85 then
			if not southHi or hi.Z > southHi.Z then southWall, southLo, southHi = p, lo, hi end
		end
	end
end
assert(southWall, "Fase 16: parede sul do planetário não localizada por geometria")
local southZ = southHi.Z
assert(84 - southZ >= 9, "Fase 16: galeria precisa de 9 studs livres entre planetário e salão")
openWall(southWall, "Z", { { 84, 96 } }, 16)

-- Painéis de parede do planetário que ficariam soltos no vão aberto: desloca
-- para o trecho inteiro a leste (X +30), com restauração por Hall16Original*.
for _, p in planetarium:GetDescendants() do
	if p:IsA("BasePart") and p.Name == "Wall_Panel" and p:GetAttribute("Hall16OriginalSize") == nil then
		local c = p.Position
		if c.X > 83 and c.X < 97 and c.Z > southLo.Z - 3 and c.Z < southHi.Z + 3 and c.Y < 16 then
			p:SetAttribute("Hall16OriginalSize", p.Size)
			p:SetAttribute("Hall16OriginalCFrame", p.CFrame)
			for _, prop in { "Transparency", "CanCollide", "CanQuery", "CanTouch" } do
				p:SetAttribute("Hall16Original" .. prop, p[prop])
			end
			p.CFrame = p.CFrame + Vector3.new(30, 0, 0)
		end
	end
end

-- Seleção geométrica da parede leste, não do nome das peças. Somente blocos
-- verticais finos junto a X 6; exclui interfaces, telas, consoles e qualquer link.
local lccWalls = 0
for _, p in LCC:GetDescendants() do
	if p:IsA("Part") and p.Shape == Enum.PartType.Block then
		local protected = p:FindFirstChildOfClass("SurfaceGui") ~= nil
		local ancestor = p.Parent
		while ancestor and ancestor ~= LCC do
			local name = string.lower(ancestor.Name)
			if name:find("screen") or name:find("console") or name:find("link") then protected = true end
			ancestor = ancestor.Parent
		end
		local lo, hi = worldBounds(p)
		if not protected and lo.X >= 2.5 and hi.X <= 8.5 and hi.X - lo.X <= 2.6
			and hi.Y - lo.Y >= 3 and hi.Z - lo.Z >= 3.5 then
			if openWall(p, "X", { { 112.95, 125.05 }, { 150.95, 163.05 } }, 12) then lccWalls += 1 end
		end
	end
end
assert(lccWalls > 0, "Fase 16: parede leste do LCC não localizada; execute a Fase 12 alinhada")
-- O rodapé leste do saguão (baixo demais para a seleção acima) também é recortado.
for _, p in LCC:GetDescendants() do
	if p:IsA("Part") and p.Name == "Lobby_East" and p.Parent and p.Parent.Name == "Baseboards" then
		openWall(p, "X", { { 112.95, 125.05 }, { 150.95, 163.05 } }, 12)
	end
end

-- A verga transversal do saguão pode terminar antes da parede leste
-- arredondada. Fecha somente a junta em T acima da passagem, medindo as
-- faces reais no mundo; a peça nova pertence à Fase 16 e é refeita por B.clear.
local lobbyLintel = LCC:FindFirstChild("Lobby_Back_Lintel", true)
if lobbyLintel and lobbyLintel:IsA("BasePart") then
	local lo, hi = worldBounds(lobbyLintel)
	local nearest, nearestGap
	for _, segment in lccWallSegments do
		local gap = segment.lo.X - hi.X
		if gap > 0.01 and gap <= 2.5
			and math.min(hi.Y, segment.hi.Y) > math.max(lo.Y, segment.lo.Y)
			and math.min(hi.Z, segment.hi.Z) > math.max(lo.Z, segment.lo.Z)
			and (not nearestGap or gap < nearestGap) then
			nearest, nearestGap = segment, gap
		end
	end
	-- Só cria a junta se o vão estiver vazio (a Lobby_Back_Wall pode já ocupá-lo).
	if nearest then
		local jlo = Vector3.new(hi.X, math.max(lo.Y, nearest.lo.Y), math.max(lo.Z, nearest.lo.Z))
		local jhi = Vector3.new(nearest.lo.X, math.min(hi.Y, nearest.hi.Y), math.min(hi.Z, nearest.hi.Z))
		local query = OverlapParams.new()
		query.FilterType = Enum.RaycastFilterType.Include
		query.FilterDescendantsInstances = { LCC }
		for _, q in workspace:GetPartBoundsInBox(CFrame.new((jlo + jhi) / 2), (jhi - jlo) - Vector3.new(0.1, 0.1, 0.1), query) do
			if q ~= lobbyLintel and q.Transparency < 1 then nearest = nil break end
		end
	end
	if nearest then
		local source = nearest.source
		local joint = wbox(Openings, "WallSegment", hi.X, nearest.lo.X,
			math.max(lo.Y, nearest.lo.Y), math.min(hi.Y, nearest.hi.Y),
			math.max(lo.Z, nearest.lo.Z) + 0.03, math.min(hi.Z, nearest.hi.Z) - 0.03,
			"#" .. source.Color:ToHex(), source.Material.Name,
			{ transparency = source:GetAttribute("Hall16OriginalTransparency"), shadow = source.CastShadow })
		joint.MaterialVariant = source.MaterialVariant
	end
end

local function glassWall(parent, x0, x1, z0, z1, height)
	wbox(parent, "BaseBand", x0, x1, 0, 3, z0, z1, "white", "SmoothPlastic")
	wbox(parent, "TopBand", x0, x1, height - 4, height, z0, z1, "white", "SmoothPlastic")
	wbox(parent, "GlassBand", x0, x1, 3, height - 4, z0, z1, "glass", "Glass", GLASS)
end
local function corridor(name, z, endpoint)
	local g = B.group(Links, name)
	wbox(g, "Floor", 6, endpoint, -1, 0, z - 6, z + 6, "lightGray", "Concrete")
	wbox(g, "Ceiling", 5.5, endpoint - 0.05, 12, 13, z - 7, z + 7, "white", "SmoothPlastic")
	for _, side in { -1, 1 } do
		local center = z + side * 6.5
		glassWall(g, 5.5, endpoint - (name == "LCC_B" and 0.05 or 0), center - 0.5, center + 0.5, 12)
	end
	portal(g, "LCCPortal", 5.5, z, "X", 12, 12)
	portal(g, "MuseumPortal", endpoint, z, "X", 12, 12)
	local lamp = wbox(g, "CeilingLight", 7, endpoint - 1, 11.7, 11.85, z - 0.5, z + 0.5, "#E9E6DC", "SmoothPlastic", DETAIL)
	light(lamp, "SurfaceLight", { Face = N.Bottom, Range = 16, Brightness = 0.8, Angle = 120 })
	table.insert(worldRoutes, { name, 4, endpoint + 5, z - 4.5, z + 4.5 })
end
corridor("LCC_A", 157, 82.5)
corridor("LCC_B", 119, 132.5)

local Gallery = B.group(Links, "EntranceGallery")
wbox(Gallery, "Floor", 84, 215, -1, 0, southZ, 84, "lightGray", "Concrete")
wbox(Gallery, "Ceiling", 83, 216, 16, 17, southLo.Z + 0.05, 85, "white", "SmoothPlastic")
-- A parede sul do planetário serve de parede norte da galeria até southHi.X.
-- A fachada norte do salão serve de parede sul da galeria a partir de X 132,5.
glassWall(Gallery, southHi.X, 216, southLo.Z, southZ, 16)
glassWall(Gallery, 83, 132, 84, 85, 16)
glassWall(Gallery, 83, 84, southZ, 84, 16)
glassWall(Gallery, 215, 216, southZ, 85, 16)
for _, pos in { { 83.5, southZ }, { 83.5, 84.5 }, { 215.5, southZ }, { 215.5, 84.5 } } do
	wcyl(Gallery, "RoundCorner", pos[1], pos[2], 0, 17, 1, "white", "SmoothPlastic")
end
wbox(Gallery, "PlanetariumThreshold", 84, 96, -1, 0, southLo.Z, southZ, "lightGray", "Concrete")
portal(Gallery, "PlanetariumPortal", 90, (southLo.Z + southZ) / 2, "Z", 12, 16)
for _, span in { { 86, 144 }, { 145, 213 } } do
	local lamp = wbox(Gallery, "GalleryLight", span[1], span[2], 15.7, 15.85, southZ + 3, southZ + 4,
		"#E9E6DC", "SmoothPlastic", DETAIL)
	light(lamp, "SurfaceLight", { Face = N.Bottom, Range = 19, Brightness = 0.8, Angle = 120 })
end
local galleryZ = (southZ + 84) / 2
table.insert(worldRoutes, { "PlanetariumDoor", 85.5, 94.5, southLo.Z - 0.5, galleryZ })
table.insert(worldRoutes, { "Gallery", 90, 205, galleryZ - 4.5, galleryZ + 4.5 })
table.insert(worldRoutes, { "GalleryTurn", 200.5, 209.5, galleryZ, 95 })

local Portal = group("NorthEntrance")
portal(Portal, "EntryPortal", 205, 85, "Z", 20, 16)
B.box(Portal, "Threshold", 135, 136, -1, 0, 17.5, 37.5, FLOOR, "Concrete")
local welcome = B.box(Portal, "MuseumTitle", 137.9, 138.2, 18, 23, 10, 45, NAVY, "SmoothPlastic", DECOR)
sign(welcome, "SPACE EXPLORATION", "A journey beyond Earth", N.Right)
local portalLamp = B.box(Portal, "PortalLight", 136, 138, 15.7, 15.9, 19, 36, "#ECE4D6", "SmoothPlastic", DETAIL)
light(portalLamp, "SurfaceLight", { Face = N.Bottom, Range = 20, Brightness = 0.7, Angle = 110 })

---------------------------------------------------------------------------------
-- 2. Casca: concreto, rodapés, estrutura metálica e treliças aparentes
---------------------------------------------------------------------------------
B.box(Shell, "HallFloor_West", 136, 345, -1, 0, -45, 100, FLOOR, "Concrete", { reflectance = 0.08 })
B.box(Shell, "HallFloor_East", 345, 400, -1, 0, -4.5, 100, FLOOR, "Concrete", { reflectance = 0.08 })
B.box(Shell, "SouthWall", 135.5, 400.5, -4, 50, -46, -45, WALL, "Concrete")
B.box(Shell, "EastWall", 400, 401, -4, 50, -45.5, 100.5, WALL, "Concrete")
B.box(Shell, "WestWall_South", 135, 136, -1, 50, -45.5, 17.5, WALL, "Concrete")
B.box(Shell, "WestWall_North", 135, 136, -1, 50, 37.5, 100.5, WALL, "Concrete")
B.box(Shell, "WestWall_Lintel", 135, 136, 16.04, 50, 17.5, 37.5, WALL, "Concrete")
-- Vão do corredor B no plano de projeto Z 100: X 164..176, altura 12.
for _, span in { { 136, 163.95 }, { 176.05, 200 }, { 330, 400 } } do
	B.box(Shell, "NorthWall", span[1], span[2], -1, 50, 100, 101, WALL, "Concrete")
	B.box(Shell, "NorthSkirting", span[1], math.min(span[2], 399.7), 0, 1.2, 99.7, 100, "#555C62", "Metal", DECOR)
end
B.box(Shell, "CorridorB_Lintel", 163.95, 176.05, 12.04, 50, 100, 101, WALL, "Concrete")
for _, pos in { { 135.5, -45.5 }, { 400.5, -45.5 }, { 135.5, 100.5 }, { 400.5, 100.5 } } do
	B.cyl(Shell, "RoundWallCorner", pos[1], pos[2], -4, 50, 1, WALL, "Concrete")
end
B.box(Shell, "Roof", 135, 401, 50, 51, -46, 100, "#3C444D", "Metal")
B.box(Shell, "SouthSkirting", 136, 344, 0, 1.2, -45, -44.7, "#555C62", "Metal", DECOR)
B.box(Shell, "EastSkirting", 399.7, 400, 0, 1.2, -4, 100, "#555C62", "Metal", DECOR)
for _, y in { 9, 35 } do
	B.box(Shell, "SouthBand", 136, 399.6, y, y + 0.35, -44.9, -44.6, STEEL, "Metal", DETAIL)
	B.box(Shell, "EastBand", 399.6, 399.9, y, y + 0.35, -45, 100, STEEL, "Metal", DETAIL)
end

-- Pórticos transversais sem pilares no centro: todo o vão do Saturn fica livre.
for _, x in { 140, 190, 240, 290, 340, 396 } do
	for _, z in { -43, 98 } do
		-- O nicho tem piso próprio três studs abaixo do salão.
		local foot = (x > 345 and z < -5) and memorialY or 0
		B.cyl(Shell, "ColumnFoot", x, z, foot, foot + 0.4, 3, STEEL, "Metal")
		B.cyl(Shell, "RoundColumn", x, z, foot + 0.4, 49, 1.6, STEEL, "Metal")
	end
	for _, y in { 43, 49 } do
		B.beam(Shell, "TrussChord", Vector3.new(x, y, -43), Vector3.new(x, y, 98), 0.7, 0.7, STEEL, "Metal", DECOR)
	end
	for i = 0, 7 do
		local z0, z1 = -43 + i * 17.625, -43 + (i + 1) * 17.625
		B.beam(Shell, "TrussDiagonal", Vector3.new(x, i % 2 == 0 and 43 or 49, z0),
			Vector3.new(x, i % 2 == 0 and 49 or 43, z1), i % 2 == 0 and 0.28 or 0.34, 0.28, STEEL, "Metal", DECOR)
	end
end
for z = -40, 98, 23 do
	B.box(Shell, "RoofPurlin", 136, 400, 48.7, 49.3, z - 0.22, z + 0.22, "#515B63", "Metal", DECOR)
end
-- Juntas discretas: continuidade visual do piso sem soleiras na circulação.
for x = 156, 396, 40 do
	local z0 = x >= 345 and -5 or -45
	B.box(Shell, "FloorJoint", x - 0.025, x + 0.025, -0.1, 0.025, z0, 100, "#707577", "SmoothPlastic", DETAIL)
end

---------------------------------------------------------------------------------
-- 3. Átrio: encontro aberto de 130 studs, montantes e teto de vidro
---------------------------------------------------------------------------------
B.box(Shell, "AtriumFloor", 200, 330, -1, 0, 100, 150, "#ACAFAB", "Concrete")
local Atrium = B.group(Shell, "GlassAtrium")
B.box(Atrium, "Clerestory", 200, 330, 49.95, 72, 99.8, 100.2, "#DCE8EA", "Glass", GLASS)
for _, x in { 200, 330 } do
	B.box(Atrium, "GlassSide", x - 0.2, x + 0.2, 0, 72, 100.2, 149.8, "#DCE8EA", "Glass", GLASS)
	for z = 100, 150, 10 do
		B.cyl(Shell, "AtriumColumn", x, z, 0, 72.5, 0.8, STEEL, "Metal")
	end
	for _, y in { 1, 24, 48, 72 } do
		B.box(Atrium, "SideTransom", x - 0.3, x + 0.3, y - 0.2, y + 0.2, 100.05, 150.25, STEEL, "Metal", DECOR)
	end
end
-- Vão do corredor A: plano de projeto Z 150, X 202..214.
for _, span in { { 200, 201.95 }, { 214.05, 330 } } do
	B.box(Atrium, "GlassEnd", span[1], span[2], 0, 72, 149.8, 150.2, "#DCE8EA", "Glass", GLASS)
end
B.box(Atrium, "GlassEnd_Header", 201.95, 214.05, 12.1, 72, 149.8, 150.2, "#DCE8EA", "Glass", GLASS)
B.box(Atrium, "GlassRoof", 200, 330, 72, 72.35, 100, 150, "#DCE8EA", "Glass", GLASS)
for x = 200, 330, 13 do
	B.cyl(Atrium, "EndMullion", x, 150, (x > 202 and x < 214) and 12 or 0, 72, 0.44, STEEL, "Metal", DECOR)
	B.box(Atrium, "RoofRafter", x - 0.25, x + 0.25, 71.4, 71.97, 100, 150, STEEL, "Metal", DECOR)
	-- Montantes somente acima do vão, sem pilares no meio da entrada.
	B.cyl(Atrium, "ClerestoryMullion", x, 100, 50, 72, 0.4, STEEL, "Metal", DECOR)
end
for z = 100, 150, 10 do
	B.box(Atrium, "RoofCrossbar", 199.75, 330.25, 71.7, 72.15, z - 0.15, z + 0.15, STEEL, "Metal", DECOR)
end
for _, y in { 1, 24, 48, 72 } do
	if y < 12 then
		for _, span in { { 199.75, 201.9 }, { 214.1, 330.25 } } do
			B.box(Atrium, "EndTransom", span[1], span[2], y - 0.24, y + 0.24, 149.6, 150.4, STEEL, "Metal", DECOR)
		end
	else
		B.box(Atrium, "EndTransom", 199.75, 330.25, y - 0.24, y + 0.24, 149.6, 150.4, STEEL, "Metal", DECOR)
	end
end
for _, x in { 216, 248, 282, 314 } do
	local p = B.box(Atrium, "DaylightFixture", x - 2, x + 2, 32, 32.3, 149.3, 149.8, "#EEEFE8", "SmoothPlastic", DETAIL)
	light(p, "PointLight", { Range = 60, Brightness = 0.85, Color = Color3.fromRGB(238, 246, 255) })
end

---------------------------------------------------------------------------------
-- 4. Ilhas: bases rasas e placas com os nomes do contrato
---------------------------------------------------------------------------------
local Islands = group("IslandMarkers")
local islandData = {
	{ "Entrance", "ENTRANCE", 136, 172, 5, 50, 158, 46, 0 },
	{ "Pioneers", "PIONEERS — MERCURY & GEMINI", 140, 200, 58, 100, 170, 60, 0 },
	{ "RocketGarden", "ROCKET GARDEN", 200, 330, 100, 150, 265, 149.5, 0 },
	{ "Apollo", "APOLLO & SATURN V", 180, 330, 5, 50, 251, 48, 0 },
	{ "Atlantis", "SPACE SHUTTLE ATLANTIS", 336, 400, 30, 100, 367, 99.75, 0 },
	{ "Memorial", "IN MEMORIAM", 345, 400, -45, -5, 373, -43.7, memorialY },
	{ "Mars", "MARS", 275, 340, -45, -5, 308, -45, 0 },
	{ "Modern", "MODERN EXPLORATION", 205, 275, -45, -5, 239, -42.2, 0 },
	{ "Missions", "MISSION WALL", 140, 205, -45, -5, 172.5, -40.6, 0 },
}
for index, d in islandData do
	local island = B.group(Islands, d[1])
	island:SetAttribute("IslandIndex", index - 1)
	local y = d[9]
	-- As marcações ficam dentro dos limites das ilhas; não estreitam os corredores.
	if d[1] ~= "Memorial" then
		B.box(island, "FloorInlay", d[3] + 1, d[4] - 1, y + 0.01, y + 0.05, d[5] + 1, d[6] - 1,
			index % 2 == 0 and "#929694" or "#82898A", "Concrete", DETAIL)
	end
	for _, z in { d[5] + 0.6, d[6] - 0.6 } do
		B.box(island, "Boundary", d[3] + 0.6, d[4] - 0.6, y + 0.05, y + 0.07, z - 0.06, z + 0.06,
			"#B6AEA0", "Metal", DETAIL)
	end
	-- Entrada, pioneiros e Apollo usam placas baixas sobre postes (dupla face); as
	-- demais encostam em parede, vidro, coluna ou no fundo da Parede de missões.
	local low = d[1] == "Entrance" or d[1] == "Pioneers" or d[1] == "Apollo"
	local sy = y + (low and 4 or (d[1] == "Missions" and 13 or 12))
	local width = d[1] == "Missions" and 56 or (d[1] == "Pioneers" and 27 or 25)
	local height = d[1] == "Missions" and 4 or 3
	local p = B.box(island, "IslandSign", d[7] - width / 2, d[7] + width / 2, sy, sy + height, d[8], d[8] + 0.25,
		NAVY, "SmoothPlastic", DECOR)
	CS:AddTag(p, "IslandSign")
	if d[1] == "Memorial" then
		p.Color = Color3.fromHex("#25282B")
		B.sign(p, d[2], nil, { face = N.Back, bg = "#25282B", titleColor = "#E4E0D8", brightness = 0.8, ppu = 32 })
	else
		sign(p, d[2], nil, d[5] < 0 and N.Back or N.Front)
		if low then sign(p, d[2], nil, d[5] < 0 and N.Front or N.Back) end
	end
	if low then
		for _, dx in { -width / 2 + 1, width / 2 - 1 } do
			B.cyl(island, "SignPost", d[7] + dx, d[8] + 0.125, y, sy, 0.3, STEEL, "Metal", DECOR)
		end
	end
end

---------------------------------------------------------------------------------
-- 5. Memorial: piso a -3, acessos e parede de memória lisa
---------------------------------------------------------------------------------
local Memorial = group("Memorial")
-- Cobre todo o retângulo do fosso, com folga sob paredes e lajes vizinhas.
B.box(Shell, "MemorialFloor", 344.5, 400.5, memorialY - 1, memorialY, -45.5, -4.5, "#383735", "Concrete")
B.box(Memorial, "WestScreen", 344, 345.03, memorialY, 23, -45.5, -5.5, "#27292B", "Concrete")
for _, span in { { 344.5, 348.5 }, { 389.5, 400.5 } } do
	B.box(Memorial, "EntryScreen", span[1], span[2], memorialY, 20, -6, -5, "#27292B", "Concrete")
end
for _, pos in { { 344.5, -45.5 }, { 344.5, -5.5 }, { 348.5, -5.5 }, { 389.5, -5.5 } } do
	B.cyl(Memorial, "RoundScreenCorner", pos[1], pos[2], memorialY, 20, 1, "#27292B", "Concrete")
end
capsule(Memorial, "MemoryWall", 346, 399, memorialY, 20, -44.5, -43.7, "#202224", "Slate")
B.box(Shell, "MemorialRim", 345, 400, memorialY, 0, -5, -4.5, "#595A58", "Concrete")
B.part(Memorial, "AccessibleRamp", CFrame.new(355, -1.5, -14), Vector3.new(12, 3, 18), "#5C5D5B", "Concrete", nil, "Wedge")
for i = 0, 5 do
	local top = -i * 0.5
	B.box(Memorial, "Step_" .. (i + 1), 365, 389, -3, top, -6 - i, -5 - i, "#595A58", "Concrete")
	B.box(Memorial, "StepNosing", 365, 389, top, top + 0.04, -6 - i, -5.85 - i, "#A99E86", "Metal", DETAIL)
end
-- Proteção da borda entre a rampa e a escada, com corrimãos nos acessos.
B.box(Memorial, "LandingRail", 361, 365, 2.8, 3.05, -5.3, -5, STEEL, "Metal")
for _, x in { 361.15, 364.85 } do
	B.cyl(Memorial, "LandingRailPost", x, -5.15, -3, 2.8, 0.2, STEEL, "Metal")
end
for _, x in { 349.25, 360.75 } do
	B.beam(Memorial, "RampHandrail", Vector3.new(x, -0.1, -23), Vector3.new(x, 2.9, -5), 0.16, 0.16, STEEL, "Metal")
	for _, point in { { -23, -3 }, { -14, -1.5 }, { -5, 0 } } do
		B.cyl(Memorial, "RailPost", x, point[1], point[2], point[2] + 2.9, 0.18, STEEL, "Metal")
	end
end
for _, x in { 355, 373, 391 } do
	aimedSpot(Memorial, "MemorialPlaqueSpot", Vector3.new(x, 13, -34), Vector3.new(x, 2.5, -41.5),
		25, 1.5, 70, WARM, x == 373)
end
-- Faixa baixa junto ao patamar: cobre as seis quinas sem luz fria no nicho.
local stepLight = B.part(Memorial, "StepSafetyLight",
	CFrame.lookAt(Vector3.new(377, 0.15, -4.8), Vector3.new(377, -2, -10)),
	Vector3.new(24, 0.15, 0.2), "#A59884", "Metal", DETAIL)
light(stepLight, "SurfaceLight", { Face = N.Front, Range = 12, Brightness = 0.35, Angle = 110, Color = WARM })
-- Preenchimento quente e suave do fosso: degraus e rampa legíveis.
light(stepLight, "PointLight", { Range = 30, Brightness = 0.6, Color = WARM })

---------------------------------------------------------------------------------
-- 6. Parede de missões: oito vitrines prontas para os sistemas
---------------------------------------------------------------------------------
local MissionWall = B.group(Hall, "MissionWall")
MissionWall.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
-- Fundo mais alto: sustenta a placa MISSION WALL.
B.box(MissionWall, "Backing", 140, 205, 0, 17, -44.6, -43.8, "#272E34", "Metal")
for i = 1, 8 do
	local x = 144 + (i - 1) * 7.6
	local slot = B.group(MissionWall, "CardSlot_" .. i)
	local plinth = capsule(slot, "Plinth", x - 3, x + 3, 0, 2.2, -43.5, -39.5, "#5E6367", "Concrete")
	B.sign(plinth, tostring(i), nil, { face = N.Back, bg = "#303B43", titleColor = "#DCE2E5", brightness = 0.8, ppu = 32 })
	B.box(slot, "Glass", x - 3, x + 3, 2.2, 8.5, -39.7, -39.5, "#C6DAE1", "Glass", { transparency = 0.78, shadow = false })
	for _, dx in { -3, 3 } do
		B.cyl(slot, "RoundMullion", x + dx, -39.6, 2.2, 8.6, 0.16, STEEL, "Metal", DECOR)
	end
	B.box(slot, "Canopy", x - 3.1, x + 3.1, 8.5, 8.7, -43.5, -39.4, STEEL, "Metal", DECOR)
	B.box(slot, "ModelAnchor", x - 0.1, x + 0.1, 2.2, 2.4, -41.1, -40.9, "white", "SmoothPlastic", { transparency = 1, collide = false })
	-- Face Back (+Z) voltada ao corredor; o sistema instala foto e card aqui.
	local photo = B.box(slot, "PhotoFrame", x - 2.5, x + 2.5, 3.5, 7.8, -43.6, -43.4, "#141C24", "SmoothPlastic", DECOR)
	photo:SetAttribute("DisplayFace", "Back")
	-- Sempre acesa, junto à Backing e atrás do plano da foto; independente do card.
	local strip = B.box(slot, "BackingLightStrip", x - 2.7, x + 2.7, 7.95, 8.1, -43.78, -43.65,
		"#DCE2E5", "SmoothPlastic", DETAIL)
	light(strip, "SurfaceLight", { Face = N.Back, Enabled = true, Range = 7, Brightness = 0.35, Angle = 110 })
	local lamp = B.box(slot, "SlotLight", x - 0.3, x + 0.3, 8, 8.3, -41.8, -41.2, "#D4CDBB", "SmoothPlastic", DETAIL)
	light(lamp, "PointLight", { Enabled = false, Range = 9, Brightness = 0.8 })
	slot.PrimaryPart = plinth
end
-- Afasta a parede 3,2 studs das colunas do pórtico (Z -43 ± 1,5 com a base);
-- a placa da ilha Missions já está no plano frontal do fundo deslocado.
MissionWall:PivotTo(MissionWall:GetPivot() + Vector3.new(0, 0, 3.2))

---------------------------------------------------------------------------------
-- 7. Recepção, ponto de chegada, mapa esquemático e saída para o planetário
---------------------------------------------------------------------------------
local Reception = group("MuseumReception")
capsule(Reception, "InformationDesk", 151, 165, 0, 3.4, 7, 12, "#58616A", "Metal")
capsule(Reception, "Countertop", 150.6, 165.4, 3.4, 3.7, 6.7, 12.3, "#C6C8C4", "Concrete")
local deskSign = B.box(Reception, "InformationSign", 151.5, 164.5, 1.3, 2.8, 12, 12.1, NAVY, "SmoothPlastic", DECOR)
sign(deskSign, "INFORMATION", nil, N.Back)
local totem = capsule(Reception, "MapTotem", 166, 167, 0, 7.5, 39, 44, NAVY, "Metal")
local mapGui = sign(totem, "MUSEUM GUIDE", "YOU ARE HERE · ENTRANCE\n1  Pioneers     2  Rocket garden\n3  Apollo         4  Atlantis\n5  Memorial     6  Mars\n7  Modern        8  Mission wall", N.Left)
local mapBackground = mapGui:FindFirstChildOfClass("Frame")
for _, label in mapBackground:GetChildren() do
	if label:IsA("TextLabel") then
		if label.Text == "MUSEUM GUIDE" then
			label.Size = UDim2.fromScale(0.88, 0.13)
		else
			label.Position = UDim2.fromScale(0.06, 0.28)
			label.Size = UDim2.fromScale(0.88, 0.41)
		end
	end
end
-- Planta simplificada na metade inferior, legível olhando da passagem para leste.
local mapFrame = Instance.new("Frame")
mapFrame.Name = "FloorPlan"
mapFrame.Position = UDim2.fromScale(0.07, 0.73)
mapFrame.Size = UDim2.fromScale(0.86, 0.22)
mapFrame.BackgroundColor3 = Color3.fromHex("#555F67")
mapFrame.BorderSizePixel = 0
mapFrame.Parent = mapBackground
for _, cell in { { 0.04, 0.12, 0.2, 0.22 }, { 0.27, 0.02, 0.39, 0.2 }, { 0.27, 0.4, 0.39, 0.16 },
	{ 0.76, 0.14, 0.19, 0.4 }, { 0.76, 0.7, 0.19, 0.23 }, { 0.52, 0.7, 0.2, 0.23 },
	{ 0.28, 0.7, 0.2, 0.23 }, { 0.04, 0.7, 0.2, 0.23 } } do
	local f = Instance.new("Frame")
	f.Position = UDim2.fromScale(cell[1], cell[2])
	f.Size = UDim2.fromScale(cell[3], cell[4])
	f.BackgroundColor3 = Color3.fromHex("#BAC1BF")
	f.BorderSizePixel = 0
	f.Parent = mapFrame
end
local arrival = B.group(Hall, "MuseumArrival", "SpawnLocation")
arrival.Size = Vector3.new(8, 0.1, 8)
arrival.CFrame = CFrame.lookAt(Vector3.new(146, 0.06, 27.5), Vector3.new(176, 0.06, 27.5))
arrival.Anchored = true
arrival.Transparency = 1
arrival.CanCollide = false
arrival.CanTouch = false
arrival.CanQuery = false
arrival.Neutral = false
arrival.Enabled = true
arrival.Duration = 0
local exit = B.box(Hall, "MuseumExit", 138.5, 139, 0, 10, 18, 37, "white", "SmoothPlastic", { transparency = 1, collide = false })
exit:SetAttribute("ExitDirection", Vector3.new(-1, 0, 0))
CS:AddTag(exit, "MuseumExit")
local exitSign = B.box(Reception, "ExitLabel", 138.2, 138.4, 12.5, 14.5, 21, 34, NAVY, "SmoothPlastic", DECOR)
sign(exitSign, "EXIT", nil, N.Right)

for _, door in { { "MuseumExit_A", 82.5, 157 }, { "MuseumExit_B", 132.5, 119 } } do
	local exitPart = wbox(Hall, door[1], door[2] + 0.8, door[2] + 1.3, 0, 10, door[3] - 6, door[3] + 6,
		"white", "SmoothPlastic", { transparency = 1, collide = false })
	exitPart:SetAttribute("ExitDirection", MUSEUM_CF:VectorToObjectSpace(Vector3.new(-1, 0, 0)))
	CS:AddTag(exitPart, "MuseumExit")
	local label = wbox(Links, "ExitLabel", door[2] + 0.5, door[2] + 0.65, 10, 11.5, door[3] - 3, door[3] + 3,
		NAVY, "SmoothPlastic", DECOR)
	sign(label, "EXIT", nil, N.Right)
end

---------------------------------------------------------------------------------
-- 8. Berços do Saturn V: só suportes e uplights; o veículo pertence à Fase 17
---------------------------------------------------------------------------------
local Supports = group("SaturnSupports")
for i, data in { { 201, 7.2 }, { 226, 7.2 }, { 252, 7.2 }, { 278, 4.8 }, { 305, 4.55 } } do
	local x, radius = data[1], data[2]
	local support = B.group(Supports, "Cradle_" .. i)
	local bottom = 22 - radius
	for _, z in { 20.5, 34.5 } do
		B.cyl(support, "Foot", x, z, 0, 0.35, 2.4, "#596168", "Metal")
		B.cyl(support, "Upright", x, z, 0.35, bottom - 0.8, 0.7, STEEL, "Metal")
	end
	-- Berço segmentado acompanhando apenas o arco inferior do casco.
	for j = 0, 5 do
		local a0, a1 = math.rad(-50 + j * 100 / 6), math.rad(-50 + (j + 1) * 100 / 6)
		local r = radius + 0.2
		B.beam(support, "Saddle", Vector3.new(x, 22 - r * math.cos(a0), 27.5 + r * math.sin(a0)),
			Vector3.new(x, 22 - r * math.cos(a1), 27.5 + r * math.sin(a1)), j % 2 == 0 and 0.8 or 0.86, 0.35, "#A4AAAB", "Metal", DECOR)
	end
	B.box(support, "Crosshead", x - 0.5, x + 0.5, bottom - 1.2, bottom - 0.05, 20.5, 34.5, STEEL, "Metal", DECOR)
	for _, side in { -1, 1 } do
		local r = radius + 0.2
		B.beam(support, "SaddleBrace", Vector3.new(x, bottom - 0.9, 27.5 + side * 7),
			Vector3.new(x, 22 - r * math.cos(math.rad(50)), 27.5 + side * r * math.sin(math.rad(50))),
			0.4, 0.4, STEEL, "Metal", DECOR)
	end
end
for i, x in { 190, 220, 250, 280, 310 } do
	for _, z in { 18, 37 } do
		local lamp = B.box(Supports, "SaturnUplight", x - 1.1, x + 1.1, 0, 0.25, z - 0.6, z + 0.6, "#30383F", "Metal", DETAIL)
		light(lamp, "SpotLight", { Face = N.Top, Range = 38, Brightness = 2.6, Angle = 85,
			Shadows = z == 18 and (i == 1 or i == 4) })
	end
end

---------------------------------------------------------------------------------
-- 9. Trilhos de luz local: penumbra no salão, destaques nas ilhas
---------------------------------------------------------------------------------
local Lights = group("GalleryLighting")
-- Reaproveita dois dos oito pontos antigos para os focos laterais e a treliça.
for _, data in { { 166, 75 }, { 226, 72 }, { 292, 72 }, { 174, -23 }, { 240, -23 }, { 308, -23 } } do
	local x, z = data[1], data[2]
	B.box(Lights, "LightingRail", x - 13, x + 13, 42.3, 42.65, z - 0.2, z + 0.2, "#20272C", "Metal", DECOR)
	local lamp = B.box(Lights, "GallerySpot", x - 0.6, x + 0.6, 41.6, 42.3, z - 0.5, z + 0.5, "#363D42", "Metal", DETAIL)
	light(lamp, "SpotLight", { Face = N.Bottom, Range = 55, Brightness = 1.6, Angle = 88 })
end
local roofFill = B.box(Lights, "TrussFill", 150, 390, 42.5, 42.65, 26.5, 28.5, "#4E5962", "Metal", DETAIL)
light(roofFill, "SurfaceLight", { Face = N.Top, Range = 20, Brightness = 0.85, Angle = 140 })

-- Dois focos no orbitador, de baixo/frente e lateral; um dedicado ao Hubble.
local orbitTarget = Vector3.new(370, 18.5, 64.5)
aimedSpot(Lights, "AtlantisFloorSpot", Vector3.new(354, 0.7, 49), orbitTarget, 46, 2.5, 80, WHITE, false)
aimedSpot(Lights, "AtlantisSideSpot", Vector3.new(393, 14, 83), orbitTarget, 44, 2.1, 85, WHITE, false)
aimedSpot(Lights, "HubbleSpot", Vector3.new(337, 1, 88), Vector3.new(348, 12, 85), 28, 1.8, 65, WHITE, false)

-- Após MUSEUM_CF: -Z ilumina a parede leste, +Z a oeste e +X o fundo sul.
-- A abertura de 150 graus cobre Y 0..50 a nove studs da parede; o feixe
-- aponta para fora da circulação e dos veículos. Mantém as mesmas cinco luzes,
-- sem sombras. As faixas leste param antes do memorial quente e rebaixado.
for _, span in { { 148, 246 }, { 246, 340 } } do
	local p = B.box(Lights, "SouthWallWash", span[1], span[2], 24, 24.2, -36.2, -36, "#515D65", "Metal", DETAIL)
	light(p, "SurfaceLight", { Face = N.Front, Range = 56, Brightness = 3, Angle = 150 })
end
for _, span in { { 145, 195 }, { 341, 391 } } do
	local p = B.box(Lights, "NorthWallWash", span[1], span[2], 24, 24.2, 91, 91.2, "#515D65", "Metal", DETAIL)
	light(p, "SurfaceLight", { Face = N.Back, Range = 56, Brightness = 2.8, Angle = 150 })
end
local eastWash = B.box(Lights, "EastWallWash", 391, 391.2, 24, 24.2, -3, 94, "#515D65", "Metal", DETAIL)
light(eastWash, "SurfaceLight", { Face = N.Right, Range = 56, Brightness = 3.2, Angle = 150 })
-- Braços de fixação: cada barra de wash presa a uma coluna do pórtico ou à parede.
for _, a in { { 240, -36.2, 240, -42.2 }, { 290, -36.2, 290, -42.2 }, { 190, 91.2, 190, 97.2 },
	{ 366, 91.2, 366, 100 } } do
	B.beam(Lights, "WashArm", Vector3.new(a[1], 24.1, a[2]), Vector3.new(a[3], 24.1, a[4]), 0.25, 0.25, STEEL, "Metal", DECOR)
end
B.beam(Lights, "WashArm", Vector3.new(391.2, 24.1, 45), Vector3.new(400, 24.1, 45), 0.25, 0.25, STEEL, "Metal", DECOR)

---------------------------------------------------------------------------------
-- 10. Zonas sem sobreposição (os sistemas podem usar consultas de posição)
---------------------------------------------------------------------------------
local Zones = group("AudioZones")
local function zone(name, ambience, x0, x1, y0, y1, z0, z1)
	local p = B.box(Zones, name, x0, x1, y0, y1, z0, z1, "white", "SmoothPlastic", { transparency = 1, collide = false })
	p:SetAttribute("Ambience", ambience)
	CS:AddTag(p, "AudioZone")
end
zone("HallWest", "hall", 136, 345, 0, 50, -45, 100)
zone("HallEast", "hall", 345, 400, 0, 50, -5, 100)
zone("Atrium", "atrium", 200, 330, 0, 72, 100, 150)
zone("Memorial", "memorial", 345, 400, memorialY, 23, -45, -5)

local function worldZone(name, x0, x1, z0, z1)
	local p = wbox(Zones, name, x0, x1, 0, 12, z0, z1, "white", "SmoothPlastic", { transparency = 1, collide = false })
	p:SetAttribute("Ambience", "hall")
	CS:AddTag(p, "AudioZone")
end
worldZone("Gallery", 84, 215, southZ, 85)
worldZone("Corridor_A", 6, 82.5, 151, 163)
worldZone("Corridor_B", 6, 132.5, 113, 125)

-- Uma única transformação, inclusive zonas, luminárias e peças da recepção.
Hall:PivotTo(MUSEUM_CF * Hall:GetPivot())
Hall:SetAttribute("LayoutRevision", 2)
for _, d in Hall:GetDescendants() do
	local direction = d:GetAttribute("ExitDirection")
	if typeof(direction) == "Vector3" then d:SetAttribute("ExitDirection", MUSEUM_CF:VectorToWorldSpace(direction)) end
end

---------------------------------------------------------------------------------
-- 11. Verificações da própria fase (sem Play nem alterações em outras fases)
---------------------------------------------------------------------------------
-- Caixas de 9 studs, acima do piso, certificam a circulação da arquitetura.
-- A Fase 17 deve preservar estes eixos; seus objetos não entram neste filtro.
-- Inclui o planetário para detectar algum fechamento antigo ainda no portal.
local clearance = OverlapParams.new()
clearance.FilterType = Enum.RaycastFilterType.Include
clearance.FilterDescendantsInstances = { Hall, planetarium, LCC }
clearance.RespectCanCollide = true
local routes = {
	{ "Portal", 135, 146, 23, 32 },
	{ "Central", 139, 395, 23, 32 },
	{ "North", 175, 391, 48.5, 57.5 },
	{ "South", 175, 391, -4.5, 4.5 },
	{ "WestLink", 170.5, 179.5, 0, 53 },
	{ "EastLink", 386.5, 395.5, 0, 90 },
	{ "AtriumLink", 260.5, 269.5, 53, 146 },
}
for _, route in routes do
	local center = CFrame.new((route[2] + route[3]) / 2, 3.2, (route[4] + route[5]) / 2)
	local size = Vector3.new(route[3] - route[2], 6, route[5] - route[4])
	local blockers = workspace:GetPartBoundsInBox(MUSEUM_CF * center, size, clearance)
	assert(#blockers == 0, "Fase 16: corredor bloqueado: " .. route[1] .. " / " .. (blockers[1] and blockers[1].Name or ""))
end

-- Ligações são medidas diretamente no mundo; nenhum raio fica no layout antigo.
for _, route in worldRoutes do
	local center = CFrame.new((route[2] + route[3]) / 2, 3.2, (route[4] + route[5]) / 2)
	local size = Vector3.new(route[3] - route[2], 6, route[5] - route[4])
	local blockers = workspace:GetPartBoundsInBox(center, size, clearance)
	assert(#blockers == 0, "Fase 16: ligação bloqueada: " .. route[1] .. " / " .. (blockers[1] and blockers[1]:GetFullName() or ""))
end

-- A inclinação da WedgePart deve subir para +Z; raycasts também detectam
-- um piso acidental cobrindo o nicho ou degraus sem apoio.
local floorRay = RaycastParams.new()
floorRay.FilterType = Enum.RaycastFilterType.Include
-- Inclui o terreno para não mascarar outra colisão acima do piso rebaixado.
local floorRoots = { Hall, baseplate }
for _, name in { "Baseplate_East", "Baseplate_South", "Baseplate_North", "Baseplate_Pit" } do
	local p = workspace:FindFirstChild(name)
	if p then table.insert(floorRoots, p) end
end
-- As soleiras da galeria encostam em pisos construídos por fases anteriores.
-- Inclua somente as peças de piso (não as paredes inteiras) para que um raio
-- vertical não seja mascarado por geometria lateral do planetário/LCC.
local function addFloorParts(root)
	if not root then return end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local n = string.lower(d.Name)
			local parentName = d.Parent and string.lower(d.Parent.Name) or ""
			if string.find(n, "floor", 1, true) or string.find(parentName, "floor", 1, true) then
				table.insert(floorRoots, d)
			end
		end
	end
end
addFloorParts(planetarium)
addFloorParts(LCC)
floorRay.FilterDescendantsInstances = floorRoots
floorRay.RespectCanCollide = true
local function checkFloor(x, z, expected)
	local hit = workspace:Raycast(MUSEUM_CF * Vector3.new(x, 6, z), MUSEUM_CF:VectorToWorldSpace(Vector3.new(0, -12, 0)), floorRay)
	assert(hit and math.abs(hit.Position.Y - expected) < 0.06,
		string.format("Fase 16: piso inesperado em (%.1f, %.1f), esperado Y %.2f", x, z, expected))
end
for _, point in { { 146, 27.5 }, { 175, 53 }, { 265, 110 }, { 391, 0 } } do
	checkFloor(point[1], point[2], 0)
end
checkFloor(377, -25, memorialY)
for _, point in { { 372, -25 }, { 350, -40 }, { 395, -10 } } do
	checkFloor(point[1], point[2], memorialY)
end
for _, z in { -6, -14, -22 } do checkFloor(355, z, (z + 5) / 6) end
for i = 0, 5 do checkFloor(377, -5.5 - i, -i * 0.5) end

for _, point in { { 90, (southLo.Z + southZ) / 2 }, { 150, galleryZ }, { 205, 84.5 }, { 40, 157 }, { 70, 119 } } do
	local hit = workspace:Raycast(Vector3.new(point[1], 6, point[2]), Vector3.new(0, -12, 0), floorRay)
	assert(hit and math.abs(hit.Position.Y) < 0.06, "Fase 16: soleira/piso de ligação incompleto")
end

-- Verifica a aproximação interna da porta sul do planetário. O volume tem
-- nove studs de largura e sete de altura, e acompanha Z=58 até a soleira;
-- pisos baixos (topo <= 0.3) são suporte válido e não contam como obstáculo.
local museumApproach = OverlapParams.new()
museumApproach.FilterType = Enum.RaycastFilterType.Include
museumApproach.FilterDescendantsInstances = { planetarium }
museumApproach.RespectCanCollide = true
local approachZ0 = 58
local approachZ1 = southZ
local approach = workspace:GetPartBoundsInBox(
	CFrame.new(90, 3.5, (approachZ0 + approachZ1) / 2),
	Vector3.new(9, 7, math.max(7, approachZ1 - approachZ0)),
	museumApproach
)
local function topY(part)
	local cf = part.CFrame
	local half = part.Size * 0.5
	local ext = math.abs(cf.XVector.Y) * half.X + math.abs(cf.YVector.Y) * half.Y + math.abs(cf.ZVector.Y) * half.Z
	return part.Position.Y + ext
end
local approachBlocker
for _, part in approach do
	if part.CanCollide and topY(part) > 0.3 then
		approachBlocker = part
		break
	end
end
assert(
	not approachBlocker,
	"Fase 16: circulação interna do planetário bloqueada / " .. (approachBlocker and approachBlocker.Name or "")
)
local exitCount = 0
for _, d in Hall:GetDescendants() do
	if CS:HasTag(d, "MuseumExit") then
		exitCount += 1
		local direction = d:GetAttribute("ExitDirection")
		assert(direction and math.abs(direction.Magnitude - 1) < 0.01, "Fase 16: saída sem direção unitária")
	end
end
assert(exitCount == 3, "Fase 16: esperado MuseumExit nas três entradas")

-- O lib marca peças/grupos. Completa também luzes, GUIs e seus descendentes.
local parts, lights, shadows = 0, 0, 0
for _, d in Hall:GetDescendants() do
	d:SetAttribute("BuildPhase", 16)
	if d:IsA("BasePart") then
		parts += 1
	elseif d:IsA("Light") then
		lights += 1
		if d.Shadows then shadows += 1 end
	end
end
assert(parts <= 580 and lights <= 60 and shadows <= 3, "Fase 16: orçamento excedido")
return string.format("Fase 16 R2: entrada (205,85), LCC A (82.5,157), B (132.5,119); %d peças, %d luzes, %d sombras", parts, lights, shadows)
