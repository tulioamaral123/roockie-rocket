-- Cliente do acesso da tripulação (NASA Space Adventure, Fase 8)
-- 1. Escurece a tela durante o elevador e a escotilha (RemoteEvent ReplicatedStorage.CrewFade).
-- 2. Ajusta o texto do prompt dos armários: "Put on suit" ou "Take off suit".
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CrewFade"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")
local cover = Instance.new("Frame")
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = Color3.fromHex("#080D20")
cover.BackgroundTransparency = 1
cover.BorderSizePixel = 0
cover.Parent = gui
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.5)
label.Size = UDim2.fromScale(0.6, 0.08)
label.BackgroundTransparency = 1
label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
label.TextScaled = true
label.TextColor3 = Color3.fromHex("#8ECDFB")
label.TextTransparency = 1
label.Parent = cover

local IN_INFO = TweenInfo.new(0.3)
local OUT_INFO = TweenInfo.new(0.5)
game:GetService("ReplicatedStorage"):WaitForChild("CrewFade").OnClientEvent:Connect(function(mode, text)
	if mode == "out" then
		label.Text = text or ""
		TweenService:Create(cover, IN_INFO, { BackgroundTransparency = 0 }):Play()
		TweenService:Create(label, IN_INFO, { TextTransparency = 0 }):Play()
	else
		TweenService:Create(cover, OUT_INFO, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, OUT_INFO, { TextTransparency = 1 }):Play()
	end
end)

-- texto dos prompts de traje
local shown = {}
local function suitOn()
	local c = player.Character
	return c ~= nil and c:FindFirstChild("SpaceSuit") ~= nil
end
local function refresh(p)
	p.ActionText = suitOn() and "Take off suit" or "Put on suit"
end
PPS.PromptShown:Connect(function(p)
	if p:GetAttribute("CrewAction") == "Suit" then
		shown[p] = true
		refresh(p)
	end
end)
PPS.PromptHidden:Connect(function(p) shown[p] = nil end)
local function watch(char)
	local function update(c)
		if c.Name == "SpaceSuit" then
			for p in shown do refresh(p) end
		end
	end
	char.ChildAdded:Connect(update)
	char.ChildRemoved:Connect(update)
	-- garante que a tela não fique escura ao renascer
	cover.BackgroundTransparency = 1
	label.TextTransparency = 1
end
if player.Character then watch(player.Character) end
player.CharacterAdded:Connect(watch)

-- dentro da cabine do elevador só vale o painel do elevador: os armários ao lado da porta
-- usam a mesma tecla (E) e roubariam o prompt
-- as zonas são as cabines (atributos ZoneOffset/ZoneSize), lidas na posição atual de cada uma
local cabs, suitPrompts = {}, {}
local function track(d)
	if d:IsA("Model") and d:GetAttribute("ZoneOffset") then
		cabs[d] = true
	elseif d:IsA("ProximityPrompt") and d:GetAttribute("CrewAction") == "Suit" then
		suitPrompts[d] = true
	end
end
local map = workspace:WaitForChild("NASAComplex")
for _, d in map:GetDescendants() do track(d) end
map.DescendantAdded:Connect(track)
map.DescendantRemoving:Connect(function(d) suitPrompts[d] = nil; cabs[d] = nil end)
local wasInside = false
while true do
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local inside = false
	if root then
		for cab in cabs do
			local floor, s = cab.PrimaryPart, cab:GetAttribute("ZoneSize")
			if floor and s then -- com StreamingEnabled o piso pode não estar carregado
				local d = (floor.CFrame * CFrame.new(cab:GetAttribute("ZoneOffset"))):PointToObjectSpace(root.Position)
				if math.abs(d.X) <= s.X / 2 and math.abs(d.Y) <= s.Y / 2 and math.abs(d.Z) <= s.Z / 2 then
					inside = true
					break
				end
			end
		end
	end
	if inside ~= wasInside then
		wasInside = inside
		for p in suitPrompts do p.Enabled = not inside end
	end
	task.wait(0.2)
end
