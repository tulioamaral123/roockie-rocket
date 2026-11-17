-- Ala de treinamento opcional; executar depois do runner 3–24, em Edit.
-- Mantém os acessos existentes. Não altera árvores nem a gravidade global.
local lib, baseUrl = ...
baseUrl = baseUrl or "http://127.0.0.1:8766/"
local B = lib.builder(25)
local Map = assert(workspace:FindFirstChild("NASAComplex"), "Run phases 1–24 first")
B.clear(Map)
local Root = B.group(Map, "AstronautTraining")
local decor = { collide = false, shadow = false }
local function box(name, x0, x1, y0, y1, z0, z1, color, material, options)
	return B.box(Root, name, x0, x1, y0, y1, z0, z1, color, material, options)
end
local function sign(name, x, y, z, width, title, body)
	local p = box(name, x - width / 2, x + width / 2, y, y + 5, z, z + 0.3, "nasaBlue", "SmoothPlastic", decor)
	B.sign(p, title, body, { accent = "red", titleColor = "white" })
	return p
end
local function station(name, x, z, action, object)
	local p = box(name, x - 1.5, x + 1.5, 0, 3, z - 1, z + 1, "nasaBlue", "Metal")
	box(name .. "Screen", x - 1.3, x + 1.3, 3, 3.3, z - 0.8, z + 0.8, "lightBlue", "Neon", decor)
	p:SetAttribute("TrainingAction", action)
	p:SetAttribute("TrainingLabel", object)
	return p
end

-- Pavilhão além da faixa de árvores (X máximo 430), sem cruzar o museu ou o crawlerway.
box("Ground", 444, 596, -2, -1, 64, 222, "#588044", "Grass")
box("Floor", 460, 580, -1, 0, 90, 202, "lightGray", "Concrete")
box("VisitorWalkEast", 5, 524, -1, 0, -99, -91, "lightGray", "Concrete")
box("VisitorWalkNorth", 516, 524, -1, 0, -91, 90, "lightGray", "Concrete")
-- Protege os trechos que passam além da borda da Baseplate.
for _, z in { -99, -91 } do
	local endX = z == -91 and 516 or 524
	B.beam(Root, "EastWalkRail", Vector3.new(490, 3, z), Vector3.new(endX, 3, z), 0.3, 0.3, "metalGray", "Metal")
	for x = 490, endX, 8 do B.cyl(Root, "EastRailPost", x, z, 0, 3, 0.3, "metalGray", "Metal") end
end
B.beam(Root, "WalkCornerRail", Vector3.new(524, 3, -99), Vector3.new(524, 3, -91), 0.3, 0.3, "metalGray", "Metal")
for _, x in { 516, 524 } do
	B.beam(Root, "WalkRail", Vector3.new(x, 3, -91), Vector3.new(x, 3, 89), 0.3, 0.3, "metalGray", "Metal")
	for z = -90, 86, 16 do B.cyl(Root, "RailPost", x, z, 0, 3, 0.3, "metalGray", "Metal") end
end
box("WestWall", 459, 460, 0, 24, 90, 203, "lightGray", "Concrete")
box("EastWall", 580, 581, 0, 24, 90, 203, "lightGray", "Concrete")
box("NorthWall", 460, 580, 0, 24, 202, 203, "lightGray", "Concrete")
box("FrontLeft", 460, 512, 0, 24, 89, 90, "lightGray", "Concrete")
box("FrontRight", 528, 580, 0, 24, 89, 90, "lightGray", "Concrete")
box("EntryHeader", 512, 528, 14, 24, 89, 90, "lightGray", "Concrete")
box("Roof", 459, 581, 24, 25, 89, 203, "white", "Concrete")
for _, x in { 459.5, 580.5 } do
	for _, z in { 89.5, 202.5 } do B.cyl(Root, "Corner", x, z, 0, 24, 1.4, "lightGray", "Concrete") end
end
for _, x in { 478, 520, 562 } do
	for _, z in { 110, 150, 185 } do
		local p = box("CeilingLight", x - 5, x + 5, 23.7, 23.9, z - 1, z + 1, "white", "Neon", decor)
		local light = Instance.new("PointLight")
		light.Range, light.Brightness, light.Shadows = 28, 1.2, false
		light.Parent = p
	end
end
sign("EntranceSign", 520, 16, 88.5, 40, "ASTRONAUT TRAINING", "Explore. Practice. Work together.")
sign("Wayfinding", 18, 2, -90.5, 18, "TRAINING CENTER >", "Follow the east visitor walk")
sign("Briefing", 476, 5, 102, 25, "TRAIN LIKE AN ASTRONAUT", "Optional simulations • Solo or crew\nGravity • Repair • Mission control")
sign("ScienceNotice", 563, 5, 102, 26, "TRAINING SIMULATIONS", "Gravity and equipment are simplified for learning.\nYour progress here lasts for this server session.")

-- Três pistas com os mesmos obstáculos: a diferença vem da gravidade local.
local gravity = B.group(Root, "GravityLab")
for i, cfg in { { "Earth", 1 }, { "Moon", 0.166 }, { "Mars", 0.38 } } do
	local x = 464 + (i - 1) * 38
	local lane = B.group(gravity, cfg[1])
	local zone = B.box(lane, "Zone", x, x + 34, 0, 23, 116, 158, "lightBlue", "SmoothPlastic", { collide = false, transparency = 1 })
	zone:SetAttribute("GravityRatio", cfg[2])
	sign("GravitySign" .. i, x + 17, 7, 157, 25, string.upper(cfg[1]) .. " GRAVITY", "Visit checkpoints 1–3 in order.\nCompare your jumps on each world.")
	for n = 1, 3 do
		local px = x + (n == 2 and 25 or 9)
		local z = 119 + n * 9
		B.box(lane, "Step" .. n, px - 4, px + 4, 0, n == 2 and 1.5 or 0.5, z - 3, z + 3, "paleGray", "Metal")
		local p = B.box(lane, "Checkpoint" .. n, px - 0.5, px + 0.5, 3, 4, z - 0.5, z + 0.5, "lightBlue", "Neon", decor)
		p:SetAttribute("TrainingAction", "Gravity")
		p:SetAttribute("TrainingLabel", cfg[1] .. " checkpoint " .. n)
		p:SetAttribute("Lane", cfg[1])
		p:SetAttribute("Checkpoint", n)
	end
end
sign("RepairSign", 481, 7, 201, 32, "SYSTEMS REPAIR", "1 Isolate power • 2 Replace filter • 3 Restore\nStart at the isolation switch. Repeat anytime.")
station("Isolate", 468, 182, "Repair", "1 • Isolate power"):SetAttribute("Step", 1)
station("Filter", 481, 182, "Repair", "2 • Replace air filter"):SetAttribute("Step", 2)
station("Restore", 494, 182, "Repair", "3 • Restore power"):SetAttribute("Step", 3)
for x = 468, 494, 13 do
	B.cyl(Root, "RepairPipe", x, 194, 0, 7, 2, "metalGray", "Metal", decor)
end
sign("CrewSign", 548, 7, 201, 42, "CREW OPERATIONS", "Start solo or team (2–4).\nPower > Cooling > Communications within 30 seconds.")
station("StartSolo", 516, 169, "Solo", "Start solo drill")
station("StartTeam", 529, 169, "Team", "Start team drill (2–4)")
for i, cfg in { { "Power", 516 }, { "Cooling", 541 }, { "Communications", 566 } } do
	station("Crew" .. i, cfg[2], 187, "Crew", cfg[1]):SetAttribute("Step", i)
end
Root:SetAttribute("TrainingReady", true)
-- O helper antigo fixa a porta 8765; esta fase aceita a porta do próprio worktree.
local systems = game:GetService("ServerScriptService"):FindFirstChild("Map_Systems")
if not (systems and systems:GetAttribute("RojoManaged")) then
	local sources = {}
	for _, side in { "server", "client" } do
		local suffix = side == "server" and ".server.luau" or ".client.luau"
		sources[side] = game:GetService("HttpService"):GetAsync(baseUrl .. "systems/" .. side .. "/AstronautTraining" .. suffix, true)
	end
	if not systems then
		systems = Instance.new("Folder")
		systems.Name, systems.Parent = "Map_Systems", game:GetService("ServerScriptService")
	end
	local sps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local client = sps:FindFirstChild("MapClient")
	if not client then client = Instance.new("Folder") client.Name, client.Parent = "MapClient", sps end
	for _, side in { "server", "client" } do
		local parent = side == "server" and systems or client
		local old = parent:FindFirstChild("AstronautTraining")
		if old then old:Destroy() end
		local s = Instance.new(side == "server" and "Script" or "LocalScript")
		s.Name, s.Source, s.Parent = "AstronautTraining", sources[side], parent
	end
end
return "Phase 25: Astronaut Training — gravity, systems repair, solo/team operations"
