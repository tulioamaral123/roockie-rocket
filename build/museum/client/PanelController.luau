--[[
	PanelController — painel de exposição e de card (museuspec §5.2, §7.1).

	PC: lateral direita (~40%); celular: metade de baixo. O mundo continua visível.
	Fecha com o X, acionando o mesmo prompt de novo (E) ou afastando-se.
	"View components" entra na câmera de exame (ComponentsController) e troca o corpo do painel
	pelos detalhes do componente tocado.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local Shared = RS:WaitForChild("MuseumSystem"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))

local UI = require(script.Parent:WaitForChild("UI"))
local Components = require(script.Parent:WaitForChild("ComponentsController"))
local Explorer = require(script.Parent:WaitForChild("RocketExplorer"))
local World = require(script.Parent:WaitForChild("WorldController"))
local State = require(script.Parent:WaitForChild("State"))

local Panel = {}

local gui, frame, titleL, subL, body, footer
local current -- { kind = "exhibit"|"card", id, data, model, anchor }
local exploring = false -- "Explore rocket" ativo: painel sempre à direita, foguete enquadrado à esquerda
local distConn
local sourcesShown = false
local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local touchSaved -- TouchControlsEnabled antes de abrir (no celular o painel cobre o direcional e o pulo)
Panel.onOpen = nil -- MuseumClient liga: fecha a janela do HUD quando o painel abre

local function showFrame()
	frame.Visible = true
	if Panel.onOpen then Panel.onOpen() end
	if UI.isTouch() and UI.isCompact() and touchSaved == nil then
		touchSaved = GuiService.TouchControlsEnabled
		GuiService.TouchControlsEnabled = false
	end
end

local function findModel(id)
	for _, m in CollectionService:GetTagged("Exhibit") do
		if m:GetAttribute("ExhibitId") == id then return m end
	end
	return nil
end

local function has(list, x)
	for _, v in list or {} do
		if v == x then return true end
	end
	return false
end

local function layout()
	local vh = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
	if exploring then
		-- exploração do foguete: coluna à direita em qualquer tela (o foguete fica na área livre)
		local compact = UI.isCompact()
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, compact and -8 or -12, 0, compact and 8 or 60)
		frame.Size = UDim2.new(compact and 0.46 or 0.34, 0, 1, compact and -16 or -76)
		return
	end
	if UI.isCompact() and vh < 520 then
		-- celular deitado: quase tela cheia, senão o rodapé come o espaço do conteúdo
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.new(1, -16, 1, -16)
	elseif UI.isCompact() then
		frame.AnchorPoint = Vector2.new(0.5, 1)
		frame.Position = UDim2.new(0.5, 0, 1, -8)
		frame.Size = UDim2.new(1, -16, 0.52, 0)
	else
		-- abaixo da barra do HUD (Diary/Settings, Y 8..52) para não cobri-la
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, -12, 0, 60)
		frame.Size = UDim2.new(0.4, 0, 1, -76)
	end
end

local function build()
	gui = UI.screenGui("MuseumPanel", 20)
	frame = UI.new("Frame", {
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.08,
		Visible = false,
		Parent = gui,
	})
	UI.corner(frame, 8)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(620, math.huge), Parent = frame })
	UI.new("UIStroke", { Color = UI.C.line, Thickness = 1, Parent = frame })
	UI.new("Frame", { -- faixa laranja no topo
		BackgroundColor3 = UI.C.accent, BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 3), Position = UDim2.new(0, 8, 0, 0), Parent = frame,
	})

	local header = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = frame })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 64), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 6), Parent = header })
	UI.list(header, 2)
	titleL = UI.label(header, "", 26, Enum.FontWeight.Bold, UI.C.text, 1)
	subL = UI.label(header, "", 15, Enum.FontWeight.Medium, UI.C.muted, 2)

	local close = UI.button(frame, "X", function() Panel.close() end, { size = UDim2.fromOffset(44, 44), textSize = 18 })
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Name = "Close"

	body = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 84),
		Size = UDim2.new(1, 0, 1, -84 - 64),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UI.C.muted,
		Parent = frame,
	})
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 10), Parent = body })
	UI.list(body, 10)

	footer = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 64),
		Parent = frame,
	})
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), Parent = footer })
	local footerList = UI.list(footer, 8, true)

	-- Corpo entre o cabeçalho e o rodapé; o rodapé cresce quando os botões quebram linha
	local function relayout()
		local h = header.AbsoluteSize.Y + 4
		local f = footerList.AbsoluteContentSize.Y + 20
		footer.Size = UDim2.new(1, 0, 0, f)
		body.Position = UDim2.new(0, 0, 0, h)
		body.Size = UDim2.new(1, 0, 1, -h - f)
	end
	layout()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if frame then layout() end
		if exploring then task.defer(Panel.updateExploreInset) end
	end)
	header:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	footerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(relayout)

	-- Esc (quando o Roblox entrega a tecla) e Backspace também fecham
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if not current then return end
		if input.KeyCode == Enum.KeyCode.Backspace and not processed and exploring then
			Explorer.exit() -- Backspace na exploração = voltar à exposição
		elseif input.KeyCode == Enum.KeyCode.Escape or (input.KeyCode == Enum.KeyCode.Backspace and not processed) then
			Panel.close()
		end
	end)
end

local function clear()
	for _, c in body:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
	for _, c in footer:GetChildren() do
		if c:IsA("GuiButton") then c:Destroy() end
	end
	body.CanvasPosition = Vector2.zero
	sourcesShown = false
end

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function heading(text)
	UI.label(body, string.upper(text), 14, Enum.FontWeight.Bold, UI.C.accent, nextOrder())
end

local function paragraph(text, color)
	UI.label(body, text, 17, Enum.FontWeight.Medium, color, nextOrder())
end

local function banner(text)
	local f = UI.new("Frame", { BackgroundColor3 = UI.C.warn, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = body })
	UI.corner(f, 4)
	UI.pad(f, 6)
	UI.label(f, text, 13, Enum.FontWeight.Bold, Color3.new(0.08, 0.08, 0.08))
end

-- Galeria de fotos reais da NASA: foto grande, setas, legenda oficial, data e crédito
local function gallery(d)
	local photos = Content.gallery(d)
	if #photos == 0 then return end
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = body })
	UI.list(holder, 4)
	-- altura grande + DominantAxis Width: a restrição reduz para 4:3 (com altura 0 a foto ficava 0 × 0)
	local frameImg = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 0, 10000), LayoutOrder = 1, Parent = holder })
	UI.new("UIAspectRatioConstraint", { AspectRatio = 4 / 3, DominantAxis = Enum.DominantAxis.Width, Parent = frameImg })
	UI.corner(frameImg, 6)
	local pic = UI.new("ImageLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, Parent = frameImg,
	})
	-- estado de carregamento: a foto nova pode levar um instante; sem isto o quadro fica preto
	local loading = UI.new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "Loading photo…",
		TextColor3 = UI.C.muted, FontFace = UI.font(Enum.FontWeight.Medium), TextSize = 14, Parent = frameImg,
	})
	-- IsLoaded nem sempre dispara o sinal de mudança: confere a cada 0,25 s (até 8 s)
	local loadSeq = 0
	local function syncLoading()
		loadSeq += 1
		local seq = loadSeq
		loading.Visible = not pic.IsLoaded
		task.spawn(function()
			local t0 = os.clock()
			while seq == loadSeq and loading.Parent and not pic.IsLoaded and os.clock() - t0 < 8 do task.wait(0.25) end
			if seq == loadSeq and loading.Parent then loading.Visible = not pic.IsLoaded end
		end)
	end
	local caption = UI.label(holder, "", 14, Enum.FontWeight.Medium, UI.C.text, 2)
	local credit = UI.label(holder, "", 12, Enum.FontWeight.Medium, UI.C.muted, 3)
	local index = 1
	local counter
	local function show()
		local item = photos[index]
		local ph = item.Photo
		pic.Image = ph.AssetId
		syncLoading()
		caption.Text = ph.Caption or ""
		local kind = ph.Illustration and "Illustration" or "Photo"
		credit.Text = string.format("%s: %s%s  ·  NASA ID %s", kind, ph.Credit, ph.Date ~= "" and ("  ·  " .. ph.Date) or "", item.Id)
		if counter then counter.Text = string.format("%d / %d", index, #photos) end
	end
	if #photos > 1 then
		for _, side in { -1, 1 } do
			local b = UI.button(frameImg, side == -1 and "<" or ">", function()
				index = (index - 1 + side) % #photos + 1
				show()
			end, { size = UDim2.fromOffset(44, 44), textSize = 20, color = UI.C.panel })
			b.AnchorPoint = Vector2.new(side == -1 and 0 or 1, 0.5)
			b.Position = UDim2.new(side == -1 and 0 or 1, side == -1 and 8 or -8, 0.5, 0)
			b.BackgroundTransparency = 0.25
		end
		counter = UI.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -8), Size = UDim2.fromOffset(64, 24),
			BackgroundColor3 = UI.C.panel, BackgroundTransparency = 0.25, TextColor3 = UI.C.text,
			FontFace = UI.font(Enum.FontWeight.SemiBold), TextSize = 14, Text = "", Parent = frameImg,
		})
		UI.corner(counter, 4)
	end
	show()
end

-- Fatos-chave, cada um com a foto/página oficial de onde veio
local function keyFacts(d)
	if not d.KeyFacts or #d.KeyFacts == 0 then return end
	heading(Text.get("panel.keyFacts"))
	for _, f in d.KeyFacts do
		local src = f.Source or ""
		local label = src:match("^https://") and src or ("NASA " .. src)
		paragraph(string.format('•  %s\n<font color="#8C99AB" size="12">Source: %s</font>', f.Text, label))
	end
end

local function dataTable(rows)
	if not rows or #rows == 0 then return end
	heading(Text.get("panel.data"))
	for _, r in rows do
		paragraph(string.format('<font color="#AEB9C8">%s</font>   %s', r.Label, r.Value))
	end
end

local function sources(list)
	if sourcesShown then return end
	sourcesShown = true
	heading(Text.get("panel.sources"))
	for _, s in list or {} do
		paragraph(string.format("%s\n<font color=\"#AEB9C8\">%s</font>", s.Title or "", s.Url or ""))
	end
	if current then
		for _, item in Content.gallery(current.data) do
			paragraph(string.format("Photo %s (%s)\n<font color=\"#AEB9C8\">%s</font>", item.Id, item.Photo.Credit, item.Photo.Source))
		end
	end
end

local function typeLine(d)
	-- o objeto 3D é reconstrução digital; as fotos são reais (crédito em cada uma)
	UI.label(body, Text.get("type." .. tostring(d.Type)) .. "  ·  " .. Text.get("panel.photosReal"), 13, Enum.FontWeight.Medium, UI.C.muted, nextOrder())
end

local function showVerified(d)
	return d.Verified == true or Config.MODE ~= "demo"
end

local function fillExhibit()
	local d = current.data
	clear()
	order = 0
	titleL.Text = string.upper(d.Name)
	local parts = { d.Program }
	if d.Period and showVerified(d) then table.insert(parts, d.Period) end
	subL.Text = table.concat(parts, "  |  ")
	if not d.Verified then banner(Text.get("panel.unverified")) end
	gallery(d)
	if d.History then
		heading(Text.get("panel.history"))
		paragraph(d.History)
	end
	for i, step in d.Timeline or {} do
		heading(string.format("%d · %s", i, step.Title))
		paragraph(string.format('<font color="#AEB9C8">%s</font>\n%s', step.Date or "", step.Text))
	end
	keyFacts(d)
	dataTable(d.Data)
	if d.DidYouKnow then
		heading(Text.get("panel.didYouKnow"))
		paragraph(d.DidYouKnow)
	end
	typeLine(d)

	-- Botões
	local model = current.model
	if model and d.Explore and has(d.Interactions, "Explore") then
		UI.button(footer, Text.get("panel.explore"), function() Panel.startExplore() end, { order = 0, color = UI.C.accent })
	end
	if model and d.Components and has(d.Interactions, "Components") then
		UI.button(footer, Text.get("panel.components"), function()
			if Components.isActive() then
				Components.exit()
				fillExhibit()
			else
				Components.enter(model, d, Panel.showComponent)
				paragraph(Text.get("panel.componentsHint"), UI.C.muted)
			end
		end, { order = 1 })
	end
	if model and has(d.Interactions, "Stages") then
		local b
		b = UI.button(footer, Components.stagesOpen(model) and Text.get("panel.stagesBack") or Text.get("panel.stages"), function()
			local open = Components.toggleStages(model, d)
			b.Text = open and Text.get("panel.stagesBack") or Text.get("panel.stages")
		end, { order = 2 })
	end
	if model and has(d.Interactions, "Doors") then
		UI.button(footer, Text.get("panel.doors"), function() Components.toggleDoors(model) end, { order = 3 })
	end
	UI.button(footer, Text.get("panel.sources"), function() sources(d.Sources) end, { order = 4 })
end

local function fillCard()
	local d = current.data
	local owned = State.progress.cards[d.Id] == true
	clear()
	order = 0
	titleL.Text = string.upper(owned and d.Name or Text.get("card.locked"))
	subL.Text = owned and (d.Year or "") or string.format(Text.get("card.unlockHint"), d.UnlockHint or "?")
	if not owned then
		paragraph(string.format(Text.get("card.unlockHint"), d.UnlockHint or "?"), UI.C.muted)
		return
	end
	if not d.Verified then banner(Text.get("panel.unverified")) end
	gallery(d)
	heading(Text.get("card.purpose"))
	paragraph(d.Purpose)
	if d.DidYouKnow then
		heading(Text.get("panel.didYouKnow"))
		paragraph(d.DidYouKnow)
	end
	if d.CommonWithYou then
		heading(Text.get("card.commonWithYou"))
		paragraph(d.CommonWithYou)
	end
	if d.RelatedExhibit then
		UI.button(footer, Text.get("panel.showInMuseum"), function()
			World.showPath(d.RelatedExhibit)
			Panel.close()
		end, { order = 1, color = UI.C.accent })
	end
	UI.button(footer, Text.get("panel.sources"), function() sources(d.Sources) end, { order = 2 })
end

-- Detalhe de um componente (chamado pelo ComponentsController)
function Panel.showComponent(c)
	if not current then return end
	clear()
	order = 0
	heading(current.data.Name)
	UI.label(body, c.Name, 22, Enum.FontWeight.Bold, UI.C.text, nextOrder())
	if c.Function then paragraph(c.Function) end
	if c.Details then paragraph(c.Details, UI.C.muted) end
	if c.Material then paragraph("Material: " .. c.Material, UI.C.muted) end
	UI.button(footer, Text.get("panel.back"), function()
		Components.exit()
		fillExhibit()
	end, { order = 1 })
end

---------------------------------------------------------------------------------
-- Explore rocket (RocketExplorer): lista de partes + detalhe da parte escolhida no mesmo painel
---------------------------------------------------------------------------------
local function isGamepad()
	local ok, pref = pcall(function() return UIS.PreferredInput end)
	return ok and pref == Enum.PreferredInput.Gamepad
end

-- foto da parte com estado de carregamento e substituto legível
local function partPhoto(c)
	local ph = c.Photo and Content.photo(c.Photo)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = body })
	UI.list(holder, 4)
	local frameImg = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 0, 10000), LayoutOrder = 1, Parent = holder })
	UI.new("UIAspectRatioConstraint", { AspectRatio = 4 / 3, DominantAxis = Enum.DominantAxis.Width, Parent = frameImg })
	UI.corner(frameImg, 6)
	local pic = UI.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, Image = ph and ph.AssetId or "", Parent = frameImg })
	local status = UI.new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), TextWrapped = true,
		Text = ph and Text.get("explore.loading") or Text.get("explore.noPhoto"),
		TextColor3 = UI.C.muted, FontFace = UI.font(Enum.FontWeight.Medium), TextSize = 14, Parent = frameImg,
	})
	-- IsLoaded nem sempre dispara o sinal de mudança: confere a cada 0,25 s (até 8 s)
	task.spawn(function()
		local t0 = os.clock()
		while status.Parent and not pic.IsLoaded and os.clock() - t0 < 8 do task.wait(0.25) end
		if not status.Parent then return end
		status.Visible = not pic.IsLoaded
		if ph and not pic.IsLoaded then status.Text = Text.get("explore.noPhoto") .. "\n" .. (ph.Caption or "") end
	end)
	if ph then
		local kind = ph.Illustration and Text.get("explore.illustration") or Text.get("explore.photo")
		UI.label(holder, ph.Caption or "", 14, Enum.FontWeight.Medium, UI.C.text, 2)
		UI.label(holder, string.format("%s: %s%s  ·  NASA ID %s", kind, ph.Credit or "NASA", (ph.Date and ph.Date ~= "") and ("  ·  " .. ph.Date) or "", c.Photo), 12, Enum.FontWeight.Medium, UI.C.muted, 3)
		if c.Overview then UI.label(holder, Text.get("explore.overview"), 12, Enum.FontWeight.Medium, UI.C.muted, 4) end
	end
end

local function fillExplore(sel)
	if not current then return end
	local d = current.data
	clear()
	order = 0
	titleL.Text = string.upper(d.Name)
	subL.Text = Text.get("explore.title")
	paragraph(isGamepad() and Text.get("explore.hintPad") or Text.get("explore.hint"), UI.C.muted)
	if sel then
		UI.label(body, sel.Name, 22, Enum.FontWeight.Bold, UI.C.text, nextOrder())
		heading(Text.get("explore.function"))
		paragraph(sel.Function)
		partPhoto(sel)
		if sel.Facts and #sel.Facts > 0 then
			heading(Text.get("explore.facts"))
			for _, f in sel.Facts do
				local src = f.Source or ""
				local label = src:match("^https://") and src or ("NASA " .. src)
				paragraph(string.format('•  %s\n<font color="#8C99AB" size="12">Source: %s</font>', f.Text, label))
			end
		end
	end
	heading(Text.get("explore.list"))
	local first, chosen
	for _, c in d.Explore do
		local isSel = sel and sel.Id == c.Id
		local b = UI.button(body, (isSel and "●  " or "○  ") .. c.Name, function()
			Explorer.select(c.Id, true)
			fillExplore(c)
		end, { size = UDim2.new(1, 0, 0, 44), color = isSel and UI.C.accent or UI.C.panel2, order = nextOrder() })
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.Name = "Part_" .. c.Id
		first = first or b
		if isSel then chosen = b end
	end
	UI.button(footer, Text.get("explore.back"), function() Explorer.exit() end, { order = 1, color = UI.C.accent })
	if isGamepad() then GuiService.SelectedObject = chosen or first end
end

function Panel.updateExploreInset()
	if not exploring or not frame then return end
	local vp = workspace.CurrentCamera.ViewportSize
	-- parte da largura coberta pelo painel (com a margem à direita)
	local covered = (vp.X - frame.AbsolutePosition.X) / math.max(vp.X, 1)
	Explorer.setInset(covered)
end

function Panel.startExplore()
	if not current or not current.model then return end
	local ok = Explorer.enter(current.model, current.data, {
		onSelect = function(c) if exploring then fillExplore(c) end end,
		onExit = function()
			if not exploring then return end
			exploring = false
			if not current then return end
			layout()
			if isGamepad() then GuiService.SelectedObject = nil end
			fillExhibit()
		end,
		overUi = function(pos)
			if not frame or not frame.Visible then return false end
			local a, z = frame.AbsolutePosition, frame.AbsoluteSize
			return pos.X >= a.X and pos.X <= a.X + z.X and pos.Y >= a.Y and pos.Y <= a.Y + z.Y
		end,
	})
	if not ok then
		paragraph(Text.get("explore.busy"), UI.C.muted)
		return
	end
	exploring = true
	layout()
	fillExplore(nil)
	task.defer(Panel.updateExploreInset)
end

local function watchDistance()
	if distConn then distConn:Disconnect() end
	local acc = 0
	distConn = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 or not current then return end
		acc = 0
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local anchor = current.anchor
		if root and anchor and anchor.Parent then
			local limit = (current.dist or Config.PROMPT_DEFAULT_DISTANCE) + Config.PANEL_CLOSE_EXTRA
			if (root.Position - anchor.Position).Magnitude > limit then Panel.close() end
		end
	end)
end

local function anchorOf(model)
	return model and (model:FindFirstChild("PromptAnchor", true) or model.PrimaryPart)
end

function Panel.openExhibit(id)
	if current and current.kind == "exhibit" and current.id == id then
		if exploring then return end -- na exploração do foguete o painel fica aberto
		Panel.close() -- acionar o mesmo prompt de novo fecha
		return
	end
	local d = Content.exhibit(id)
	if not d then return end
	if not gui then build() end
	Panel.close()
	local model = findModel(id)
	current = { kind = "exhibit", id = id, data = d, model = model, anchor = anchorOf(model), dist = d.PromptDistance }
	State.mark("exhibitsSeen", id)
	fillExhibit()
	showFrame()
	watchDistance()
end

function Panel.openCard(id)
	if current and current.kind == "card" and current.id == id then
		Panel.close()
		return
	end
	local d = Content.card(id)
	if not d then return end
	if not gui then build() end
	Panel.close()
	current = { kind = "card", id = id, data = d, anchor = World.cardSlotAnchor(id), dist = 10 }
	fillCard()
	showFrame()
	watchDistance()
end

function Panel.close()
	if exploring then
		exploring = false
		Explorer.exit()
		if frame then layout() end
	end
	if Components.isActive() then Components.exit() end
	if current and current.model then Components.resetModel(current.model) end
	current = nil
	if distConn then
		distConn:Disconnect()
		distConn = nil
	end
	if frame then frame.Visible = false end
	if touchSaved ~= nil then
		GuiService.TouchControlsEnabled = touchSaved
		touchSaved = nil
	end
end

function Panel.isOpen()
	return current ~= nil
end

return Panel
