--[[
	Mira — M1 Task 1: mira "+" no centro da tela. Quando o centro da câmera aponta para um ponto
	vermelho (dentro de AnguloMira graus e sem nada no caminho além do vidro), avisa o servidor
	(MiraInicio); ao sair do ponto, MiraFim. O círculo radial enche no tempo de segurar.
	O servidor mede o tempo e decide; o cliente só desenha.
]]

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = require(script.Parent:WaitForChild("UI"))

local Mira = {}

local remotes = RS:WaitForChild("RookieRocket"):WaitForChild("Remotes")
local gui, cruz, anel, setAnel, rotulo = nil, nil, nil, nil, nil
local conexao = nil
local pontos, janelas, exterior = {}, nil, nil
local feitos = {}
local segurar = 2
local angulo = 3.5
local alvo, inicioAlvo = nil, 0
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function criarGui()
	gui = UI.screenGui("RookieMira", 11)
	cruz = UI.texto(gui, {
		Text = "+",
		tamanho = 44,
		peso = Enum.FontWeight.Bold,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	cruz.AnchorPoint = Vector2.new(0.5, 0.5)
	-- anel de progresso: 24 segmentos em volta da mira
	anel = UI.new("Frame", { Size = UDim2.fromOffset(90, 90), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = gui })
	local segs = {}
	for i = 1, 24 do
		local a = (i - 1) / 24 * math.pi * 2 - math.pi / 2
		local s = UI.new("Frame", {
			Size = UDim2.fromOffset(7, 7),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * 40, 0.5, math.sin(a) * 40),
			BackgroundColor3 = UI.C.green,
			BackgroundTransparency = 0.85,
			Parent = anel,
		})
		UI.corner(s, 4)
		segs[i] = s
	end
	setAnel = function(v)
		for i, s in segs do s.BackgroundTransparency = (i / 24 <= v) and 0 or 0.85 end
	end
	rotulo = UI.texto(gui, {
		Text = "",
		tamanho = 16,
		peso = Enum.FontWeight.SemiBold,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(260, 24),
		Position = UDim2.new(0.5, 0, 0.5, 58),
	})
	rotulo.AnchorPoint = Vector2.new(0.5, 0)
end

local function livre(origem, destino)
	params.FilterDescendantsInstances = { janelas, exterior, game:GetService("Players").LocalPlayer.Character }
	return workspace:Raycast(origem, destino - origem, params) == nil
end

local function mudarAlvo(novo)
	if novo == alvo then return end
	if alvo then remotes.AcaoTask:FireServer({ acao = "MiraFim" }) end
	alvo = novo
	inicioAlvo = os.clock()
	if novo then remotes.AcaoTask:FireServer({ acao = "MiraInicio", ponto = novo }) end
end

local function quadro()
	local cam = workspace.CurrentCamera
	local raio = cam:ViewportPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	local melhor, menor = nil, math.rad(angulo)
	for i, p in pontos do
		if not feitos[i] then
			local dir = (p.Position - raio.Origin).Unit
			local a = math.acos(math.clamp(dir:Dot(raio.Direction.Unit), -1, 1))
			if a < menor and livre(raio.Origin, p.Position) then
				melhor, menor = i, a
			end
		end
	end
	mudarAlvo(melhor)
	if alvo then
		setAnel(math.clamp((os.clock() - inicioAlvo) / segurar, 0, 1))
		cruz.TextColor3 = UI.C.green
		rotulo.Text = "Hold steady…"
	else
		setAnel(0)
		cruz.TextColor3 = UI.C.text
		local n = 0
		for _ in feitos do n += 1 end
		rotulo.Text = ("Targets %d/%d"):format(n, #pontos)
	end
end

function Mira.ligar(nave, cfg)
	if conexao then return end
	local ext = nave:WaitForChild("Exterior")
	exterior = ext
	janelas = nave:WaitForChild("Windows")
	local pasta = ext:WaitForChild("AlignPoints")
	pontos = {}
	for i = 1, cfg.TotalPontos do
		pontos[i] = pasta:WaitForChild("Point" .. i)
	end
	angulo = cfg.AnguloMira or angulo
	criarGui()
	conexao = RunService.RenderStepped:Connect(quadro)
end

-- dados da sincronização: pontos já travados e tempo de segurar (com/sem Giroscópio)
function Mira.atualizar(dados)
	feitos = {}
	for k, v in (dados and dados.feitos) or {} do
		if v then feitos[tonumber(k) or k] = true end
	end
	segurar = (dados and dados.segurar) or segurar
	if alvo and feitos[alvo] then
		alvo = nil
	end
	-- cor dos pontos: travado fica verde (local)
	for i, p in pontos do
		p.Color = feitos[i] and UI.C.green or Color3.fromHex("FF2A1F")
	end
end

function Mira.desligar()
	if not conexao then return end
	conexao:Disconnect()
	conexao = nil
	if alvo then remotes.AcaoTask:FireServer({ acao = "MiraFim" }) end
	alvo = nil
	for _, p in pontos do p.Color = Color3.fromHex("FF2A1F") end
	if gui then gui:Destroy() gui = nil end
end

return Mira
