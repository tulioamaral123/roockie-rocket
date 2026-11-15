--[[
	ComponentsController — hotspots, vista de estágios, portas e câmera de exame (museuspec §5.3).

	- enter(model, data, onSelect): câmera Scriptable orbitando o modelo (arrastar gira,
	  roda/pinça aproxima) e marcadores BillboardGui nos Attachments com o Id de cada componente.
	- toggleStages(model, data): afasta os sub-Models com StageIndex ao longo do eixo do foguete
	  (tween de um NumberValue aplicado com PivotTo) e põe um rótulo em cada estágio.
	- toggleDoors(model): gira PayloadDoor_L/R em volta da dobradiça (atributos HingeOffset e
	  OpenAngle; as portas são construídas abertas).
	- resetModel(model): junta os estágios e reabre as portas (ao fechar o painel).
	Tudo é local: outros jogadores não veem a mudança.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))

local C = {}

local active -- câmera de exame
local stageState = {} -- [model] = { open, value, orig, labels }
local doorState = {} -- [model] = { closed, value }

local function reduceMotion()
	return State.settings().reduceMotion == true
end

local function tweenTime(t)
	return reduceMotion() and 0.05 or t
end

---------------------------------------------------------------------------------
-- Câmera de exame + marcadores
---------------------------------------------------------------------------------
function C.isActive()
	return active ~= nil
end

function C.exit()
	if not active then return end
	for _, x in active.cleanup do
		if typeof(x) == "RBXScriptConnection" then x:Disconnect() else x:Destroy() end
	end
	RunService:UnbindFromRenderStep("MuseumExamCamera")
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
	active = nil
end

function C.enter(model, data, onSelect)
	C.exit()
	local cam = workspace.CurrentCamera
	local cf, size = model:GetBoundingBox()
	local center = cf.Position
	local radius = size.Magnitude / 2
	local v = cam.CFrame.Position - center
	local a = {
		cleanup = {},
		yaw = math.atan2(v.X, v.Z),
		pitch = math.clamp(math.asin(math.clamp(v.Unit.Y, -1, 1)), -0.15, 1.2),
		dist = math.clamp(radius * 1.25, 10, 260),
		minDist = math.max(radius * 0.45, 6),
		maxDist = math.max(radius * 2.5, 30),
	}
	active = a
	cam.CameraType = Enum.CameraType.Scriptable

	local dragging = false
	table.insert(a.cleanup, UIS.InputBegan:Connect(function(input, processed)
		if processed then return end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.Touch then
			dragging = true
		end
	end))
	table.insert(a.cleanup, UIS.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	table.insert(a.cleanup, UIS.InputChanged:Connect(function(input, processed)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseWheel and not processed then
			a.dist = math.clamp(a.dist * (1 - input.Position.Z * 0.12), a.minDist, a.maxDist)
		elseif dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
			a.yaw -= input.Delta.X * 0.006
			a.pitch = math.clamp(a.pitch + input.Delta.Y * 0.005, -0.15, 1.3)
		end
	end))
	local pinchStart
	table.insert(a.cleanup, UIS.TouchPinch:Connect(function(_, scale, _, state, processed)
		if processed then return end
		if state == Enum.UserInputState.Begin then pinchStart = a.dist end
		if pinchStart and scale > 0 then a.dist = math.clamp(pinchStart / scale, a.minDist, a.maxDist) end
	end))

	local cur = cam.CFrame
	RunService:BindToRenderStep("MuseumExamCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if not active then return end
		local dir = Vector3.new(math.sin(a.yaw) * math.cos(a.pitch), math.sin(a.pitch), math.cos(a.yaw) * math.cos(a.pitch))
		local goal = CFrame.lookAt(center + dir * a.dist, center)
		local k = reduceMotion() and 1 or math.min(1, dt * 8)
		cur = cur:Lerp(goal, k)
		cam.CFrame = cur
	end)

	-- Marcadores
	local holder = Instance.new("Folder")
	holder.Name = "MuseumHotspots"
	holder.Parent = UI.playerGui()
	table.insert(a.cleanup, holder)
	for _, comp in data.Components or {} do
		local att = model:FindFirstChild(comp.Id, true)
		if att and att:IsA("Attachment") then
			local bb = UI.new("BillboardGui", {
				Adornee = att, AlwaysOnTop = true, Size = UDim2.fromOffset(190, 44),
				LightInfluence = 0, MaxDistance = 2000, Active = true, Parent = holder,
			})
			local b = UI.button(bb, "+  " .. comp.Name, function() onSelect(comp) end, {
				size = UDim2.fromScale(1, 1), textSize = 13, color = UI.C.panel,
			})
			b.BackgroundTransparency = 0.15
			b.TextWrapped = true
		end
	end
end

---------------------------------------------------------------------------------
-- Estágios
---------------------------------------------------------------------------------
local function stagesOf(model)
	local list = {}
	for _, m in model:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("StageIndex") then table.insert(list, m) end
	end
	table.sort(list, function(x, y) return x:GetAttribute("StageIndex") < y:GetAttribute("StageIndex") end)
	return list
end

function C.stagesOpen(model)
	return stageState[model] ~= nil and stageState[model].open
end

local function labelAt(model, text, parentFolder)
	local cf, size = model:GetBoundingBox()
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y / 2 + 4, 0))
	p.Parent = parentFolder
	local bb = UI.new("BillboardGui", { Adornee = p, AlwaysOnTop = true, Size = UDim2.fromOffset(200, 30), LightInfluence = 0, Parent = p })
	local l = UI.new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.panel, BackgroundTransparency = 0.15,
		Text = text, TextScaled = true, FontFace = UI.font(Enum.FontWeight.Bold), TextColor3 = UI.C.text, Parent = bb,
	})
	UI.corner(l, 4)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = l })
	return p
end

function C.toggleStages(model, data)
	local stages = stagesOf(model)
	if #stages < 2 then return false end
	local s = stageState[model]
	if not s then
		s = { open = false, value = Instance.new("NumberValue"), orig = {}, labels = nil }
		for i, st in stages do s.orig[i] = st:GetPivot() end
		local dir = (s.orig[#stages].Position - s.orig[1].Position).Unit
		local gap = 10 -- studs a mais entre cada estágio
		s.value.Changed:Connect(function(v)
			for i, st in stages do
				st:PivotTo(s.orig[i] + dir * (i - 1) * gap * v)
			end
		end)
		stageState[model] = s
	end
	s.open = not s.open
	local tw = TweenService:Create(s.value, TweenInfo.new(tweenTime(1.4), Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Value = s.open and 1 or 0 })
	tw:Play()
	if s.labels then
		s.labels:Destroy()
		s.labels = nil
	end
	if s.open then
		tw.Completed:Wait()
		if not s.open then return false end
		s.labels = Instance.new("Folder")
		s.labels.Name = "MuseumStageLabels"
		s.labels.Parent = workspace
		for _, st in stages do
			local text = (data.Stages and data.Stages[st.Name]) or st.Name
			labelAt(st, text, s.labels)
		end
	end
	return s.open
end

---------------------------------------------------------------------------------
-- Portas do compartimento de carga
---------------------------------------------------------------------------------
function C.toggleDoors(model)
	local doors = {}
	for _, n in { "PayloadDoor_L", "PayloadDoor_R" } do
		local d = model:FindFirstChild(n, true)
		if d and d:IsA("Model") and typeof(d:GetAttribute("HingeOffset")) == "CFrame" then table.insert(doors, d) end
	end
	if #doors == 0 then return end
	local s = doorState[model]
	if not s then
		s = { closed = false, value = Instance.new("NumberValue"), orig = {} }
		for i, d in doors do s.orig[i] = d:GetPivot() end
		s.value.Changed:Connect(function(v)
			for i, d in doors do
				local hinge = s.orig[i] * d:GetAttribute("HingeOffset")
				local ang = math.rad(d:GetAttribute("OpenAngle") or 90) * v
				-- fechar = girar em volta do eixo Z da dobradiça no sentido oposto ao da abertura
				d:PivotTo(hinge * CFrame.Angles(0, 0, -ang) * hinge:Inverse() * s.orig[i])
			end
		end)
		doorState[model] = s
	end
	s.closed = not s.closed
	TweenService:Create(s.value, TweenInfo.new(tweenTime(2.5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = s.closed and 1 or 0 }):Play()
end

function C.resetModel(model)
	local s = stageState[model]
	if s and s.open then
		local data = nil
		C.toggleStages(model, data or {})
	end
	local d = doorState[model]
	if d and d.closed then C.toggleDoors(model) end
end

return C
