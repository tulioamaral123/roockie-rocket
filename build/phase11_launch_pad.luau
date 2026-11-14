--[[
	NASA Space Adventure — Fase 11: área externa, parte A (spec-v3 §9, §10, Etapa 5)

	Tudo em Z > 320 e X > −85 (a faixa X ≤ −85 é da sala de controle / observação):

	1. Crawlerway do portão dos fundos (Z 321) até a plataforma, reta em X = 0, piso no topo Y 0.
	   Duas faixas de cascalho (X ±4..±26, sob as esteiras do crawler em X ±11..±19), canteiro
	   central de grama e acostamentos de concreto até X ±45 (largura total 90).
	   Zona de exclusão X −40..40: só o piso (e marcações sem colisão rente ao piso).
	2. Plataforma de lançamento (Pad 39B simplificado), centro de destino do conjunto em (0, 0, 700):
	   hardstand de concreto, 6 pedestais de apoio do ML (topo Y 7) fora da pegada do crawler e da
	   escada da base, trincheira de chamas e defletor no sentido +Z (Z > 722), tanques esféricos
	   de LH2 (+X) e LOX (−X) com tubulações até as placas de umbilicais de solo, torre de água
	   (~105) e 3 torres de para-raios (~200) com catenária decorativa sem colisão. Cercas.
	   Sem torre de serviço fixa: a torre do Mobile Launcher faz esse papel.
	3. Estacionamento do crawler no lado +X (centro (90, 0, 620)), com ramal até a rota.
	4. Pontos da rota em Map.TransportSystem.CrawlerRoute: Point_01…Point_06,
	   Destination_LaunchPad (0, 0, 700) e Parking_Crawler (90, 0, 620). Mesma convenção do
	   Start_VAB: caixa 1 × 1 × 1 apoiada no piso (Y 0..1); o pivô exato fica no atributo Pivot.
	5. Placas e iluminação moderada (SpotLights sem sombra).

	Executar depois das Fases 1–10. Idempotente (B.clear apaga só o que tem BuildPhase = 11).
]]

local lib = ...
local B = lib.builder(11)

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–10 antes")
B.clear(Map)

local TS = Map:FindFirstChild("TransportSystem")
assert(TS and TS:FindFirstChild("CrawlerRoute"), "Execute a Fase 9 antes (TransportSystem.CrawlerRoute)")
local Route = TS.CrawlerRoute

local DECOR = { collide = false }
local DECOR_NS = { collide = false, shadow = false }
local HIDDEN = { collide = false, shadow = false, transparency = 1 }
local N = Enum.NormalId
local V = Vector3.new

-- Cotas principais
local ROUTE_Z0, ROUTE_Z1 = 321, 660 -- crawlerway (o hardstand começa em Z 660)
local ROUTE_HALF = 45 -- largura total 90
local PAD = V(0, 0, 700) -- pivô do TransportAssembly estacionado
local PAD_X0, PAD_X1, PAD_Z1 = -80, 92, 860 -- hardstand + avental da trincheira
local TRENCH_Z0, TRENCH_Z1 = 724, 820
local PARK = V(90, 0, 620)
local PARK_X0, PARK_X1, PARK_Z0, PARK_Z1 = 62, 122, 586, 660
local SPUR_X0, SPUR_Z0 = 45, 575

local CONCRETE, PAVE, GRAVEL, GRASS = "#B9B7B1", "#A7A59F", "#B5AE9F", "#6F8A4C"

-- Contagem de peças/luzes no fim
local Root = B.group(Map, "LaunchComplex")

---------------------------------------------------------------------------------
-- 1. Crawlerway
---------------------------------------------------------------------------------
local cw = B.group(Root, "Crawlerway")
-- Soleira: fecha a fresta de 0,8 entre a folha inferior do portão (Z 320,2) e a rota
B.box(cw, "Threshold", -40, 40, -1, 0, 320.2, ROUTE_Z0, CONCRETE, "Concrete")
B.box(cw, "Shoulder_L", -ROUTE_HALF, -26, -1, 0, ROUTE_Z0, ROUTE_Z1, CONCRETE, "Concrete")
B.box(cw, "Lane_L", -26, -4, -1, 0, ROUTE_Z0, ROUTE_Z1, GRAVEL, "Pebble")
B.box(cw, "Median", -4, 4, -1, 0, ROUTE_Z0, ROUTE_Z1, GRASS, "Grass")
B.box(cw, "Lane_R", 4, 26, -1, 0, ROUTE_Z0, ROUTE_Z1, GRAVEL, "Pebble")
B.box(cw, "Shoulder_R", 26, ROUTE_HALF, -1, 0, ROUTE_Z0, ROUTE_Z1, CONCRETE, "Concrete")
-- Marcações rente ao piso (sem colisão, 0,04 de altura)
local marks = B.group(cw, "Markings")
for _, x in { -ROUTE_HALF + 0.5, ROUTE_HALF - 0.5 } do
	B.box(marks, "Edge_Line", x - 0.3, x + 0.3, 0, 0.04, ROUTE_Z0, ROUTE_Z1, "safety", "SmoothPlastic", DECOR_NS)
end
for _, x in { -40, 40 } do -- limite da zona de exclusão
	for z = ROUTE_Z0 + 4, ROUTE_Z1 - 8, 16 do
		B.box(marks, "Exclusion_Dash", x - 0.25, x + 0.25, 0, 0.04, z, z + 8, "red", "SmoothPlastic", DECOR_NS)
	end
end
task.wait()

---------------------------------------------------------------------------------
-- 3. Estacionamento do crawler + ramal (lado +X)
---------------------------------------------------------------------------------
local park = B.group(Root, "CrawlerParking")
B.box(park, "Spur", SPUR_X0, PARK_X0, -1, 0, SPUR_Z0, PARK_Z1, CONCRETE, "Concrete")
-- Chanfro a 45° na junção rota/ramal (curva suave), mesmo concreto do acostamento
B.part(park, "Spur_Fillet", CFrame.new(SPUR_X0, -0.5, SPUR_Z0) * CFrame.Angles(0, math.rad(45), 0),
	V(15, 1, 15), CONCRETE, "Concrete")
B.box(park, "Parking_Slab", PARK_X0, PARK_X1, -1, 0, PARK_Z0, PARK_Z1, PAVE, "Concrete")
-- Contorno da vaga (crawler 38 × 44, folga ≥ 4 em cada lado): só tinta no piso
local px0, px1, pz0, pz1 = PARK.X - 23, PARK.X + 23, PARK.Z - 26, PARK.Z + 26
B.box(park, "Bay_Line", px0, px1, 0, 0.04, pz0, pz0 + 0.6, "safety", "SmoothPlastic", DECOR_NS)
B.box(park, "Bay_Line", px0, px1, 0, 0.04, pz1 - 0.6, pz1, "safety", "SmoothPlastic", DECOR_NS)
B.box(park, "Bay_Line", px0, px0 + 0.6, 0, 0.04, pz0, pz1, "safety", "SmoothPlastic", DECOR_NS)
B.box(park, "Bay_Line", px1 - 0.6, px1, 0, 0.04, pz0, pz1, "safety", "SmoothPlastic", DECOR_NS)
B.box(park, "Center_Mark", PARK.X - 3, PARK.X + 3, 0, 0.04, PARK.Z - 0.3, PARK.Z + 0.3, "white", "SmoothPlastic", DECOR_NS)
B.box(park, "Center_Mark", PARK.X - 0.3, PARK.X + 0.3, 0, 0.04, PARK.Z - 3, PARK.Z + 3, "white", "SmoothPlastic", DECOR_NS)
-- Faixa de guia do ramal (do eixo da rota até o centro da vaga)
B.box(park, "Guide_Line", 26, px0, 0, 0.04, PARK.Z - 0.3, PARK.Z + 0.3, "safety", "SmoothPlastic", DECOR_NS)
task.wait()

---------------------------------------------------------------------------------
-- 2. Plataforma de lançamento
---------------------------------------------------------------------------------
local Pad = B.group(Root, "LaunchPad")
local arch = B.group(Pad, "Architecture")
-- Hardstand (topo Y 0). Ao norte da linha Z 724 o piso é dividido para a trincheira não piscar.
B.box(arch, "Hardstand", PAD_X0, PAD_X1, -1, 0, ROUTE_Z1, TRENCH_Z0, CONCRETE, "Concrete")
B.box(arch, "Apron_W", PAD_X0, -16, -1, 0, TRENCH_Z0, PAD_Z1, CONCRETE, "Concrete")
B.box(arch, "Apron_E", 16, PAD_X1, -1, 0, TRENCH_Z0, PAD_Z1, CONCRETE, "Concrete")

-- Marcações da posição final (sem colisão)
local pm = B.group(arch, "Markings")
local mlx, mlz0, mlz1 = 24.1, PAD.Z - 20, PAD.Z + 20 -- pegada da base do ML
B.box(pm, "ML_Footprint", -mlx, mlx, 0, 0.04, mlz0, mlz0 + 0.6, "safety", "SmoothPlastic", DECOR_NS)
B.box(pm, "ML_Footprint", -mlx, mlx, 0, 0.04, mlz1 - 0.6, mlz1, "safety", "SmoothPlastic", DECOR_NS)
B.box(pm, "ML_Footprint", -mlx, -mlx + 0.6, 0, 0.04, mlz0, mlz1, "safety", "SmoothPlastic", DECOR_NS)
B.box(pm, "ML_Footprint", mlx - 0.6, mlx, 0, 0.04, mlz0, mlz1, "safety", "SmoothPlastic", DECOR_NS)
B.box(pm, "Pad_Centerline", -0.3, 0.3, 0, 0.04, ROUTE_Z1, mlz0, "white", "SmoothPlastic", DECOR_NS)
for _, x in { -34, 34 } do -- envelope de 68 na plataforma
	for z = ROUTE_Z1 + 2, 720, 12 do
		B.box(pm, "Envelope_Dash", x - 0.25, x + 0.25, 0, 0.04, z, z + 6, "red", "SmoothPlastic", DECOR_NS)
	end
end

-- Pedestais de apoio do ML (topo Y 7). X ±22,3..±24: dentro da base (X ±24,1), fora do crawler
-- (X ±19,1) e fora da escada da base (X −22..−16), que passa por eles ao entrar.
local ped = B.group(arch, "ML_Support_Pedestals")
for _, s in { -1, 1 } do
	for _, dz in { -15, 0, 15 } do
		local x0, x1 = s < 0 and -24 or 22.3, s < 0 and -22.3 or 24
		local p = B.box(ped, "Pedestal", x0, x1, 0, 6.6, PAD.Z + dz - 2, PAD.Z + dz + 2, "midGray", "Concrete")
		p:SetAttribute("SupportsMobileLauncher", true)
		B.box(ped, "Pedestal_Cap", x0, x1, 6.6, 7, PAD.Z + dz - 2, PAD.Z + dz + 2, "darkGray", "DiamondPlate")
	end
end

-- Placas de umbilicais de solo (fora do envelope de 68)
local umb = B.group(arch, "Ground_Umbilicals")
local plates = {}
for _, s in { -1, 1 } do
	local x0, x1 = s < 0 and -39 or 35, s < 0 and -35 or 39
	local pl = B.box(umb, s < 0 and "Umbilical_Plate_LOX" or "Umbilical_Plate_LH2", x0, x1, 0, 3, 706, 716, "metalGray", "DiamondPlate")
	B.box(umb, "Valve_Box", x0 + 0.5, x1 - 0.5, 3, 5, 708, 714, s < 0 and "#3A7BD5" or "white", "Metal")
	plates[s] = pl
end
task.wait()

-- Trincheira de chamas e defletor (acima do chão; a Baseplate não é escavada)
local trench = B.group(Pad, "FlameTrench")
B.box(trench, "Trench_Floor", -16, 16, -1, 0, TRENCH_Z0, PAD_Z1, "#5E5C58", "Concrete")
B.box(trench, "Scorch", -10, 10, 0, 0.04, TRENCH_Z0 + 20, TRENCH_Z1 + 30, "#2F2E2C", "Concrete", DECOR_NS)
for _, s in { -1, 1 } do
	local xi, xo = s * 10, s * 16
	B.box(trench, "Trench_Wall", math.min(xi, xo), math.max(xi, xo), 0, 6, TRENCH_Z0, TRENCH_Z1, "#9C9A94", "Concrete")
	-- berma externa em degrau
	local xb = s * 19
	B.box(trench, "Berm", math.min(xo, xb), math.max(xo, xb), 0, 3, TRENCH_Z0, TRENCH_Z1, "#A7A59F", "Concrete")
	B.box(trench, "Wall_Cap", math.min(xi, xo), math.max(xi, xo), 6, 6.4, TRENCH_Z0, TRENCH_Z1, "darkGray", "Metal")
end
local defl = B.group(Pad, "FlameDeflector")
-- Cunha: face alta (10) em Z 724, rampa descendo até Z 744 (desvia o jato para +Z)
B.part(defl, "Deflector", CFrame.new(0, 5, TRENCH_Z0 + 10) * CFrame.Angles(0, math.pi, 0), V(20, 10, 20),
	"#6B6A66", "Metal", nil, "Wedge")
B.box(defl, "Deflector_Base", -10, 10, 0, 1, TRENCH_Z0, TRENCH_Z0 + 22, "#4A4946", "Metal")
task.wait()

---------------------------------------------------------------------------------
-- Tanques cenográficos e tubulações
---------------------------------------------------------------------------------
local tanks = B.group(Pad, "ServiceTanks")
local function sphereTank(name, c, dia, color, legR)
	local m = B.group(tanks, name)
	local cy = dia / 2 + 2
	B.cyl(m, "Foundation", c.X, c.Z, 0, 0.6, dia + 4, "midGray", "Concrete")
	for i = 0, 7 do
		local a = i * math.pi / 4
		B.cyl(m, "Leg", c.X + legR * math.cos(a), c.Z + legR * math.sin(a), 0.6, cy, 1.4, "metalGray", "Metal")
	end
	B.ball(m, "Sphere", V(c.X, cy, c.Z), dia, color, "Metal") -- metal: tanque pintado (docs/materials)
	B.cyl(m, "Equator_Band", c.X, c.Z, cy - 0.4, cy + 0.4, dia + 0.3, "paleGray", "Metal", DECOR)
	B.cyl(m, "Vent_Stack", c.X, c.Z, cy + dia / 2 - 1, cy + dia / 2 + 6, 1, "metalGray", "Metal")
	return m, cy
end
local lh2 = sphereTank("LH2_Tank", V(70, 0, 738), 30, "white", 12)
local lox = sphereTank("LOX_Tank", V(-60, 0, 748), 26, "#F2F4F5", 10)

local pipes = B.group(tanks, "Pipes")
local function pipeRun(name, pts, dia, color)
	for i = 1, #pts - 1 do
		B.cylBetween(pipes, name, pts[i], pts[i + 1], dia, color, "Metal")
	end
	for i = 1, #pts do -- suportes nos vértices
		local p = pts[i]
		B.box(pipes, "Pipe_Support", p.X - 0.8, p.X + 0.8, 0, math.max(p.Y - dia / 2, 0.2), p.Z - 0.8, p.Z + 0.8, "darkGray", "Metal")
	end
end
-- LH2 → placa +X (duas linhas paralelas)
pipeRun("LH2_Line", { V(62, 1.6, 724), V(50, 1.6, 713), V(39, 1.6, 713) }, 1.6, "white")
pipeRun("LH2_Vent_Line", { V(66, 1.0, 722), V(52, 1.0, 709), V(39, 1.0, 709) }, 0.9, "safety")
-- LOX → placa −X
pipeRun("LOX_Line", { V(-53, 1.6, 736), V(-45, 1.6, 713), V(-39, 1.6, 713) }, 1.6, "#3A7BD5")
pipeRun("LOX_Vent_Line", { V(-57, 1.0, 735), V(-48, 1.0, 709), V(-39, 1.0, 709) }, 0.9, "safety")
task.wait()

---------------------------------------------------------------------------------
-- Torre de água (~105)
---------------------------------------------------------------------------------
local wt = B.group(Pad, "WaterTower")
local WT = V(48, 0, 812)
local WT_LEG_TOP, WT_DIA = 84, 22
B.cyl(wt, "Foundation", WT.X, WT.Z, 0, 0.8, 22, "midGray", "Concrete")
local legPts = {}
for i = 0, 5 do
	local a = i * math.pi / 3
	local p0 = V(WT.X + 9 * math.cos(a), 0.8, WT.Z + 9 * math.sin(a))
	local p1 = V(WT.X + 6 * math.cos(a), WT_LEG_TOP, WT.Z + 6 * math.sin(a))
	B.cylBetween(wt, "Leg", p0, p1, 1.4, "paleGray", "Metal")
	legPts[i] = { p0, p1 }
end
for _, t in { 0.25, 0.5, 0.75 } do -- anéis de travamento
	for i = 0, 5 do
		local a, b = legPts[i], legPts[(i + 1) % 6]
		B.cylBetween(wt, "Brace", a[1]:Lerp(a[2], t), b[1]:Lerp(b[2], t), 0.6, "paleGray", "Metal")
	end
end
B.cyl(wt, "Riser", WT.X, WT.Z, 0.8, WT_LEG_TOP + 2, 3, "metalGray", "Metal")
B.cyl(wt, "Tank_Skirt", WT.X, WT.Z, WT_LEG_TOP - 1, WT_LEG_TOP + 1, 14, "paleGray", "Metal")
local wtBall = B.ball(wt, "Tank", V(WT.X, 105 - WT_DIA / 2, WT.Z), WT_DIA, "white", "Metal")
B.cyl(wt, "Tank_Band", WT.X, WT.Z, 93.6, 94.4, WT_DIA + 0.3, "nasaBlue", "Metal", DECOR)
-- Adutora até a parede da trincheira (+X)
pipeRun("Water_Main", { V(WT.X - 6, 1.4, WT.Z - 4), V(19.5, 1.4, 790) }, 2.4, "metalGray")
task.wait()

---------------------------------------------------------------------------------
-- Torres de para-raios (~200) + catenária
---------------------------------------------------------------------------------
local lt = B.group(Pad, "LightningTowers")
local TOWERS = { V(-60, 0, 688), V(60, 0, 688), V(-42, 0, 830) }
local MAST_TOP = 200
local tops = {}
for ti, c in TOWERS do
	local m = B.group(lt, "Lightning_Tower_" .. ti)
	B.box(m, "Footing", c.X - 5, c.X + 5, 0, 1.5, c.Z - 5, c.Z + 5, "midGray", "Concrete")
	local H, h = 180, 3.2 -- metade da largura no pé e no topo
	local corners = {}
	for k, d in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		local p0 = V(c.X + d[1] * h, 1.5, c.Z + d[2] * h)
		local p1 = V(c.X + d[1] * 1.6, H, c.Z + d[2] * 1.6)
		B.cylBetween(m, "Leg", p0, p1, 0.9, "metalGray", "Metal")
		corners[k] = { p0, p1 }
	end
	local LEVELS = 9
	for lv = 1, LEVELS do
		local t0, t1 = (lv - 1) / LEVELS, lv / LEVELS
		for k = 1, 4 do
			local a, b = corners[k], corners[k % 4 + 1]
			B.cylBetween(m, "Band", a[1]:Lerp(a[2], t1), b[1]:Lerp(b[2], t1), 0.45, "metalGray", "Metal", DECOR)
			-- diagonal em zigue-zague
			local even = lv % 2 == 0
			B.cylBetween(m, "Diagonal", (even and a or b)[1]:Lerp((even and a or b)[2], t0),
				(even and b or a)[1]:Lerp((even and b or a)[2], t1), 0.35, "metalGray", "Metal", DECOR)
		end
	end
	B.cyl(m, "Mast", c.X, c.Z, H, MAST_TOP, 1.4, "paleGray", "SmoothPlastic", DECOR)
	B.ball(m, "Beacon", V(c.X, MAST_TOP + 0.6, c.Z), 1.4, "red", "Neon", DECOR_NS)
	tops[ti] = V(c.X, MAST_TOP - 1, c.Z)
end
local cat = B.group(lt, "Catenary")
local function wire(p0, p1, sag, segs)
	local prev = p0
	for i = 1, segs do
		local t = i / segs
		local p = p0:Lerp(p1, t) - V(0, 4 * sag * t * (1 - t), 0)
		B.cylBetween(cat, "Wire", prev, p, 0.25, "black", "Metal", DECOR_NS)
		prev = p
	end
end
wire(tops[1], tops[2], 22, 10) -- passa sobre a plataforma, ponto mais baixo ~177
wire(tops[1], tops[3], 18, 8)
wire(tops[2], tops[3], 22, 10)
-- Estais de descida até âncoras no chão, sempre para fora da plataforma
for ti, a in { V(-80, 0, 670), V(86, 0, 670), V(-62, 0, 856) } do
	B.box(cat, "Anchor", a.X - 1.5, a.X + 1.5, 0, 1, a.Z - 1.5, a.Z + 1.5, "midGray", "Concrete")
	B.cylBetween(cat, "Ground_Wire", tops[ti], a + V(0, 1, 0), 0.25, "black", "Metal", DECOR_NS)
end
task.wait()

---------------------------------------------------------------------------------
-- Cercas (painéis de alambrado translúcidos + postes)
---------------------------------------------------------------------------------
local fences = B.group(Root, "Fences")
local function fence(name, x0, z0, x1, z1)
	local m = B.group(fences, name)
	local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
	local n = math.max(1, math.ceil(len / 24))
	for i = 0, n do
		local t = i / n
		local x, z = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
		B.box(m, "Post", x - 0.25, x + 0.25, -1, 8, z - 0.25, z + 0.25, "metalGray", "Metal")
	end
	if x0 == x1 then
		B.box(m, "Mesh", x0 - 0.05, x0 + 0.05, -1, 7.6, z0, z1, "midGray", "Metal", { transparency = 0.65 })
		B.box(m, "Top_Rail", x0 - 0.15, x0 + 0.15, 7.6, 7.9, z0, z1, "metalGray", "Metal", DECOR)
	else
		B.box(m, "Mesh", x0, x1, -1, 7.6, z0 - 0.05, z0 + 0.05, "midGray", "Metal", { transparency = 0.65 })
		B.box(m, "Top_Rail", x0, x1, 7.6, 7.9, z0 - 0.15, z0 + 0.15, "metalGray", "Metal", DECOR)
	end
end
fence("Crawlerway_Fence_W", -48, 321.5, -48, 652) -- encosta na parede dos fundos do VAB (Z 321)
fence("Crawlerway_Fence_E", 48, 321.5, 48, 562)
fence("Pad_Fence_W", -83, 652, -83, 878)
fence("Pad_Fence_N", -83, 878, 96, 878)
fence("Pad_Fence_E", 96, 664, 96, 878)
fence("Pad_Fence_S_W", -83, 652, -48, 652)
fence("Parking_Fence_E", 126, 582, 126, 664)
fence("Parking_Fence_S", 66, 582, 126, 582)
fence("Pad_Fence_S_E", 96, 664, 126, 664)
-- fecha a brecha entre a cerca leste da rota e a do estacionamento (fora do caminho do crawler, Z ≥ 598)
fence("Parking_Fence_Link_W", 48, 562, 48, 582)
fence("Parking_Fence_Link_S", 48, 582, 66, 582)
task.wait()

---------------------------------------------------------------------------------
-- 5. Placas e iluminação
---------------------------------------------------------------------------------
local signs = B.group(Root, "Signage")
-- Placa em dois postes; face Front (−Z) ou a face indicada
local function board(name, cx, cz, w, h, y0, title, body, opts, axis)
	local m = B.group(signs, name)
	local p
	if axis == "X" then -- painel paralelo ao eixo Z (lido de ±X)
		for _, dz in { -w / 2 + 0.4, w / 2 - 0.4 } do
			B.box(m, "Post", cx - 0.2, cx + 0.2, 0, y0 + h, cz + dz - 0.2, cz + dz + 0.2, "darkGray", "Metal")
		end
		p = B.box(m, "Panel", cx - 0.15, cx + 0.15, y0, y0 + h, cz - w / 2, cz + w / 2, "space", "SmoothPlastic")
	else
		for _, dx in { -w / 2 + 0.4, w / 2 - 0.4 } do
			B.box(m, "Post", cx + dx - 0.2, cx + dx + 0.2, 0, y0 + h, cz - 0.2, cz + 0.2, "darkGray", "Metal")
		end
		p = B.box(m, "Panel", cx - w / 2, cx + w / 2, y0, y0 + h, cz - 0.15, cz + 0.15, "space", "SmoothPlastic")
	end
	B.sign(p, title, body, opts)
	return p
end
board("Sign_Crawlerway", 56, 334, 14, 6, 3, "CRAWLERWAY", "Launch Pad 39B ↑ 380 studs · Crawler route — keep clear",
	{ accent = "safety", titleColor = "safety", maxBody = 34 })
board("Sign_Exclusion_W", -54, 470, 12, 5, 2, "DANGER", "Crawler exclusion zone. Do not enter the crawlerway.",
	{ face = N.Right, bg = "#8E1F18", titleColor = "white", accent = "safety", maxBody = 34 }, "X")
board("Sign_Exclusion_E", 54, 470, 12, 5, 2, "DANGER", "Crawler exclusion zone. Do not enter the crawlerway.",
	{ face = N.Left, bg = "#8E1F18", titleColor = "white", accent = "safety", maxBody = 34 }, "X")
board("Sign_Pad", -64, 650, 18, 7, 3, "LAUNCH COMPLEX 39B", "Space Launch System · Mobile Launcher pad",
	{ accent = "red", titleColor = "white", maxBody = 34 })
board("Sign_Parking", 104, 578, 16, 5, 2, "CRAWLER PARKING", "Crawler-Transporter rest area · no fixed structures",
	{ accent = "safety", titleColor = "safety", maxBody = 34 })
board("Sign_LH2", 75, 712, 12, 4, 1.5, "LH2 · LIQUID HYDROGEN", nil, { titleColor = "white", bg = "nasaBlue" })
board("Sign_LOX", -64, 724, 12, 4, 1.5, "LOX · LIQUID OXYGEN", nil, { titleColor = "white", bg = "nasaBlue" })
board("Sign_Water", 64, 795, 12, 4, 1.5, "SOUND SUPPRESSION WATER", nil, { titleColor = "lightBlue" })
board("Sign_Trench", -30, 780, 12, 4, 1.5, "FLAME TRENCH · KEEP OUT", nil, { face = N.Right, bg = "#8E1F18", titleColor = "white" }, "X")

local lights = B.group(Root, "Lighting")
local nLights = 0
local function lampPost(cx, cz, h, armDir, range, angle, bright)
	local m = B.group(lights, "Lamp_Post")
	B.cyl(m, "Pole", cx, cz, 0, h, 0.8, "metalGray", "Metal")
	local hx = cx + armDir * 3
	B.box(m, "Arm", math.min(cx, hx), math.max(cx, hx), h - 0.4, h, cz - 0.25, cz + 0.25, "metalGray", "Metal", DECOR)
	local head = B.box(m, "Lamp", hx - 1, hx + 1, h - 0.9, h - 0.4, cz - 0.6, cz + 0.6, "#FFF4D8", "Neon", DECOR_NS)
	B.light(head, "SpotLight", { Face = N.Bottom, Range = range, Angle = angle, Brightness = bright,
		Color = Color3.fromRGB(255, 240, 215), Shadows = false })
	nLights += 1
end
for _, z in { 380, 480, 580 } do
	lampPost(-54, z, 18, 1, 40, 110, 1.6)
	lampPost(54, z, 18, -1, 40, 110, 1.6)
end
lampPost(-78, 700, 30, 1, 60, 100, 2) -- floods da plataforma
lampPost(90, 700, 30, -1, 60, 100, 2)
lampPost(128, 620, 18, -1, 45, 110, 1.4) -- estacionamento (poste fora da área)
task.wait()

---------------------------------------------------------------------------------
-- 4. Pontos da rota (mesma convenção do Start_VAB: caixa 1³ com a base no piso)
---------------------------------------------------------------------------------
local function point(name, pos, attrs)
	local p = B.box(Route, name, pos.X - 0.5, pos.X + 0.5, pos.Y, pos.Y + 1, pos.Z - 0.5, pos.Z + 0.5, "safety", "SmoothPlastic", HIDDEN)
	p:SetAttribute("Pivot", pos)
	for k, v in attrs or {} do p:SetAttribute(k, v) end
	return p
end
local MAIN = { 321, 400, 480, 560, PARK.Z, 665 }
for i, z in MAIN do
	point(string.format("Point_%02d", i), V(0, 0, z), { Order = i, Leg = "Main" })
end
Route:FindFirstChild("Point_05"):SetAttribute("ParkingJunction", true)
point("Destination_LaunchPad", PAD, { Order = #MAIN + 1, Leg = "Main" })
point("Parking_Crawler", PARK, { Leg = "Parking", Via = "Point_05" })

-- Resumo
local nParts = 0
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("BuildPhase") == 11 then nParts += 1 end
end
return string.format("Fase 11: crawlerway, plataforma e estacionamento (%d peças, %d luzes)", nParts, nLights)
