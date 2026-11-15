--[[
	GerenciadorMissao — boot do servidor do Rookie Rocket (docs/rookie-rocket-spec.md, docs/rookie-contrato.md).

	- Cria (se faltar) ReplicatedStorage.RookieRocket.Remotes.
	- Uma Sessao por nave (Mercury = missão 1, ISS = missão 2).
	- Quiosque no LCC: prompts de embarque e tela de status.
	- Repassa os remotes para a sessão do jogador. O cliente nunca envia tempo, peso nem estrelas.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = RS:WaitForChild("RookieRocket")
local Missoes = require(root:WaitForChild("Config"):WaitForChild("Missoes"))
local Naves = require(script.Parent:WaitForChild("Naves"))
local Sessao = require(script.Parent:WaitForChild("Sessao"))
local Dados = require(script.Parent:WaitForChild("DataStoreManager"))
local TasksMercury = require(script.Parent:WaitForChild("TasksMercury"))
local TasksISS = require(script.Parent:WaitForChild("TasksISS"))

local function garantir(parent, classe, nome)
	local x = parent:FindFirstChild(nome)
	if x and not x:IsA(classe) then
		x:Destroy()
		x = nil
	end
	if not x then
		x = Instance.new(classe)
		x.Name = nome
		x.Parent = parent
	end
	return x
end

local pastaRemotes = garantir(root, "Folder", "Remotes")
local remotes = {}
for _, nome in { "SelecionarEquipamento", "IniciarLancamento", "AcaoTask", "ReiniciarTaskOuMissao", "SincronizarEstado" } do
	remotes[nome] = garantir(pastaRemotes, "RemoteEvent", nome)
end

local mapa = workspace:WaitForChild("NASAComplex"):WaitForChild("RookieRocket", 30)
if not mapa then
	warn("[RookieRocket] NASAComplex.RookieRocket não existe: rode as Fases 19 e 20")
	return
end

local tasks = {}
for k, v in TasksMercury do tasks[k] = v end
for k, v in TasksISS do tasks[k] = v end

local ctx = {
	remotes = remotes,
	dados = Dados,
	tasks = tasks,
	emMissao = {}, -- [player] = sessao
	retorno = nil,
}

---------------------------------------------------------------------------------
-- Quiosque
---------------------------------------------------------------------------------

local kiosk = mapa:WaitForChild("Kiosk", 10)
local telaStatus = nil
if kiosk then
	local ret = kiosk:FindFirstChild("ReturnPoint")
	if ret then ctx.retorno = ret.CFrame end
	local tela = kiosk:FindFirstChild("Screen")
	if tela then
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RookieStatus"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 0
		gui.Brightness = 1.5
		gui.Parent = tela
		local fundo = Instance.new("Frame")
		fundo.Size = UDim2.fromScale(1, 1)
		fundo.BackgroundColor3 = Color3.fromHex("0E1A36")
		fundo.Parent = gui
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(0.9, 0.86)
		t.Position = UDim2.fromScale(0.05, 0.07)
		t.BackgroundTransparency = 1
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextScaled = true
		t.RichText = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
		t.Parent = fundo
		telaStatus = t
	end
end

local sessoes = {}

local FASES = {
	Livre = "ready to board",
	Preparacao = "crew preparing",
	Lancamento = "launching!",
	Task = "in flight",
	Falha = "in flight",
	Resultado = "landed",
}

local function atualizarTela()
	if not telaStatus then return end
	local linhas = { '<font color="#E8892E">MISSION BRIEFING</font>' }
	for _, s in sessoes do
		table.insert(linhas, ("%s\n%d/%d crew · %s"):format(s.missao.Nome, #s.tripulacao, Missoes.RegrasGerais.MaxJogadoresPorNave, FASES[s.fase] or s.fase))
	end
	telaStatus.Text = table.concat(linhas, "\n\n")
end
ctx.aoMudar = atualizarTela

---------------------------------------------------------------------------------
-- Sessões
---------------------------------------------------------------------------------

for id, m in Missoes.Lista do
	local nave = mapa:WaitForChild(m.Nave, 10)
	if nave then
		local ok, s = pcall(Sessao.new, id, nave, ctx)
		if ok then
			sessoes[id] = s
		else
			warn("[RookieRocket] nave " .. m.Nave .. ":", s)
		end
	else
		warn("[RookieRocket] nave ausente: NASAComplex.RookieRocket." .. m.Nave)
	end
end

if kiosk then
	for id, nomePeca in { [1] = "BoardMercury", [2] = "BoardISS" } do
		local peca = kiosk:FindFirstChild(nomePeca)
		local s = sessoes[id]
		if peca and s then
			-- pedestais lado a lado: teclas diferentes para os dois prompts aparecerem juntos
			local pr = Naves.prompt(peca, "Board " .. s.missao.Chave .. " mission", s.missao.Nome, {
				distancia = 9,
				tecla = id == 2 and Enum.KeyCode.F or Enum.KeyCode.E,
			})
			pr.Triggered:Connect(function(player)
				local ok, motivo = s:embarcar(player)
				if not ok and motivo then s:aviso(player, motivo) end
			end)
		end
	end
end
atualizarTela()

-- Ponte para outros sistemas do servidor (GuideSystem: a Ana embarca a equipe no topo do foguete)
-- ServerStorage.RookieBridge.Embarcar:Invoke(player, missaoId) → ok, motivo
-- ServerStorage.RookieBridge.Perfil:Invoke(player) → { estrelas = { ["1"] = n, ... } }
-- ServerStorage.RookieBridge.EmMissao:Invoke(player) → boolean
do
	local SS = game:GetService("ServerStorage")
	local ponte = garantir(SS, "Folder", "RookieBridge")
	garantir(ponte, "BindableFunction", "Embarcar").OnInvoke = function(player, id)
		local s = sessoes[id]
		if not s or typeof(player) ~= "Instance" or not player:IsA("Player") then return false, nil end
		local ok, motivo = s:embarcar(player)
		if not ok and motivo then s:aviso(player, motivo) end
		return ok, motivo
	end
	garantir(ponte, "BindableFunction", "Perfil").OnInvoke = function(player)
		return Dados.perfil(player)
	end
	garantir(ponte, "BindableFunction", "EmMissao").OnInvoke = function(player)
		return ctx.emMissao[player] ~= nil
	end
end

---------------------------------------------------------------------------------
-- Remotes (cliente → servidor), todos validados
---------------------------------------------------------------------------------

local function sessaoDe(player)
	return ctx.emMissao[player]
end

remotes.SelecionarEquipamento.OnServerEvent:Connect(function(player, chave, ligado)
	local s = sessaoDe(player)
	if s then s:selecionar(player, chave, ligado == true) end
end)

remotes.IniciarLancamento.OnServerEvent:Connect(function(player)
	local s = sessaoDe(player)
	if s then s:lancar(player) end
end)

local function enviarPerfil(player, dados)
	remotes.SincronizarEstado:FireClient(player, { tipo = "Perfil", estrelas = dados.estrelas, cards = dados.cards })
end

remotes.AcaoTask.OnServerEvent:Connect(function(player, msg)
	-- o cliente pede o próprio perfil ao iniciar (pode ter perdido o envio do load)
	if type(msg) == "table" and msg.acao == "Perfil" then
		enviarPerfil(player, Dados.perfil(player))
		return
	end
	local s = sessaoDe(player)
	if s then s:acao(player, msg) end
end)

remotes.ReiniciarTaskOuMissao.OnServerEvent:Connect(function(player, modo)
	local s = sessaoDe(player)
	if s and (modo == "Task" or modo == "Missao" or modo == "Sair") then s:reiniciar(player, modo) end
end)

---------------------------------------------------------------------------------
-- Perfil (álbum) e saída de jogadores
---------------------------------------------------------------------------------

Dados.iniciar(enviarPerfil)

Players.PlayerRemoving:Connect(function(player)
	local s = ctx.emMissao[player]
	if s then s:sair(player, false) end
end)

-- morreu/renasceu: o personagem novo aparece no mapa, então sai da nave
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local s = ctx.emMissao[player]
		if s then s:sair(player, false) end
	end)
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function()
		local s = ctx.emMissao[player]
		if s then s:sair(player, false) end
	end)
end

RunService.Heartbeat:Connect(function(dt)
	for _, s in sessoes do
		local ok, err = pcall(s.tick, s, dt)
		if not ok then warn("[RookieRocket] tick:", err) end
	end
end)
