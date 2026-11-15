--[[
	ShowController — show de lançamento (museuspec §6), roteirizado por Content/Shows.

	Local: só quem acionou vê. Pode sair a qualquer momento ("Exit show"); cleanup()
	restaura luz, console, foguete do diorama, estágios do Saturn V, câmera e interface.
	Usa: SpaceMuseumExhibits.LaunchDiorama (MiniRocket, ParticleEmitters),
	LaunchConsole (ConsoleLight com Order, Screen), Saturn V (Stage_* com ShowLight).
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local MS = RS:WaitForChild("MuseumSystem")
local Shared = MS:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))

local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))

local Show = {}

local run -- estado do show em andamento

local function exhibitsRoot()
	local m = workspace:FindFirstChild("NASAComplex")
	return m and m:FindFirstChild("SpaceMuseumExhibits")
end

local function saturn()
	for _, m in CollectionService:GetTagged("Exhibit") do
		if m:GetAttribute("ExhibitId") == "saturn_v" then return m end
	end
	return nil
end

local function remember(obj, props)
	local saved = {}
	for _, k in props do saved[k] = obj[k] end
	table.insert(run.restore, { obj = obj, props = saved })
end

local function buildGui()
	local gui = UI.screenGui("MuseumShow", 25)
	local exit = UI.button(gui, Text.get("show.exit"), function() Show.stop() end, { color = UI.C.accent, textSize = 17 })
	exit.AnchorPoint = Vector2.new(0.5, 0)
	exit.Position = UDim2.new(0.5, 0, 0, 8)
	local cap = UI.new("TextLabel", {
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.new(1, -240, 0, 0), -- 120 px livres de cada lado (direcional e pulo no celular)
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Text = "",
		Visible = false,
		TextWrapped = true,
		FontFace = UI.font(Enum.FontWeight.SemiBold),
		TextColor3 = UI.C.text,
		Parent = gui,
	})
	cap:SetAttribute("BaseTextSize", 22)
	cap.TextSize = 22
	UI.setTextLevel(UI.textLevel)
	UI.corner(cap, 6)
	UI.pad(cap, 10)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(900, math.huge), Parent = cap })
	local big = UI.new("TextLabel", {
		Name = "Big", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
		-- altura relativa: no celular não cobre o botão de sair
		Size = UDim2.new(0, 300, 0.3, 0), BackgroundTransparency = 1, Text = "", TextScaled = true,
		FontFace = UI.font(Enum.FontWeight.Heavy), TextColor3 = UI.C.text, TextStrokeTransparency = 0.5, Parent = gui,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 120, Parent = big })
	return gui, cap, big
end

-- tween de câmera do show: guardado para cancelar ao sair (senão continua puxando a câmera Custom)
local function camTween(goal, info)
	if run.camTween then run.camTween:Cancel() end
	run.camTween = TweenService:Create(workspace.CurrentCamera, info, { CFrame = goal })
	run.camTween:Play()
end

local function caption(text)
	if not State.settings().captions then return end
	run.cap.Text = text
	run.cap.Visible = true
	local my = {}
	run.capToken = my
	task.delay(6, function()
		if run and run.capToken == my then run.cap.Visible = false end
	end)
end

local function screen(text)
	local scr = run.console and run.console:FindFirstChild("Screen", true)
	if not (scr and scr:IsA("BasePart")) then return end
	local g = scr:FindFirstChild("ShowScreen")
	if not g then
		local faceName = scr:GetAttribute("DisplayFace") or scr:GetAttribute("ScreenFace")
		local ok, face = pcall(function() return Enum.NormalId[faceName] end)
		g = UI.new("SurfaceGui", {
			Name = "ShowScreen", Face = ok and face or Enum.NormalId.Front, LightInfluence = 0, Brightness = 2,
			SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 30, Parent = scr,
		})
		UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHex("04070F"), BorderSizePixel = 0, Parent = g })
		UI.new("TextLabel", {
			Name = "T", Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), BackgroundTransparency = 1,
			TextScaled = true, FontFace = UI.font(Enum.FontWeight.Bold), TextColor3 = UI.C.text, Text = "", Parent = g.Frame,
		})
		table.insert(run.destroy, g)
	end
	g.Frame.T.Text = text
end

local function setConsoleLight(part)
	remember(part, { "Color", "Material" })
	part.Color = UI.C.green
	part.Material = Enum.Material.Neon
end

local function stageLight(stageName, label)
	local sv = run.saturn
	if not sv then return end
	if run.stageLight then run.stageLight.Enabled = false end
	if run.stageLabel then run.stageLabel:Destroy() end
	local st = sv:FindFirstChild(stageName, true)
	if not st then return end
	local holder = st:FindFirstChild("ShowLight", true)
	local light = holder and holder:FindFirstChildWhichIsA("Light", true)
	if light then
		remember(light, { "Enabled" })
		light.Enabled = true
		run.stageLight = light
	end
	local cf, size = st:GetBoundingBox()
	if run.camPos then
		local goal = CFrame.lookAt(run.camPos, run.camLook:Lerp(cf.Position, 0.35))
		local cam = workspace.CurrentCamera
		if State.settings().reduceMotion then
			cam.CFrame = goal
		else
			camTween(goal, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
		end
	end
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.Position = cf.Position - Vector3.new(0, size.Y / 2 + 3, 0)
	p.Parent = workspace
	local bb = UI.new("BillboardGui", { Adornee = p, AlwaysOnTop = true, Size = UDim2.fromOffset(280, 36), LightInfluence = 0, Parent = p })
	local l = UI.new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.accent, Text = label, TextScaled = true,
		FontFace = UI.font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Parent = bb,
	})
	UI.corner(l, 4)
	UI.pad(l, 5)
	run.stageLabel = p
	table.insert(run.destroy, p)
end

local actions = {}

function actions.dim()
	remember(Lighting, { "Brightness", "ExposureCompensation", "Ambient", "OutdoorAmbient" })
	local t = State.settings().reduceMotion and 0.1 or 2.5
	TweenService:Create(Lighting, TweenInfo.new(t), {
		Brightness = Lighting.Brightness * 0.3,
		ExposureCompensation = Lighting.ExposureCompensation - 1.3,
		Ambient = Lighting.Ambient:Lerp(Color3.new(0, 0, 0), 0.7),
		OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(Color3.new(0, 0, 0), 0.7),
	}):Play()
end

function actions.restore()
	for _, r in run.restore do
		if r.obj == Lighting then
			TweenService:Create(Lighting, TweenInfo.new(2.5), r.props):Play()
		end
	end
end

function actions.screen(s) screen(s.Text) end
function actions.caption(s) caption(s.Text) end

function actions.console(s)
	for _, p in run.lights do
		if p:GetAttribute("Order") == s.Order then setConsoleLight(p) end
	end
end

function actions.allConsole()
	for _, p in run.lights do setConsoleLight(p) end
end

function actions.countdown(s)
	local my = run
	for n = s.From, 1, -1 do
		if run ~= my then return end
		run.big.Text = tostring(n)
		screen("T-" .. n)
		task.wait(1)
	end
	if run == my then run.big.Text = "" end
end

function actions.ignite()
	if not run.diorama then return end
	for _, e in run.diorama:GetDescendants() do
		if e:IsA("ParticleEmitter") or e:IsA("Light") or e:IsA("Fire") or e:IsA("Smoke") then
			remember(e, { "Enabled" })
			e.Enabled = true
		end
	end
end

function actions.liftoff(s)
	local rocket = run.diorama and run.diorama:FindFirstChild("MiniRocket", true)
	if not rocket then return end
	local orig = rocket:GetPivot()
	table.insert(run.pivots, { model = rocket, cf = orig })
	local v = Instance.new("NumberValue")
	table.insert(run.destroy, v)
	v.Changed:Connect(function(x) rocket:PivotTo(orig + Vector3.new(0, (s.Height or 25) * x, 0)) end)
	TweenService:Create(v, TweenInfo.new(s.Seconds or 12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 1 }):Play()
end

function actions.shake(s)
	if State.settings().reduceMotion then return end
	local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local my = run
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if run ~= my or t > (s.Seconds or 4) then
			hum.CameraOffset = Vector3.zero
			conn:Disconnect()
			return
		end
		local a = 0.18 * (1 - t / (s.Seconds or 4))
		local jitter = Vector3.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)
		if my.camPos then
			-- câmera do show (Scriptable): treme em volta da posição fixa
			workspace.CurrentCamera.CFrame = CFrame.lookAt(my.camPos + jitter, my.camLook)
		else
			hum.CameraOffset = jitter
		end
	end)
	table.insert(run.conns, conn)
end

function actions.stage(s) stageLight(s.Stage, s.Label) end

function actions.final()
	caption(Text.get("show.simplified"))
	run.big.Text = ""
	local my = run
	task.delay(5, function()
		if run == my then
			MS.Remotes.ShowWatched:FireServer(my.id)
			State.mark("showsSeen", my.id)
			Show.stop()
		end
	end)
end

function Show.isRunning()
	return run ~= nil
end

function Show.start(id, beforeStart)
	if run then return end
	local show = Content.show(id)
	if not show then return end
	if beforeStart then beforeStart() end
	local root = exhibitsRoot()
	local gui, cap, big = buildGui()
	run = {
		id = id, gui = gui, cap = cap, big = big,
		restore = {}, destroy = {}, pivots = {}, conns = {},
		diorama = root and root:FindFirstChild("LaunchDiorama", true),
		console = root and root:FindFirstChild("LaunchConsole", true),
		saturn = saturn(),
		lights = {},
	}
	if run.console then
		for _, p in run.console:GetDescendants() do
			if p:IsA("BasePart") and CollectionService:HasTag(p, "ConsoleLight") then table.insert(run.lights, p) end
		end
	end
	-- Só para este jogador: esconde o próprio personagem (fica entre a câmera e o diorama) e o HUD
	local char = Players.LocalPlayer.Character
	if char then
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				remember(d, { "LocalTransparencyModifier" })
				d.LocalTransparencyModifier = 1
			end
		end
	end
	local hud = Players.LocalPlayer.PlayerGui:FindFirstChild("MuseumHud")
	if hud then
		remember(hud, { "Enabled" })
		hud.Enabled = false
	end
	-- Câmera do show
	if show.Camera then
		local cam = workspace.CurrentCamera
		run.camera = { type = cam.CameraType, fov = cam.FieldOfView }
		local c = show.Camera
		-- a peça ShowCamera (Fase 17) acompanha o museu onde ele estiver; o roteiro é só reserva
		local marker = run.console and run.console:FindFirstChild("ShowCamera", true)
		if marker and marker:IsA("BasePart") then
			run.camPos = marker.Position
			run.camLook = marker.Position + marker.CFrame.LookVector * 38
		else
			run.camPos = Vector3.new(table.unpack(c.Position))
			run.camLook = Vector3.new(table.unpack(c.LookAt))
		end
		cam.CameraType = Enum.CameraType.Scriptable
		if c.FieldOfView then cam.FieldOfView = c.FieldOfView end
		local goal = CFrame.lookAt(run.camPos, run.camLook)
		if State.settings().reduceMotion then
			cam.CFrame = goal
		else
			camTween(goal, TweenInfo.new(1.5, Enum.EasingStyle.Sine))
		end
	end
	-- morrer ou reaparecer no meio encerra o show (restaura câmera, luz, HUD e personagem)
	local LP = Players.LocalPlayer
	table.insert(run.conns, LP.CharacterAdded:Connect(function() Show.stop() end))
	local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum0 then table.insert(run.conns, hum0.Died:Connect(function() Show.stop() end)) end
	local my = run
	local t0 = os.clock()
	task.spawn(function()
		for _, step in show.Steps do
			local wait = step.At - (os.clock() - t0)
			if wait > 0 then task.wait(wait) end
			if run ~= my then return end
			local f = actions[step.Do]
			if f then
				task.spawn(function()
					local ok, err = pcall(f, step)
					if not ok then warn("[Show] " .. step.Do .. ": " .. tostring(err)) end
				end)
			end
		end
	end)
end

function Show.stop()
	local r = run
	if not r then return end
	run = nil
	if r.camTween then r.camTween:Cancel() end
	for _, c in r.conns do c:Disconnect() end
	local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.CameraOffset = Vector3.zero end
	for _, p in r.pivots do p.model:PivotTo(p.cf) end
	for i = #r.restore, 1, -1 do
		local x = r.restore[i]
		if x.obj == Lighting then
			TweenService:Create(Lighting, TweenInfo.new(1.2), x.props):Play()
		elseif x.obj.Parent then
			for k, v in x.props do x.obj[k] = v end
		end
	end
	for _, d in r.destroy do d:Destroy() end
	r.gui:Destroy()
	if r.camera then
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = r.camera.fov
		if hum then cam.CameraSubject = hum end
	end
end

return Show
