--[[
	Paineis — UIs abertas pelos prompts com o atributo RookiePainel:
	- "Radio" (M1 Task 2): teclado numérico; envia o código ao servidor.
	- "Canadarm" (M2 Task 1): 4 esferas para arrastar até os 4 alvos X + slider da válvula de
	  pressão com a zona verde. Em co-op, um alinha as esferas e outro cuida do slider.
	Os painéis não travam o movimento: dá para fechar, andar e voltar.
]]

local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("UI"))

local P = {}

local remotes = RS:WaitForChild("RookieRocket"):WaitForChild("Remotes")
local radioGui, canadarmGui = nil, nil
local canadarm = {}
local conexoes = {} -- sinais globais (UserInputService) dos painéis abertos

local function conectar(sinal, f)
	local c = sinal:Connect(f)
	table.insert(conexoes, c)
	return c
end

local function desconectarTudo()
	for _, c in conexoes do c:Disconnect() end
	table.clear(conexoes)
end

---------------------------------------------------------------------------------
-- Rádio
---------------------------------------------------------------------------------

local function abrirRadio()
	if radioGui then radioGui.Enabled = true return end
	radioGui = UI.screenGui("RookieRadio", 25)
	local painel = UI.painel(radioGui, { Size = UDim2.fromOffset(300, 430), Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5) })
	UI.pad(painel, 14)
	UI.texto(painel, { Text = "RADIO · BACKUP FREQUENCY", tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.accent })
	local visor = UI.texto(painel, {
		Text = "",
		tamanho = 34,
		peso = Enum.FontWeight.Bold,
		alinhar = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.fromOffset(0, 28),
	})
	visor.FontFace = Font.fromEnum(Enum.Font.Code)
	visor.BackgroundTransparency = 0
	visor.BackgroundColor3 = Color3.fromHex("0A0F1C")
	UI.corner(visor, 6)
	local digitado = ""
	local function mostrar() visor.Text = digitado == "" and "_ _ _ _" or digitado end
	mostrar()
	local teclado = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 260), Position = UDim2.fromOffset(0, 92), BackgroundTransparency = 1, Parent = painel })
	UI.new("UIGridLayout", { CellSize = UDim2.new(1 / 3, -6, 0, 58), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = teclado })
	local teclas = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK" }
	for i, k in teclas do
		UI.botao(teclado, {
			Text = k,
			tamanho = 24,
			ordem = i,
			Size = UDim2.new(),
			cor = (k == "OK" and UI.C.green) or (k == "C" and UI.C.red) or UI.C.panel2,
			aoClicar = function()
				if k == "C" then
					digitado = ""
				elseif k == "OK" then
					if digitado ~= "" then remotes.AcaoTask:FireServer({ acao = "Codigo", valor = digitado }) end
					digitado = ""
				elseif #digitado < 6 then
					digitado ..= k
				end
				mostrar()
			end,
		})
	end
	UI.botao(painel, {
		Text = "Close",
		cor = UI.C.panel2,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -44),
		aoClicar = function() radioGui.Enabled = false end,
	})
end

---------------------------------------------------------------------------------
-- Canadarm
---------------------------------------------------------------------------------

local function abrirCanadarm()
	if canadarmGui then canadarmGui.Enabled = true return end
	canadarmGui = UI.screenGui("RookieCanadarm", 25)
	local painel = UI.painel(canadarmGui, { Size = UDim2.fromScale(0.94, 0.7), max = Vector2.new(760, 440), Position = UDim2.fromScale(0.5, 0.58) })
	UI.pad(painel, 14)
	UI.texto(painel, { Text = "CANADARM · DOCKING UNITY & ZARYA", tamanho = 14, peso = Enum.FontWeight.Bold, cor = UI.C.accent })

	-- área das esferas (esquerda)
	local area = UI.new("Frame", { Size = UDim2.new(0.68, -8, 1, -86), Position = UDim2.fromOffset(0, 30), BackgroundColor3 = Color3.fromHex("0A0F1C"), ClipsDescendants = true, Parent = painel })
	UI.corner(area, 8)
	UI.stroke(area)
	local alvosPos = { Vector2.new(0.72, 0.2), Vector2.new(0.85, 0.45), Vector2.new(0.72, 0.72), Vector2.new(0.55, 0.47) }
	local inicioPos = { Vector2.new(0.12, 0.18), Vector2.new(0.12, 0.4), Vector2.new(0.12, 0.62), Vector2.new(0.12, 0.84) }
	canadarm.alvos, canadarm.esferas, canadarm.feitas = {}, {}, {}
	for i = 1, 4 do
		local x = UI.texto(area, {
			Text = "✕",
			tamanho = 34,
			peso = Enum.FontWeight.Bold,
			cor = UI.C.yellow,
			alinhar = Enum.TextXAlignment.Center,
			Size = UDim2.fromOffset(52, 52),
			Position = UDim2.fromScale(alvosPos[i].X, alvosPos[i].Y),
		})
		x.AnchorPoint = Vector2.new(0.5, 0.5)
		canadarm.alvos[i] = x
		local bola = UI.new("TextButton", {
			Text = tostring(i),
			FontFace = UI.font(Enum.FontWeight.Bold),
			TextSize = 18,
			TextColor3 = UI.C.panel,
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromHex("F2F2F2"),
			Size = UDim2.fromOffset(46, 46),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(inicioPos[i].X, inicioPos[i].Y),
			ZIndex = 3,
			Parent = area,
		})
		UI.corner(bola, 23)
		canadarm.esferas[i] = bola
		-- arrastar (mouse e toque)
		local arrastando = nil
		bola.InputBegan:Connect(function(input)
			if canadarm.feitas[i] then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				arrastando = input
			end
		end)
		conectar(UIS.InputChanged, function(input)
			if not arrastando then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input == arrastando then
				local abs, tam = area.AbsolutePosition, area.AbsoluteSize
				local px = math.clamp((input.Position.X - abs.X) / tam.X, 0.04, 0.96)
				local py = math.clamp((input.Position.Y - abs.Y) / tam.Y, 0.06, 0.94)
				bola.Position = UDim2.fromScale(px, py)
			end
		end)
		conectar(UIS.InputEnded, function(input)
			if not arrastando then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input == arrastando then
				arrastando = nil
				local b, a = bola.AbsolutePosition + bola.AbsoluteSize / 2, canadarm.alvos[i]
				local c = a.AbsolutePosition + a.AbsoluteSize / 2
				if (b - c).Magnitude <= 30 then
					remotes.AcaoTask:FireServer({ acao = "Esfera", i = i })
				end
				-- a posição final vem do servidor (atualizar): se não travou, volta
				task.delay(0.35, function()
					if not canadarm.feitas[i] then bola.Position = UDim2.fromScale(inicioPos[i].X, inicioPos[i].Y) end
				end)
			end
		end)
	end
	canadarm.alvosPos = alvosPos

	-- slider da válvula (direita, vertical)
	local lado = UI.new("Frame", { Size = UDim2.new(0.32, 0, 1, -86), Position = UDim2.new(0.68, 8, 0, 30), BackgroundTransparency = 1, Parent = painel })
	UI.texto(lado, { Text = "ARM PRESSURE VALVE", tamanho = 13, peso = Enum.FontWeight.Bold, alinhar = Enum.TextXAlignment.Center })
	local trilho = UI.new("Frame", { Size = UDim2.new(0, 56, 1, -60), Position = UDim2.new(0.5, -28, 0, 28), BackgroundColor3 = UI.C.panel2, Parent = lado })
	UI.corner(trilho, 8)
	UI.stroke(trilho)
	local zona = UI.new("Frame", { BackgroundColor3 = UI.C.green, BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.4), Parent = trilho })
	local agulha = UI.new("Frame", { BackgroundColor3 = UI.C.red, Size = UDim2.new(1, 14, 0, 4), Position = UDim2.new(0, -7, 0.5, 0), ZIndex = 3, Parent = trilho })
	local alca = UI.new("TextButton", {
		Text = "≡",
		TextSize = 20,
		FontFace = UI.font(Enum.FontWeight.Bold),
		TextColor3 = UI.C.panel,
		BackgroundColor3 = UI.C.accent,
		AutoButtonColor = false,
		Size = UDim2.new(1, 24, 0, 36),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 4,
		Parent = trilho,
	})
	UI.corner(alca, 8)
	canadarm.zona, canadarm.agulha, canadarm.alca = zona, agulha, alca
	local legenda = UI.texto(lado, { Text = "needle = pressure · handle = valve", tamanho = 12, cor = UI.C.muted, alinhar = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 1, -28) })
	legenda.Size = UDim2.new(1, 0, 0, 28)

	local segurando = nil
	local ultimoEnvio = 0
	alca.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then segurando = input end
	end)
	conectar(UIS.InputChanged, function(input)
		if not segurando then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input == segurando then
			local abs, tam = trilho.AbsolutePosition, trilho.AbsoluteSize
			local y = math.clamp((input.Position.Y - abs.Y) / tam.Y, 0, 1)
			alca.Position = UDim2.fromScale(0.5, y)
			-- topo do trilho = pressão alta (1), base = 0
			if os.clock() - ultimoEnvio >= 0.06 then
				ultimoEnvio = os.clock()
				remotes.AcaoTask:FireServer({ acao = "Pressao", valor = 1 - y })
			end
		end
	end)
	conectar(UIS.InputEnded, function(input)
		if segurando and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == segurando) then
			local y = alca.Position.Y.Scale
			remotes.AcaoTask:FireServer({ acao = "Pressao", valor = 1 - y })
			segurando = nil
		end
	end)
	canadarm.segurandoAlca = function() return segurando ~= nil end

	UI.botao(painel, {
		Text = "Close",
		cor = UI.C.panel2,
		Size = UDim2.new(0, 140, 0, 44),
		Position = UDim2.new(1, -140, 1, -44),
		aoClicar = function() canadarmGui.Enabled = false end,
	})
end

-- dados da sincronização (pressão, zona, esferas já travadas)
function P.atualizarCanadarm(d)
	if not canadarmGui or not d then return end
	local zMin, zMax = d.zonaMin or 0.4, d.zonaMax or 0.6
	canadarm.zona.Position = UDim2.fromScale(0, 1 - zMax)
	canadarm.zona.Size = UDim2.fromScale(1, zMax - zMin)
	local p = d.pressao or 0.5
	canadarm.agulha.Position = UDim2.new(0, -7, 1 - p, -2)
	local verde = p >= zMin and p <= zMax
	canadarm.agulha.BackgroundColor3 = verde and UI.C.green or UI.C.red
	if not canadarm.segurandoAlca() and d.valvula then
		canadarm.alca.Position = UDim2.fromScale(0.5, 1 - d.valvula) -- outro jogador mexeu
	end
	for i, feita in d.esferas or {} do
		if feita and not canadarm.feitas[i] then
			canadarm.feitas[i] = true
			local a = canadarm.alvosPos[i]
			canadarm.esferas[i].Position = UDim2.fromScale(a.X, a.Y)
			canadarm.esferas[i].BackgroundColor3 = UI.C.green
			canadarm.alvos[i].TextColor3 = UI.C.green
		end
	end
end

function P.abrir(nome)
	if nome == "Radio" then
		abrirRadio()
	elseif nome == "Canadarm" then
		abrirCanadarm()
	end
end

-- fim da task (ou da missão): fecha e descarta
function P.fecharTodos()
	if radioGui then radioGui:Destroy() radioGui = nil end
	if canadarmGui then canadarmGui:Destroy() canadarmGui = nil end
	canadarm = {}
	desconectarTudo()
end

function P.fecharSeNaoFor(estado)
	local m, n = estado and estado.missao, estado and estado.task
	local naTask = estado and estado.fase == "Task"
	if radioGui and not (naTask and m == 1 and n == 2) then
		radioGui:Destroy()
		radioGui = nil
	end
	if canadarmGui and not (naTask and m == 2 and n == 1) then
		canadarmGui:Destroy()
		canadarmGui = nil
		canadarm = {}
		desconectarTudo()
	end
end

return P
