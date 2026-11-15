--[[
	ArrivalCutscene — cutscene de chegada ao nascer.

	Na primeira entrada da sessão, se o jogador está no começo do tutorial (etapa MeetMarcos ou
	ainda sem etapa), o personagem aparece na praça em frente à recepção (Fase 24) e caminha
	sozinho até o saguão, passando pela porta automática da fachada (Entrance_AutoDoor, Fase 6;
	o AutomaticDoors do servidor abre ao chegar perto). Duas tomadas:
	  1. vista ampla da praça e da fachada, com o título do jogo;
	  2. de dentro do saguão, a porta se abrindo e o jogador entrando.
	Depois a câmera volta para trás do jogador e o tutorial segue (encontrar o Marcos).
	"Skip ›" (clique, toque, Espaço/Enter ou B) põe o personagem direto no saguão.
	Controles travados durante a cena; tudo local ao jogador (o cliente é dono do personagem).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("GuideUI"))

local Arrival = {}
local player = Players.LocalPlayer

local START = CFrame.lookAt(Vector3.new(0, 3, -34), Vector3.new(0, 3, 0)) -- praça, de frente para a porta
local INSIDE = Vector3.new(0, 3, 9) -- saguão, logo depois da porta
local DOOR = Vector3.new(0, 5, -0.5)
local SHOT1, TOTAL = 4.2, 10

local played = false
local running = nil

local function ease(a)
	return a < 0.5 and 2 * a * a or 1 - (-2 * a + 2) ^ 2 / 2
end

local function buildGui()
	local gui = UI.screenGui("ArrivalCutscene", 40)
	gui.IgnoreGuiInset = true
	for _, anchor in { 0, 1 } do
		UI.new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, anchor), Position = UDim2.fromScale(0, anchor),
			Size = UDim2.fromScale(1, 0.11), Parent = gui,
		})
	end
	local title = UI.text(gui, {
		Text = "ROOKIE ROCKET", TextSize = 54, Weight = Enum.FontWeight.Heavy,
		AlignX = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromOffset(700, 64),
	})
	title.TextStrokeTransparency = 0.5
	local sub = UI.text(gui, {
		Text = "Welcome to the Space Center", TextSize = 22, Weight = Enum.FontWeight.SemiBold,
		Color = UI.C.accent, AlignX = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.15, 66), Size = UDim2.fromOffset(700, 30),
	})
	sub.TextStrokeTransparency = 0.6
	local fade = UI.new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = gui,
	})
	local skip = UI.button(gui, { Text = "Skip ›", Color = UI.C.panel2, Size = UDim2.fromOffset(110, 44) })
	skip.Name = "SkipArrival"
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -16, 0, 60)
	return gui, title, sub, fade, skip
end

local function stop(r, toInside)
	if running ~= r then return end
	running = nil
	player:SetAttribute("InCutscene", nil)
	pcall(function() RunService:UnbindFromRenderStep("ArrivalCutsceneCamera") end)
	pcall(function() CAS:UnbindAction("ArrivalCutsceneFreeze") end)
	pcall(function() CAS:UnbindAction("ArrivalCutsceneSkip") end)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if toInside and root then
		root.CFrame = CFrame.lookAt(INSIDE, INSIDE + Vector3.new(0, 0, 10))
	end
	if hum and root then hum:MoveTo(root.Position) end
	if hum and r.speed then hum.WalkSpeed = r.speed end
	local cam = workspace.CurrentCamera
	if cam == r.cam then
		cam.CameraType = Enum.CameraType.Custom
		if hum then cam.CameraSubject = hum end
		if root then
			local look = root.CFrame.LookVector
			cam.CFrame = CFrame.lookAt(root.Position - look * 12 + Vector3.new(0, 5, 0), root.Position + look * 6)
		end
	end
	local gui = r.gui
	if gui then
		local tw = TweenService:Create(r.fade, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		r.fade.BackgroundTransparency = toInside and 0 or r.fade.BackgroundTransparency
		tw:Play()
		for _, d in gui:GetDescendants() do
			if d:IsA("Frame") and d ~= r.fade then
				TweenService:Create(d, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			elseif d:IsA("TextLabel") or d:IsA("TextButton") then
				d.Visible = false
			end
		end
		task.delay(0.45, function() gui:Destroy() end)
	end
end

local function play(char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	local hum = char:WaitForChild("Humanoid", 10)
	if not (root and hum) then return end
	local cam = workspace.CurrentCamera
	-- espera a câmera padrão assumir; se outra cena estiver ativa, não toca
	task.wait(0.5)
	if cam.CameraType ~= Enum.CameraType.Custom then return end
	played = true
	local gui, title, sub, fade, skip = buildGui()
	local r = { cam = cam, gui = gui, fade = fade }
	running = r
	player:SetAttribute("InCutscene", true) -- NavigationClient esconde setas e objetivo
	root.CFrame = START
	root.AssemblyLinearVelocity = Vector3.zero

	local function pular()
		if running == r then stop(r, true) end
	end
	skip.Activated:Connect(pular)
	CAS:BindActionAtPriority("ArrivalCutsceneFreeze", function() return Enum.ContextActionResult.Sink end, false,
		Enum.ContextActionPriority.High.Value + 60,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump,
		Enum.KeyCode.Thumbstick1)
	CAS:BindActionAtPriority("ArrivalCutsceneSkip", function(_, state)
		if state == Enum.UserInputState.Begin then pular() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 60, Enum.KeyCode.Space, Enum.KeyCode.Return, Enum.KeyCode.ButtonB)

	local t0 = os.clock()
	local walking = false
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(fade, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	RunService:BindToRenderStep("ArrivalCutsceneCamera", Enum.RenderPriority.Camera.Value + 2, function()
		if running ~= r then return end
		if workspace.CurrentCamera ~= cam or not root.Parent then return stop(r, false) end
		local t = os.clock() - t0
		cam.CameraType = Enum.CameraType.Scriptable
		-- o personagem começa a andar depois do título
		if not walking and t > 1.6 then
			walking = true
			-- passo de caminhada (mais devagar que a corrida padrão), devolvido no fim
			r.speed = hum.WalkSpeed
			hum.WalkSpeed = 9
			hum:MoveTo(INSIDE)
		end
		-- título some aos poucos
		local ta = math.clamp((t - 2.8) / 0.8, 0, 1)
		title.TextTransparency, sub.TextTransparency = ta, ta
		title.TextStrokeTransparency, sub.TextStrokeTransparency = 0.5 + ta * 0.5, 0.6 + ta * 0.4
		if t < SHOT1 then
			-- 1. vista ampla da praça e da fachada, aproximando
			local a = ease(t / SHOT1)
			cam.CFrame = CFrame.lookAt(Vector3.new(30, 16, -66):Lerp(Vector3.new(16, 9, -50), a), DOOR + Vector3.new(0, 2, 0))
		else
			-- 2. de dentro do saguão: a porta abre e o jogador entra
			cam.CFrame = CFrame.lookAt(Vector3.new(9, 6, 20), root.Position:Lerp(DOOR, 0.3) + Vector3.new(0, 1, 0))
		end
		cam.FieldOfView = 70
		-- chegou ao saguão (ou demorou demais): termina
		if (walking and root.Position.Z > INSIDE.Z - 1.5 and t > SHOT1 + 1.2) or t > TOTAL then
			stop(r, root.Position.Z < 2)
		end
	end)
end

function Arrival.isRunning()
	return running ~= nil
end

function Arrival.start()
	local function onChar(char)
		if played then return end
		local stage = player:GetAttribute("GuideStage")
		if stage ~= nil and stage ~= "MeetMarcos" then
			played = true -- quem já está adiante no tutorial não vê a chegada
			return
		end
		task.spawn(play, char)
	end
	if player.Character then onChar(player.Character) end
	player.CharacterAdded:Connect(onChar)
end

return Arrival
