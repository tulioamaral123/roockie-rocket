--[[
	Preparacao — tela de Preparação da Missão (spec §2), sincronizada em co-op:
	3 equipamentos (liga/desliga), barra de peso ao vivo (verde ≤ 50, amarela 51–60, vermelha > 60),
	"Weight X / 60 kg · Free Y kg", bônus de leveza, tripulação, LAUNCH (sempre clicável, para
	permitir o erro didático) e Leave ship. Quem decide o peso é o servidor; aqui só se desenha.
]]

local RS = game:GetService("ReplicatedStorage")

local UI = require(script.Parent:WaitForChild("UI"))
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))

local P = {}

local remotes = RS:WaitForChild("RookieRocket"):WaitForChild("Remotes")
local gui, painel = nil, nil
local refs = {}
local missaoAtual = nil
local fechadoPeloJogador = false

local function construir(missao)
	gui = UI.screenGui("RookiePreparacao", 20)
	painel = UI.painel(gui, { Size = UDim2.fromScale(0.94, 0.86), max = Vector2.new(820, 600) })
	UI.pad(painel, 16)
	local corpo = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = painel,
	})
	UI.lista(corpo, 10)
	UI.texto(corpo, { Text = Missoes.Textos.Preparacao:upper(), tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.accent, ordem = 1 })
	UI.texto(corpo, { Text = missao.Nome, tamanho = 24, peso = Enum.FontWeight.Bold, ordem = 2, Size = UDim2.new(1, 0, 0, 32) })
	UI.texto(corpo, {
		Text = "Pick up to 2 items together. The rocket carries 60 kg and the ship alone weighs 20 kg. The lighter you fly, the more seconds you save.",
		tamanho = 15,
		cor = UI.C.muted,
		ordem = 3,
		auto = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
	})

	-- equipamentos
	local linha = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4, Parent = corpo })
	local grade = UI.new("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -8, 0, 168),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = linha,
	})
	if UI.isTouch() or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 700) then
		grade.CellSize = UDim2.new(1, 0, 0, 120) -- celular: um item por linha
	end
	refs.itens = {}
	for ordem, chave in missao.OrdemEquipamentos do
		local eq = missao.Equipamentos[chave]
		local card = UI.new("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = UI.C.panel2,
			LayoutOrder = ordem,
			Name = chave,
			Parent = linha,
		})
		UI.corner(card, 10)
		local borda = UI.new("UIStroke", { Color = UI.C.line, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
		UI.pad(card, 10)
		UI.lista(card, 4)
		UI.texto(card, { Text = eq.Nome, tamanho = 18, peso = Enum.FontWeight.Bold, ordem = 1 })
		UI.texto(card, { Text = ("%d kg · Task %d"):format(eq.Peso, eq.TaskAlvo), tamanho = 15, cor = UI.C.yellow, peso = Enum.FontWeight.SemiBold, ordem = 2 })
		UI.texto(card, { Text = eq.Efeito, tamanho = 14, cor = UI.C.muted, ordem = 3, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
		local estado = UI.texto(card, { Text = "Not loaded", tamanho = 14, peso = Enum.FontWeight.Bold, ordem = 4 })
		card.Activated:Connect(function()
			local ligado = card:GetAttribute("Ligado") == true
			remotes.SelecionarEquipamento:FireServer(chave, not ligado)
		end)
		refs.itens[chave] = { card = card, borda = borda, estado = estado }
	end

	-- barra de peso
	local _, setPeso
	refs.barraFrame, setPeso = UI.barra(corpo, { Size = UDim2.new(1, 0, 0, 22), ordem = 5 })
	refs.setPeso = setPeso
	refs.textoPeso = UI.texto(corpo, { Text = "", tamanho = 18, peso = Enum.FontWeight.Bold, ordem = 6 })
	refs.textoBonus = UI.texto(corpo, { Text = "", tamanho = 15, cor = UI.C.green, ordem = 7 })
	refs.tripulacao = UI.texto(corpo, { Text = "", tamanho = 15, cor = UI.C.muted, ordem = 8, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })

	-- rodapé
	local rodape = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 52), Position = UDim2.new(0, 0, 1, -52), BackgroundTransparency = 1, Parent = painel })
	UI.lista(rodape, 10, true, Enum.HorizontalAlignment.Right)
	UI.botao(rodape, {
		Text = Missoes.Textos.Sair,
		cor = UI.C.panel2,
		Size = UDim2.new(0, 150, 1, 0),
		ordem = 1,
		aoClicar = function() remotes.ReiniciarTaskOuMissao:FireServer("Sair") end,
	})
	UI.botao(rodape, {
		Text = "Close",
		cor = UI.C.panel2,
		Size = UDim2.new(0, 110, 1, 0),
		ordem = 2,
		aoClicar = function()
			fechadoPeloJogador = true
			gui.Enabled = false
		end,
	})
	UI.botao(rodape, {
		Text = Missoes.Textos.Lancar,
		cor = UI.C.accent,
		Size = UDim2.new(0, 170, 1, 0),
		tamanho = 20,
		ordem = 3,
		aoClicar = function() remotes.IniciarLancamento:FireServer() end,
	})
end

function P.atualizar(estado)
	local missao = Missoes.Lista[estado.missao]
	if estado.fase ~= "Preparacao" then
		if gui then gui.Enabled = false end
		fechadoPeloJogador = false
		return
	end
	if missaoAtual ~= estado.missao or not gui then
		if gui then gui:Destroy() end
		missaoAtual = estado.missao
		construir(missao)
	end
	if not fechadoPeloJogador then gui.Enabled = true end

	local limite = Missoes.RegrasGerais.LimiteFoguete
	local peso = estado.peso
	for chave, r in refs.itens do
		local on = estado.itens[chave] == true
		r.card:SetAttribute("Ligado", on)
		r.borda.Color = on and UI.C.accent or UI.C.line
		r.estado.Text = on and "✔ Loaded" or "Not loaded"
		r.estado.TextColor3 = on and UI.C.accent or UI.C.muted
	end
	local cor = UI.C.green
	if peso > limite then
		cor = UI.C.red
	elseif peso > Missoes.RegrasGerais.PesoVerdeAte then
		cor = UI.C.yellow
	end
	refs.setPeso(peso / limite, cor)
	refs.textoPeso.Text = Missoes.formatar(Missoes.Textos.BarraPeso, { x = peso, free = limite - peso })
	refs.textoPeso.TextColor3 = cor
	refs.textoBonus.Text = peso <= limite and Missoes.formatar(Missoes.Textos.Bonus, { s = estado.bonus })
		or ("Over the limit by %d kg!"):format(peso - limite)
	refs.textoBonus.TextColor3 = peso <= limite and UI.C.green or UI.C.red
	local nomes = {}
	for _, t in estado.tripulacao do table.insert(nomes, t.nome) end
	refs.tripulacao.Text = ("Crew (%d/%d): %s"):format(#nomes, Missoes.RegrasGerais.MaxJogadoresPorNave, table.concat(nomes, ", "))
end

-- prompt "Mission prep" do console: reabre
function P.abrir()
	fechadoPeloJogador = false
	if gui then gui.Enabled = true end
end

function P.fechar()
	if gui then gui:Destroy() gui = nil end
	missaoAtual = nil
	fechadoPeloJogador = false
end

return P
