--[[
	NPCService — Marcos Pontes e Ana (spec §2, §4, §7, §8).

	- Monta os dois NPCs R15 (HumanoidDescription + cores/peças do Dialogues.Appearance), com
	  Animator (parado/andando), PathfindingService + Humanoid:MoveTo e grupo de colisão próprio
	  (não colidem com jogadores, para nunca bloquear a passagem).
	- Marcos: perto do Spawn; "Talk" → boas-vindas → acompanha o grupo até o museu → despede-se →
	  volta ao Spawn. Quem chega durante o trajeto entra no grupo (mesma fala, sem duplicar).
	- Museu: o primeiro prompt de exposição (ExhibitId) acionado libera a etapa do foguete.
	- Ana: fora de cena (ServerStorage) até alguém chegar à entrada do foguete; sirene + chamada,
	  guia o grupo pelo vestiário e pela escada até o elevador da tripulação e espera no braço de
	  acesso. Lá explica a missão obrigatória e o trade-off e abre a escolha da missão.
	- Embarque pela ponte ServerStorage.RookieBridge (GerenciadorMissao do Rookie Rocket); a
	  escolha no topo inclui traje e trade-off antes do teleporte.

	Remotes: DialogueEvent (servidor → cliente: Dialogue/Toast/Sound/Bubble; cliente → servidor:
	Done), MissionSelect (servidor → cliente: Open/Feedback; cliente → servidor: Suit/Board com manifesto).
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")
local PPS = game:GetService("ProximityPromptService")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GS = RS:WaitForChild("GuideSystem")
local Settings = require(GS:WaitForChild("Config"):WaitForChild("Settings"))
local Dialogues = require(GS.Config:WaitForChild("Dialogues"))
local World = require(script.Parent:WaitForChild("World"))
local MarcosLook = require(script.Parent:WaitForChild("MarcosLook"))

local NPCService = {}

local Progress, Remotes
local npcs = {} -- [name] = { model, humanoid, root, state, group = { [player] = true }, token }

local NPC_GROUP, PLAYER_GROUP = "GuideNPC", "GuidePlayer"

---------------------------------------------------------------------------------
-- Ponte com o Rookie Rocket
---------------------------------------------------------------------------------

local bridgeFolder, bridgeWaited = nil, false
local function bridge(name)
	if not bridgeFolder then
		if bridgeWaited then
			bridgeFolder = ServerStorage:FindFirstChild("RookieBridge")
			if not bridgeFolder then return nil end
		else
			bridgeWaited = true
			bridgeFolder = ServerStorage:WaitForChild("RookieBridge", 30)
			if not bridgeFolder then warn("[GuideSystem] ServerStorage.RookieBridge ausente: o embarque pela Ana não funciona") end
		end
	end
	return bridgeFolder and bridgeFolder:FindFirstChild(name)
end

local function invoke(name, ...)
	local fn = bridge(name)
	if not fn then return nil end
	local ok, a, b = pcall(fn.Invoke, fn, ...)
	if ok then return a, b end
	warn("[GuideSystem] RookieBridge." .. name .. ":", a)
	return nil
end

local function mercuryDone(player)
	local perfil = invoke("Perfil", player)
	return type(perfil) == "table" and type(perfil.estrelas) == "table" and (perfil.estrelas["1"] or 0) > 0
end

---------------------------------------------------------------------------------
-- Diálogos (cada jogador recebe a fala uma vez; o servidor espera "Done" ou o tempo acabar)
---------------------------------------------------------------------------------

local waiting = {} -- [token] = { [player] = true }
local nextToken = 0

local function npcModel(speaker)
	local n = npcs[speaker]
	return n and n.model
end

-- mostra o diálogo `key` aos jogadores; com wait, espera todos fecharem (ou o tempo esgotar)
local function say(players, key, opts)
	opts = opts or {}
	local lines = Dialogues.Lines[key]
	if not lines then return end
	nextToken += 1
	local token = nextToken
	local pending = {}
	for _, p in players do
		if p.Parent and not (opts.once and Progress.seen(p, key)) then
			Progress.markSeen(p, key)
			pending[p] = true
			Remotes.DialogueEvent:FireClient(p, {
				kind = opts.toast and "Toast" or "Dialogue",
				token = token,
				key = key,
				speaker = lines[1][1],
				npc = npcModel(lines[1][1]),
			})
		end
	end
	if not opts.wait or next(pending) == nil then return end
	waiting[token] = pending
	local limit = os.clock() + 8 + #lines * 8
	while next(pending) and os.clock() < limit do task.wait(0.2) end
	waiting[token] = nil
end

local function bubble(players, speaker, text)
	for _, p in players do
		if not p.Parent then continue end
		Remotes.DialogueEvent:FireClient(p, { kind = "Bubble", npc = npcModel(speaker), text = text })
	end
end

local function sound(players, id)
	for _, p in players do
		if p.Parent then Remotes.DialogueEvent:FireClient(p, { kind = "Sound", sound = id }) end
	end
end

local function listOf(set)
	local out = {}
	for p in set do if p.Parent then table.insert(out, p) end end
	return out
end

---------------------------------------------------------------------------------
-- Montagem dos NPCs
---------------------------------------------------------------------------------

local function setupCollisionGroups()
	pcall(function()
		if not PhysicsService:IsCollisionGroupRegistered(NPC_GROUP) then PhysicsService:RegisterCollisionGroup(NPC_GROUP) end
		if not PhysicsService:IsCollisionGroupRegistered(PLAYER_GROUP) then PhysicsService:RegisterCollisionGroup(PLAYER_GROUP) end
		PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, PLAYER_GROUP, false)
		PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, NPC_GROUP, false)
	end)
	local function tag(char)
		for _, p in char:GetDescendants() do
			if p:IsA("BasePart") then p.CollisionGroup = PLAYER_GROUP end
		end
		char.DescendantAdded:Connect(function(p)
			if p:IsA("BasePart") then p.CollisionGroup = PLAYER_GROUP end
		end)
	end
	local function hook(pl)
		pl.CharacterAdded:Connect(tag)
		if pl.Character then tag(pl.Character) end
	end
	Players.PlayerAdded:Connect(hook)
	for _, pl in Players:GetPlayers() do hook(pl) end
end

local function weld(part, to, cf)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = to.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = part, to
	w.Parent = part
	part.Parent = to.Parent
	return part
end

local function piece(shape, size, color, material)
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end

local function patch(part, face, text, bg, fg)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 60
	g.LightInfluence = 0.6
	g.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = bg
	t.TextColor3 = fg
	t.TextScaled = true
	t.Text = text
	t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	t.Parent = g
end

-- detalhes montados com peças (cabelo, emblemas, cinto); trocados por itens do catálogo se houver ids
local function dress(model, name, look)
	local head = model:FindFirstChild("Head")
	local upper = model:FindFirstChild("UpperTorso")
	local lower = model:FindFirstChild("LowerTorso")
	if not (head and upper and lower) then return end
	if look.Style == "Marcos" then
		MarcosLook.apply(model, look) -- visual detalhado (trailer do Rookie Rocket)
		return
	end
	if look.Accessories == "" then
		-- cabelo em blocos (a cabeça R15 padrão é um cubo arredondado): topo, nuca e laterais curtas
		local hs = head.Size
		local function slab(nm, size, cf, round)
			local p = piece(nil, size, look.Hair, Enum.Material.Fabric)
			p.Name = nm
			if round then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = p
			end
			return weld(p, head, cf)
		end
		local w, d = hs.X + 0.1, hs.Z + 0.1
		slab("Guide_Hair", Vector3.new(w, 0.32, d), CFrame.new(0, hs.Y / 2 - 0.02, 0.02))
		slab("Guide_HairBack", Vector3.new(w, hs.Y * 0.62, 0.14), CFrame.new(0, hs.Y * 0.16, d / 2 - 0.03))
		for _, sx in { -1, 1 } do
			slab("Guide_HairSide", Vector3.new(0.12, hs.Y * 0.42, d * 0.7), CFrame.new(sx * (w / 2 - 0.03), hs.Y * 0.24, d * 0.13))
		end
		if look.Female then
			slab("Guide_HairBun", Vector3.new(0.75, 0.75, 0.75), CFrame.new(0, hs.Y * 0.3, d / 2 + 0.25), true)
			slab("Guide_HairTail", Vector3.new(0.45, 1.2, 0.45), CFrame.new(0, -hs.Y * 0.15, d / 2 + 0.22), true)
		end
	end
	-- bandeira no ombro esquerdo (Marcos Pontes: primeiro astronauta brasileiro)
	local larm = model:FindFirstChild("LeftUpperArm")
	if look.Flag == "Brazil" and larm then
		local ls2 = larm.Size
		local flag = piece(nil, Vector3.new(0.62, 0.44, 0.05), Color3.fromHex("009B3A"))
		flag.Name = "Guide_Flag"
		weld(flag, larm, CFrame.new(-ls2.X / 2 - 0.03, ls2.Y * 0.18, 0) * CFrame.Angles(0, math.rad(90), 0))
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 100
		g.LightInfluence = 0.6
		g.Parent = flag
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromHex("009B3A")
		bg.BorderSizePixel = 0
		bg.Parent = g
		local diamond = Instance.new("Frame")
		diamond.AnchorPoint = Vector2.new(0.5, 0.5)
		diamond.Position = UDim2.fromScale(0.5, 0.5)
		diamond.Size = UDim2.fromScale(0.5, 0.7)
		diamond.Rotation = 45
		diamond.BackgroundColor3 = Color3.fromHex("FEDF00")
		diamond.BorderSizePixel = 0
		diamond.Parent = bg
		local globe = Instance.new("Frame")
		globe.AnchorPoint = Vector2.new(0.5, 0.5)
		globe.Position = UDim2.fromScale(0.5, 0.5)
		globe.Size = UDim2.fromScale(0.36, 0.5)
		globe.BackgroundColor3 = Color3.fromHex("002776")
		globe.BorderSizePixel = 0
		globe.Parent = bg
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = globe
	end
	local us = upper.Size
	-- emblema no peito (esquerdo) e crachá com o nome (direito)
	local badge = piece(nil, Vector3.new(0.5, 0.5, 0.05), look.Accent)
	badge.Name = "Guide_Patch"
	weld(badge, upper, CFrame.new(-us.X * 0.25, us.Y * 0.18, -us.Z / 2 - 0.02))
	patch(badge, Enum.NormalId.Front, look.Patch or "RR", look.Accent, Color3.new(1, 1, 1))
	local tagP = piece(nil, Vector3.new(0.7, 0.22, 0.05), Color3.new(1, 1, 1))
	tagP.Name = "Guide_NameTag"
	weld(tagP, upper, CFrame.new(us.X * 0.25, us.Y * 0.22, -us.Z / 2 - 0.02))
	patch(tagP, Enum.NormalId.Front, string.upper(name), Color3.new(1, 1, 1), Color3.fromHex("0E1A36"))
	-- cinto / faixa na cor de destaque
	local ls = lower.Size
	local belt = piece(nil, Vector3.new(ls.X + 0.06, 0.25, ls.Z + 0.06), look.Accent)
	belt.Name = "Guide_Belt"
	weld(belt, lower, CFrame.new(0, ls.Y * 0.3, 0))
	if look.Female then
		-- gola azul sobre o uniforme branco
		local collar = piece(nil, Vector3.new(us.X * 0.6, 0.2, us.Z + 0.06), look.Accent)
		collar.Name = "Guide_Collar"
		weld(collar, upper, CFrame.new(0, us.Y / 2 - 0.12, 0))
	end
end

local function description(look)
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = look.Skin
	d.TorsoColor = look.Suit
	d.LeftArmColor, d.RightArmColor = look.Suit, look.Suit
	d.LeftLegColor, d.RightLegColor = look.Suit, look.Suit
	if look.Shirt ~= 0 then d.Shirt = look.Shirt end
	if look.Pants ~= 0 then d.Pants = look.Pants end
	if look.Face ~= 0 then d.Face = look.Face end
	if look.Accessories ~= "" then d.HairAccessory = look.Accessories end
	if look.Female then
		d.BodyTypeScale = 0.3
		d.ProportionScale = 0.6
		d.HeightScale = 0.96
		d.WidthScale = 0.88
		d.DepthScale = 0.9
	else
		d.HeightScale = 1
		d.WidthScale = 1
	end
	return d
end

local function animate(n)
	local animator = n.humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", n.humanoid)
	local function load(id, priority, looped)
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, track = pcall(animator.LoadAnimation, animator, a)
		if not ok then return nil end
		track.Priority = priority
		track.Looped = looped
		return track
	end
	n.idle = load(Settings.Animations.Idle, Enum.AnimationPriority.Idle, true)
	n.walk = load(Settings.Animations.Walk, Enum.AnimationPriority.Movement, true)
	n.wave = load(Settings.Animations.Wave, Enum.AnimationPriority.Action, false)
	if n.idle then n.idle:Play() end
	local walking = false
	n.humanoid.Running:Connect(function(speed)
		local w = speed > 0.5
		if w == walking then
			if w and n.walk then n.walk:AdjustSpeed(math.clamp(speed / 14, 0.6, 1.4)) end
			return
		end
		walking = w
		if w then
			if n.walk then n.walk:Play(0.2) end
		elseif n.walk then
			n.walk:Stop(0.25)
		end
	end)
end

local function build(name, cf, parent)
	local look = Dialogues.Appearance[name]
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description(look), Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("[GuideSystem] não foi possível montar " .. name .. ":", model)
		return nil
	end
	model.Name = name == "Marcos" and "MarcosPontes" or name
	model.Archivable = true
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local spk = Dialogues.Speakers[name]
	hum.DisplayName = spk.Name
	hum.NameDisplayDistance = 45
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.WalkSpeed = Settings.WalkSpeed[name] or 12
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	dress(model, spk.Name, look)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then p.CollisionGroup = NPC_GROUP end
	end
	model:SetAttribute("GuideNPC", name)
	model:PivotTo(cf)
	model.Parent = parent
	pcall(function() root:SetNetworkOwner(nil) end)
	local n = { name = name, model = model, humanoid = hum, root = root, state = "Idle", group = {}, token = 0, home = cf }
	animate(n)
	return n
end

---------------------------------------------------------------------------------
-- Movimento: PathfindingService + MoveTo, com espera de quem ficou para trás
---------------------------------------------------------------------------------

local function stop(n)
	n.token += 1
	if n.root.Parent then n.humanoid:MoveTo(n.root.Position) end
end

local function face(n, pos)
	local r = n.root.Position
	if (Vector3.new(pos.X, r.Y, pos.Z) - r).Magnitude < 0.1 then return end
	n.root.CFrame = CFrame.lookAt(r, Vector3.new(pos.X, r.Y, pos.Z))
end

local function nearestFollower(n)
	local bd = math.huge
	for p in n.group do
		local r = World.rootOf(p)
		if r then bd = math.min(bd, (r.Position - n.root.Position).Magnitude) end
	end
	return bd
end

-- um passo de MoveTo com tempo-limite; teleporta se ficar preso (nunca trava a apresentação)
local function step(n, pos, token)
	local hum = n.humanoid
	hum:MoveTo(pos)
	local t0, last, lastT = os.clock(), n.root.Position, os.clock()
	while n.token == token do
		local d = n.root.Position - pos
		if Vector2.new(d.X, d.Z).Magnitude < 2.2 and math.abs(d.Y) < 4.5 then return true end
		if os.clock() - lastT > 1.5 then
			if (n.root.Position - last).Magnitude < 1 then
				hum.Jump = true
				if os.clock() - t0 > 4 then
					n.model:PivotTo(CFrame.new(pos) * n.root.CFrame.Rotation)
					return true
				end
			end
			last, lastT = n.root.Position, os.clock()
			hum:MoveTo(pos) -- MoveTo expira sozinho depois de 8 s
		end
		task.wait(0.1)
	end
	return false
end

-- anda até `goal`; com leash, para e espera quem acompanha (o grupo)
local function walkTo(n, goal, leash)
	n.token += 1
	local token = n.token
	local path = PathfindingService:CreatePath(Settings.Agent)
	local ok = pcall(function() path:ComputeAsync(n.root.Position, goal) end)
	local pts = {}
	if ok and path.Status == Enum.PathStatus.Success then
		for _, w in path:GetWaypoints() do
			table.insert(pts, { pos = w.Position + Vector3.new(0, 3, 0), jump = w.Action == Enum.PathWaypointAction.Jump })
		end
	else
		pts = { { pos = goal } }
	end
	local lastWait = 0
	local waitBudget = 45 -- s de espera pelo grupo neste trajeto; depois segue sem esperar
	for _, w in pts do
		if n.token ~= token then return false end
		-- espera o grupo (no máximo 45 s seguidos; quem saiu do jogo deixa o grupo)
		for p in n.group do
			if not p.Parent then n.group[p] = nil end
		end
		local waitStart = os.clock()
		while leash and next(n.group) and nearestFollower(n) > Settings.Radius.FollowLeash and n.token == token
			and waitBudget - (os.clock() - waitStart) > 0 do
			n.humanoid:MoveTo(n.root.Position)
			local players = listOf(n.group)
			if os.clock() - lastWait > 12 then
				lastWait = os.clock()
				if n.name == "Marcos" then
					bubble(players, "Marcos", "This way! Follow me.")
				else
					bubble(players, "Ana", "Over here! Keep up, rookie!")
				end
			end
			local r = players[1] and World.rootOf(players[1])
			if r then face(n, r.Position) end
			task.wait(0.4)
		end
		waitBudget -= os.clock() - waitStart
		if w.jump then n.humanoid.Jump = true end
		if not step(n, w.pos, token) then return false end
	end
	return n.token == token
end

local function walkRoute(n, route, leash)
	for _, p in route do
		if not walkTo(n, p, leash) then return false end
	end
	return true
end

---------------------------------------------------------------------------------
-- Marcos Pontes
---------------------------------------------------------------------------------

local function marcosEscort(run)
	local m = npcs.Marcos
	if m.run ~= run then return end
	m.state = "Escort"
	local museum = World.point("PrimeiroMuseu")
	local arrived = museum and walkTo(m, museum, true)
	if m.run ~= run then return end -- outro jogador começou um novo acompanhamento
	if arrived then
		m.state = "Arrived"
		local near = {}
		for _, p in listOf(m.group) do
			local r = World.rootOf(p)
			if r and (r.Position - museum).Magnitude <= Settings.Radius.MuseumArrival + 10 then table.insert(near, p) end
		end
		local r1 = near[1] and World.rootOf(near[1])
		if r1 then face(m, r1.Position) end
		if m.wave then m.wave:Play() end
		say(near, "MarcosFarewell", { wait = true, once = true })
		for _, p in near do
			m.group[p] = nil
			if Progress.is(p, "FollowMarcos") then Progress.set(p, "Museum") end
		end
		task.wait(2)
		if m.run ~= run then return end
	end
	-- quem ainda não chegou recebe a despedida ao chegar (ver tick)
	m.state = "Returning"
	m.group = {}
	if walkTo(m, m.home.Position, false) and m.run == run then
		face(m, (m.home * CFrame.new(0, 0, -5)).Position)
		m.state = "Idle"
	end
end

local function marcosTalk(player)
	local m = npcs.Marcos
	if not m then return end
	local stage = Progress.get(player)
	if stage ~= "MeetMarcos" then
		if stage == "FollowMarcos" then
			bubble({ player }, "Marcos", "Stay close, " .. player.DisplayName .. "! The museum is this way.")
		else
			bubble({ player }, "Marcos", "Enjoy the complex, " .. player.DisplayName .. "!")
		end
		return
	end
	if m.state == "Welcome" or m.state == "Escort" then
		-- entra no grupo que já está a caminho (mesmo diálogo, sem repetir eventos)
		m.group[player] = true
		Progress.set(player, "FollowMarcos")
		say({ player }, m.state == "Welcome" and "MarcosWelcome" or "MarcosJoin", { once = true })
		return
	end
	-- Idle, Returning ou Arrived: começa um novo acompanhamento
	stop(m)
	m.run = (m.run or 0) + 1
	local run = m.run
	m.state = "Welcome"
	m.group = { [player] = true }
	local r = World.rootOf(player)
	-- quem também está perto e ainda não falou com ele entra junto
	for _, p in Progress.players("MeetMarcos") do
		local rp = World.rootOf(p)
		if p ~= player and rp and r and (rp.Position - r.Position).Magnitude <= 14 then m.group[p] = true end
	end
	if r then face(m, r.Position) end
	if m.wave then m.wave:Play() end
	local players = listOf(m.group)
	for _, p in players do Progress.set(p, "FollowMarcos") end
	say(players, "MarcosWelcome", { wait = true, once = true })
	task.spawn(marcosEscort, run)
end

---------------------------------------------------------------------------------
-- Ana
---------------------------------------------------------------------------------

local anaParking -- ServerStorage: fora da área de visão

local function anaShow(cf)
	local a = npcs.Ana
	a.model:PivotTo(cf)
	a.model.Parent = World.guides:FindFirstChild("NPCs") or World.guides
	pcall(function() a.root:SetNetworkOwner(nil) end)
	if a.idle and not a.idle.IsPlaying then a.idle:Play() end
end

local function anaHide()
	local a = npcs.Ana
	stop(a)
	a.state = "Hidden"
	a.group = {}
	a.model.Parent = anaParking
end

local function anaToTop()
	local a = npcs.Ana
	local cf = World.topSpot()
	if not cf then return end
	stop(a)
	anaShow(cf)
	if a.idle then a.idle:Play() end
	a.state = "AtTop"
	a.topSince = os.clock()
	-- quem ainda seguia a Ana passa a ir ao elevador (ela já está no topo)
	for p in a.group do
		if p.Parent and Progress.is(p, "FollowAna") then Progress.set(p, "Elevator") end
	end
	a.group = {}
end

local function anaGuide()
	local a = npcs.Ana
	a.state = "Guiding"
	local route = World.route("Ana_Route")
	local top = World.stairsTop()
	if top then table.insert(route, top) end
	local front = World.lowerCabFront()
	if front then table.insert(route, front) end
	local ok = walkRoute(a, route, true)
	if not ok and a.state ~= "Guiding" then return end
	local players = listOf(a.group)
	local near = {}
	for _, p in players do
		local r = World.rootOf(p)
		if r and front and (r.Position - front).Magnitude <= 24 then table.insert(near, p) end
	end
	local r1 = near[1] and World.rootOf(near[1])
	if r1 then face(a, r1.Position) end
	for _, p in players do
		if Progress.is(p, "FollowAna") then Progress.set(p, "Elevator") end
	end
	say(near, "AnaElevator", { wait = true, once = true })
	if a.state ~= "Guiding" then return end -- alguém chegou ao topo antes e ela já subiu
	-- entra na cabine e "sobe pelo elevador" (aparece no braço de acesso)
	local inside = World.lowerCabInside()
	if inside then walkTo(a, inside, false) end
	if a.state ~= "Guiding" then return end
	task.wait(0.5)
	anaToTop()
end

local function anaCall(players)
	local a = npcs.Ana
	if not a then return end
	if a.state == "AtTop" then
		sound(players, "Siren")
		for _, p in players do
			Progress.set(p, "Elevator")
			say({ p }, "AnaBusy", { toast = true, once = true })
		end
		return
	end
	if a.state == "Calling" or a.state == "Guiding" then
		for _, p in players do
			a.group[p] = true
			Progress.set(p, "FollowAna")
			say({ p }, "AnaCall", { once = true })
		end
		return
	end
	-- Hidden: sirene, a Ana entra em cena pela porta do vestiário e vai até o jogador
	a.state = "Calling"
	for _, p in players do a.group[p] = true end
	sound(players, "Siren")
	local start = World.pointCF("Ana")
	if start then anaShow(start) end
	bubble(players, "Ana", "Hey, rookie! Over here!")
	local entrance = World.point("RocketEntrance")
	if entrance then walkTo(a, entrance, false) end
	if a.state ~= "Calling" then return end
	local group = listOf(a.group)
	local r1 = group[1] and World.rootOf(group[1])
	if r1 then face(a, r1.Position) end
	if a.wave then a.wave:Play() end
	for _, p in group do Progress.set(p, "FollowAna") end
	say(group, "AnaCall", { wait = true, once = true })
	task.spawn(anaGuide)
end

local function openMissionSelect(player)
	local first = not mercuryDone(player)
	Remotes.MissionSelect:FireClient(player, {
		kind = "Open",
		first = first,
		issLocked = first,
	})
end

local function anaTalk(player)
	local a = npcs.Ana
	if not a or a.state ~= "AtTop" or not World.isAtTop(player) then return end
	a.topSince = os.clock()
	local stage = Progress.get(player)
	local r = World.rootOf(player)
	if r then face(a, r.Position) end
	if stage == "TalkAna" or stage == "Elevator" or stage == "FollowAna" then
		Progress.set(player, "TalkAna")
		if a.talking and a.talking[player] then return end
		a.talking = a.talking or {}
		a.talking[player] = true
		say({ player }, mercuryDone(player) and "AnaTopReturning" or "AnaTop", { wait = true })
		a.talking[player] = nil
		if Progress.is(player, "TalkAna") then Progress.set(player, "ChooseMission") end
		openMissionSelect(player)
	elseif stage == "ChooseMission" or stage == "Free" then
		if stage == "Free" and not Progress.seen(player, "AnaTopReturning") then
			say({ player }, "AnaTopReturning", { wait = true, once = true })
		end
		openMissionSelect(player)
	end
end

---------------------------------------------------------------------------------
-- Laço: chegadas (museu, entrada do foguete, topo) e retorno da missão
---------------------------------------------------------------------------------

local tickCount = 0
local function tick()
	tickCount += 1
	local checkMission = tickCount % 3 == 0 -- consulta o Rookie Rocket a cada ~1 s
	local museum = World.point("PrimeiroMuseu")
	local entrance = World.point("RocketEntrance")
	local callers = {}
	for _, p in Players:GetPlayers() do
		local stage = Progress.get(p)
		local r = World.rootOf(p)
		if stage == "InMission" then
			if checkMission and invoke("EmMissao", p) == false then Progress.set(p, "Free") end
		elseif r then
			if checkMission and invoke("EmMissao", p) == true then
				Progress.set(p, "InMission")
			elseif stage == "FollowMarcos" and museum and (r.Position - museum).Magnitude <= Settings.Radius.MuseumArrival then
				local m = npcs.Marcos
				if not (m and m.group[p] and m.state == "Escort") then
					-- chegou depois do Marcos (ou ele já voltou): despedida pelo rádio
					if m then m.group[p] = nil end
					Progress.set(p, "Museum")
					task.spawn(say, { p }, "MarcosFarewell", { once = true })
				end
			elseif stage == "Rocket" and entrance and (r.Position - entrance).Magnitude <= Settings.Radius.RocketEntrance
				and math.abs(r.Position.Y - entrance.Y) < 8 then
				table.insert(callers, p)
			elseif (stage == "Elevator" or stage == "FollowAna") and World.isAtTop(p) then
				local a = npcs.Ana
				if a and a.state ~= "AtTop" then anaToTop() end
				Progress.set(p, "TalkAna")
			elseif (stage == "Free" or stage == "ChooseMission") and World.isAtTop(p) then
				-- voltou ao topo depois: a Ana reaparece para abrir a escolha
				local a = npcs.Ana
				if a and a.state == "Hidden" then anaToTop() end
			elseif stage == "TalkAna" then
				local a = npcs.Ana
				if a and a.state ~= "AtTop" and World.isAtTop(p) then anaToTop() end
				if a and a.state == "AtTop" and (r.Position - a.root.Position).Magnitude <= 9 and not (a.talking and a.talking[p]) then
					task.spawn(anaTalk, p)
				end
			end
		end
	end
	if #callers > 0 and not NPCService._calling then
		NPCService._calling = true
		task.spawn(function()
			local ok, err = pcall(anaCall, callers)
			NPCService._calling = false
			if not ok then warn("[GuideSystem] anaCall:", err) end
		end)
	end
	-- Ana volta para fora de cena quando ninguém mais precisa dela no topo
	local a = npcs.Ana
	if a and a.state == "AtTop" and os.clock() - (a.topSince or 0) > 60 then
		local needed = false
		for _, p in Players:GetPlayers() do
			local s = Progress.get(p)
			if s == "FollowAna" or s == "Elevator" or s == "TalkAna" or s == "ChooseMission" or (s == "Free" and World.isAtTop(p)) then
				needed = true
				a.topSince = os.clock()
				break
			end
		end
		if not needed then anaHide() end
	end
end

---------------------------------------------------------------------------------

function NPCService.model(name)
	local n = npcs[name]
	return n and n.model
end

function NPCService.isEscorting(name, player)
	local n = npcs[name]
	return n ~= nil and n.group[player] == true and (n.state == "Escort" or n.state == "Welcome")
end

local function prompt(n, key, onTrigger)
	local cfg = Dialogues.Prompts[key]
	local p = Instance.new("ProximityPrompt")
	p.Name = "GuidePrompt"
	p.ActionText = cfg.Action
	p.ObjectText = cfg.Object
	p.MaxActivationDistance = Settings.Radius.Talk
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.Parent = n.root
	p.Triggered:Connect(function(player)
		if not World.rootOf(player) then return end
		onTrigger(player)
	end)
	return p
end

function NPCService.start(progress, remotes)
	Progress, Remotes = progress, remotes
	setupCollisionGroups()
	local npcFolder = World.guides and World.guides:FindFirstChild("NPCs")
	if not npcFolder then
		warn("[GuideSystem] NASAComplex.Guides.NPCs não existe: rode a Fase 22")
		return
	end
	for _, old in npcFolder:GetChildren() do
		if old:GetAttribute("GuideNPC") then old:Destroy() end
	end
	anaParking = ServerStorage:FindFirstChild("GuideParking") or Instance.new("Folder")
	anaParking.Name = "GuideParking"
	anaParking.Parent = ServerStorage

	local mcf = World.pointCF("Spawn_Marcos")
	if mcf then
		npcs.Marcos = build("Marcos", mcf, npcFolder)
		if npcs.Marcos then
			prompt(npcs.Marcos, "TalkMarcos", function(player) task.spawn(marcosTalk, player) end)
		end
	end
	local acf = World.pointCF("Ana")
	if acf then
		npcs.Ana = build("Ana", acf, anaParking)
		if npcs.Ana then
			npcs.Ana.state = "Hidden"
			local pr = prompt(npcs.Ana, "TalkAna", function(player)
				local s = Progress.get(player)
				if s == "FollowAna" or s == "Rocket" then
					bubble({ player }, "Ana", "Follow me, " .. player.DisplayName .. "! We're going up.")
				else
					task.spawn(anaTalk, player)
				end
			end)
			npcs.Ana.prompt = pr
		end
	end

	remotes.DialogueEvent.OnServerEvent:Connect(function(player, msg)
		if type(msg) == "table" and msg.kind == "Done" and type(msg.token) == "number" then
			local w = waiting[msg.token]
			if w then w[player] = nil end
		end
	end)

	-- escolha da missão: validada no servidor (etapa, posição, bloqueio da primeira missão)
	local lastChoice = {}
	Players.PlayerRemoving:Connect(function(p) lastChoice[p] = nil end)
	remotes.MissionSelect.OnServerEvent:Connect(function(player, choice)
		if os.clock() - (lastChoice[player] or 0) < 0.25 then return end
		lastChoice[player] = os.clock()
		if choice == "Cancel" then return end
		if type(choice) ~= "table" then return end
		local stage = Progress.get(player)
		if stage == "InMission" and invoke("EmMissao", player) == false then
			Progress.set(player, "Free")
			stage = "Free"
		end
		local a = npcs.Ana
		local r = World.rootOf(player)
		if not r then return end
		local top = (stage == "ChooseMission" or stage == "Free") and a and World.isAtTop(player)
			and (r.Position - a.root.Position).Magnitude <= 25
		if not top then return end
		local function reply(text)
			Remotes.MissionSelect:FireClient(player, { kind = "Feedback", text = text })
		end
		if choice.action == "Suit" then
			local suit = ServerStorage:FindFirstChild("CrewSuit")
			local ok = suit and suit:Invoke(player, true)
			reply(ok and "Space suit ready. Choose equipment, then board." or "Space suit unavailable. Try again.")
			return
		end
		if choice.action ~= "Board" or (choice.id ~= 1 and choice.id ~= 2) then return end
		if choice.id == 2 and not mercuryDone(player) then reply(Dialogues.MissionSelect.Locked) return end
		local ok, reason = invoke("Embarcar", player, choice.id, choice.items)
		if ok then Progress.set(player, "InMission") else reply(reason or "Boarding unavailable. Try again.") end
	end)

	-- museu: a primeira exposição selecionada libera o caminho até o foguete
	PPS.PromptTriggered:Connect(function(p, player)
		local part = p.Parent
		local r = World.rootOf(player)
		local near = r and part and part:IsA("BasePart") and (r.Position - part.Position).Magnitude <= p.MaxActivationDistance + 8
		if p:GetAttribute("ExhibitId") and near and Progress.is(player, "Museum") then
			Progress.set(player, "Rocket")
			task.delay(1, function()
				say({ player }, "MuseumDone", { toast = true, once = true })
			end)
		end
	end)

	task.spawn(bridge, "Perfil") -- espera a ponte do Rookie Rocket fora do laço
	-- a Ana só mostra o prompt no topo
	task.spawn(function()
		while true do
			if npcs.Ana and npcs.Ana.prompt then npcs.Ana.prompt.Enabled = npcs.Ana.state == "AtTop" or npcs.Ana.state == "Guiding" end
			local ok, err = pcall(tick)
			if not ok then warn("[GuideSystem] tick:", err) end
			task.wait(0.3)
		end
	end)
end

return NPCService
