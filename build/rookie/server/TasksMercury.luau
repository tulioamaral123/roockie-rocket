--[[
	Tasks da Missão 1 · Projeto Mercury (spec §4.1). Cada tipo devolve new(sessao, n).
	Mira      — Task 1: 4 pontos vermelhos fora das janelas, segurar a mira.
	Codigo    — Task 2: código na prancheta → teclado do rádio; EJECT pisca ao lado.
	Retropack — Task 3: decidir em 10 s e segurar HOLD RETROPACK (soltar só pausa).
]]

local RS = game:GetService("ReplicatedStorage")
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))
local Naves = require(script.Parent.Naves)

local Tasks = {}

-- base comum: guarda sessão, config e itens; limite de tempo e falha por tempo
local function base(sessao, n)
	return {
		s = sessao,
		n = n,
		cfg = sessao.missao.Tasks[n],
		nave = sessao.nave,
		conexoes = {},
	}
end

local function desconectar(self)
	for _, c in self.conexoes do c:Disconnect() end
	table.clear(self.conexoes)
end

---------------------------------------------------------------------------------
-- Task 1 · Mira
---------------------------------------------------------------------------------

local Mira = {}
Mira.__index = Mira

function Mira.new(sessao, n)
	local self = setmetatable(base(sessao, n), Mira)
	self.pontos = Naves.numerados(Naves.peca(self.nave, "Exterior/AlignPoints"), "Point")
	assert(#self.pontos >= self.cfg.TotalPontos, "[RookieRocket] AlignPoints insuficientes")
	self.feitos = {}
	self.mirando = {} -- [player] = { ponto = i, inicio = os.clock() }
	self.segurar = sessao:temItem("Giroscopio") and sessao.missao.Equipamentos.Giroscopio.TempoSegurar
		or self.cfg.TempoBaseSegurar
	-- o raio da validação ignora vidro, pontos e personagens
	self.params = RaycastParams.new()
	self.params.FilterType = Enum.RaycastFilterType.Exclude
	return self
end

function Mira:iniciar() end

function Mira:limiteTempo()
	return self.cfg.LimiteTempo
end

-- o jogador enxerga o ponto? (linha livre da cabeça até ele, atravessando só vidro)
function Mira:linhaLivre(player, ponto)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return false end
	local filtro = { Naves.peca(self.nave, "Windows"), Naves.peca(self.nave, "Exterior") }
	for _, p in self.s.tripulacao do
		if p.Character then table.insert(filtro, p.Character) end
	end
	self.params.FilterDescendantsInstances = filtro
	local origem = head.Position
	local destino = ponto.Position
	local hit = workspace:Raycast(origem, destino - origem, self.params)
	return hit == nil
end

function Mira:acao(player, msg)
	if msg.acao == "MiraInicio" then
		local i = msg.ponto
		if type(i) ~= "number" or not self.pontos[i] or i > self.cfg.TotalPontos or self.feitos[i] then return end
		if not self.s:aBordo(player) or not self:linhaLivre(player, self.pontos[i]) then
			self.mirando[player] = nil
			return
		end
		local m = self.mirando[player]
		if m and m.ponto == i then
			m.visto = os.clock() -- o cliente repete MiraInicio enquanto mira (mantém o hold)
		else
			self.mirando[player] = { ponto = i, inicio = os.clock(), visto = os.clock() }
		end
	elseif msg.acao == "MiraFim" then
		self.mirando[player] = nil
	end
end

function Mira:tick()
	local agora = os.clock()
	for player, m in self.mirando do
		local valido = agora - m.visto <= 0.8
		if valido and agora - (m.checado or 0) >= 0.25 then
			m.checado = agora
			valido = self.s:aBordo(player) and self:linhaLivre(player, self.pontos[m.ponto])
		end
		if self.feitos[m.ponto] or not valido then
			self.mirando[player] = nil
		elseif agora - m.inicio >= self.segurar then
			self.feitos[m.ponto] = true
			self.mirando[player] = nil
			self.s:efeito("PontoTravado", { ponto = m.ponto })
			self.s:marcar()
		end
	end
	local n = 0
	for _ in self.feitos do n += 1 end
	if n >= self.cfg.TotalPontos then
		self.s:concluirTask()
	elseif self.s:tempoTask() > self.cfg.LimiteTempo then
		self.s:falhar("Tempo")
	end
end

function Mira:jogadorSaiu(player)
	self.mirando[player] = nil
end

function Mira:estado()
	-- array completo de booleanos (tabela esparsa não atravessa RemoteEvent inteira)
	local feitos = {}
	for i = 1, self.cfg.TotalPontos do feitos[i] = self.feitos[i] == true end
	return { feitos = feitos, segurar = self.segurar }
end

function Mira:limpar()
	table.clear(self.mirando)
end

---------------------------------------------------------------------------------
-- Task 2 · Código do rádio
---------------------------------------------------------------------------------

local Codigo = {}
Codigo.__index = Codigo

function Codigo.new(sessao, n)
	local self = setmetatable(base(sessao, n), Codigo)
	self.manual = sessao:temItem("ManualBordo")
	self.limite = self.cfg.LimiteTempo + (self.manual and sessao.missao.Equipamentos.ManualBordo.BonusTempo or 0)
	self.clipboard = Naves.peca(self.nave, "Stations/NavTable/Clipboard")
	self.keypad = Naves.peca(self.nave, "Stations/Radio/Keypad")
	self.eject = Naves.peca(self.nave, "Stations/Radio/EjectButton")
	return self
end

-- desenha a prancheta (SurfaceGui no servidor: todos veem o mesmo papel)
function Codigo:desenhar(codigo)
	local old = self.clipboard:FindFirstChild("RookieClipboard")
	if old then old:Destroy() end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "RookieClipboard"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 0.6
	gui.Parent = self.clipboard
	local fonte = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	local function texto(props)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.TextColor3 = Color3.fromHex("1D2430")
		t.FontFace = fonte
		t.TextScaled = true
		for k, v in props do t[k] = v end
		t.Parent = gui
		return t
	end
	texto({ Text = "COMM RECOVERY PROCEDURE", Size = UDim2.fromScale(0.9, 0.08), Position = UDim2.fromScale(0.05, 0.06) })
	texto({
		Text = "1. Switch to the backup frequency.\n2. Enter the code below on the radio keypad.\n3. Do NOT eject.",
		Size = UDim2.fromScale(0.9, 0.3),
		Position = UDim2.fromScale(0.05, 0.18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 22,
		TextWrapped = true,
		FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
	})
	local caixa = texto({
		Text = codigo and ("CODE  " .. codigo) or "—",
		Size = UDim2.fromScale(0.8, self.manual and 0.2 or 0.12),
		Position = UDim2.fromScale(0.1, 0.6),
		FontFace = Font.fromEnum(Enum.Font.Code),
	})
	if self.manual and codigo then
		-- Manual de Bordo: código destacado em amarelo
		caixa.BackgroundTransparency = 0
		caixa.BackgroundColor3 = Color3.fromHex("FFE14D")
		local borda = Instance.new("UIStroke")
		borda.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		borda.Thickness = 4
		borda.Color = Color3.fromHex("C98A00")
		borda.Parent = caixa
	end
end

function Codigo:iniciar()
	local d = self.cfg.DigitosCodigo
	local min, max = 10 ^ (d - 1), 10 ^ d - 1
	self.codigo = tostring(math.random(min, max))
	self:desenhar(self.codigo)
	-- o cliente abre o teclado ao usar este prompt (atributo RookiePainel)
	self.promptRadio = Naves.prompt(self.keypad, "Use radio", "Radio keypad", { painel = "Radio" })
	self.promptEject = Naves.prompt(self.eject, "EJECT CAPSULE", "Emergency", { tecla = Enum.KeyCode.F })
	table.insert(self.conexoes, self.promptEject.Triggered:Connect(function(p)
		if self.s:membro(p) then self.s:falhar("EjetarBlackout", { name = self.s:nome(p) }) end
	end))
end

function Codigo:limiteTempo()
	return self.limite
end

function Codigo:acao(player, msg)
	if msg.acao ~= "Codigo" or type(msg.valor) ~= "string" then return end
	if not self.s:perto(player, self.keypad) then return end
	local valor = string.gsub(string.sub(msg.valor, 1, 12), "%s", "")
	if valor == self.codigo then
		self.s:efeito("RadioOk", { fala = self.cfg.FalaAcerto })
		self.s:concluirTask()
	else
		self.s:aviso(player, Missoes.Textos.CodigoInvalido)
	end
end

function Codigo:tick()
	if self.s:tempoTask() > self.limite then self.s:falhar("Tempo") end
end

function Codigo:estado()
	return { limite = self.limite, manual = self.manual }
end

function Codigo:limpar()
	desconectar(self)
	if self.promptEject then self.promptEject:Destroy() end
	if self.promptRadio then self.promptRadio:Destroy() end
	self:desenhar(nil)
end

---------------------------------------------------------------------------------
-- Task 3 · Retropack
---------------------------------------------------------------------------------

local Retropack = {}
Retropack.__index = Retropack

function Retropack.new(sessao, n)
	local self = setmetatable(base(sessao, n), Retropack)
	self.escudo = sessao:temItem("EscudoReforcado")
	self.segurar = self.escudo and sessao.missao.Equipamentos.EscudoReforcado.TempoSegurar or self.cfg.TempoBaseSegurar
	self.progresso = 0 -- segundos acumulados
	self.decidiu = false
	self.segurando = {} -- [player] = prompt
	return self
end

function Retropack:iniciar()
	local reentry = Naves.peca(self.nave, "Stations/Reentry")
	self.promptEject = Naves.prompt(Naves.peca(reentry, "EjectButton"), "EJECT CAPSULE", "Emergency", { tecla = Enum.KeyCode.F })
	table.insert(self.conexoes, self.promptEject.Triggered:Connect(function(p)
		if self.s:membro(p) then self.s:falhar("EjetarEscudo", { name = self.s:nome(p) }) end
	end))
	self.promptsManter = {}
	for _, nome in { "RetainButtonA", "RetainButtonB" } do
		-- HoldDuration = tempo total: o anel do prompt anda junto com a barra quando o jogador não solta
		local pr = Naves.prompt(Naves.peca(reentry, nome), "HOLD RETROPACK", "Retropack", { segurar = self.segurar })
		table.insert(self.promptsManter, pr)
		table.insert(self.conexoes, pr.PromptButtonHoldBegan:Connect(function(p)
			if not self.s:perto(p, pr.Parent) then return end
			self.decidiu = true
			self.segurando[p] = pr
			self.s:marcar()
		end))
		table.insert(self.conexoes, pr.PromptButtonHoldEnded:Connect(function(p)
			if self.segurando[p] == pr then self.segurando[p] = nil end
			self.s:marcar()
		end))
		table.insert(self.conexoes, pr.Triggered:Connect(function(p)
			-- segurou o tempo todo sem soltar: o progresso já está no máximo (ou quase)
			if self.segurando[p] == pr then self.segurando[p] = nil end
			self.s:marcar()
		end))
	end
end

function Retropack:limiteTempo()
	return not self.decidiu and self.cfg.TempoDecisao or nil
end

function Retropack:acao() end

function Retropack:segurandoAgora()
	local n = 0
	for p, pr in self.segurando do
		if self.s:perto(p, pr.Parent, pr.MaxActivationDistance + 2) then n += 1 else self.segurando[p] = nil end
	end
	return n
end

function Retropack:tick(dt)
	if not self.decidiu then
		if self.s:tempoTask() > self.cfg.TempoDecisao then self.s:falhar("Tempo") end
		return
	end
	if self:segurandoAgora() > 0 then
		self.progresso = math.min(self.segurar, self.progresso + dt)
		-- tolerância de 1 frame: o prompt dispara Triggered exatamente no fim do tempo
		if self.progresso >= self.segurar - 0.05 then self.s:concluirTask() end
	end
end

function Retropack:jogadorSaiu(player)
	self.segurando[player] = nil
end

function Retropack:estado()
	return {
		decidiu = self.decidiu,
		progresso = self.progresso / self.segurar,
		segurar = self.segurar,
		segurando = self:segurandoAgora(),
		escudo = self.escudo,
	}
end

function Retropack:limpar()
	desconectar(self)
	if self.promptEject then self.promptEject:Destroy() end
	for _, pr in self.promptsManter or {} do pr:Destroy() end
	table.clear(self.segurando)
end

Tasks.Mira = Mira
Tasks.Codigo = Codigo
Tasks.Retropack = Retropack
return Tasks
