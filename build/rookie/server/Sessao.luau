--[[
	Sessao — uma nave = uma sessão (1 a 4 jogadores). Máquina de estados da spec §2.1:

	  Livre → Preparacao → Lancamento → Task (1..3) → Resultado
	                 ↑           │            │
	                 └── Falha ←─┴────────────┘   (Falha: "Retry task" ou "Restart mission")

	Autoridade total aqui: peso, cronômetros (os.clock), estrelas. O cliente só manda intenções.
	Cada task é um módulo com new(sessao, n) → { iniciar, tick(dt), acao(player, msg), estado(), limpar }.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))
local Naves = require(script.Parent.Naves)

local REGRAS = Missoes.RegrasGerais
local SYNC_TASK = 0.1 -- s entre sincronizações durante uma task

local Sessao = {}
Sessao.__index = Sessao

--[[
	ctx = { remotes, dados (DataStoreManager), tasks = { [n] = moduloTask }, retorno = CFrame, emMissao = {} }
]]
function Sessao.new(missaoId, nave, ctx)
	local self = setmetatable({}, Sessao)
	self.id = missaoId
	self.missao = Missoes.Lista[missaoId]
	self.nave = nave
	self.ctx = ctx
	self.remotes = ctx.remotes
	self.bounds = Naves.peca(nave, "Bounds")
	self.spawns = Naves.numerados(Naves.peca(nave, "Spawns"), "Spawn")
	self.tripulacao = {} -- lista de Players, em ordem de embarque
	self.itens = {}
	self.fase = "Livre"
	self.taskAtual = 0
	self.tempos = {} -- segundos (float) de cada task concluída
	self.handler = nil
	self.falha = nil
	self.resultado = nil
	self.ultimoSync = 0
	self.sujo = false

	-- prompts fixos da nave
	Naves.prompt(Naves.peca(nave, "Stations/PrepConsole"), "Mission prep", self.missao.Nome, { painel = "Preparacao" })
	self.promptSaida = Naves.prompt(Naves.peca(nave, "Stations/Exit"), Missoes.Textos.Sair, self.missao.Nome)
	self.promptSaida.Triggered:Connect(function(p)
		if self:membro(p) and self:podeSair() then self:sair(p, true) end
	end)
	return self
end

---------------------------------------------------------------------------------
-- Tripulação
---------------------------------------------------------------------------------

function Sessao:membro(player)
	return table.find(self.tripulacao, player) ~= nil
end

function Sessao:aBordo(player)
	local root = Naves.raiz(player)
	return root ~= nil and self:membro(player) and Naves.dentro(self.bounds, root.Position, 2)
end

-- pode agir numa estação? (membro, vivo, a bordo e perto da peça)
function Sessao:perto(player, peca, dist)
	return self:membro(player)
		and Naves.vivo(player)
		and Naves.distancia(player, peca) <= (dist or REGRAS.DistanciaAcao)
end

function Sessao:podeSair()
	return self.fase == "Preparacao" or self.fase == "Resultado" or self.fase == "Falha"
end

function Sessao:lider()
	return self.tripulacao[1]
end

function Sessao:nome(player)
	player = player or self:lider()
	return player and player.DisplayName or "crew"
end

-- quiosque: embarcar
function Sessao:embarcar(player)
	if self.ctx.emMissao[player] then return false, Missoes.Textos.JaEmMissao end
	if self.fase ~= "Livre" and self.fase ~= "Preparacao" then return false, Missoes.Textos.MissaoEmAndamento end
	if #self.tripulacao >= REGRAS.MaxJogadoresPorNave then return false, Missoes.Textos.NaveCheia end
	if not Naves.vivo(player) then return false, nil end
	table.insert(self.tripulacao, player)
	self.ctx.emMissao[player] = self
	if self.fase == "Livre" then
		self.fase = "Preparacao"
		self.itens = {}
	end
	local spawn = self.spawns[#self.tripulacao] or self.spawns[1]
	task.spawn(function()
		if not Naves.teleportar(player, spawn.CFrame) then self:sair(player, false) end
	end)
	self:sync()
	return true
end

-- sai da sessão; teleporta de volta ao LCC se pedido
function Sessao:sair(player, voltar)
	local i = table.find(self.tripulacao, player)
	if not i then return end
	table.remove(self.tripulacao, i)
	self.ctx.emMissao[player] = nil
	if self.handler and self.handler.jogadorSaiu then self.handler:jogadorSaiu(player) end
	player:SetAttribute("RookieEVA", nil)
	player:SetAttribute("RookieGaze", nil)
	self.remotes.SincronizarEstado:FireClient(player, { tipo = "Saiu" })
	if voltar and self.ctx.retorno then
		task.spawn(Naves.teleportar, player, self.ctx.retorno)
	end
	if #self.tripulacao == 0 then
		self:resetar()
	else
		self:sync()
	end
end

-- nave vazia: volta ao estado inicial
function Sessao:resetar()
	self:pararTask()
	self.fase = "Livre"
	self.itens = {}
	self.tempos = {}
	self.taskAtual = 0
	self.falha = nil
	self.resultado = nil
	self:sync()
end

---------------------------------------------------------------------------------
-- Preparação e lançamento
---------------------------------------------------------------------------------

function Sessao:selecionar(player, chave, ligado)
	if self.fase ~= "Preparacao" or not self:membro(player) then return end
	if type(chave) ~= "string" or not self.missao.Equipamentos[chave] then return end -- só itens desta missão
	self.itens[chave] = ligado == true or nil
	self:sync()
end

function Sessao:peso()
	return Missoes.pesoTotal(self.missao, self.itens)
end

function Sessao:temItem(chave)
	return self.itens[chave] == true
end

function Sessao:lancar(player)
	if self.fase ~= "Preparacao" or not self:membro(player) then return end
	local peso = self:peso()
	if peso > REGRAS.LimiteFoguete then
		-- erro didático: o foguete nem sai da plataforma
		self:falhar("ExcessoPeso", { name = self:nome(player), weight = peso }, false)
		return
	end
	self.bonus = Missoes.bonusLeveza(peso)
	self.tempos = {}
	self.resultado = nil
	self.fase = "Lancamento"
	self.fimLancamento = os.clock() + REGRAS.SegundosLancamento
	self:efeito("Lancamento", { duracao = REGRAS.SegundosLancamento })
	self:sync()
end

---------------------------------------------------------------------------------
-- Tasks
---------------------------------------------------------------------------------

function Sessao:pararTask()
	if self.handler then
		local h = self.handler
		self.handler = nil
		local ok, err = pcall(h.limpar, h)
		if not ok then warn("[RookieRocket] limpar task:", err) end
	end
end

function Sessao:iniciarTask(n)
	self:pararTask()
	self.taskAtual = n
	self.fase = "Task"
	self.falha = nil
	local cfg = self.missao.Tasks[n]
	local modulo = self.ctx.tasks[cfg.Tipo]
	self.handler = modulo.new(self, n)
	self.inicioTask = os.clock()
	self.inicioTaskServidor = workspace:GetServerTimeNow()
	self.handler:iniciar()
	self:efeito("TaskInicio", { task = n })
	self:sync()
end

function Sessao:tempoTask()
	if self.fase ~= "Task" then return 0 end
	return os.clock() - self.inicioTask
end

-- chamada pelo módulo da task quando o objetivo é cumprido
function Sessao:concluirTask()
	if self.fase ~= "Task" then return end
	local n = self.taskAtual
	self.tempos[n] = os.clock() - self.inicioTask
	self:pararTask()
	self:efeito("TaskConcluida", { task = n })
	if n < #self.missao.Tasks then
		self:iniciarTask(n + 1)
	else
		self:finalizar()
	end
end

--[[
	Falha: chave de Missoes.FalasMarcos (ou "Tempo" → com/sem o item da task).
	podeRepetir = false só no excesso de peso (não há task para repetir).
]]
function Sessao:falhar(chave, valores, podeRepetir)
	if self.fase ~= "Task" and self.fase ~= "Preparacao" then return end
	valores = valores or {}
	valores.name = valores.name or self:nome()
	if chave == "Tempo" then
		local itemChave, eq = Missoes.itemDaTask(self.missao, self.taskAtual)
		valores.equipment = eq and eq.Nome or "equipment"
		chave = (itemChave and self:temItem(itemChave)) and "FaltaTempoComItem" or "FaltaTempoSemItem"
	end
	self:pararTask()
	self.falha = {
		chave = chave,
		texto = Missoes.formatar(Missoes.FalasMarcos[chave] or chave, valores),
		podeRepetir = podeRepetir ~= false,
		task = self.taskAtual,
	}
	self.fase = "Falha"
	self:efeito("Falha", { chave = chave })
	self:sync()
end

function Sessao:finalizar()
	local t = {}
	for i = 1, 3 do t[i] = math.floor((self.tempos[i] or 0) + 0.5) end
	local total, estrelas = Missoes.resultado(t[1], t[2], t[3], self.bonus or 0)
	local fala
	if estrelas > 0 then
		fala = Missoes.FalasMarcos.Sucesso
	else
		fala = Missoes.formatar(Missoes.FalasMarcos.DemorouDemais, { name = self:nome(), total = total })
	end
	self.resultado = {
		t = t,
		bonus = self.bonus or 0,
		total = total,
		estrelas = estrelas,
		equacao = Missoes.equacao(t[1], t[2], t[3], self.bonus or 0, total, estrelas),
		fala = fala,
		card = estrelas > 0 and self.missao.Card or nil,
		medalha = Missoes.Textos.Medalhas[estrelas],
	}
	self.fase = "Resultado"
	self.taskAtual = 0
	for _, p in self.tripulacao do
		if estrelas > 0 then self.ctx.dados.registrar(p, self.id, estrelas, self.missao.Card) end
	end
	self:efeito("Resultado", { estrelas = estrelas })
	self:sync()
end

-- botões do modal de falha e da tela de resultado
function Sessao:reiniciar(player, modo)
	if not self:membro(player) then return end
	if modo == "Task" and self.fase == "Falha" and self.falha and self.falha.podeRepetir then
		-- zera só o cronômetro da task atual; itens e tempos anteriores ficam
		self:iniciarTask(self.falha.task)
	elseif modo == "Missao" and (self.fase == "Falha" or self.fase == "Resultado") then
		self:pararTask()
		self.fase = "Preparacao"
		self.taskAtual = 0
		self.tempos = {}
		self.falha = nil
		self.resultado = nil
		self:voltarAosSpawns()
		self:sync()
	elseif modo == "Sair" and self:podeSair() then
		self:sair(player, true)
	end
end

function Sessao:voltarAosSpawns()
	for i, p in self.tripulacao do
		p:SetAttribute("RookieEVA", nil)
		p:SetAttribute("RookieGaze", nil)
		local s = self.spawns[i] or self.spawns[1]
		task.spawn(Naves.teleportar, p, s.CFrame)
	end
end

function Sessao:acao(player, msg)
	if self.fase ~= "Task" or not self.handler or not self:membro(player) then return end
	if type(msg) ~= "table" or type(msg.acao) ~= "string" then return end
	self.handler:acao(player, msg)
end

---------------------------------------------------------------------------------
-- Laço e sincronização
---------------------------------------------------------------------------------

function Sessao:tick(dt)
	-- jogador que caiu fora da nave (ou morreu) sai da sessão
	for i = #self.tripulacao, 1, -1 do
		local p = self.tripulacao[i]
		if p.Parent ~= Players or not Naves.vivo(p) then self:sair(p, false) end
	end
	if self.fase == "Lancamento" and os.clock() >= self.fimLancamento then
		self:iniciarTask(1)
	elseif self.fase == "Task" and self.handler then
		local ok, err = pcall(self.handler.tick, self.handler, dt)
		if not ok then warn("[RookieRocket] task tick:", err) end
		if self.fase == "Task" and os.clock() - self.ultimoSync >= SYNC_TASK then self:sync() end
	end
	if self.sujo then self:sync() end
end

-- pedido de sincronização no próximo tick (para várias mudanças no mesmo frame)
function Sessao:marcar()
	self.sujo = true
end

function Sessao:estado()
	local tripulantes = {}
	for _, p in self.tripulacao do
		table.insert(tripulantes, { id = p.UserId, nome = p.DisplayName })
	end
	local itens = {}
	for k, v in self.itens do
		if v then itens[k] = true end
	end
	local tempos = {}
	for i, t in self.tempos do tempos[i] = math.floor(t + 0.5) end
	local limite = nil
	if self.handler and self.handler.limiteTempo then limite = self.handler:limiteTempo() end
	return {
		tipo = "Estado",
		missao = self.id,
		fase = self.fase,
		tripulacao = tripulantes,
		itens = itens,
		peso = self:peso(),
		bonus = Missoes.bonusLeveza(self:peso()),
		task = self.taskAtual,
		inicioTask = self.inicioTaskServidor,
		limite = limite,
		tempos = tempos,
		dados = self.handler and self.handler:estado() or nil,
		falha = self.falha,
		resultado = self.resultado,
	}
end

function Sessao:sync()
	self.sujo = false
	self.ultimoSync = os.clock()
	local e = self:estado()
	for _, p in self.tripulacao do
		self.remotes.SincronizarEstado:FireClient(p, e)
	end
	if self.ctx.aoMudar then self.ctx.aoMudar(self) end
end

function Sessao:aviso(player, texto)
	self.remotes.SincronizarEstado:FireClient(player, { tipo = "Aviso", texto = texto })
end

-- efeito visual/sonoro pontual para toda a tripulação
function Sessao:efeito(nome, dados)
	local msg = { tipo = "Efeito", nome = nome, dados = dados or {}, missao = self.id }
	for _, p in self.tripulacao do
		self.remotes.SincronizarEstado:FireClient(p, msg)
	end
end

return Sessao
