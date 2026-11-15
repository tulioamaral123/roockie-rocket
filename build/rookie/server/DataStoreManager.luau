--[[
	DataStoreManager — melhores estrelas por missão e cards do Álbum (spec §6).
	Chave "u_<UserId>" → { v = 1, estrelas = { ["1"] = n, ["2"] = n }, cards = { Friendship7 = true } }.
	Tudo em pcall com novas tentativas; sem acesso à API (Studio sem permissão) fica só na memória.
	Salva ao mudar (com intervalo mínimo), ao sair e no BindToClose.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local M = {}

local NOME_STORE = "RookieRocket_v1"
local store = nil
local okStore = pcall(function()
	store = DataStoreService:GetDataStore(NOME_STORE)
end)
local avisado = false

local perfis = {} -- [player] = dados
local carregado = {} -- [player] = true quando o load terminou (com ou sem sucesso)
local pendente = {} -- [player] = true se há mudança não salva
local aoAtualizar = nil -- callback(player, dados)

local function novo()
	return { v = 1, estrelas = {}, cards = {} }
end

local function tentar(f)
	for tentativa = 1, 3 do
		local ok, res = pcall(f)
		if ok then return true, res end
		if not avisado then
			avisado = true
			warn("[RookieRocket] DataStore indisponível (progresso só na memória nesta sessão):", res)
		end
		task.wait(tentativa * 1.5)
	end
	return false
end

-- normaliza dados lidos (versões futuras / dados corrompidos)
local function validar(d)
	if type(d) ~= "table" then return novo() end
	local out = novo()
	if type(d.estrelas) == "table" then
		for k, v in d.estrelas do
			if type(v) == "number" then out.estrelas[tostring(k)] = math.clamp(math.floor(v), 0, 3) end
		end
	end
	if type(d.cards) == "table" then
		for k, v in d.cards do
			if v == true and type(k) == "string" then out.cards[k] = true end
		end
	end
	return out
end

local function carregar(player)
	local dados = novo()
	if okStore and store then
		local ok, res = tentar(function()
			return store:GetAsync("u_" .. player.UserId)
		end)
		if ok then dados = validar(res) end
	end
	if player.Parent ~= Players then return end
	-- se algo foi registrado durante o load, mescla
	local atual = perfis[player]
	if atual then
		for k, v in atual.estrelas do dados.estrelas[k] = math.max(dados.estrelas[k] or 0, v) end
		for k in atual.cards do dados.cards[k] = true end
	end
	perfis[player] = dados
	carregado[player] = true
	if aoAtualizar then aoAtualizar(player, dados) end
end

local function salvar(player)
	local dados = perfis[player]
	if not dados or not carregado[player] or not okStore or not store then return end
	pendente[player] = nil
	tentar(function()
		store:UpdateAsync("u_" .. player.UserId, function(antigo)
			-- nunca perde progresso: mescla com o que já está salvo
			local d = validar(antigo)
			for k, v in dados.estrelas do d.estrelas[k] = math.max(d.estrelas[k] or 0, v) end
			for k in dados.cards do d.cards[k] = true end
			return d
		end)
	end)
end

function M.iniciar(callback)
	aoAtualizar = callback
	Players.PlayerAdded:Connect(function(p) task.spawn(carregar, p) end)
	for _, p in Players:GetPlayers() do task.spawn(carregar, p) end
	Players.PlayerRemoving:Connect(function(p)
		if pendente[p] then salvar(p) end
		perfis[p] = nil
		carregado[p] = nil
		pendente[p] = nil
	end)
	game:BindToClose(function()
		local threads = {}
		for p in pendente do
			table.insert(threads, task.spawn(salvar, p))
		end
		task.wait(2)
	end)
	-- salva o que mudou a cada 30 s
	task.spawn(function()
		while true do
			task.wait(30)
			for p in pendente do task.spawn(salvar, p) end
		end
	end)
end

function M.perfil(player)
	return perfis[player] or novo()
end

-- missão concluída: guarda a melhor nota e desbloqueia o card
function M.registrar(player, missaoId, estrelas, card)
	local d = perfis[player]
	if not d then
		d = novo()
		perfis[player] = d
	end
	local k = tostring(missaoId)
	d.estrelas[k] = math.max(d.estrelas[k] or 0, estrelas)
	if card then d.cards[card] = true end
	pendente[player] = true
	if aoAtualizar then aoAtualizar(player, d) end
	if carregado[player] then task.spawn(salvar, player) end
end

return M
