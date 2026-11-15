--[[
	Hud — HUD das tasks: alerta piscando, nome e objetivo da task, cronômetro (relógio do
	servidor), efeito do equipamento usado, barra específica de cada task, legendas e avisos.
	Também os botões fixos "Album" e "Credits" (fora e dentro da missão).
]]

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("UI"))
local EVA = require(script.Parent:WaitForChild("EVA"))
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))

local H = {}

local gui = nil
local r = {}
local estado = nil
local conexao = nil

local function construir()
	gui = UI.screenGui("RookieHud", 15)
	gui.Enabled = false
	-- alerta (topo, abaixo da barra do Roblox)
	r.alerta = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.9, 0, 0, 40),
		BackgroundColor3 = UI.C.red,
		Parent = gui,
	})
	UI.corner(r.alerta, 8)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(620, 40), Parent = r.alerta })
	r.alertaTexto = UI.texto(r.alerta, { Text = "", tamanho = 18, peso = Enum.FontWeight.Heavy, alinhar = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), escalar = true })

	-- cartão da task
	r.card = UI.painel(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.new(0.9, 0, 0, 0),
		max = Vector2.new(620, 400),
	})
	r.card.AutomaticSize = Enum.AutomaticSize.Y
	UI.pad(r.card, 10)
	UI.lista(r.card, 4)
	local topo = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1, Parent = r.card })
	r.titulo = UI.texto(topo, { Text = "", tamanho = 18, peso = Enum.FontWeight.Bold, Size = UDim2.new(1, -110, 1, 0), escalar = true })
	r.timer = UI.texto(topo, {
		Text = "",
		tamanho = 22,
		peso = Enum.FontWeight.Heavy,
		cor = UI.C.yellow,
		alinhar = Enum.TextXAlignment.Right,
		Size = UDim2.new(0, 110, 1, 0),
		Position = UDim2.new(1, -110, 0, 0),
	})
	r.objetivo = UI.texto(r.card, { Text = "", tamanho = 15, cor = UI.C.muted, ordem = 2, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
	r.item = UI.texto(r.card, { Text = "", tamanho = 14, cor = UI.C.accent, peso = Enum.FontWeight.SemiBold, ordem = 3, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
	r.barraFrame, r.setBarra = UI.barra(r.card, { Size = UDim2.new(1, 0, 0, 16), ordem = 4 })
	r.zona = UI.new("Frame", { BackgroundColor3 = UI.C.green, BackgroundTransparency = 0.6, Size = UDim2.fromScale(0, 1), Visible = false, Parent = r.barraFrame })
	r.extra = UI.texto(r.card, { Text = "", tamanho = 15, peso = Enum.FontWeight.SemiBold, ordem = 5, auto = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })

	-- legenda (rádio) e avisos
	r.legenda = UI.texto(gui, {
		Text = "",
		tamanho = 20,
		peso = Enum.FontWeight.SemiBold,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.new(0.9, 0, 0, 60),
		Position = UDim2.new(0.5, 0, 1, -150),
	})
	r.legenda.AnchorPoint = Vector2.new(0.5, 1)
	r.legenda.TextStrokeTransparency = 0.4
	r.legenda.Visible = false
end

-- toasts ficam numa ScreenGui própria (aparecem também fora das tasks)
local toastGui = nil
function H.aviso(texto)
	if not toastGui then toastGui = UI.screenGui("RookieAvisos", 40) end
	local t = UI.texto(toastGui, {
		Text = texto,
		tamanho = 18,
		peso = Enum.FontWeight.Bold,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.new(0.8, 0, 0, 48),
		Position = UDim2.new(0.5, 0, 0.62, 0),
	})
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.BackgroundTransparency = 0.15
	t.BackgroundColor3 = UI.C.panel
	UI.corner(t, 8)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 48), Parent = t })
	task.delay(2.6, function()
		local tw = TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		t:Destroy()
	end)
end

function H.legenda(texto)
	if not gui then return end
	r.legenda.Text = '"' .. texto .. '"'
	r.legenda.Visible = true
	task.delay(4, function()
		if r.legenda.Text == '"' .. texto .. '"' then r.legenda.Visible = false end
	end)
end

local function textoItem(missao, n, itens)
	local chave, eq = Missoes.itemDaTask(missao, n)
	if not chave then return "" end
	if itens[chave] then return "Using " .. eq.Nome .. ": " .. eq.Efeito end
	return "Without " .. eq.Nome .. " (" .. eq.Efeito .. ")"
end

-- detalhes por task: barra, zona verde e linha extra
local function detalhes(e)
	local d = e.dados or {}
	local missao, n = e.missao, e.task
	r.barraFrame.Visible, r.zona.Visible = false, false
	r.extra.Text, r.extra.TextColor3 = "", UI.C.text
	if missao == 1 and n == 1 then
		local feitos = 0
		for _, v in d.feitos or {} do
			if v then feitos += 1 end
		end
		r.extra.Text = ("Targets locked: %d/4 · hold %.1f s each"):format(feitos, d.segurar or 2)
	elseif missao == 1 and n == 3 then
		if d.decidiu then
			r.barraFrame.Visible = true
			r.setBarra(d.progresso or 0, UI.C.green)
			r.extra.Text = ("Retropack held: %d%% · %d astronaut(s) holding · %.0f s needed"):format(
				math.floor((d.progresso or 0) * 100),
				d.segurando or 0,
				d.segurar or 10
			)
		else
			r.extra.Text = "DECIDE NOW: EJECT CAPSULE or HOLD RETROPACK"
			r.extra.TextColor3 = UI.C.red
		end
	elseif missao == 2 and n == 1 then
		r.barraFrame.Visible, r.zona.Visible = true, true
		local p = d.pressao or 0.5
		local verde = p >= (d.zonaMin or 0) and p <= (d.zonaMax or 1)
		r.setBarra(p, verde and UI.C.green or (p >= 0.9 and UI.C.red or UI.C.yellow))
		r.zona.Position = UDim2.fromScale(d.zonaMin or 0.4, 0)
		r.zona.Size = UDim2.fromScale((d.zonaMax or 0.6) - (d.zonaMin or 0.4), 1)
		local n2 = 0
		for _, v in d.esferas or {} do
			if v then n2 += 1 end
		end
		r.extra.Text = ("Arm pressure %d%% · spheres aligned %d/4"):format(math.floor(p * 100), n2)
		if (d.noMax or 0) > 0 then
			r.extra.Text ..= (" · MAX PRESSURE %.1f s!"):format(d.noMax)
			r.extra.TextColor3 = UI.C.red
		end
	elseif missao == 2 and n == 2 then
		local n2 = 0
		for _, v in d.presos or {} do
			if v then n2 += 1 end
		end
		r.extra.Text = ("Cables on pulleys: %d/2 · carry speed limit %d studs/s"):format(n2, d.velMax or 6)
		local folga = EVA.folga()
		local eu = tostring(game:GetService("Players").LocalPlayer.UserId)
		local carregando = false
		for _, uid in d.carregando or {} do
			if tostring(uid) == eu then carregando = true end
		end
		if carregando and folga and folga > 0.8 then
			r.extra.Text ..= " · SLOW DOWN!"
			r.extra.TextColor3 = UI.C.red
		end
		if not EVA.ativo() then r.extra.Text ..= "\nGo to the Airlock and press Start EVA." end
	elseif missao == 2 and n == 3 then
		r.barraFrame.Visible = true
		local p = (d.pressao or 100) / 100
		r.setBarra(p, p > 0.5 and UI.C.yellow or UI.C.red)
		r.extra.Text = ("Cabin pressure %d%% · losing %.1f%%/s · hatch %s · seal hold %.1f s"):format(
			math.floor(d.pressao or 100),
			(d.taxa or 2.5) * (d.fechada and 0.5 or 1),
			d.fechada and "CLOSED" or "OPEN",
			d.segurar or 3
		)
		if game:GetService("Players").LocalPlayer:GetAttribute("RookieGaze") then r.extra.Text ..= "\nYou have the epoxy gauze." end
	end
end

local function quadro()
	local e = estado
	if not e or e.fase ~= "Task" then return end
	local decorrido = workspace:GetServerTimeNow() - (e.inicioTask or workspace:GetServerTimeNow())
	if e.limite then
		local resta = e.limite - decorrido
		r.timer.Text = UI.segundos(resta)
		r.timer.TextColor3 = resta <= 10 and UI.C.red or UI.C.yellow
	else
		r.timer.Text = UI.segundos(decorrido)
		r.timer.TextColor3 = UI.C.yellow
	end
	-- alerta piscando
	r.alerta.BackgroundTransparency = (math.floor(os.clock() * 2.5) % 2 == 0) and 0 or 0.35
	if e.missao == 2 and e.task == 2 then detalhes(e) end -- velocidade muda a cada quadro
end

function H.atualizar(e)
	estado = e
	if not gui then construir() end
	if e.fase ~= "Task" then
		gui.Enabled = false
		if e.fase == "Lancamento" then
			gui.Enabled = true
			r.alerta.Visible = false
			r.titulo.Text = "LIFTOFF"
			r.objetivo.Text = "Hold on! The tasks start in a few seconds."
			r.item.Text, r.extra.Text, r.timer.Text = "", "", ""
			r.barraFrame.Visible = false
		end
		return
	end
	local missao = Missoes.Lista[e.missao]
	local cfg = missao.Tasks[e.task]
	gui.Enabled = true
	r.alerta.Visible = true
	r.alertaTexto.Text = cfg.Alerta
	r.titulo.Text = ("TASK %d/3 · %s"):format(e.task, cfg.Nome)
	r.objetivo.Text = cfg.Objetivo
	r.item.Text = textoItem(missao, e.task, e.itens or {})
	detalhes(e)
	if not conexao then conexao = RunService.RenderStepped:Connect(quadro) end
end

function H.esconder()
	if gui then gui.Enabled = false end
	estado = nil
	if conexao then conexao:Disconnect() conexao = nil end
end

return H
