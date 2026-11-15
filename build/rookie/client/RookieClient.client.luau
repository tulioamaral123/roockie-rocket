--[[
	RookieClient — boot do cliente do Rookie Rocket. Só desenha e manda intenções:
	recebe SincronizarEstado (Estado / Efeito / Aviso / Perfil / Saiu) e distribui para
	Preparacao, Hud, Modais, Paineis, Mira, EVA e Efeitos (módulos irmãos).
]]

local RS = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local raiz = RS:WaitForChild("RookieRocket")
local Missoes = require(raiz:WaitForChild("Config"):WaitForChild("Missoes"))
local remotes = raiz:WaitForChild("Remotes")

local pasta = script.Parent
local Efeitos = require(pasta:WaitForChild("Efeitos"))
local EVA = require(pasta:WaitForChild("EVA"))
local Preparacao = require(pasta:WaitForChild("Preparacao"))
local Hud = require(pasta:WaitForChild("Hud"))
local Modais = require(pasta:WaitForChild("Modais"))
local Paineis = require(pasta:WaitForChild("Paineis"))
local Mira = require(pasta:WaitForChild("Mira"))

Efeitos.iniciar(Missoes.Audio)
EVA.iniciar()
Modais.iniciar()

local mapa = nil
local function nave(id)
	mapa = mapa or workspace:WaitForChild("NASAComplex"):WaitForChild("RookieRocket", 30)
	local m = Missoes.Lista[id]
	return mapa and m and mapa:WaitForChild(m.Nave, 30)
end

local function limparTudo()
	Mira.desligar()
	Paineis.fecharTodos()
	Preparacao.fechar()
	Hud.esconder()
	Modais.fechar()
	Efeitos.sair()
end

local function aoEstado(e)
	if e.fase == "Livre" then
		limparTudo()
		return
	end
	local modelo = nave(e.missao)
	if not modelo then return end
	Efeitos.entrar(e.missao, modelo)
	Efeitos.aplicar(e)
	Preparacao.atualizar(e)
	Hud.atualizar(e)
	Modais.atualizar(e)
	Paineis.fecharSeNaoFor(e)

	local naTask = e.fase == "Task"
	if naTask and e.missao == 1 and e.task == 1 then
		Mira.ligar(modelo, Missoes.Lista[1].Tasks[1])
		Mira.atualizar(e.dados)
	else
		Mira.desligar()
	end
	if naTask and e.missao == 2 and e.task == 1 then Paineis.atualizarCanadarm(e.dados) end
	if naTask and e.missao == 2 and e.task == 2 and e.dados then EVA.configurar(e.dados.velEVA, e.dados.velMax) end
end

remotes.SincronizarEstado.OnClientEvent:Connect(function(msg)
	if type(msg) ~= "table" then return end
	if msg.tipo == "Estado" then
		aoEstado(msg)
	elseif msg.tipo == "Efeito" then
		Efeitos.pulso(msg.nome, msg.dados or {})
		if msg.nome == "RadioOk" and msg.dados and msg.dados.fala then Hud.legenda(msg.dados.fala) end
	elseif msg.tipo == "Aviso" then
		Hud.aviso(msg.texto)
	elseif msg.tipo == "Perfil" then
		Modais.perfil(msg)
	elseif msg.tipo == "Saiu" then
		limparTudo()
	end
end)

-- prompts que abrem UI (o servidor marca com o atributo RookiePainel)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local painel = prompt:GetAttribute("RookiePainel")
	if painel == "Preparacao" then
		Preparacao.abrir()
	elseif painel then
		Paineis.abrir(painel)
	end
end)

-- álbum: pede o próprio perfil (o envio do servidor no load pode ter chegado antes deste script)
remotes.AcaoTask:FireServer({ acao = "Perfil" })
