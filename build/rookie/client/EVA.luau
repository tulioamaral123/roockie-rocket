--[[
	EVA — flutuação 3D livre na caminhada espacial (M2 Task 2), ligada pelo atributo
	RookieEVA do jogador (o servidor liga ao passar pela Airlock).
	Propulsores suaves: a velocidade segue o comando com aceleração limitada.
	Teclado: WASD/setas na direção da câmera, Espaço sobe, Shift esquerdo/C desce.
	Toque/controle: thumbstick + botões ▲ ▼ na tela.
	O personagem é do cliente (network owner), então a física replica sozinha.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")

local UI = require(script.Parent:WaitForChild("UI"))

local EVA = {}

local player = Players.LocalPlayer
local ativo = false
local velMax = 12
local aceleracao = 14 -- studs/s²
local subir, descer = 0, 0
local vel = Vector3.zero
local lv, ao, att = nil, nil, nil
local conexao = nil
local guiBotoes = nil
local limiteCabo = nil -- velocidade máxima carregando cabo (para o aviso "devagar")

local function acaoVertical(nome, estado)
	local v = estado == Enum.UserInputState.Begin and 1 or 0
	if nome == "RookieSubir" then subir = v else descer = v end
	return Enum.ContextActionResult.Sink
end

local function botoesToque()
	if guiBotoes or not UI.isTouch() then return end
	guiBotoes = UI.screenGui("RookieEVA", 12)
	local function b(txt, y, nome)
		local bt = UI.botao(guiBotoes, {
			Text = txt,
			Size = UDim2.fromOffset(64, 64),
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -24, 1, y),
			cor = UI.C.panel2,
			tamanho = 26,
		})
		bt.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then acaoVertical(nome, Enum.UserInputState.Begin) end
		end)
		bt.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then acaoVertical(nome, Enum.UserInputState.End) end
		end)
	end
	-- acima do botão de pulo (que fica no canto inferior direito)
	b("▲", -240, "RookieSubir")
	b("▼", -168, "RookieDescer")
end

local function ligar()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	ativo = true
	vel = Vector3.zero
	hum.PlatformStand = true
	att = Instance.new("Attachment")
	att.Name = "RookieEVA"
	att.Parent = root
	lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root
	ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.Responsiveness = 12
	ao.MaxTorque = math.huge
	ao.CFrame = root.CFrame.Rotation
	ao.Parent = root
	CAS:BindAction("RookieSubir", acaoVertical, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	CAS:BindAction("RookieDescer", acaoVertical, false, Enum.KeyCode.LeftShift, Enum.KeyCode.C, Enum.KeyCode.ButtonB)
	botoesToque()
	conexao = RunService.Heartbeat:Connect(function(dt)
		local cam = workspace.CurrentCamera
		local mover = hum.MoveDirection -- já vem na direção da câmera (plano XZ)
		local alvo = mover * velMax + Vector3.new(0, (subir - descer) * velMax * 0.7, 0)
		local dv = alvo - vel
		local passo = aceleracao * dt
		if dv.Magnitude > passo then dv = dv.Unit * passo end
		vel += dv
		if vel.Magnitude > velMax then vel = vel.Unit * velMax end
		lv.VectorVelocity = vel
		-- corpo olha para onde a câmera olha (sem inclinar)
		local look = cam.CFrame.LookVector
		local plano = Vector3.new(look.X, 0, look.Z)
		if plano.Magnitude > 0.01 then ao.CFrame = CFrame.lookAt(Vector3.zero, plano.Unit) end
	end)
end

local function desligar()
	ativo = false
	if conexao then conexao:Disconnect() conexao = nil end
	CAS:UnbindAction("RookieSubir")
	CAS:UnbindAction("RookieDescer")
	subir, descer = 0, 0
	for _, x in { lv, ao, att } do
		if x then x:Destroy() end
	end
	lv, ao, att = nil, nil, nil
	if guiBotoes then guiBotoes:Destroy() guiBotoes = nil end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function atualizar()
	local quer = player:GetAttribute("RookieEVA") == true
	if quer and not ativo then
		ligar()
	elseif not quer and ativo then
		desligar()
	end
end

function EVA.configurar(velocidadeEVA, velocidadeCabo)
	velMax = velocidadeEVA or velMax
	limiteCabo = velocidadeCabo
end

-- velocidade atual em relação ao limite do cabo (para o HUD avisar antes de escorregar)
function EVA.folga()
	if not ativo or not limiteCabo then return nil end
	return vel.Magnitude / limiteCabo
end

function EVA.ativo()
	return ativo
end

function EVA.iniciar()
	player:GetAttributeChangedSignal("RookieEVA"):Connect(atualizar)
	player.CharacterAdded:Connect(function()
		if ativo then desligar() end
		task.defer(atualizar)
	end)
	atualizar()
end

return EVA
