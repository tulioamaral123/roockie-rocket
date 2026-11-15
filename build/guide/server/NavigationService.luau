--[[
	NavigationService — destino atual de cada jogador e caminho até ele (spec §6).

	O servidor calcula o caminho com PathfindingService (as paredes nunca ficam no meio) e manda
	ao cliente pelo RemoteEvent NavigationUpdate:
	  { stage, objective, points = { Vector3 ... }, target = Vector3?, beacon = boolean }
	O cliente só desenha a seta. Cada jogador tem a própria rota; nada é compartilhado.

	Rotas por etapa (pontos da Fase 22 + pontos relativos ao lançador, ver World):
	  MeetMarcos    → Marcos
	  FollowMarcos  → Marcos (visita guiada) ou Museum1End (fim do museu 1)
	  Museum        → exposição mais próxima
	  Rocket        → AnaMeet (diante da sala de comando do LCC)
	  FollowAna     → Ana
	  Elevator      → (pé da escada → topo da escada →) cabine do elevador
	  TalkAna, ChooseMission → Ana no braço de acesso (ou o elevador, se o jogador não está no topo)
	  InMission, Free → sem seta
]]

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local GS = RS:WaitForChild("GuideSystem")
local Settings = require(GS:WaitForChild("Config"):WaitForChild("Settings"))
local Dialogues = require(GS.Config:WaitForChild("Dialogues"))
local World = require(script.Parent:WaitForChild("World"))

local NavigationService = {}

local Progress, Remotes, NPC
local cache = {} -- [player] = { from, to, stage, points, time }

local ROCKET_VIAS = { "AnaMeet" } -- a Ana encontra o jogador diante da sala de comando do LCC

local function npcPos(name)
	local m = NPC and NPC.model(name)
	local root = m and m:IsDescendantOf(workspace) and m:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

-- caminho do chão até o elevador (vale para quem não está no topo)
local function elevatorRoute(rootPos)
	local cabFront, cab = World.lowerCabFront(), World.lowerCabInside()
	if not cab then return nil end
	-- já no deck do lançador: direto à cabine
	local top = World.stairsTop()
	if top and rootPos.Y > top.Y - 4 then return { cabFront, cab } end
	local vias = {}
	for _, p in World.route("Ana_Route") do table.insert(vias, p) end
	-- só os pontos da rota a partir do mais próximo do jogador
	local best, bd = 1, math.huge
	for i, p in vias do
		local d = (p - rootPos).Magnitude
		if d < bd then best, bd = i, d end
	end
	local out = {}
	for i = best, #vias do table.insert(out, vias[i]) end
	if top then table.insert(out, top) end
	table.insert(out, cabFront)
	table.insert(out, cab)
	return out
end

-- destino final (Vector3) + lista de pontos intermediários; nil = sem seta
local function destination(player, rootPos)
	local stage = Progress.get(player)
	if stage == "MeetMarcos" then
		local p = npcPos("Marcos")
		return p and { p }, true
	elseif stage == "FollowMarcos" then
		local p = NPC.isEscorting("Marcos", player) and npcPos("Marcos") or World.point("Museum1End")
		return p and { p }, true
	elseif stage == "Museum" then
		local p = World.nearestExhibit(rootPos)
		return p and { p }, true
	elseif stage == "Rocket" then
		local i = Progress.via(player)
		-- avança os pontos já atingidos (ou pulados: o jogador está mais perto de um ponto adiante)
		for j = #ROCKET_VIAS, i, -1 do
			local p = World.point(ROCKET_VIAS[j])
			if p and (p - rootPos).Magnitude <= Settings.Radius.Via then
				i = math.min(j + 1, #ROCKET_VIAS)
				break
			end
		end
		Progress.setVia(player, i)
		local out = {}
		for j = i, #ROCKET_VIAS do
			local p = World.point(ROCKET_VIAS[j])
			if p then table.insert(out, p) end
		end
		return #out > 0 and out or nil, true
	elseif stage == "FollowAna" then
		local p = npcPos("Ana")
		return p and { p }, true
	elseif stage == "Elevator" then
		return elevatorRoute(rootPos), true
	elseif stage == "TalkAna" or stage == "ChooseMission" then
		if World.isAtTop(player) then
			local p = npcPos("Ana")
			if p and (p - rootPos).Magnitude < 7 then return nil end
			return p and { p }, true
		end
		return elevatorRoute(rootPos), true
	end
	return nil
end

local function computePath(from: Vector3, to: Vector3)
	local path = PathfindingService:CreatePath(Settings.Agent)
	local ok = pcall(function() path:ComputeAsync(from, to) end)
	if ok and path.Status == Enum.PathStatus.Success then
		local out = {}
		for _, w in path:GetWaypoints() do table.insert(out, w.Position) end
		return out
	end
	return nil
end

-- caminho por todos os pontos intermediários (só o primeiro trecho é calculado com pathfinding;
-- os seguintes são recalculados quando o jogador chega neles)
local function build(rootPos, vias)
	local first = computePath(rootPos, vias[1])
	local pts = first or { rootPos, vias[1] }
	for i = 2, #vias do table.insert(pts, vias[i]) end
	return pts, first ~= nil
end

local function send(player, stage, data)
	Remotes.NavigationUpdate:FireClient(player, data)
	local c = cache[player]
	if c then c.sentStage = stage end
end

local function update(player, force)
	local root = World.rootOf(player)
	local stage = Progress.get(player)
	local c = cache[player] or {}
	cache[player] = c
	if not root then return end
	local vias, beacon = destination(player, root.Position)
	if not vias then
		if c.sentStage ~= stage or c.points then
			c.points = nil
			send(player, stage, { stage = stage, objective = Dialogues.Objectives[stage] })
		end
		return
	end
	local target = vias[#vias]
	local first = vias[1]
	local now = os.clock()
	local moved = c.from and (root.Position - c.from).Magnitude or math.huge
	local targetMoved = c.first and (first - c.first).Magnitude or math.huge
	if not force and c.sentStage == stage and c.points
		and targetMoved < 6 and (moved < Settings.Repath.MoveThreshold or now - c.time < Settings.Repath.Interval) then
		return
	end
	if c.busy then return end
	c.busy = true
	local pts, ok = build(root.Position, vias)
	c.busy = false
	if Progress.get(player) ~= stage then return end -- mudou de etapa durante o cálculo
	c.from, c.first, c.points, c.time = root.Position, first, pts, now
	send(player, stage, {
		stage = stage,
		objective = Dialogues.Objectives[stage],
		points = pts,
		target = target,
		beacon = beacon == true,
		exact = ok,
	})
end

function NavigationService.refresh(player)
	task.spawn(update, player, true)
end

-- portas automáticas: o pathfinding pode atravessar as folhas (elas abrem quando o jogador chega)
local function passThroughDoors(root)
	for _, d in root:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("AutoDoor") then
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") and not p:FindFirstChild("GuidePassThrough") then
					local m = Instance.new("PathfindingModifier")
					m.Name = "GuidePassThrough"
					m.PassThrough = true
					m.Parent = p
				end
			end
		end
	end
end

function NavigationService.start(progress, remotes, npc)
	Progress, Remotes, NPC = progress, remotes, npc
	passThroughDoors(workspace:WaitForChild("NASAComplex"))
	Progress.onChanged(function(player) update(player, true) end)
	Players.PlayerRemoving:Connect(function(p) cache[p] = nil end)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(1)
			update(p, true)
		end)
	end)
	-- o cliente pede um caminho novo quando sai muito da rota
	remotes.NavigationUpdate.OnServerEvent:Connect(function(player, msg)
		if msg == "Repath" then
			local c = cache[player]
			if not c or os.clock() - (c.repathAt or 0) < 2 then return end
			c.repathAt = os.clock()
			task.spawn(update, player, true)
		end
	end)
	task.spawn(function()
		while true do
			for _, p in Players:GetPlayers() do task.spawn(update, p, false) end
			task.wait(0.5)
		end
	end)
end

return NavigationService
