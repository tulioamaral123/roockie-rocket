--[[
	Mira — M1 Task 1 "The Autopilot Failure" no painel de atitude (Stations/FlightPanel).

	O jogador vai ao painel em frente aos assentos e aciona "Take attitude control" (prompt do
	servidor com RookiePainel = "Atitude"). A câmera aproxima do painel e abre a tela de atitude:
	uma mira "+" que o jogador move (mouse, WASD/setas, analógico ou arrastando o dedo) enquanto
	a cápsula deriva sozinha (o piloto automático falhou). Manter a mira sobre cada um dos 4
	marcadores vermelhos até o anel encher trava o alvo.
	O servidor mede o tempo de segurar e decide (MiraInicio/MiraFim/PainelSair); o cliente só desenha.
	Os pontos externos (AlignPoints) ficam verdes quando travados, como antes.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("UI"))

local Mira = {}

local player = Players.LocalPlayer
local remotes = RS:WaitForChild("RookieRocket"):WaitForChild("Remotes")

-- alvos na tela de atitude (coordenadas normalizadas 0..1), um por AlignPoint
local ALVOS = { Vector2.new(0.22, 0.3), Vector2.new(0.78, 0.26), Vector2.new(0.27, 0.74), Vector2.new(0.74, 0.7) }
local RAIO = 0.075 -- distância (normalizada) para a mira estar "sobre" o alvo
local VEL_TECLA = 0.55 -- velocidade da mira no teclado/controle (tela por segundo)

local ligado = false
local nave, cfg = nil, nil
local pontos = {}
local feitos = {}
local segurar = 2
local aberto = false
local gui, tela, cruz, anel, setAnel, rotulo, marcas = nil, nil, nil, nil, nil, nil, {}
local conexao = nil
local alvo, inicioAlvo, ultimoRepique = nil, 0, 0
local mira = Vector2.new(0.5, 0.5) -- posição da mira (com a deriva)
local base = Vector2.new(0.5, 0.5) -- posição comandada pelo jogador
local deriva = Vector2.zero
local tDeriva = 0
local camAntes = nil

-- trava o personagem (andar e pular) enquanto o painel está aberto; as teclas continuam
-- chegando ao UserInputService, que move a mira
local CAS = game:GetService("ContextActionService")
local function controles(on)
	if on then
		CAS:UnbindAction("RookieAtitudeTravar")
	else
		CAS:BindActionAtPriority("RookieAtitudeTravar", function() return Enum.ContextActionResult.Sink end, false,
			Enum.ContextActionPriority.High.Value + 100,
			Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump,
			Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space,
			Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
			Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA)
	end
end

local function mudarAlvo(novo)
	if novo == alvo then return end
	if alvo then remotes.AcaoTask:FireServer({ acao = "MiraFim" }) end
	alvo = novo
	inicioAlvo = os.clock()
	if novo then remotes.AcaoTask:FireServer({ acao = "MiraInicio", ponto = novo }) end
end

local function pintarMarcas()
	for i, m in marcas do
		local ok = feitos[i]
		m.BackgroundColor3 = ok and UI.C.green or Color3.fromHex("FF2A1F")
		m:FindFirstChild("Rotulo").Text = ok and "LOCKED" or ("TARGET " .. i)
	end
end

local function criarGui()
	gui = UI.screenGui("RookieAtitude", 26)
	-- moldura do painel (CRT antigo, anos 60)
	local moldura = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.fromScale(0.62, 0.62),
		BackgroundColor3 = Color3.fromHex("2B2B27"),
		Parent = gui,
	})
	UI.new("UIAspectRatioConstraint", { AspectRatio = 1.6, Parent = moldura })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(760, 475), Parent = moldura })
	UI.corner(moldura, 18)
	UI.stroke(moldura, Color3.fromHex("D9D2BC"), 3)
	tela = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -28, 1, -28),
		BackgroundColor3 = Color3.fromHex("071A10"),
		ClipsDescendants = true,
		Parent = moldura,
	})
	UI.corner(tela, 12)
	-- grade e eixos
	for k = 1, 7 do
		UI.new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromScale(k / 8, 0), BackgroundColor3 = Color3.fromHex("1E6B3E"), BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tela })
		UI.new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, k / 8), BackgroundColor3 = Color3.fromHex("1E6B3E"), BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tela })
	end
	UI.new("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.fromHex("3FD17A"), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = tela })
	UI.new("Frame", { Size = UDim2.new(0, 2, 1, 0), Position = UDim2.fromScale(0.5, 0), BackgroundColor3 = Color3.fromHex("3FD17A"), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = tela })
	local titulo = UI.texto(tela, {
		Text = "ATTITUDE CONTROL · MANUAL",
		tamanho = 15,
		peso = Enum.FontWeight.Bold,
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(12, 8),
	})
	titulo.TextColor3 = Color3.fromHex("3FD17A")
	-- marcadores (um por alvo)
	marcas = {}
	for i, p in ALVOS do
		local m = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(p.X, p.Y),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = Color3.fromHex("FF2A1F"),
			Parent = tela,
		})
		UI.corner(m, 13)
		local r = UI.texto(m, { Text = "TARGET " .. i, tamanho = 11, peso = Enum.FontWeight.Bold, alinhar = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(90, 16), Position = UDim2.new(0.5, 0, 1, 4) })
		r.Name = "Rotulo"
		r.AnchorPoint = Vector2.new(0.5, 0)
		r.TextColor3 = Color3.fromHex("C9F5D8")
		marcas[i] = m
	end
	-- mira + anel de progresso
	cruz = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(90, 90), BackgroundTransparency = 1, Parent = tela })
	local mais = UI.texto(cruz, { Text = "+", tamanho = 46, peso = Enum.FontWeight.Bold, alinhar = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
	mais.TextYAlignment = Enum.TextYAlignment.Center
	mais.Name = "Mais"
	local segs = {}
	for i = 1, 24 do
		local a = (i - 1) / 24 * math.pi * 2 - math.pi / 2
		local s = UI.new("Frame", {
			Size = UDim2.fromOffset(7, 7),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * 36, 0.5, math.sin(a) * 36),
			BackgroundColor3 = UI.C.green,
			BackgroundTransparency = 0.85,
			Parent = cruz,
		})
		UI.corner(s, 4)
		segs[i] = s
	end
	setAnel = function(v)
		for i, s in segs do s.BackgroundTransparency = (i / 24 <= v) and 0 or 0.85 end
	end
	anel = cruz
	rotulo = UI.texto(gui, {
		Text = "",
		tamanho = 16,
		peso = Enum.FontWeight.SemiBold,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(520, 24),
		Position = UDim2.new(0.5, 0, 0.82, 0),
	})
	rotulo.AnchorPoint = Vector2.new(0.5, 0)
	local ajuda = UI.texto(gui, {
		Text = UI.isTouch() and "Drag to steer the capsule · keep the + on each red target"
			or "Mouse, WASD or arrows to steer · keep the + on each red target · Q to leave",
		tamanho = 14,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(620, 20),
		Position = UDim2.new(0.5, 0, 0.86, 0),
	})
	ajuda.AnchorPoint = Vector2.new(0.5, 0)
	ajuda.TextColor3 = UI.C.muted
	local sair = UI.botao(gui, {
		Text = "Leave panel",
		Size = UDim2.fromOffset(170, 46),
		Position = UDim2.new(0.5, 0, 0.9, 0),
	})
	sair.AnchorPoint = Vector2.new(0.5, 0)
	sair.Activated:Connect(function() Mira.fecharPainel() end)
	pintarMarcas()
end

-- posição do mouse/dedo dentro da tela (0..1), ou nil se fora
local function ponteiro()
	if not tela then return nil end
	local m = UIS:GetMouseLocation() - Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
	local p, s = tela.AbsolutePosition, tela.AbsoluteSize
	if s.X <= 0 or s.Y <= 0 then return nil end
	return Vector2.new((m.X - p.X) / s.X, (m.Y - p.Y) / s.Y)
end

local usouMouse = false
local function quadro(dt)
	if not aberto then return end
	-- mouse livre para mirar (a câmera em primeira pessoa prenderia o cursor)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	-- comando do jogador
	local eixo = Vector2.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then eixo += Vector2.new(0, -1) end
	if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then eixo += Vector2.new(0, 1) end
	if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then eixo += Vector2.new(-1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then eixo += Vector2.new(1, 0) end
	for _, st in UIS:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if st.KeyCode == Enum.KeyCode.Thumbstick1 and st.Position.Magnitude > 0.15 then
			eixo += Vector2.new(st.Position.X, -st.Position.Y)
		end
	end
	if eixo.Magnitude > 0 then
		usouMouse = false
		base += eixo.Unit * math.min(eixo.Magnitude, 1) * VEL_TECLA * dt
	elseif usouMouse then
		local p = ponteiro()
		if p then base = p end
	end
	base = Vector2.new(math.clamp(base.X, 0.03, 0.97), math.clamp(base.Y, 0.05, 0.95))
	-- deriva da cápsula: o piloto automático falhou, a mira escorrega devagar
	tDeriva += dt
	local alvoDeriva = Vector2.new(math.noise(tDeriva * 0.35, 1.7) * 0.11, math.noise(tDeriva * 0.35, 9.3) * 0.11)
	deriva = deriva:Lerp(alvoDeriva, math.clamp(dt * 2, 0, 1))
	mira = Vector2.new(math.clamp(base.X + deriva.X, 0, 1), math.clamp(base.Y + deriva.Y, 0, 1))
	cruz.Position = UDim2.fromScale(mira.X, mira.Y)
	-- alvo sob a mira (proporção da tela corrigida para círculo)
	local asp = tela.AbsoluteSize.X / math.max(1, tela.AbsoluteSize.Y)
	local melhor, menor = nil, RAIO
	for i, p in ALVOS do
		if not feitos[i] then
			local d = Vector2.new((mira.X - p.X) * asp, mira.Y - p.Y).Magnitude
			if d < menor then melhor, menor = i, d end
		end
	end
	mudarAlvo(melhor)
	if alvo and os.clock() - ultimoRepique >= 0.4 then
		ultimoRepique = os.clock()
		remotes.AcaoTask:FireServer({ acao = "MiraInicio", ponto = alvo })
	end
	local mais = cruz:FindFirstChild("Mais")
	if alvo then
		setAnel(math.clamp((os.clock() - inicioAlvo) / segurar, 0, 1))
		mais.TextColor3 = UI.C.green
		rotulo.Text = "Hold steady…"
	else
		setAnel(0)
		mais.TextColor3 = Color3.new(1, 1, 1)
		local n = 0
		for _ in feitos do n += 1 end
		rotulo.Text = ("Targets locked %d/%d"):format(n, #ALVOS)
	end
end

-- abre a tela de atitude: câmera aproxima do painel, controles do personagem desligados
function Mira.abrirPainel()
	if not ligado or aberto or not nave then return end
	local painel = nave:FindFirstChild("Stations") and nave.Stations:FindFirstChild("FlightPanel")
	if not painel then return end
	aberto = true
	controles(false)
	local cam = workspace.CurrentCamera
	camAntes = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable
	local frente = painel.CFrame.LookVector -- o console olha para dentro da cabine
	local foco = painel.Position + Vector3.new(0, 1.2, 0)
	local alvoCam = CFrame.lookAt(foco + frente * 6 + Vector3.new(0, 0.8, 0), foco)
	TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = alvoCam }):Play()
	base, deriva, tDeriva = Vector2.new(0.5, 0.5), Vector2.zero, math.random() * 50
	usouMouse = false -- a mira começa no centro; segue o mouse depois que ele se mexer
	-- esconde o próprio personagem (o capacete tapava a tela de perto)
	local char = player.Character
	if char then
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 1 end
		end
	end
	criarGui()
	conexao = RunService.RenderStepped:Connect(quadro)
end

function Mira.fecharPainel()
	if not aberto then return end
	aberto = false
	if conexao then conexao:Disconnect() conexao = nil end
	if alvo then remotes.AcaoTask:FireServer({ acao = "MiraFim" }) end
	alvo = nil
	remotes.AcaoTask:FireServer({ acao = "PainelSair" })
	if gui then gui:Destroy() gui = nil end
	tela, cruz = nil, nil
	local cam = workspace.CurrentCamera
	cam.CameraType = camAntes or Enum.CameraType.Custom
	controles(true)
	local char = player.Character
	if char then
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
		end
	end
end

UIS.InputChanged:Connect(function(input)
	if aberto and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		usouMouse = true
	end
end)
UIS.InputBegan:Connect(function(input, processed)
	if aberto and not processed and (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB) then
		Mira.fecharPainel()
	end
end)

function Mira.ligar(modelo, c)
	if ligado then return end
	ligado = true
	nave, cfg = modelo, c
	local pasta = modelo:WaitForChild("Exterior"):WaitForChild("AlignPoints")
	pontos = {}
	for i = 1, c.TotalPontos do pontos[i] = pasta:WaitForChild("Point" .. i) end
end

-- dados da sincronização: alvos já travados e tempo de segurar (com/sem Giroscópio)
function Mira.atualizar(dados)
	feitos = {}
	for k, v in (dados and dados.feitos) or {} do
		if v then feitos[tonumber(k) or k] = true end
	end
	segurar = (dados and dados.segurar) or segurar
	if alvo and feitos[alvo] then alvo = nil end
	for i, p in pontos do
		p.Color = feitos[i] and UI.C.green or Color3.fromHex("FF2A1F")
	end
	if aberto then pintarMarcas() end
end

function Mira.desligar()
	if aberto then Mira.fecharPainel() end
	if not ligado then return end
	ligado = false
	for _, p in pontos do p.Color = Color3.fromHex("FF2A1F") end
	pontos, nave = {}, nil
end

return Mira
