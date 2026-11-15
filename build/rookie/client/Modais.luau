--[[
	Modais — balão do Marcos Pontes nas falhas (Retry task / Restart mission), tela de resultado
	(equação "T1 + T2 + T3 − bônus = total · estrelas", fala, card NASA), Álbum (cards
	desbloqueados + melhores estrelas, do DataStore) e Créditos (aviso dos valores didáticos).
	Os botões fixos "Album" e "Credits" ficam à direita, no meio da tela (fora das zonas do Roblox).
]]

local RS = game:GetService("ReplicatedStorage")

local UI = require(script.Parent:WaitForChild("UI"))
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))

local M = {}

local remotes = RS:WaitForChild("RookieRocket"):WaitForChild("Remotes")
local gui = nil
local modal = nil
local perfil = { estrelas = {}, cards = {} }
local albumGui, creditosGui = nil, nil

local function fecharModal()
	if modal then modal:Destroy() modal = nil end
end

-- avatar do guia: foto oficial (se configurada) ou monograma
local function retrato(parent)
	local guia = Missoes.Guia
	local f
	if guia.Foto ~= "" then
		f = UI.new("ImageLabel", { Image = guia.Foto, ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromOffset(84, 84), BackgroundColor3 = UI.C.panel2, Parent = parent })
	else
		f = UI.texto(parent, { Text = "MP", tamanho = 30, peso = Enum.FontWeight.Heavy, alinhar = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(84, 84) })
		f.BackgroundTransparency = 0
		f.BackgroundColor3 = UI.C.accent
	end
	UI.corner(f, 42)
	return f
end

local function baseModal(altura)
	fecharModal()
	modal = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Parent = gui })
	local p = UI.painel(modal, { Size = UDim2.fromScale(0.94, 0.8), max = Vector2.new(720, altura) })
	UI.pad(p, 18)
	return p
end

local function falaDoGuia(p, texto, y)
	local cab = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 90), Position = UDim2.fromOffset(0, y or 0), BackgroundTransparency = 1, Parent = p })
	retrato(cab)
	UI.texto(cab, { Text = Missoes.Guia.Nome, tamanho = 20, peso = Enum.FontWeight.Bold, Position = UDim2.fromOffset(100, 14), Size = UDim2.new(1, -100, 0, 26) })
	UI.texto(cab, { Text = Missoes.Guia.Papel, tamanho = 14, cor = UI.C.muted, Position = UDim2.fromOffset(100, 42), Size = UDim2.new(1, -100, 0, 20) })
	local balao = UI.texto(p, {
		Text = texto,
		tamanho = 18,
		Position = UDim2.fromOffset(0, (y or 0) + 98),
		Size = UDim2.new(1, 0, 0, 0),
		auto = Enum.AutomaticSize.Y,
		alinharY = Enum.TextYAlignment.Top,
	})
	balao.BackgroundTransparency = 0
	balao.BackgroundColor3 = UI.C.panel2
	UI.corner(balao, 10)
	UI.pad(balao, 12)
	return balao
end

local function rodape(p, botoes)
	local r = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 1, -50), BackgroundTransparency = 1, Parent = p })
	UI.lista(r, 10, true, Enum.HorizontalAlignment.Right)
	for i, b in botoes do
		UI.botao(r, { Text = b[1], cor = b[3] or UI.C.accent, Size = UDim2.new(0, b[4] or 190, 1, 0), ordem = i, aoClicar = b[2] })
	end
end

---------------------------------------------------------------------------------
-- Falha e resultado
---------------------------------------------------------------------------------

local ultimoMostrado = nil
local aprendizadoVisto = {}

-- Parabéns + o que o jogador aprendeu em cada task (Missoes.Lista[n].Aprendizado)
function M.aprendizado(ap, res, continuar)
	local p = baseModal(600)
	-- rolagem para caber em telas pequenas (celular)
	local lista = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, Parent = p,
	})
	UI.lista(lista, 10)
	UI.texto(lista, { Text = ap.Titulo, tamanho = 26, peso = Enum.FontWeight.Heavy, cor = UI.C.yellow, ordem = 1 })
	UI.texto(lista, { Text = ("MISSION COMPLETE · %s · %d★"):format(string.upper(res.medalha or ""), res.estrelas or 0), tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.green, ordem = 2 })
	local fala = UI.texto(lista, { Text = ap.Fala, tamanho = 17, Size = UDim2.new(1, 0, 0, 0), auto = Enum.AutomaticSize.Y, ordem = 3 })
	fala.TextColor3 = UI.C.text
	for i, item in ap.Itens do
		local card = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UI.C.panel2, LayoutOrder = 3 + i, Parent = lista })
		UI.corner(card, 10)
		UI.pad(card, 12)
		UI.lista(card, 4)
		UI.texto(card, { Text = item.Task, tamanho = 18, peso = Enum.FontWeight.Bold, cor = UI.C.accent, ordem = 1 })
		for k, area in item.Areas do
			UI.texto(card, { Text = "•  " .. area, tamanho = 16, ordem = 1 + k })
		end
	end
	rodape(p, { { "Continue  ›", continuar, UI.C.accent, 190 } })
end

function M.atualizar(estado)
	if estado.fase == "Falha" and estado.falha then
		local chave = "F" .. estado.falha.chave .. (estado.falha.task or 0)
		if ultimoMostrado == chave and modal then return end
		ultimoMostrado = chave
		local p = baseModal(460)
		UI.texto(p, { Text = (estado.falha.chave == "DemorouDemais" and "MISSION FAILED · " .. string.upper(Missoes.Textos.DemorouDemais))
			or (estado.falha.task and estado.falha.task > 0 and ("MISSION FAILED · TASK %d"):format(estado.falha.task))
			or "LAUNCH FAILED", tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.red })
		local y = 28
		if estado.falha.equacao then
			local eq = UI.texto(p, { Text = estado.falha.equacao, tamanho = 20, peso = Enum.FontWeight.Bold, cor = UI.C.red, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 0), auto = Enum.AutomaticSize.Y })
			eq.TextWrapped = true
			y = 92
		end
		falaDoGuia(p, estado.falha.texto, y)
		local botoes = {}
		if estado.falha.podeRepetir then
			table.insert(botoes, { Missoes.Textos.TentarTask, function() remotes.ReiniciarTaskOuMissao:FireServer("Task") end })
		end
		table.insert(botoes, { Missoes.Textos.RecomecarMissao, function() remotes.ReiniciarTaskOuMissao:FireServer("Missao") end, estado.falha.podeRepetir and UI.C.panel2 or UI.C.accent })
		rodape(p, botoes)
	elseif estado.fase == "Resultado" and estado.resultado then
		local res = estado.resultado
		local chave = "R" .. res.equacao
		if ultimoMostrado == chave and modal then return end
		-- missão concluída: primeiro a tela de parabéns e do que foi aprendido (uma vez por resultado)
		local missao = Missoes.Lista[estado.missao]
		local ap = missao and missao.Aprendizado
		if res.estrelas > 0 and ap and not aprendizadoVisto[chave] then
			if ultimoMostrado == "A" .. chave and modal then return end
			ultimoMostrado = "A" .. chave
			M.aprendizado(ap, res, function()
				aprendizadoVisto[chave] = true
				ultimoMostrado = nil
				M.atualizar(estado)
			end)
			return
		end
		ultimoMostrado = chave
		local p = baseModal(560)
		local ok = res.estrelas > 0
		UI.texto(p, { Text = ok and ("MISSION COMPLETE · " .. string.upper(res.medalha)) or "MISSION FAILED · " .. string.upper(Missoes.Textos.DemorouDemais), tamanho = 14, peso = Enum.FontWeight.Bold, cor = ok and UI.C.green or UI.C.red })
		local eq = UI.texto(p, { Text = res.equacao, tamanho = 22, peso = Enum.FontWeight.Bold, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 0), auto = Enum.AutomaticSize.Y })
		eq.TextColor3 = ok and UI.C.yellow or UI.C.red
		falaDoGuia(p, res.fala, 92)
		local botoes = {}
		if res.card then
			table.insert(botoes, { "Open album", function() M.album(res.card) end, UI.C.panel2, 160 })
		end
		table.insert(botoes, { Missoes.Textos.VoarDeNovo, function() remotes.ReiniciarTaskOuMissao:FireServer("Missao") end, UI.C.panel2, 150 })
		table.insert(botoes, { Missoes.Textos.VoltarLCC, function() remotes.ReiniciarTaskOuMissao:FireServer("Sair") end, UI.C.accent, 170 })
		rodape(p, botoes)
	else
		ultimoMostrado = nil
		fecharModal()
	end
end

function M.fechar()
	ultimoMostrado = nil
	fecharModal()
end

---------------------------------------------------------------------------------
-- Álbum e créditos
---------------------------------------------------------------------------------

function M.perfil(p)
	perfil = { estrelas = p.estrelas or {}, cards = p.cards or {} }
	if albumGui and albumGui.Enabled then M.album() end
end

function M.album(destaque)
	if albumGui then albumGui:Destroy() end
	albumGui = UI.screenGui("RookieAlbum", 35)
	local fundo = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Parent = albumGui })
	local p = UI.painel(fundo, { Size = UDim2.fromScale(0.94, 0.86), max = Vector2.new(860, 620) })
	UI.pad(p, 16)
	UI.texto(p, { Text = "NASA ALBUM", tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.accent })
	local lista = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -84), Position = UDim2.fromOffset(0, 28), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = p })
	UI.lista(lista, 12)
	for id, missao in Missoes.Lista do
		local card = Missoes.Cards[missao.Card]
		local tem = perfil.cards[missao.Card] == true
		local melhor = perfil.estrelas[tostring(id)] or 0
		local f = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UI.C.panel2, LayoutOrder = id, Parent = lista })
		UI.corner(f, 10)
		UI.stroke(f, destaque == missao.Card and UI.C.accent or UI.C.line, destaque == missao.Card and 3 or 1.5)
		UI.pad(f, 12)
		local img = UI.new("ImageLabel", {
			Image = tem and card.Foto or "",
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromOffset(180, 135),
			BackgroundColor3 = Color3.fromHex("0A0F1C"),
			Parent = f,
		})
		UI.corner(img, 8)
		if not tem then
			UI.texto(img, { Text = "🔒", tamanho = 40, alinhar = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
		end
		local col = UI.new("Frame", { Size = UDim2.new(1, -196, 0, 0), Position = UDim2.fromOffset(196, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = f })
		UI.lista(col, 4)
		UI.texto(col, { Text = card.Titulo, tamanho = 20, peso = Enum.FontWeight.Bold, ordem = 1 })
		UI.texto(col, { Text = ("Best: %s"):format(melhor > 0 and string.rep("⭐", melhor) or "not completed yet"), tamanho = 15, cor = UI.C.yellow, ordem = 2 })
		UI.texto(col, {
			Text = tem and card.Texto or ("Complete \"" .. missao.Nome .. "\" with at least 1 star to unlock this card."),
			tamanho = 15,
			cor = tem and UI.C.text or UI.C.muted,
			ordem = 3,
			auto = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
		})
		if tem then
			UI.texto(col, { Text = card.Legenda .. " Photo: " .. card.Credito, tamanho = 12, cor = UI.C.muted, ordem = 4, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
		end
	end
	UI.botao(p, { Text = "Close", cor = UI.C.panel2, Size = UDim2.new(0, 140, 0, 44), Position = UDim2.new(1, -140, 1, -44), aoClicar = function() albumGui:Destroy() albumGui = nil end })
end

function M.creditos()
	if creditosGui then creditosGui:Destroy() end
	creditosGui = UI.screenGui("RookieCreditos", 35)
	local fundo = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Parent = creditosGui })
	local p = UI.painel(fundo, { Size = UDim2.fromScale(0.9, 0.7), max = Vector2.new(640, 440) })
	UI.pad(p, 18)
	UI.lista(p, 10)
	UI.texto(p, { Text = "CREDITS · ROOKIE ROCKET", tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.accent, ordem = 0 })
	for i, linha in Missoes.Textos.Creditos do
		UI.texto(p, { Text = linha, tamanho = i == 1 and 18 or 16, peso = i == 1 and Enum.FontWeight.Bold or Enum.FontWeight.Medium, cor = i == 1 and UI.C.yellow or UI.C.text, ordem = i, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
	end
	UI.botao(p, { Text = "Close", cor = UI.C.panel2, Size = UDim2.new(0, 140, 0, 44), ordem = 99, aoClicar = function() creditosGui:Destroy() creditosGui = nil end })
end

function M.iniciar()
	gui = UI.screenGui("RookieModais", 30)
	-- botões fixos à direita, meio da tela
	local barra = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.42, 0), Size = UDim2.fromOffset(104, 104), BackgroundTransparency = 1, Parent = UI.screenGui("RookieBotoes", 5) })
	UI.lista(barra, 8)
	UI.botao(barra, { Text = "Album", Size = UDim2.new(1, 0, 0, 46), cor = UI.C.panel, tamanho = 16, ordem = 1, aoClicar = function() M.album() end })
	UI.botao(barra, { Text = "Credits", Size = UDim2.new(1, 0, 0, 46), cor = UI.C.panel, tamanho = 16, ordem = 2, aoClicar = M.creditos })
end

return M
