--[[
	Tasks da Missão 2 · ISS (spec §4.2). Cada tipo devolve new(sessao, n).
	Acoplamento — Task 1: 4 esferas nos alvos X + slider de pressão na zona verde (Canadarm).
	EVA         — Task 2: sair pela Airlock e levar 2 cabos até as polias sem correr demais.
	Vazamento   — Task 3: fechar a escotilha, achar o furo, pegar a gaze e segurar no furo.
]]

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))
local Naves = require(script.Parent.Naves)

local Tasks = {}

local function base(sessao, n)
	return { s = sessao, n = n, cfg = sessao.missao.Tasks[n], nave = sessao.nave, conexoes = {} }
end

local function desconectar(self)
	for _, c in self.conexoes do c:Disconnect() end
	table.clear(self.conexoes)
end

---------------------------------------------------------------------------------
-- Task 1 · Acoplamento (Unity & Zarya)
---------------------------------------------------------------------------------

local Acoplamento = {}
Acoplamento.__index = Acoplamento

local zaryaInicial = {} -- [nave] = CFrame do build (desalinhada), para repetir a task

function Acoplamento.new(sessao, n)
	local self = setmetatable(base(sessao, n), Acoplamento)
	self.console = Naves.peca(self.nave, "Stations/CanadarmConsole")
	self.zarya = Naves.peca(self.nave, "Exterior/Zarya")
	self.encaixe = Naves.peca(self.nave, "Exterior/ZaryaDockedPose")
	zaryaInicial[self.nave] = zaryaInicial[self.nave] or self.zarya:GetPivot()
	local mult = sessao:temItem("SensorPressao") and sessao.missao.Equipamentos.SensorPressao.MultiplicadorZonaVerde or 1
	self.zonaMin = self.cfg.ZonaVerdeCentro - self.cfg.ZonaVerdeMeiaLargura * mult
	self.zonaMax = self.cfg.ZonaVerdeCentro + self.cfg.ZonaVerdeMeiaLargura * mult
	self.pressao = self.cfg.ZonaVerdeCentro
	self.valvula = self.cfg.ZonaVerdeCentro -- posição do slider (0..1)
	self.deriva = 0.15
	self.alvoDeriva = 0.25
	self.trocaDeriva = 0
	self.tempoNoMax = 0
	self.esferas = {}
	self.ultimoAjuste = {}
	return self
end

function Acoplamento:iniciar()
	self.zarya:PivotTo(zaryaInicial[self.nave])
	Naves.prompt(self.console, "Use Canadarm console", "Canadarm", { painel = "Canadarm" }).Name = "RookieTaskPrompt"
end

function Acoplamento:limiteTempo()
	return self.cfg.LimiteTempo
end

function Acoplamento:naZonaVerde()
	return self.pressao >= self.zonaMin and self.pressao <= self.zonaMax
end

function Acoplamento:acao(player, msg)
	if not self.s:perto(player, self.console) then return end
	if msg.acao == "Pressao" and type(msg.valor) == "number" and msg.valor == msg.valor then
		-- no máximo 20 ajustes por segundo por jogador
		local agora = os.clock()
		if agora - (self.ultimoAjuste[player] or 0) < 0.05 then return end
		self.ultimoAjuste[player] = agora
		self.valvula = math.clamp(msg.valor, 0, 1)
	elseif msg.acao == "Esfera" and type(msg.i) == "number" then
		local i = msg.i
		if i ~= math.floor(i) or i < 1 or i > self.cfg.TotalEsferas or self.esferas[i] then return end
		-- arrastar uma esfera leva tempo: no máximo uma trava a cada 0,6 s
		local agora = os.clock()
		if agora - (self.ultimaEsfera or 0) < 0.6 then return end
		self.ultimaEsfera = agora
		if not self:naZonaVerde() then
			self.s:aviso(player, Missoes.Textos.ForaZonaVerde)
			self.s:efeito("EsferaEscorregou", { i = i })
			return
		end
		self.esferas[i] = true
		self.s:marcar()
		local n = 0
		for _ in self.esferas do n += 1 end
		if n >= self.cfg.TotalEsferas then
			-- "clack": módulos travam lá fora
			self.s:efeito("Acoplado", {})
			local alvo = self.encaixe.CFrame
			local inicio = self.zarya:GetPivot()
			local v = Instance.new("NumberValue")
			v.Changed:Connect(function(a)
				if self.zarya.Parent then self.zarya:PivotTo(inicio:Lerp(alvo, a)) end
			end)
			local tw = TweenService:Create(v, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Value = 1 })
			tw.Completed:Connect(function() v:Destroy() end)
			tw:Play()
			self.s:concluirTask()
		end
	end
end

function Acoplamento:tick(dt)
	-- deriva aleatória: obriga quem cuida do slider a reajustar sempre
	self.trocaDeriva -= dt
	if self.trocaDeriva <= 0 then
		self.trocaDeriva = 1.2 + math.random() * 1.3
		self.alvoDeriva = (math.random() * 2 - 1) * self.cfg.Perturbacao + 0.12 -- puxa um pouco para cima
	end
	self.deriva += (self.alvoDeriva - self.deriva) * math.min(1, dt * 1.5)
	local alvo = math.clamp(self.valvula + self.deriva, 0, 1)
	self.pressao += (alvo - self.pressao) * math.min(1, dt * self.cfg.RespostaPressao)
	self.pressao = math.clamp(self.pressao, 0, 1)

	if self.pressao >= self.cfg.PressaoMaxima then
		self.tempoNoMax += dt
		if self.tempoNoMax >= self.cfg.TempoPressaoMaxFalha then
			self.s:falhar("PressaoMaximaAcoplamento")
			return
		end
	else
		self.tempoNoMax = 0
	end
	if self.s:tempoTask() > self.cfg.LimiteTempo then self.s:falhar("Tempo") end
end

function Acoplamento:estado()
	return {
		pressao = self.pressao,
		valvula = self.valvula,
		zonaMin = self.zonaMin,
		zonaMax = self.zonaMax,
		esferas = (function()
			local a = {}
			for i = 1, self.cfg.TotalEsferas do a[i] = self.esferas[i] == true end
			return a
		end)(),
		noMax = self.tempoNoMax,
	}
end

function Acoplamento:limpar()
	desconectar(self)
	local p = self.console:FindFirstChild("RookieTaskPrompt", true)
	if p then p:Destroy() end
end

---------------------------------------------------------------------------------
-- Task 2 · EVA (painel solar preso)
---------------------------------------------------------------------------------

local EVA = {}
EVA.__index = EVA

function EVA.new(sessao, n)
	local self = setmetatable(base(sessao, n), EVA)
	self.hatch = Naves.peca(self.nave, "Airlock/InnerHatch")
	self.evaStart = Naves.peca(self.nave, "Airlock/EvaStart")
	self.evaReturn = Naves.peca(self.nave, "Airlock/EvaReturn")
	self.limites = Naves.peca(self.nave, "Exterior/EvaBounds")
	self.cabos = Naves.numerados(Naves.peca(self.nave, "Exterior/Cables"), "Cable")
	self.polias = Naves.numerados(Naves.peca(self.nave, "Exterior/Pulleys"), "Pulley")
	local mult = sessao:temItem("LuvasAderentes") and sessao.missao.Equipamentos.LuvasAderentes.MultiplicadorVelocidade or 1
	self.velMax = self.cfg.VelocidadeMaxCabo * mult
	self.origem = {}
	for i, c in self.cabos do self.origem[i] = c.CFrame end
	self.carregando = {} -- [i] = player
	self.rapido = {} -- [i] = segundos acima do limite
	self.presos = {} -- [i] = true
	self.prompts = {}
	return self
end

function EVA:iniciar()
	local pr = Naves.prompt(self.hatch, "Start EVA", "Airlock")
	table.insert(self.prompts, pr)
	table.insert(self.conexoes, pr.Triggered:Connect(function(p)
		if not self.s:perto(p, self.hatch) or p:GetAttribute("RookieEVA") then return end
		p:SetAttribute("RookieEVA", true)
		task.spawn(Naves.teleportar, p, self.evaStart.CFrame)
	end))
	for i, cabo in self.cabos do
		cabo.CFrame = self.origem[i]
		local pc = Naves.prompt(cabo, "Grab cable", "Cable " .. i, { distancia = 9 })
		table.insert(self.prompts, pc)
		table.insert(self.conexoes, pc.Triggered:Connect(function(p)
			if self.presos[i] or self.carregando[i] or not p:GetAttribute("RookieEVA") or not self.s:perto(p, cabo, 10) then return end
			for _, outro in self.carregando do
				if outro == p then return end -- um cabo por vez
			end
			self.s:aviso(p, "Cable " .. i .. " secured. Follow the arrow to the matching pulley; move slowly.")
			self.carregando[i] = p
			self.rapido[i] = 0
			pc.Enabled = false
			self.s:marcar()
		end))
		self.prompts["cabo" .. i] = pc
	end
end

function EVA:limiteTempo()
	return self.cfg.LimiteTempo
end

function EVA:acao(player, msg)
	-- o jogador pode voltar para dentro antes do fim
	if msg.acao == "VoltarEVA" and player:GetAttribute("RookieEVA") then
		self:soltarDo(player)
		player:SetAttribute("RookieEVA", nil)
		task.spawn(Naves.teleportar, player, self.evaReturn.CFrame)
	end
end

function EVA:devolver(i)
	self.carregando[i] = nil
	self.rapido[i] = 0
	self.cabos[i].CFrame = self.origem[i]
	local pc = self.prompts["cabo" .. i]
	if pc then pc.Enabled = true end
	self.s:marcar()
end

function EVA:soltarDo(player)
	for i, p in self.carregando do
		if p == player then self:devolver(i) end
	end
end

function EVA:tick(dt)
	for _, p in self.s.tripulacao do
		if p:GetAttribute("RookieEVA") then
			-- cabo de segurança: não sair da área de EVA
			local root = Naves.raiz(p)
			if root and not Naves.dentro(self.limites, root.Position, 4) then
				local local_ = self.limites.CFrame:PointToObjectSpace(root.Position)
				local meia = self.limites.Size / 2
				local preso = Vector3.new(
					math.clamp(local_.X, -meia.X, meia.X),
					math.clamp(local_.Y, -meia.Y, meia.Y),
					math.clamp(local_.Z, -meia.Z, meia.Z)
				)
				p.Character:PivotTo(CFrame.new(self.limites.CFrame:PointToWorldSpace(preso)) * root.CFrame.Rotation)
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
	for i, p in self.carregando do
		local root = Naves.raiz(p)
		if not root or not p:GetAttribute("RookieEVA") or not self.s:membro(p) then
			self:devolver(i)
		else
			local cabo = self.cabos[i]
			cabo.CFrame = root.CFrame * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.rad(90), 0)
			if root.AssemblyLinearVelocity.Magnitude > self.velMax then
				self.rapido[i] += dt
				if self.rapido[i] >= self.cfg.ToleranciaEscorregar then
					self.s:aviso(p, Missoes.Textos.EscorregouCabo)
					self.s:efeito("CaboEscorregou", { i = i })
					self:devolver(i)
				end
			else
				self.rapido[i] = 0
			end
			local polia = self.polias[i]
			if self.carregando[i] and polia and (cabo.Position - polia.Position).Magnitude <= self.cfg.DistanciaPolia then
				self.carregando[i] = nil
				self.presos[i] = true
				cabo.CFrame = polia.CFrame
				self.s:efeito("CaboPreso", { i = i })
				self.s:marcar()
			end
		end
	end
	local n = 0
	for _ in self.presos do n += 1 end
	if n >= self.cfg.TotalCabos then
		self.s:concluirTask()
	elseif self.s:tempoTask() > self.cfg.LimiteTempo then
		self.s:falhar("Tempo")
	end
end

function EVA:jogadorSaiu(player)
	self:soltarDo(player)
end

function EVA:estado()
	local carregando = {}
	for i, p in self.carregando do carregando[tostring(i)] = p.UserId end
	local presos = {}
	for i = 1, self.cfg.TotalCabos do presos[i] = self.presos[i] == true end
	return { presos = presos, carregando = carregando, velMax = self.velMax, velEVA = self.cfg.VelocidadeEVA }
end

function EVA:limpar()
	desconectar(self)
	for _, pr in self.prompts do pr:Destroy() end
	table.clear(self.prompts)
	-- todos de volta para dentro; cabos no lugar para a próxima tentativa
	local volta = self.evaReturn.CFrame
	local bounds = self.s.bounds
	for _, p in self.s.tripulacao do
		if p:GetAttribute("RookieEVA") then
			p:SetAttribute("RookieEVA", nil)
			task.spawn(function()
				Naves.teleportar(p, volta, function() return self.s.ctx.emMissao[p] == self.s end)
				-- o personagem é do cliente: se a física dele desfez o teleporte, tenta de novo
				for _ = 1, 3 do
					task.wait(0.6)
					local root = Naves.raiz(p)
					if self.s.ctx.emMissao[p] ~= self.s or not root or Naves.dentro(bounds, root.Position, 2) then break end
					Naves.teleportar(p, volta, function() return self.s.ctx.emMissao[p] == self.s end)
				end
			end)
		end
	end
	for i, c in self.cabos do c.CFrame = self.origem[i] end
	table.clear(self.carregando)
end

---------------------------------------------------------------------------------
-- Task 3 · Vazamento de 2 mm
---------------------------------------------------------------------------------

local Vazamento = {}
Vazamento.__index = Vazamento

local portaAberta = {} -- [nave] = CFrame da porta no build

function Vazamento.new(sessao, n)
	local self = setmetatable(base(sessao, n), Vazamento)
	self.hatch = Naves.peca(self.nave, "Stations/AdjacentHatch")
	self.porta = Naves.peca(self.hatch, "Door")
	self.portaFechada = Naves.peca(self.hatch, "DoorClosedPose")
	self.toolbox = Naves.peca(self.nave, "Stations/Toolbox")
	self.furos = Naves.numerados(Naves.peca(self.nave, "LeakSpots"), "Spot")
	portaAberta[self.nave] = portaAberta[self.nave] or self.porta.CFrame
	self.kit = sessao:temItem("KitVedacao")
	local eq = sessao.missao.Equipamentos.KitVedacao
	self.taxa = self.cfg.TaxaPerdaArBase * (self.kit and eq.ReducaoPerdaAr or 1)
	self.segurar = self.kit and eq.TempoSegurar or self.cfg.TempoBaseSegurar
	self.pressao = 100
	self.fechada = false
	self.prompts = {}
	return self
end

local function emissores(peca, ligado)
	for _, e in peca:GetDescendants() do
		if e:IsA("ParticleEmitter") then e.Enabled = ligado end
	end
end

function Vazamento:iniciar()
	self.porta.CFrame = portaAberta[self.nave]
	for _, p in self.s.tripulacao do p:SetAttribute("RookieGaze", nil) end
	self.furo = math.random(1, #self.furos)
	local furo = self.furos[self.furo]
	emissores(furo, true)

	local ph = Naves.prompt(Naves.peca(self.hatch, "Prompt"), "Close hatch", "Next module")
	table.insert(self.prompts, ph)
	table.insert(self.conexoes, ph.Triggered:Connect(function(p)
		if self.fechada or not self.s:perto(p, ph.Parent) then return end
		self.fechada = true
		ph.Enabled = false
		TweenService:Create(self.porta, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = self.portaFechada.CFrame }):Play()
		self.s:efeito("EscotilhaFechada", {})
		self.s:marcar()
	end))

	local pt = Naves.prompt(self.toolbox, "Take epoxy gauze", "Toolbox")
	table.insert(self.prompts, pt)
	table.insert(self.conexoes, pt.Triggered:Connect(function(p)
		if not self.s:perto(p, self.toolbox) then return end
		p:SetAttribute("RookieGaze", true)
		self.s:aviso(p, "Epoxy gauze ready. Follow the arrow to the leak and hold F to seal it.")
		self.s:marcar()
	end))

	-- tecla F: a caixa de ferramentas (E) pode ficar perto do furo
	local pf = Naves.prompt(furo, "Seal leak", "2 mm hole", { segurar = self.segurar, distancia = 8, tecla = Enum.KeyCode.F })
	table.insert(self.prompts, pf)
	-- o servidor mede o próprio hold (o cliente poderia encurtar o HoldDuration)
	self.inicioHold = {}
	table.insert(self.conexoes, pf.PromptButtonHoldBegan:Connect(function(p)
		if self.s:perto(p, furo, 8) then self.inicioHold[p] = { elapsed = 0, ended = nil } end
	end))
	table.insert(self.conexoes, pf.PromptButtonHoldEnded:Connect(function(p)
		local hold = self.inicioHold[p]
		if hold then hold.ended = os.clock() end
	end))
	-- não limpar em PromptButtonHoldEnded: no servidor ele chega ANTES do Triggered (testado
	-- no Studio); um novo HoldBegan já reinicia a contagem se o jogador soltar e apertar de novo
	table.insert(self.conexoes, pf.Triggered:Connect(function(p)
		local inicio = self.inicioHold[p]
		self.inicioHold[p] = nil
		if not inicio or inicio.elapsed < self.segurar - 0.2 or (inicio.ended and os.clock() - inicio.ended > 0.3) then return end
		if not self.s:perto(p, furo) then return end
		if not self.fechada then
			self.s:aviso(p, Missoes.Textos.FecheEscotilha)
		elseif not p:GetAttribute("RookieGaze") then
			self.s:aviso(p, Missoes.Textos.PrecisaGaze)
		else
			self.s:efeito("FuroVedado", {})
			self.s:concluirTask()
		end
	end))
end

function Vazamento:limiteTempo()
	return nil -- falha pela pressão, não por tempo
end

function Vazamento:acao() end

function Vazamento:tick(dt)
	for p, hold in self.inicioHold or {} do
		if not self.s:perto(p, self.furos[self.furo], 8) or (hold.ended and os.clock() - hold.ended > 0.3) then
			self.inicioHold[p] = nil
		elseif not hold.ended then hold.elapsed += dt end
	end
	local taxa = self.taxa * (self.fechada and self.cfg.MultiplicadorEscotilhaFechada or 1)
	self.pressao = math.max(0, self.pressao - taxa * dt)
	if self.pressao <= 0 then self.s:falhar("Tempo") end
end

function Vazamento:estado()
	return { pressao = self.pressao, fechada = self.fechada, taxa = self.taxa, segurar = self.segurar, furo = self.furo }
end

function Vazamento:limpar()
	desconectar(self)
	for _, pr in self.prompts do pr:Destroy() end
	table.clear(self.prompts)
	for _, f in self.furos do emissores(f, false) end
	self.porta.CFrame = portaAberta[self.nave]
	for _, p in self.s.tripulacao do p:SetAttribute("RookieGaze", nil) end
end

Tasks.Acoplamento = Acoplamento
Tasks.EVA = EVA
Tasks.Vazamento = Vazamento
return Tasks
