--[[
	MuseumCutscene — cutscene na primeira entrada do jogador no salão principal do museu.

	Quatro tomadas de câmera com falas do Marcos Pontes (fictícias, como as do resto do jogo):
	motores F-1 vistos de baixo → passeio ao lado do Saturn V → Atlantis → visão geral. Depois a
	câmera volta suave para o jogador. Barras de cinema, legenda com o nome do Marcos e "Skip ›"
	(clique, toque, Espaço/Enter ou B no controle).
	Uma vez por sessão; só começa se a câmera estiver livre (sem show, exploração do foguete ou
	outra câmera controlada). Personagem parado durante a cena; tudo local ao jogador.
	Coordenadas do salão (Fases 16/17): interior X 133..277, Z 86..348, teto em Y 50;
	Saturn V no eixo X 205, Y 22, de Z 125 (motores) a Z 283; Atlantis em (164, 18, 316).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local GS = RS:WaitForChild("GuideSystem")
local Dialogues = require(GS:WaitForChild("Config"):WaitForChild("Dialogues"))
local UI = require(script.Parent:WaitForChild("GuideUI"))

local MuseumCutscene = {}
local player = Players.LocalPlayer

local HALL_MIN, HALL_MAX = Vector3.new(133, -2, 86), Vector3.new(277, 40, 348)

-- tomadas: câmera vai de "from" a "to" olhando de "lookFrom" a "lookTo" em "dur" segundos
local SHOTS = {
	{
		from = Vector3.new(205, 5, 98), to = Vector3.new(205, 7, 108),
		lookFrom = Vector3.new(205, 24, 130), lookTo = Vector3.new(205, 22, 140),
		dur = 6,
		line = "Welcome to the museum's main hall! Look up: this is a life-size Saturn V, the rocket that carried astronauts to the Moon.",
	},
	{
		from = Vector3.new(246, 30, 140), to = Vector3.new(246, 30, 262),
		lookFrom = Vector3.new(205, 22, 150), lookTo = Vector3.new(205, 22, 272),
		dur = 7,
		line = "It is 110.6 meters tall. Its three stages fired one after another, each one dropping away when its job was done.",
	},
	{
		from = Vector3.new(222, 30, 298), to = Vector3.new(214, 26, 288),
		lookFrom = Vector3.new(170, 18, 318), lookTo = Vector3.new(164, 18, 316),
		dur = 6,
		line = "Over here is the Space Shuttle Atlantis. It flew 33 missions and spent 307 days in space.",
	},
	{
		from = Vector3.new(266, 44, 336), to = Vector3.new(262, 40, 318),
		lookFrom = Vector3.new(200, 10, 220), lookTo = Vector3.new(195, 10, 205),
		dur = 6,
		line = "Walk up to any exhibit and use its prompt to discover its story. Have fun exploring!",
	},
}

local played = false
local running = nil

local function inHall(p)
	return p.X > HALL_MIN.X and p.X < HALL_MAX.X and p.Y > HALL_MIN.Y and p.Y < HALL_MAX.Y
		and p.Z > HALL_MIN.Z and p.Z < HALL_MAX.Z
end

local function buildGui()
	local gui = UI.screenGui("MuseumCutscene", 40)
	gui.IgnoreGuiInset = true
	local bars = {}
	for i, anchor in { 0, 1 } do
		bars[i] = UI.new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, anchor), Position = UDim2.fromScale(0, anchor),
			Size = UDim2.fromScale(1, 0), Parent = gui,
		})
	end
	local box = UI.new("Frame", {
		BackgroundColor3 = UI.C.panel, BackgroundTransparency = 0.15,
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0.8, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(760, 400), Parent = box })
	UI.corner(box, 12)
	UI.stroke(box, UI.C.line)
	UI.pad(box, 14)
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	local spk = Dialogues.Speakers.Marcos
	UI.text(box, {
		Text = spk.Name, Color = spk.Color, TextSize = 15, Weight = Enum.FontWeight.Bold,
		Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1,
	})
	local body = UI.text(box, {
		Text = "", TextSize = UI.isTouch() and 16 or 18, Weight = Enum.FontWeight.Medium,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})
	local skip = UI.button(gui, {
		Text = "Skip ›", Color = UI.C.panel2, Size = UDim2.fromOffset(110, 44),
	})
	skip.Name = "SkipCutscene"
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -16, 0, 16 + 44)
	return gui, bars, box, body, skip
end

local function stop()
	local r = running
	if not r then return end
	running = nil
	player:SetAttribute("InCutscene", nil)
	pcall(function() RunService:UnbindFromRenderStep("MuseumCutsceneCamera") end)
	pcall(function() CAS:UnbindAction("MuseumCutsceneFreeze") end)
	pcall(function() CAS:UnbindAction("MuseumCutsceneSkip") end)
	local cam = workspace.CurrentCamera
	if cam == r.cam then
		cam.FieldOfView = r.fov
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
	end
	if r.conn then r.conn:Disconnect() end
	if r.gui then r.gui:Destroy() end
end

local function ease(a)
	return a < 0.5 and 2 * a * a or 1 - (-2 * a + 2) ^ 2 / 2 -- InOut quad
end

local function play()
	local cam = workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Custom then return false end
	played = true
	local gui, bars, box, body, skip = buildGui()
	local r = { cam = cam, fov = cam.FieldOfView, gui = gui, start = cam.CFrame }
	running = r
	player:SetAttribute("InCutscene", true) -- NavigationClient esconde setas e objetivo

	local function skipNow()
		if running ~= r then return end
		r.skip = true
	end
	skip.Activated:Connect(skipNow)
	CAS:BindActionAtPriority("MuseumCutsceneFreeze", function() return Enum.ContextActionResult.Sink end, false,
		Enum.ContextActionPriority.High.Value + 60,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump,
		Enum.KeyCode.Thumbstick1)
	CAS:BindActionAtPriority("MuseumCutsceneSkip", function(_, state)
		if state == Enum.UserInputState.Begin then skipNow() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 60,
		Enum.KeyCode.Space, Enum.KeyCode.Return, Enum.KeyCode.ButtonB)

	-- câmera: cada tomada interpola posição e alvo; no fim volta ao ponto de partida
	local shot, t0 = 0, 0
	local current
	local function nextShot()
		shot += 1
		t0 = os.clock()
		local s = SHOTS[shot]
		if s then
			body.Text = s.line
			box.Visible = true
		end
		current = s
	end
	cam.CameraType = Enum.CameraType.Scriptable
	for _, b in bars do
		TweenService:Create(b, TweenInfo.new(0.5), { Size = UDim2.fromScale(1, 0.11) }):Play()
	end
	nextShot()
	local back -- volta ao jogador
	RunService:BindToRenderStep("MuseumCutsceneCamera", Enum.RenderPriority.Camera.Value + 2, function()
		if running ~= r then return end
		if workspace.CurrentCamera ~= cam then return stop() end
		cam.CameraType = Enum.CameraType.Scriptable
		if r.skip and not back then
			back = { from = cam.CFrame, t0 = os.clock(), dur = 0.6 }
			box.Visible = false
		end
		if back then
			local a = math.clamp((os.clock() - back.t0) / back.dur, 0, 1)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local goal = r.start
			if root then
				-- atrás e acima do jogador, olhando para onde ele olha
				local look = root.CFrame.LookVector
				local pos = root.Position - look * 12 + Vector3.new(0, 5, 0)
				goal = CFrame.lookAt(pos, root.Position + look * 6 + Vector3.new(0, 2, 0))
			end
			cam.CFrame = back.from:Lerp(goal, ease(a))
			if a >= 1 then stop() end
			return
		end
		local s = current
		if not s then
			r.skip = true
			return
		end
		local a = math.clamp((os.clock() - t0) / s.dur, 0, 1)
		local e = ease(a)
		local pos = s.from:Lerp(s.to, e)
		local look = s.lookFrom:Lerp(s.lookTo, e)
		local target = CFrame.lookAt(pos, look)
		-- primeira tomada começa da câmera do jogador (sem corte seco)
		if shot == 1 and a < 0.25 then
			target = r.start:Lerp(target, ease(a / 0.25))
		end
		cam.CFrame = target
		cam.FieldOfView = 70
		if a >= 1 then nextShot() end
	end)
	-- encerra também se o personagem sumir
	r.conn = player.CharacterRemoving:Connect(stop)
	return true
end

function MuseumCutscene.isRunning()
	return running ~= nil
end

function MuseumCutscene.start()
	task.spawn(function()
		while not played do
			task.wait(0.5)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and not running and inHall(root.Position) then
				play()
			end
		end
	end)
end

return MuseumCutscene
