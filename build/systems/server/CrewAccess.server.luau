-- Acesso da tripulação (NASA Space Adventure, Fase 8)
-- Trata os ProximityPrompts do Map com o atributo CrewAction:
--   "Suit"     → veste/tira o traje (Shirt/Pants do ForgeGUI + capacete soldado à cabeça)
--   "Elevator" → leva quem está na zona da própria cabine até a outra cabine (mesma posição relativa).
--                A zona é o atributo ZoneOffset/ZoneSize da cabine, relativo ao piso (PrimaryPart).
--   "Teleport" → leva quem acionou até a peça apontada pelo ObjectValue TargetRef do prompt
--                (escotilhas da Orion). Tudo é relativo: funciona com o lançador em qualquer posição.
--   "Sit"      → senta quem acionou no Seat que contém o prompt (cabine da Orion)
-- Elevador e escotilha escurecem a tela do jogador pelo RemoteEvent ReplicatedStorage.CrewFade.
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local map = workspace:WaitForChild("NASAComplex")

-- Traje espacial branco da NASA (camisa e calça clássicas criadas no ForgeGUI)
local SUIT_SHIRT = "rbxassetid://106949180814943"
local SUIT_PANTS = "rbxassetid://82940626824190"

local function weldTo(p, target, parent)
	p.Anchored = false
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = parent
	local w = Instance.new("WeldConstraint")
	w.Part0 = p
	w.Part1 = target
	w.Parent = p
end

local function newPart(shape, size, cf, color, material)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- A roupa original vai para a pasta Stored dentro do traje (fora do personagem ela não aparece)
local CLOTHES = { Shirt = true, Pants = true, ShirtGraphic = true }

local function putOnSuit(char)
	local suit = Instance.new("Model")
	suit.Name = "SpaceSuit"
	local stored = Instance.new("Folder")
	stored.Name = "Stored"
	stored.Parent = suit
	for _, c in char:GetChildren() do
		if CLOTHES[c.ClassName] then c.Parent = stored end
	end
	suit.Parent = char
	local shirt = Instance.new("Shirt")
	shirt.Name = "SpaceSuit_Shirt"
	shirt.ShirtTemplate = SUIT_SHIRT
	shirt.Parent = char
	local pants = Instance.new("Pants")
	pants.Name = "SpaceSuit_Pants"
	pants.PantsTemplate = SUIT_PANTS
	pants.Parent = char
	local head = char:FindFirstChild("Head")
	if head then
		local d = math.max(head.Size.Y, head.Size.Z) * 1.9
		local bubble = newPart(Enum.PartType.Ball, Vector3.one * d, head.CFrame * CFrame.new(0, 0.1, 0), Color3.new(1, 1, 1), Enum.Material.Glass)
		bubble.Name = "Helmet"
		bubble.Transparency = 0.72
		weldTo(bubble, head, suit)
		local ring = newPart(Enum.PartType.Cylinder, Vector3.new(0.3, d * 0.8, d * 0.8),
			head.CFrame * CFrame.new(0, -head.Size.Y * 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromHex("#EDEDED"), Enum.Material.SmoothPlastic)
		ring.Name = "Neck_Ring"
		weldTo(ring, head, suit)
	end
	-- esconde acessórios (cabelo, chapéus, roupas 3D) que atravessariam o capacete ou cobririam o traje
	for _, a in char:GetChildren() do
		if a:IsA("Accessory") then
			for _, h in a:GetDescendants() do
				if h:IsA("BasePart") then
					h:SetAttribute("SuitHidden", h.Transparency)
					h.Transparency = 1
				end
			end
		end
	end
end

local function takeOffSuit(char, suit)
	for _, n in { "SpaceSuit_Shirt", "SpaceSuit_Pants" } do
		local c = char:FindFirstChild(n)
		if c then c:Destroy() end
	end
	local stored = suit:FindFirstChild("Stored")
	if stored then
		for _, c in stored:GetChildren() do c.Parent = char end
	end
	suit:Destroy()
	for _, a in char:GetChildren() do
		if a:IsA("Accessory") then
			for _, h in a:GetDescendants() do
				if h:IsA("BasePart") and h:GetAttribute("SuitHidden") then
					h.Transparency = h:GetAttribute("SuitHidden")
					h:SetAttribute("SuitHidden", nil)
				end
			end
		end
	end
end

local TweenService = game:GetService("TweenService")
local fade = game:GetService("ReplicatedStorage"):WaitForChild("CrewFade")
local DOOR_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local FADE_TIME = 0.35

local function unseat(hum)
	if hum and hum.SeatPart then
		local w = hum.SeatPart:FindFirstChild("SeatWeld")
		if w then w:Destroy() end
		hum.Sit = false
		task.wait(0.25)
	end
end

local function move(player, char, cf)
	pcall(player.RequestStreamAroundAsync, player, cf.Position, 3)
	char:PivotTo(cf)
end

-- portas do elevador: cada folha (Door_L/Door_R) tem OpenOffset; peças com FollowDoor acompanham.
-- As posições ficam guardadas relativas ao piso da cabine, para seguir o lançador quando ele se move.
local doorSets = {}
local function doorsOf(cab)
	if doorSets[cab] then return doorSets[cab] end
	local set = {}
	local ref = cab.PrimaryPart.CFrame
	for _, leaf in cab:GetChildren() do
		local off = leaf:IsA("BasePart") and leaf:GetAttribute("OpenOffset")
		if off then
			local parts = { leaf }
			for _, p in cab:GetChildren() do
				if p:GetAttribute("FollowDoor") == leaf.Name then table.insert(parts, p) end
			end
			for _, p in parts do
				local closed = ref:ToObjectSpace(p.CFrame)
				table.insert(set, { part = p, closed = closed, open = CFrame.new(off) * closed })
			end
		end
	end
	doorSets[cab] = set
	return set
end
local function setDoors(cab, open)
	local ref = cab.PrimaryPart.CFrame
	for _, d in doorsOf(cab) do
		TweenService:Create(d.part, DOOR_INFO, { CFrame = ref * (open and d.open or d.closed) }):Play()
	end
end
local function zoneCF(cab)
	return cab.PrimaryPart.CFrame * CFrame.new(cab:GetAttribute("ZoneOffset"))
end
local function cabsOf(prompt)
	local cab = prompt.Parent and prompt.Parent.Parent
	local list = {}
	if cab and cab.Parent then
		for _, c in cab.Parent:GetChildren() do
			if c:IsA("Model") and c.Name:match("^Cab_") then table.insert(list, c) end
		end
	end
	return list
end
-- abre todas as portas de elevador ao iniciar
for _, d in map:GetDescendants() do
	if d:IsA("ProximityPrompt") and d:GetAttribute("CrewAction") == "Elevator" then
		for _, cab in cabsOf(d) do setDoors(cab, true) end
	end
end

local busy = {}
local function ride(prompt)
	local key = prompt.Parent.Parent.Parent
	if busy[key] then return end
	busy[key] = true
	local cabs = cabsOf(prompt)
	for _, cab in cabs do
		local lamp = cab:FindFirstChild("Status_Lamp")
		if lamp then lamp.Color = Color3.fromHex("#E5B52E") end
		local p = cab:FindFirstChild("Call_Panel") and cab.Call_Panel:FindFirstChildOfClass("ProximityPrompt")
		if p then p.Enabled = false end
		setDoors(cab, false)
	end
	task.wait(DOOR_INFO.Time)
	local own = prompt.Parent.Parent
	local other
	for _, cab in cabs do if cab ~= own then other = cab end end
	local s = own:GetAttribute("ZoneSize")
	local riders = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and other then
			local d = zoneCF(own):PointToObjectSpace(root.Position)
			if math.abs(d.X) <= s.X / 2 and math.abs(d.Y) <= s.Y / 2 and math.abs(d.Z) <= s.Z / 2 then
				table.insert(riders, player)
				fade:FireClient(player, "out", prompt:GetAttribute("FadeText"))
			end
		end
	end
	task.wait(FADE_TIME + 0.9)
	for _, player in riders do
		local char = player.Character
		if char then
			unseat(char:FindFirstChildOfClass("Humanoid"))
			-- posição atual das duas cabines, lida agora (o lançador pode ter se movido)
			move(player, char, zoneCF(other) * zoneCF(own):ToObjectSpace(char:GetPivot()))
		end
	end
	task.wait(0.2)
	for _, player in riders do fade:FireClient(player, "in") end
	for _, cab in cabs do
		setDoors(cab, true)
		local lamp = cab:FindFirstChild("Status_Lamp")
		if lamp then lamp.Color = Color3.fromHex("#3CCB5A") end
		local p = cab:FindFirstChild("Call_Panel") and cab.Call_Panel:FindFirstChildOfClass("ProximityPrompt")
		if p then p.Enabled = true end
	end
	task.wait(DOOR_INFO.Time)
	busy[key] = nil
end

-- assentos: o prompt some quando o assento está ocupado
for _, d in map:GetDescendants() do
	if d:IsA("ProximityPrompt") and d:GetAttribute("CrewAction") == "Sit" and d.Parent:IsA("Seat") then
		local seat, pr = d.Parent, d
		seat:GetPropertyChangedSignal("Occupant"):Connect(function() pr.Enabled = seat.Occupant == nil end)
	end
end

local teleporting = {}
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(map) then return end
	local action = prompt:GetAttribute("CrewAction")
	local char = player.Character
	if not action or not char or not char:FindFirstChild("HumanoidRootPart") then return end
	-- durante a missão Friendship 7 (Fase 15) o jogador fica na cápsula: nenhum prompt da tripulação vale
	if player:GetAttribute("MissionActive") then return end
	if action == "Suit" then
		local suit = char:FindFirstChild("SpaceSuit")
		if suit then takeOffSuit(char, suit) else putOnSuit(char) end
		player:SetAttribute("SuitOn", char:FindFirstChild("SpaceSuit") ~= nil)
	elseif action == "Sit" then
		local seat, hum = prompt.Parent, char:FindFirstChildOfClass("Humanoid")
		if seat:IsA("Seat") and hum and not seat.Occupant then
			unseat(hum)
			seat:Sit(hum)
		end
	elseif action == "Elevator" then
		task.spawn(ride, prompt)
	elseif action == "Teleport" then
		local ref = prompt:FindFirstChild("TargetRef")
		local point = ref and ref:IsA("ObjectValue") and ref.Value
		if point and point:IsA("BasePart") and not teleporting[player] then
			teleporting[player] = true
			fade:FireClient(player, "out", prompt:GetAttribute("FadeText"))
			task.wait(FADE_TIME + 0.4)
			if player.Parent and char.Parent then
				unseat(char:FindFirstChildOfClass("Humanoid"))
				move(player, char, point.CFrame) -- posição atual da referência
			end
			task.wait(0.2)
			fade:FireClient(player, "in")
			teleporting[player] = nil
		end
	end
end)
