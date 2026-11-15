-- Manifesto em duas abas; o servidor continua validando traje, carga e embarque.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GS = RS:WaitForChild("GuideSystem")
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))
local UI = require(script.Parent:WaitForChild("GuideUI"))
local ItemIcons = require(script.Parent:WaitForChild("ItemIcons"))
local player = Players.LocalPlayer
local MissionSelect = {}
local R = Missoes.RegrasGerais
local MAX_ITEMS = 2 -- Sessao também recusa mais de dois.
local selected, items, locked = 1, {}, true
local panel, title, status, missionRow, equipmentGrid, gridLayout
local weight, weightFill, ready, suitButton, missionName
local pages, missionCards, itemCards, tweens = {}, {}, {}, {}
local activeTab = 1
local transitionId = 0
local refresh, buildEquipment, resize

local function close()
	panel.Visible = false
end

local function stopTweens()
	transitionId += 1
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)
end

local function showTab(index, animate)
	local previous = activeTab
	stopTweens()
	activeTab = index
	title.Text = index == 1 and "SELECT YOUR MISSION" or "CHOOSE YOUR EQUIPMENT"
	for i, page in pages do
		page.Visible = i == index or (animate and i == previous)
		page.Position = UDim2.new()
		page.GroupTransparency = 0
	end
	if not animate or previous == index then
		for i, page in pages do
			page.Visible = i == index
		end
		return
	end
	local direction = index > previous and 1 or -1
	local incoming, outgoing = pages[index], pages[previous]
	incoming.Position = UDim2.fromOffset(direction * 24, 0)
	incoming.GroupTransparency = 1
	local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local enter = TweenService:Create(incoming, info, { Position = UDim2.new(), GroupTransparency = 0 })
	local leave = TweenService:Create(outgoing, info, {
		Position = UDim2.fromOffset(-direction * 24, 0), GroupTransparency = 1,
	})
	tweens = { enter, leave }
	local token = transitionId
	leave.Completed:Connect(function()
		if token == transitionId then
			outgoing.Visible = false
		end
	end)
	enter:Play()
	leave:Play()
end

local function stack(parent, gap)
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = parent,
	})
end

local function label(parent, text, size, order, color)
	return UI.text(parent, {
		Text = text, TextSize = size, Color = color,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order,
	})
end

-- A borda reage sem reconstruir os cartões nem perder a posição de rolagem.
local function interactive(button, isSelected, isDisabled)
	button.AutoButtonColor = false
	UI.stroke(button, UI.C.line, 1.5)
	local border = button:FindFirstChildOfClass("UIStroke")
	local hovered, pressed = false, false
	local function update()
		local disabled = isDisabled and isDisabled()
		local chosen = isSelected()
		border.Color = not disabled and (chosen or pressed) and UI.C.accent
			or (not disabled and hovered and UI.C.muted or UI.C.line)
		border.Thickness = chosen and not disabled and 2.5 or 1.5
	end
	button.MouseEnter:Connect(function() hovered = true update() end)
	button.MouseLeave:Connect(function() hovered, pressed = false, false update() end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			update()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = false
			update()
		end
	end)
	update()
	return update
end

local function buildMissions()
	for id = 1, 2 do
		local mission = Missoes.Lista[id]
		local card = UI.button(missionRow, {
			Text = "", Color = UI.C.panel2, Size = UDim2.new(0.5, -6, 0, 0), LayoutOrder = id,
		})
		card.Name = "Mission" .. id
		card.AutomaticSize = Enum.AutomaticSize.Y
		UI.pad(card, 16)
		stack(card, 12)
		label(card, mission.Nome, 20, 1).FontFace = UI.font(Enum.FontWeight.Bold)
		label(card, mission.Tagline, 16, 2, UI.C.accent)
		label(card, mission.Descricao, 15, 3, UI.C.muted)
		label(card, "Task guide", 16, 4).FontFace = UI.font(Enum.FontWeight.Bold)
		for i, line in mission.Guia do
			-- As linhas já incluem a numeração exata fornecida pela configuração.
			label(card, line, 14, 4 + i, UI.C.muted)
		end
		local badge = label(card, "LOCKED · Earn 1★ on Mercury", 14, 8, UI.C.accent)
		local choose = UI.button(card, {
			Text = "Select mission ›", TextSize = 16,
			Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 9,
		})
		local function selectMission()
			if id == 2 and locked then return end
			if selected ~= id then
				selected, items = id, {}
				buildEquipment()
			end
			status.Text = "Choose up to two items. The crew shares one payload."
			refresh()
			showTab(2, true)
		end
		card.Activated:Connect(selectMission)
		choose.Activated:Connect(selectMission)
		local update = interactive(card, function() return selected == id end, function() return id == 2 and locked end)
		missionCards[id] = { card = card, badge = badge, choose = choose, update = update }
	end
end

buildEquipment = function()
	for _, entry in itemCards do
		entry.card:Destroy()
	end
	table.clear(itemCards)
	local mission = Missoes.Lista[selected]
	missionName.Text = mission.Nome
	for index, key in mission.OrdemEquipamentos do
		local eq = mission.Equipamentos[key]
		local card = UI.button(equipmentGrid, {
			Text = "", Color = UI.C.panel2, LayoutOrder = index,
		})
		card.Name = key
		local icon = ItemIcons.make(eq.Icone, card, 54)
		icon.Position = UDim2.fromOffset(12, 12)
		if icon:GetAttribute("Fallback") then
			UI.text(icon, {
				Text = string.sub(eq.Nome, 1, 1), TextSize = 24,
				AlignX = Enum.TextXAlignment.Center, AlignY = Enum.TextYAlignment.Center,
			})
		end
		local check = UI.text(card, {
			Text = "✓", Color = UI.C.accent, TextSize = 24,
			Position = UDim2.new(1, -38, 0, 12), Size = UDim2.fromOffset(28, 32),
		})
		UI.text(card, {
			Text = eq.Nome, TextSize = 16, Weight = Enum.FontWeight.Bold,
			Position = UDim2.fromOffset(12, 76), Size = UDim2.new(1, -24, 0, 48),
		})
		UI.text(card, {
			Text = eq.Peso .. " kg", TextSize = 23, Color = UI.C.accent, Weight = Enum.FontWeight.Bold,
			Position = UDim2.fromOffset(12, 128), Size = UDim2.new(1, -24, 0, 32),
		})
		UI.text(card, {
			Text = eq.Efeito, TextSize = 14, Color = UI.C.muted,
			Position = UDim2.fromOffset(12, 168), Size = UDim2.new(1, -24, 1, -180),
		})
		local update = interactive(card, function() return items[key] == true end)
		itemCards[key] = { card = card, check = check, update = update }
		card.Activated:Connect(function()
			if not items[key] then
				local n = 0
				for _ in items do n += 1 end
				if n >= MAX_ITEMS then
					status.Text = "You can take up to two items. Remove one to choose another."
					return
				end
			end
			items[key] = not items[key] or nil
			status.Text = "Choose up to two items. The crew shares one payload."
			refresh()
		end)
	end
	resize()
end

refresh = function()
	for id, entry in missionCards do
		local disabled = id == 2 and locked
		entry.badge.Visible = disabled
		entry.card.Active = not disabled
		entry.card.Selectable = not disabled
		entry.choose.Active = not disabled
		entry.choose.Selectable = not disabled
		entry.choose.Text = disabled and "Locked" or "Select mission ›"
		entry.card.BackgroundTransparency = disabled and 0.5 or 0
		for _, child in entry.card:GetDescendants() do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = disabled and child ~= entry.badge and 0.45 or 0
			end
		end
		entry.update()
	end
	for key, entry in itemCards do
		entry.check.Visible = items[key] == true
		entry.update()
	end
	local total = Missoes.pesoTotal(Missoes.Lista[selected], items)
	local limit = R.LimiteFoguete
	local over = total > limit
	weight.Text = over
		and ("OVER LIMIT · Weight %d / %d kg · remove %d kg"):format(total, limit, total - limit)
		or ("Weight %d / %d kg (ship %d kg) · Free %d kg · Lightness bonus −%d s"):format(
			total, limit, R.PesoNave, limit - total, Missoes.bonusLeveza(total))
	weight.TextColor3 = over and UI.C.red
		or (total > R.PesoVerdeAte and Color3.fromHex("FFE14D") or Color3.fromHex("54E878"))
	weightFill.Size = UDim2.fromScale(math.clamp(total / limit, 0, 1), 1)
	weightFill.BackgroundColor3 = weight.TextColor3
	local suit = player:GetAttribute("SuitOn") == true
	suitButton.Text = suit and "✓ Space suit ready" or "Put on space suit"
	local n = 0
	for _ in items do n += 1 end
	ready.Text = ("%s Suit   ·   ✓ Items %d / %d   ·   %s Weight %d / %d kg"):format(
		suit and "✓" or "✗", n, MAX_ITEMS, over and "✗" or "✓", total, limit)
	ready.TextColor3 = (suit and not over) and Color3.fromHex("54E878") or Color3.fromHex("FFE14D")
end

resize = function()
	local narrow = missionRow.AbsoluteSize.X < 680
	local layout = missionRow:FindFirstChildOfClass("UIListLayout")
	layout.FillDirection = narrow and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	for _, entry in missionCards do
		entry.card.Size = narrow and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -6, 0, 0)
	end
	local width = equipmentGrid.AbsoluteSize.X
	local phone = UI.isTouch() and panel.AbsoluteSize.Y < 500
	local columns = (phone or width < 600) and 2 or 3
	local cellWidth = (width - (columns - 1) * 12) / columns
	gridLayout.FillDirectionMaxCells = columns
	gridLayout.CellSize = UDim2.new(1 / columns, -12 * (columns - 1) / columns, 0, cellWidth < 170 and 364 or 300)
end

function MissionSelect.open(data)
	locked = data.issLocked == true
	selected, items = 1, {}
	status.Text = ("Choose a mission and up to two items. The capsule weighs %d kg and the rocket lifts %d kg.\nCo-op: the first crew member to board sets the shared manifest; the others have 12 s to join."):format(R.PesoNave, R.LimiteFoguete)
	panel.Visible = true
	buildEquipment()
	refresh()
	for _, page in pages do
		page:FindFirstChild("Content").CanvasPosition = Vector2.zero
	end
	showTab(1, false)
end

function MissionSelect.start()
	local gui = UI.screenGui("MissionSelectGui", 25)
	panel = UI.new("Frame", {
		BackgroundColor3 = UI.C.panel, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.94, 0.92),
		Visible = false, ClipsDescendants = true, Parent = gui,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(1000, 900), Parent = panel })
	UI.corner(panel, 14)
	UI.pad(panel, 16)
	title = UI.text(panel, {
		TextSize = UI.isTouch() and 18 or 22, Weight = Enum.FontWeight.Bold,
		Size = UDim2.new(1, 0, 0, 56),
	})
	status = UI.text(panel, {
		TextSize = 14, Color = UI.C.muted, Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	})
	local viewport = UI.new("Frame", {
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = panel,
	})
	-- O status cresce em telas estreitas; o conteúdo mantém sua própria rolagem.
	local function fitViewport()
		local top = 60 + status.AbsoluteSize.Y + 12
		viewport.Position = UDim2.fromOffset(0, top)
		viewport.Size = UDim2.new(1, 0, 1, -top - 58)
	end
	status:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitViewport)
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitViewport)
	local contents = {}
	for i = 1, 2 do
		local page = UI.new("CanvasGroup", {
			Name = i == 1 and "MissionsTab" or "EquipmentTab", BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), Visible = i == 1, Parent = viewport,
		})
		pages[i] = page
		local scroll = UI.new("ScrollingFrame", {
			Name = "Content", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(), ScrollBarThickness = 4,
			ScrollingDirection = Enum.ScrollingDirection.Y, Parent = page,
		})
		UI.pad(scroll, 4)
		local content = UI.new("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, Parent = scroll,
		})
		stack(content, 12)
		contents[i] = content
	end
	missionRow = UI.new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Parent = contents[1],
	})
	stack(missionRow, 12)
	local back = UI.button(contents[2], {
		Text = "‹ Back", Color = UI.C.panel2, Size = UDim2.fromOffset(110, 44), LayoutOrder = 1,
	})
	back.Activated:Connect(function() showTab(1, true) end)
	missionName = label(contents[2], "", 20, 2)
	missionName.FontFace = UI.font(Enum.FontWeight.Bold)
	equipmentGrid = UI.new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = contents[2],
	})
	gridLayout = UI.new("UIGridLayout", {
		CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = equipmentGrid,
	})
	weight = label(contents[2], "", 16, 4)
	local track = UI.new("Frame", {
		BackgroundColor3 = UI.C.panel2, Size = UDim2.new(1, 0, 0, 10), LayoutOrder = 5, Parent = contents[2],
	})
	UI.corner(track, 5)
	weightFill = UI.new("Frame", { BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = track })
	UI.corner(weightFill, 5)
	ready = label(contents[2], "", 15, 6)
	ready.Name = "Checklist"
	ready.FontFace = UI.font(Enum.FontWeight.Bold)
	suitButton = UI.button(contents[2], {
		Text = "Put on space suit", Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 7,
	})
	suitButton.Activated:Connect(function() GS.Remotes.MissionSelect:FireServer({ action = "Suit" }) end)
	local board = UI.button(contents[2], {
		Text = "Board and launch ›", Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 8,
	})
	board.Activated:Connect(function()
		GS.Remotes.MissionSelect:FireServer({ action = "Board", id = selected, items = items })
	end)
	local cancel = UI.button(panel, {
		Text = "Cancel", Color = UI.C.panel2, Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -44),
	})
	cancel.Activated:Connect(close)
	buildMissions()
	missionRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	equipmentGrid:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	fitViewport()
	GS:WaitForChild("Remotes"):WaitForChild("MissionSelect").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then return end
		if data.kind == "Open" then
			MissionSelect.open(data)
		elseif data.kind == "Feedback" then
			status.Text = data.text
			refresh()
		end
	end)
	player:GetAttributeChangedSignal("SuitOn"):Connect(function()
		if panel.Visible then refresh() end
	end)
	player:GetAttributeChangedSignal("RookieMission"):Connect(function()
		if player:GetAttribute("RookieMission") then close() end
	end)
end

return MissionSelect
