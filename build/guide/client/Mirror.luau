--[[
	Mirror — espelho do Crew Suit-Up Room (Fase 22: VABHangar.CrewSuitUpRoom.Mirror.Mirror_Glass).

	O Roblox não tem reflexo de personagens; o espelho é um ViewportFrame num SurfaceGui do vidro:
	- uma cópia estática da sala (feita uma vez) e uma cópia do personagem do jogador, com as
	  peças acompanhando o personagem real a cada quadro;
	- a câmera do ViewportFrame fica no reflexo da câmera do jogador (atrás do vidro), olhando para
	  o centro do espelho, com o campo de visão do tamanho do vidro.
	Só funciona com o jogador a até 18 studs do espelho (custo zero no resto do mapa).

	Celular/tablet: dentro do vestiário a câmera vai para primeira pessoa (para olhar o espelho e
	vestir o traje); ao sair, volta ao modo anterior, a menos que a opção "First person camera"
	do Settings esteja ligada.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Mirror = {}

local player = Players.LocalPlayer
local RANGE = 18
-- interior do vestiário (Fase 8): X −60..−36,5, Z 244..258
local ROOM_MIN, ROOM_MAX = Vector3.new(-60, -2, 244), Vector3.new(-36.5, 12, 258)

local function isTouch()
	local ok, pref = pcall(function() return UIS.PreferredInput end)
	if ok and pref ~= nil then return pref == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

local glass, gui, vp, world, cam = nil, nil, nil, nil, nil
local charCopy, map = nil, {} -- [peça original] = peça da cópia
local copiedFor, copiedSuit = nil, nil
local roomCopied = false

local function findGlass()
	local m = workspace:FindFirstChild("NASAComplex")
	local h = m and m:FindFirstChild("VABHangar")
	local room = h and h:FindFirstChild("CrewSuitUpRoom")
	local mirror = room and room:FindFirstChild("Mirror")
	return mirror and mirror:FindFirstChild("Mirror_Glass"), room
end

local function setup()
	local room
	glass, room = findGlass()
	if not glass then return false end
	gui = Instance.new("SurfaceGui")
	gui.Name = "MirrorView"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Adornee = glass
	gui.Parent = player:WaitForChild("PlayerGui")
	vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundColor3 = Color3.fromHex("DDE3E8")
	vp.Ambient = Color3.fromRGB(190, 190, 195)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(0.3, -1, 0.5)
	vp.Parent = gui
	world = Instance.new("WorldModel")
	world.Parent = vp
	cam = Instance.new("Camera")
	cam.Parent = vp
	vp.CurrentCamera = cam
	-- cópia estática da sala (sem o próprio espelho), feita uma vez
	if room and not roomCopied then
		roomCopied = true
		for _, d in room:GetDescendants() do
			-- fora o próprio espelho e o que está no plano dele ou atrás (a parede do fundo taparia a câmera)
			local frente = (d:IsA("BasePart") and (d.Position - glass.Position):Dot(glass.CFrame.LookVector)) or 0
			if d:IsA("BasePart") and not d:IsDescendantOf(glass.Parent) and d.Transparency < 1 and frente > 0.3 then
				local ok, c = pcall(function() return d:Clone() end)
				if ok and c then
					for _, k in c:GetChildren() do
						if not (k:IsA("SurfaceGui") or k:IsA("Decal") or k:IsA("SpecialMesh")) then k:Destroy() end
					end
					c.Anchored = true
					c.Parent = world
				end
			end
		end
	end
	return true
end

local function copyCharacter(char)
	if charCopy then charCopy:Destroy() end
	charCopy, map = nil, {}
	char.Archivable = true
	local ok, c = pcall(function() return char:Clone() end)
	if not ok or not c then return end
	for _, d in c:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then d:Destroy() end
	end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	-- liga peça original → cópia pelo caminho relativo
	for _, p in char:GetDescendants() do
		if p:IsA("BasePart") then
			local rel = {}
			local x = p
			while x and x ~= char do
				table.insert(rel, 1, x.Name)
				x = x.Parent
			end
			local q = c
			for _, n in rel do q = q and q:FindFirstChild(n) end
			if q and q:IsA("BasePart") then
				q.Anchored = true
				map[p] = q
			end
		end
	end
	c.Parent = world
	charCopy = c
	copiedFor = char
	copiedSuit = char:FindFirstChild("SpaceSuit") ~= nil
end

local function inRoom(pos)
	return pos.X > ROOM_MIN.X and pos.X < ROOM_MAX.X and pos.Z > ROOM_MIN.Z and pos.Z < ROOM_MAX.Z
		and pos.Y > ROOM_MIN.Y and pos.Y < ROOM_MAX.Y
end

local touchFP = false -- primeira pessoa ligada por este módulo (celular dentro do vestiário)
local prevMode = nil
local lastRecopy = 0

function Mirror.start()
	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local pos = root.Position

		-- celular: primeira pessoa dentro do vestiário
		if isTouch() then
			local dentro = inRoom(pos)
			if dentro and not touchFP and player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
				touchFP = true
				prevMode = player.CameraMode
				player.CameraMode = Enum.CameraMode.LockFirstPerson
			elseif not dentro and touchFP then
				touchFP = false
				player.CameraMode = prevMode or Enum.CameraMode.Classic
				if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
					local min = player.CameraMinZoomDistance
					player.CameraMinZoomDistance = 10
					task.delay(0.2, function() player.CameraMinZoomDistance = min end)
				end
			end
		end

		-- espelho: só perto dele
		if not glass then
			glass = findGlass()
			if not glass then return end
		end
		if (pos - glass.Position).Magnitude > RANGE then
			if gui then gui.Enabled = false end
			return
		end
		if not gui and not setup() then return end
		gui.Enabled = true
		-- cópia do personagem: refaz quando troca de personagem ou de roupa (traje), a cada 1,5 s no máximo
		local hasSuit = char:FindFirstChild("SpaceSuit") ~= nil
		if copiedFor ~= char or (hasSuit ~= copiedSuit and os.clock() - lastRecopy > 1.5) then
			lastRecopy = os.clock()
			copyCharacter(char)
		end
		for p, q in map do
			if p.Parent then
				q.CFrame = p.CFrame
				q.Transparency = p.Transparency
			end
		end
		-- câmera no reflexo da câmera do jogador (o vidro olha para a sala: Front = LookVector)
		local n = glass.CFrame.LookVector
		local center = glass.Position + n * (glass.Size.Z / 2)
		local eye = workspace.CurrentCamera.CFrame.Position
		local behind = eye - 2 * (eye - center):Dot(n) * n
		local d = math.max(1, (center - behind).Magnitude)
		cam.CFrame = CFrame.lookAt(behind, center)
		cam.FieldOfView = math.clamp(math.deg(2 * math.atan((glass.Size.Y / 2) / d)), 10, 100)
	end)
end

return Mirror
