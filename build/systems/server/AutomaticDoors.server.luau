-- Portas automáticas (NASA Space Adventure, Fase 6)
-- Abre qualquer Model com o atributo AutoDoor = true quando um jogador entra no raio do sensor.
-- Cada folha é um Model filho com o atributo OpenOffset (Vector3).
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local map = workspace:WaitForChild("NASAComplex")
local INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local doors = {}

local function register(model)
	if doors[model] or not model:IsA("Model") or not model:GetAttribute("AutoDoor") then return end
	local leaves = {}
	for _, leaf in model:GetChildren() do
		local offset = leaf:IsA("Model") and leaf:GetAttribute("OpenOffset")
		if offset then
			local closed = leaf:GetPivot()
			local value = Instance.new("CFrameValue")
			value.Value = closed
			value.Changed:Connect(function(cf) leaf:PivotTo(cf) end)
			table.insert(leaves, { value = value, closed = closed, open = closed + offset })
		end
	end
	doors[model] = {
		leaves = leaves,
		isOpen = false,
		center = model:GetAttribute("SensorCenter") or model:GetPivot().Position,
		radius = model:GetAttribute("SensorRadius") or 12,
	}
end

for _, d in map:GetDescendants() do register(d) end
map.DescendantAdded:Connect(function(d) task.defer(register, d) end)

while true do
	for model, door in doors do
		if not model.Parent then
			doors[model] = nil
			continue
		end
		local near = false
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - door.center).Magnitude <= door.radius then
				near = true
				break
			end
		end
		if near ~= door.isOpen then
			door.isOpen = near
			for _, leaf in door.leaves do
				TweenService:Create(leaf.value, INFO, { Value = near and leaf.open or leaf.closed }):Play()
			end
		end
	end
	task.wait(0.15)
end
