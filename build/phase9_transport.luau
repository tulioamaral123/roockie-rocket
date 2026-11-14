--[[
	NASA Space Adventure — Fase 9: conjunto de transporte (spec-v3, Etapa 2)

	Reorganiza o lançador, o SLS e a torre esquerda num único conjunto móvel e coloca
	o crawler embaixo:

	  Map.TransportSystem
	  ├── TransportAssembly            pivô (0, 0, 265)
	  │   ├── CrawlerTransporter       pivô (0, 0, 265), Y 0..7
	  │   ├── MobileLauncher           pivô (0, 7, 265), base Y 7..15,5
	  │   │   ├── Base                 deck, holddown posts, escada, luzes do deck
	  │   │   ├── ServiceTower         antiga torre esquerda + elevador da tripulação
	  │   │   ├── Umbilicals           braços dos níveis 40 e 60 (um Model por braço)
	  │   │   ├── AccessArms           braço da tripulação + braço de serviço do nível 100
	  │   │   └── WhiteRoom
	  │   └── SLSRocket                pivô (0, 16, 265)
	  └── CrawlerRoute
	      └── Start_VAB

	- Tudo o que estava sobre o deck sobe RISE = 5,5 (base do ML com 8,5; topo do SLS em 133).
	- Os pedestais do lançador são substituídos pelo crawler; a escada do deck é refeita.
	- A torre direita é removida (estava dentro do envelope de transporte).
	- O vestiário fica fixo no piso do VAB (Fase 8) e não faz parte do conjunto.
	- Elevador e escotilhas da Orion usam referências relativas (Fase 8): nada a corrigir aqui.

	Executar depois das Fases 3–8 (o run_in_studio.luau já inclui esta fase).
	Esta fase move peças criadas pelas Fases 3, 5 e 8. Para refazê-la, reexecute
	a partir da Fase 3; rodá-la de novo sem isso não faz nada.
]]

local lib = ...
local B = lib.builder(9)

local Map = workspace:FindFirstChild("Map")
assert(Map, "Execute as Fases 1–8 antes")
local Hangar = Map.Rocket_Hangar

local oldML = Hangar.Launch_Platform:FindFirstChild("Mobile_Launcher")
if not oldML then
	if Map:FindFirstChild("TransportSystem") then
		return "Fase 9: já aplicada (para refazer, reexecute a partir da Fase 3)"
	end
	error("Fase 9: Mobile_Launcher não encontrado; execute as Fases 3–8 antes")
end
local leftover = Map:FindFirstChild("TransportSystem")
if leftover then leftover:Destroy() end

local RISE = 5.5
local ROCKET_Z = 265
local CRAWLER_TOP = 7
local DECK_TOP = 10 + RISE -- 15,5 (topo do deck da Fase 3 + RISE)
local UP = Vector3.new(0, RISE, 0)
local DECOR = { collide = false }
local HIDDEN = { collide = false, transparency = 1, shadow = false }

local function raise(inst)
	if inst:IsA("BasePart") then
		inst.CFrame += UP
	elseif inst:IsA("Model") then
		inst:PivotTo(inst:GetPivot() + UP)
	else
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") then d.CFrame += UP end
		end
	end
end

local function setPivot(model, cf)
	if model.PrimaryPart then
		model.PrimaryPart.PivotOffset = model.PrimaryPart.CFrame:ToObjectSpace(cf)
	else
		model.WorldPivot = cf
	end
end

local function move(inst, parent, name)
	inst.Parent = parent
	if name then inst.Name = name end
	return inst
end

---------------------------------------------------------------------------------
-- Hierarquia
---------------------------------------------------------------------------------
local TS = B.group(Map, "TransportSystem", "Folder")
local TA = B.group(TS, "TransportAssembly")
local CR = B.group(TA, "CrawlerTransporter")
local ML = B.group(TA, "MobileLauncher")
local route = B.group(TS, "CrawlerRoute", "Folder")

B.box(route, "Start_VAB", -0.5, 0.5, 0, 1, ROCKET_Z - 0.5, ROCKET_Z + 0.5, "safety", "SmoothPlastic", HIDDEN)

---------------------------------------------------------------------------------
-- Base do Mobile Launcher (Y 7..15,5)
---------------------------------------------------------------------------------
local base = move(oldML, ML, "Base")
for _, d in base:GetChildren() do
	if d.Name == "Pedestal" or d.Name == "Access_Stairs" then
		d:Destroy()
	elseif d.Name == "Deck" then
		local y0, y1 = CRAWLER_TOP, DECK_TOP
		d.Size = Vector3.new(d.Size.X, y1 - y0, d.Size.Z)
		d.CFrame = CFrame.new(d.Position.X, (y0 + y1) / 2, d.Position.Z)
	else
		raise(d)
	end
end
-- escada de acesso ao deck (frente, lado esquerdo), do piso até a chapa (Y 15,6)
local stairs = B.group(base, "Access_Stairs")
local STEPS, PLATE_TOP = 15, DECK_TOP + 0.1
for i = 1, STEPS do
	B.box(stairs, "Step", -22, -16, 0, i * PLATE_TOP / STEPS, 245 - (STEPS + 1 - i), 245 - (STEPS - i), "darkGray", "DiamondPlate")
end
local z0s = 245 - STEPS
for _, x in { -22.15, -15.85 } do
	B.beam(stairs, "Rail", Vector3.new(x, PLATE_TOP / STEPS + 3, z0s + 0.5), Vector3.new(x, PLATE_TOP + 3, 245), 0.25, 0.25, "safety", "Metal", DECOR)
end
-- luzes do deck (Fase 5)
local lights = workspace:FindFirstChild("Lighting_Objects")
local hangarLights = lights and lights:FindFirstChild("Hangar")
if hangarLights then
	for _, l in hangarLights:GetChildren() do
		if l.Name == "Rocket_Flood" then
			raise(l)
			move(l, base)
		end
	end
end

---------------------------------------------------------------------------------
-- SLS
---------------------------------------------------------------------------------
local sls = move(Hangar.SLS_Rocket.SLS_Block1, TA, "SLSRocket")
raise(sls)
setPivot(sls, CFrame.new(0, DECK_TOP + 0.5, ROCKET_Z))

---------------------------------------------------------------------------------
-- Torres: a esquerda vira a torre móvel; a direita sai do envelope
---------------------------------------------------------------------------------
local crew = Hangar.Crew_Access
local tower = move(Hangar.Gantry.Service_Tower_L, ML, "ServiceTower")
raise(tower)
local elevator = move(crew.Crew_Elevator, tower)
raise(elevator)
Hangar.Gantry.Service_Tower_R:Destroy()
if hangarLights then
	for _, l in hangarLights:GetChildren() do
		if l.Name == "Tower_Flood" then
			if l.Position.X < 0 then
				raise(l)
				move(l, tower)
			else
				l:Destroy()
			end
		end
	end
end

-- braços da torre: níveis 40 e 60 → Umbilicals; nível 100 → AccessArms.Service_Arm
local umb = B.group(ML, "Umbilicals")
local arms = B.group(ML, "AccessArms")
local levels = {}
for _, d in tower:GetChildren() do
	if d:IsA("BasePart") and (d.Name == "Arm_Deck" or d.Name == "Arm_Rail" or d.Name == "White_Room") then
		local lvl = math.floor((d.Position.Y - RISE + 1) / 20 + 0.5) * 20 -- 40, 60 ou 100
		levels[lvl] = levels[lvl] or {}
		table.insert(levels[lvl], d)
	end
end
for lvl, parts in levels do
	local m
	if lvl < 100 then
		m = B.group(umb, "Umbilical_" .. lvl)
	else
		m = B.group(arms, "Service_Arm_" .. lvl)
	end
	for _, p in parts do p.Parent = m end
	setPivot(m, CFrame.new(-17, lvl + RISE, ROCKET_Z)) -- articulação junto à torre
end

-- braço da tripulação (Fase 8) e White Room
local crewArm = move(crew.Crew_Access_Arm, arms)
raise(crewArm)
local wr = move(crewArm.White_Room, ML, "WhiteRoom")
local CREW_TOP = 111.5 + RISE
setPivot(crewArm, CFrame.new(-17.4, CREW_TOP, ROCKET_Z))

-- O vestiário (Crew_Access.Suit_Room) é fixo no piso do VAB e não entra no conjunto.
-- Elevador e escotilhas usam referências relativas (Fase 8), então acompanham o conjunto sozinhos.

setPivot(ML, CFrame.new(0, CRAWLER_TOP, ROCKET_Z))

---------------------------------------------------------------------------------
-- Crawler-Transporter (Y 0..7, sob a base do ML)
---------------------------------------------------------------------------------
local root = B.box(CR, "Root", -0.5, 0.5, 0, 1, ROCKET_Z - 0.5, ROCKET_Z + 0.5, "safety", "SmoothPlastic", HIDDEN)
CR.PrimaryPart = root
root.PivotOffset = CFrame.new(0, -0.5, 0) -- pivô no piso

local X0, X1, Z0, Z1 = -19, 19, ROCKET_Z - 18, ROCKET_Z + 18 -- 38 × 36
B.box(CR, "Upper_Frame", X0, X1, 5, CRAWLER_TOP, Z0, Z1, "metalGray", "Metal")
B.box(CR, "Lower_Body", -10, 10, 2.5, 5, Z0 + 4, Z1 - 4, "darkGray", "Metal")
for _, sx in { -1, 1 } do
	B.box(CR, "Edge_Stripe", sx * 19, sx * 19.1, 5.6, 6.4, Z0, Z1, "safety", "SmoothPlastic", DECOR)
end
for _, sz in { -1, 1 } do
	local z = (sz < 0) and Z0 or Z1
	B.box(CR, "Edge_Stripe", X0, X1, 5.6, 6.4, z + sz * 0.05, z + sz * 0.1, "safety", "SmoothPlastic", DECOR)
end
-- quatro truques, cada um com duas esteiras
for _, sx in { -1, 1 } do
	for _, zc in { Z0 + 5, Z1 - 5 } do
		local truck = B.group(CR, "Truck")
		B.box(truck, "Truck_Frame", sx * 11, sx * 19, 3, 5, zc - 5, zc + 5, "darkGray", "Metal")
		for _, t in { { 11.3, 14.7 }, { 15.3, 18.7 } } do
			B.box(truck, "Track", sx * t[1], sx * t[2], 0, 3, zc - 4.8, zc + 4.8, "black", "Metal")
			for k = -3, 3 do
				B.box(truck, "Track_Shoe", sx * t[1] - sx * 0.05, sx * t[2] + sx * 0.05, 2.6, 3.05, zc + k * 1.35 - 0.3, zc + k * 1.35 + 0.3, "darkGray", "Metal", DECOR)
			end
		end
		B.cyl(truck, "Jack_Cylinder", sx * 15, zc, 5, CRAWLER_TOP, 2.6, "paleGray", "Metal", DECOR)
	end
end
-- duas cabines de operação em cantos opostos
for _, c in { { x0 = -18.5, x1 = -13, z0 = Z1, z1 = Z1 + 4, face = 1 }, { x0 = 13, x1 = 18.5, z0 = Z0 - 4, z1 = Z0, face = -1 } } do
	local cab = B.group(CR, "Operator_Cab")
	B.box(cab, "Cab_Body", c.x0, c.x1, 2, 6.5, c.z0, c.z1, "paleGray", "SmoothPlastic")
	local zf = (c.face > 0) and c.z1 or c.z0
	B.box(cab, "Window", c.x0 + 0.5, c.x1 - 0.5, 4, 5.8, zf, zf + c.face * 0.1, "glass", "Glass", { transparency = 0.3, collide = false })
	B.box(cab, "Roof_Trim", c.x0, c.x1, 6.5, 6.8, c.z0, c.z1, "safety", "SmoothPlastic")
	B.cyl(cab, "Beacon", (c.x0 + c.x1) / 2, (c.z0 + c.z1) / 2, 6.8, 7.4, 0.8, "safety", "Neon", DECOR)
end

TA.PrimaryPart = nil
TA.WorldPivot = CFrame.new(0, 0, ROCKET_Z)

local n = 0
for _, d in TA:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
return string.format("Fase 9: conjunto de transporte montado (%d peças)", n)
