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
	self.boardingPoints = {}
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
	Naves.prompt(Naves.peca(nave, "Stations/PrepConsole"), "Flight manifest confirmed", self.missao.Nome, { ligado = false })
	self.promptSaida = Naves.prompt(Naves.peca(nave, "Stations/Exit"), Missoes.Textos.Sair, self.missao.Nome)
	self.promptSaida.Triggered:Connect(function(p)
		if self:perto(p, self.promptSaida.Parent, 8) and self:podeSair() then self:sair(p, true) end
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
	return self.fase ~= "Livre"
end

function Sessao:lider()
	return self.tripulacao[1]
end

function Sessao:nome(player)
	player = player or self:lider()
	return player and player.DisplayName or "crew"
end

-- Ana: manifesto validado na plataforma antes do teleporte.
function Sessao:embarcar(player, manifest)
	if player:GetAttribute("SuitOn") ~= true or not (player.Character and player.Character:FindFirstChild("SpaceSuit")) then
		return false, "Put on your space suit before boarding."
	end
	local selected = {}
	if manifest ~= nil then
		if type(manifest) ~= "table" then return false, "Invalid flight manifest." end
		local count = 0
		for key, value in manifest do
			if type(key) ~= "string" or value ~= true or not self.missao.Equipamentos[key] then return false, "Invalid equipment." end
			selected[key] = true
			count += 1
		end
		local weight = Missoes.pesoTotal(self.missao, selected)
		if weight > REGRAS.LimiteFoguete then
			return false, Missoes.formatar(Missoes.FalasMarcos.ExcessoPeso, { name = player.DisplayName, weight = weight })
		end
		if count > 2 then return false, "Choose up to two items for the shared 60 kg payload." end
		if self.fase ~= "Livre" then
			local names = {}
			for _, key in self.missao.OrdemEquipamentos do
				if self.itens[key] then table.insert(names, self.missao.Equipamentos[key].Nome) end
			end
			local shared = "Match the crew payload: " .. (#names > 0 and table.concat(names, " + ") or "no equipment") .. " (" .. self:peso() .. "/60 kg)."
			for key in self.itens do if not selected[key] then return false, shared end end
			for key in selected do if not self.itens[key] then return false, shared end end
		end
	end
	if self.ctx.emMissao[player] then return false, Missoes.Textos.JaEmMissao end
	if self.fase ~= "Livre" and self.fase ~= "Preparacao" and not (manifest and self.fase == "Lancamento" and os.clock() < self.fimLancamento - 1) then return false, Missoes.Textos.MissaoEmAndamento end
	if #self.tripulacao >= REGRAS.MaxJogadoresPorNave then return false, Missoes.Textos.NaveCheia end
	local boardingRoot = Naves.raiz(player)
	if not Naves.vivo(player) or not boardingRoot then return false, nil end
	self.boardingPoints[player] = boardingRoot.CFrame
	table.insert(self.tripulacao, player)
	self.ctx.emMissao[player] = self
	player:SetAttribute("RookieMission", self.id)
	if self.fase == "Livre" then
		self.fase = "Preparacao"
		self.itens = selected
		self.preflight = manifest ~= nil
	end
	local spawn = self.spawns[#self.tripulacao] or self.spawns[1]
	local lugar = #self.tripulacao
	task.spawn(function()
		if not Naves.teleportar(player, spawn.CFrame, function() return self.ctx.emMissao[player] == self end) then
			self:sair(player, false)
			return
		end
		-- entra já sentado num assento livre da cápsula (o da sua vez na tripulação, se livre)
		self:sentar(player, lugar)
		if self.preflight and self.fase == "Preparacao" then
			self:lancar(player)
		end
	end)
	self:sync()
	return true
end

-- senta o jogador num assento livre da nave (Seats/Seat_N/Seat, Fase 19); naves sem assentos: nada
function Sessao:sentar(player, preferido)
	local pasta = self.nave:FindFirstChild("Seats")
	if not pasta then return end
	local lista = {}
	for _, g in pasta:GetChildren() do
		local seat = g:FindFirstChild("Seat")
		if seat and seat:IsA("Seat") then table.insert(lista, seat) end
	end
	table.sort(lista, function(a, b) return (a:GetAttribute("SeatNumber") or 0) < (b:GetAttribute("SeatNumber") or 0) end)
	local escolhido
	local p = lista[preferido or 1]
	if p and not p.Occupant then escolhido = p end
	if not escolhido then
		for _, seat in lista do
			if not seat.Occupant then escolhido = seat break end
		end
	end
	if not escolhido then return end
	task.wait(0.15) -- deixa o personagem assentar depois do teleporte
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and self.ctx.emMissao[player] == self and not escolhido.Occupant then
		escolhido:Sit(hum)
	end
end

-- sai da sessão; teleporta de volta ao LCC se pedido
function Sessao:sair(player, voltar)
	local i = table.find(self.tripulacao, player)
	if not i then return end
	table.remove(self.tripulacao, i)
	self.ctx.emMissao[player] = nil
	self.boardingPoints[player] = nil
	player:SetAttribute("RookieMission", nil)
	if self.handler and self.handler.jogadorSaiu then self.handler:jogadorSaiu(player) end
	player:SetAttribute("RookieEVA", nil)
	player:SetAttribute("RookieGaze", nil)
	self.remotes.SincronizarEstado:FireClient(player, { tipo = "Saiu" })
	if voltar and self.ctx.retorno then
		task.spawn(Naves.teleportar, player, self.ctx.retorno, function() return self.ctx.emMissao[player] == nil end)
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
	if self.preflight or self.fase ~= "Preparacao" or not self:membro(player) then return end
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
	for _, crew in self.tripulacao do
		if crew:GetAttribute("SuitOn") ~= true or not (crew.Character and crew.Character:FindFirstChild("SpaceSuit")) then
			self:aviso(player, "Every astronaut must wear a space suit.")
			return
		end
	end
	local count = 0
	for _ in self.itens do count += 1 end
	local peso = self:peso()
	if peso > REGRAS.LimiteFoguete then
		-- erro didático: o foguete nem sai da plataforma
		self:falhar("ExcessoPeso", { name = self:nome(player), weight = peso }, false)
		return
	end
	if count > 2 then self:aviso(player, "Choose up to two items.") return end
	self.bonus = Missoes.bonusLeveza(peso)
	self.tempos = {}
	self.resultado = nil
	self.fase = "Lancamento"
	if self.id == 2 then
		local hatch = Naves.talvez(self.nave, "Capsule/DockingHatch")
		if hatch then hatch.CanCollide = true hatch.Transparency = 0 end
		local collar = Naves.talvez(self.nave, "Capsule/DockingCollar")
		if collar then
			local final = collar:GetAttribute("DockedPose")
			collar.CFrame = final * CFrame.new(3, 0, 0)
			game:GetService("TweenService"):Create(collar, TweenInfo.new(REGRAS.SegundosLancamento), { CFrame = final }):Play()
		end
	end
	self.fimLancamento = os.clock() + math.max(12, REGRAS.SegundosLancamento)
	self.fimLancamentoServidor = workspace:GetServerTimeNow() + math.max(12, REGRAS.SegundosLancamento)
	self:efeito("Lancamento", { duracao = math.max(12, REGRAS.SegundosLancamento) })
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
	if self.id == 2 then
		local hatch = Naves.talvez(self.nave, "Capsule/DockingHatch")
		if hatch then hatch.CanCollide = false hatch.Transparency = 1 end
	end
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
	-- segundos inteiros arredondados para cima: a equação na tela bate com a conta e nunca
	-- dá mais estrelas do que o tempo real merece
	for i = 1, 3 do t[i] = math.ceil((self.tempos[i] or 0) - 0.001) end
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
	if estrelas == 0 then
		-- "Took too long" é falha: modal do guia com Retry task (Task 3) e Restart mission
		self.falha = {
			chave = "DemorouDemais",
			texto = fala,
			podeRepetir = true,
			task = #self.missao.Tasks,
			equacao = self.resultado.equacao,
		}
		self.resultado = nil
		self.fase = "Falha"
		self:efeito("Falha", { chave = "DemorouDemais" })
		self:sync()
		return
	end
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
		local crew = table.clone(self.tripulacao)
		for _, p in crew do
			local returnTo = self.boardingPoints[p] or self.ctx.retorno
			self:sair(p, false)
			task.spawn(function()
				if returnTo then Naves.teleportar(p, returnTo - Vector3.new(0, 3, 0), function() return self.ctx.emMissao[p] == nil end) end
				local guides = RS:FindFirstChild("GuideSystem")
				local remote = guides and guides:FindFirstChild("Remotes") and guides.Remotes:FindFirstChild("MissionSelect")
				if remote then
					local profile = self.ctx.dados.perfil(p)
					remote:FireClient(p, { kind = "Open", issLocked = (profile.estrelas["1"] or 0) < 1 })
				end
			end)
		end
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
	for i, t in self.tempos do tempos[i] = math.ceil(t - 0.001) end
	local limite = nil
	if self.handler and self.handler.limiteTempo then limite = self.handler:limiteTempo() end
	return {
		tipo = "Estado",
		missao = self.id,
		preflight = self.preflight == true,
		fimLancamento = self.fimLancamentoServidor,
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
