--[[
	PanelInteractionController — botões físicos do console por raio a partir da câmera.
	- Mouse (primeira pessoa: centro da tela), toque (posição do toque) ou gatilho R2 do controle.
	- Alvos: Models com o atributo MissionButton (o raio aceita as peças Base e Cap) e a tela do
	  terminal (MissionButton = "CodeInput").
	- Destaque (Highlight) no botão sob a mira; animação de afundar local (só este cliente vê).
	- onPress(action, input) / onRelease(action, input) ficam com o MissionController.
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local P = {}
local enabled = false
local buttons = {} -- [action] = { model, cap, home }
local partAction = {} -- [BasePart] = action
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local onPress, onRelease
local held = {} -- [InputObject] = action
local down = {} -- [action] = true quando o botão fica afundado
local highlight
local conns = {}
local MAX_DIST = 16
local PRESS = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEPTH = 0.09

function P.init(root, extraTargets, pressFn, releaseFn)
	onPress, onRelease = pressFn, releaseFn
	local list = {}
	for _, m in root:GetDescendants() do
		local action = m:GetAttribute("MissionButton")
		if action and m:IsA("Model") then
			local cap = m:FindFirstChild("Cap")
			buttons[action] = { model = m, cap = cap, home = cap and cap.CFrame, color = cap and cap.Color }
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Name ~= "Label" then
					partAction[d] = action
					table.insert(list, d)
				end
			end
		end
	end
	for part, action in extraTargets do
		partAction[part] = action
		table.insert(list, part)
	end
	params.FilterDescendantsInstances = list
end

local function rayFrom(input)
	local cam = workspace.CurrentCamera
	local ray
	if input and input.UserInputType == Enum.UserInputType.Touch then
		ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
	elseif UIS.MouseBehavior == Enum.MouseBehavior.LockCenter or (input and input.KeyCode == Enum.KeyCode.ButtonR2) then
		local v = cam.ViewportSize
		ray = cam:ViewportPointToRay(v.X / 2, v.Y / 2)
	else
		local m = UIS:GetMouseLocation()
		ray = cam:ViewportPointToRay(m.X, m.Y)
	end
	local hit = workspace:Raycast(ray.Origin, ray.Direction * MAX_DIST, params)
	return hit and partAction[hit.Instance], hit
end

function P.animate(action)
	local b = buttons[action]
	if not b or not b.cap then return end
	local low = b.home - Vector3.new(0, DEPTH, 0)
	local tw = TweenService:Create(b.cap, PRESS, { CFrame = low })
	tw.Completed:Connect(function()
		if not down[action] then TweenService:Create(b.cap, PRESS, { CFrame = b.home }):Play() end
	end)
	tw:Play()
end

-- botão fica afundado (true) ou volta (false)
function P.setDown(action, isDown)
	local b = buttons[action]
	down[action] = isDown or nil
	if b and b.cap then
		b.cap.CFrame = isDown and b.home - Vector3.new(0, DEPTH, 0) or b.home
	end
end

-- botão aceso (Neon, cor opcional) ou apagado (cor original)
function P.setLit(action, lit, color)
	local b = buttons[action]
	if not b or not b.cap then return end
	b.cap.Material = lit and Enum.Material.Neon or Enum.Material.SmoothPlastic
	b.cap.Color = (lit and color) or b.color
end

function P.enable()
	if enabled then return end
	enabled = true
	highlight = Instance.new("Highlight")
	highlight.Name = "F7ButtonHover"
	highlight.FillTransparency = 0.75
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineColor = Color3.fromRGB(255, 230, 140)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = workspace.CurrentCamera
	table.insert(conns, UIS.InputBegan:Connect(function(input, processed)
		local t = input.UserInputType
		local isPointer = t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonR2
		if not isPointer or processed then return end
		local action = rayFrom(input)
		if action then
			held[input] = action
			if buttons[action] then P.animate(action) end
			onPress(action, input)
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		local action = held[input]
		if action then
			held[input] = nil
			onRelease(action, input)
		end
	end))
	-- destaque do botão sob a mira (mouse/controle; no toque não há mira)
	table.insert(conns, RunService.RenderStepped:Connect(function()
		if UIS.TouchEnabled and not UIS.MouseEnabled then
			highlight.Enabled = false
			return
		end
		local action = rayFrom(nil)
		local b = action and buttons[action]
		if b then
			highlight.Adornee = b.model
			highlight.Enabled = true
		else
			highlight.Enabled = false
		end
	end))
end

function P.disable()
	enabled = false
	for _, c in conns do c:Disconnect() end
	table.clear(conns)
	for input, action in held do onRelease(action, input) end
	table.clear(held)
	if highlight then highlight:Destroy() end
	highlight = nil
	for action in buttons do
		P.setDown(action, false)
		P.setLit(action, false)
	end
end

-- qualquer botão ainda pressionado com esta ação?
function P.isHeld(action)
	for _, a in held do
		if a == action then return true end
	end
	return false
end

return P
