-- Painel único de voo: missão, traje e trade-off antes do embarque. Servidor valida tudo.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GS = RS:WaitForChild("GuideSystem")
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))
local UI = require(script.Parent:WaitForChild("GuideUI"))
local player = Players.LocalPlayer
local MissionSelect = {}
local panel, list, status, weight, suitButton, weightFill, ready
local R = Missoes.RegrasGerais
local MAX_ITEMS = 2 -- o servidor (Sessao) também recusa mais de dois
local selected, items, locked = 1, {}, true
local refresh

local function close()
	panel.Visible = false
end

refresh = function()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	for id = 1, 2 do
		local b = UI.button(list, {
			Text = (selected == id and "● SELECTED · " or "○ ") .. Missoes.Lista[id].Nome
				.. (id == 2 and locked and " · LOCKED (earn 1★ on Mercury)" or ""),
			TextSize = 15, Color = selected == id and UI.C.accent or UI.C.panel2,
			Size = UDim2.new(1, 0, 0, 46), LayoutOrder = id,
		})
		b.Activated:Connect(function()
			if id == 2 and locked then status.Text = "Earn a Mercury star to unlock the ISS." return end
			selected, items = id, {}
			status.Text = "Choose up to two items. The crew shares one payload."
			refresh()
		end)
	end
	local mission = Missoes.Lista[selected]
	-- resumo da missão escolhida: as três tasks, na ordem
	local resumo = {}
	for i, t in mission.Tasks do
		resumo[i] = ("Task %d · %s"):format(i, t.Nome)
	end
	local info = UI.text(list, {
		Text = table.concat(resumo, "\n"), TextSize = 14, Color = UI.C.muted,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3,
	})
	info.Name = "Summary"
	for index, key in mission.OrdemEquipamentos do
		local eq = mission.Equipamentos[key]
		local b = UI.button(list, {
			Text = (items[key] and "✓ " or "+ ") .. eq.Nome .. " · " .. eq.Peso .. " kg\n" .. eq.Efeito,
			TextSize = 14, Color = items[key] and UI.C.accent or UI.C.panel2,
			Size = UDim2.new(1, 0, 0, 72), LayoutOrder = 3 + index,
		})
		b.TextWrapped = true
		b.Activated:Connect(function()
			if not items[key] then
				local n = 0
				for _ in items do n += 1 end
				if n >= MAX_ITEMS then
					status.Text = "You can take up to two items. Remove one to choose another."
					return
				end
			end
			items[key] = not items[key] or nil
			refresh()
		end)
	end
	local total = Missoes.pesoTotal(mission, items)
	local limit = R.LimiteFoguete
	local over = total > limit
	weight.Text = over
		and ("OVER LIMIT · Weight %d / %d kg · remove %d kg"):format(total, limit, total - limit)
		or ("Weight %d / %d kg (ship %d kg) · Free %d kg · Lightness bonus −%d s"):format(total, limit, R.PesoNave, limit - total, Missoes.bonusLeveza(total))
	weight.TextColor3 = over and UI.C.red or (total > R.PesoVerdeAte and Color3.fromHex("FFE14D") or Color3.fromHex("54E878"))
	weightFill.Size = UDim2.fromScale(math.clamp(total / limit, 0, 1), 1)
	weightFill.BackgroundColor3 = weight.TextColor3
	local suit = player:GetAttribute("SuitOn") == true
	suitButton.Text = suit and "✓ Space suit ready" or "Put on space suit"
	-- o que falta para embarcar (texto, não só cor); o botão continua ativo e o servidor explica
	local n = 0
	for _ in items do n += 1 end
	ready.Text = ("%s Suit   ·   ✓ Items %d / %d   ·   %s Weight %d / %d kg"):format(
		suit and "✓" or "✗", n, MAX_ITEMS, over and "✗" or "✓", total, limit)
	ready.TextColor3 = (suit and not over) and Color3.fromHex("54E878") or Color3.fromHex("FFE14D")
end

function MissionSelect.open(data)
	locked = data.issLocked == true
	selected, items = 1, {}
	status.Text = ("Choose a mission and up to two items. The capsule weighs %d kg and the rocket lifts %d kg.\nCo-op: the first crew member to board sets the shared manifest; the others have 12 s to join."):format(R.PesoNave, R.LimiteFoguete)
	refresh()
	panel.Visible = true
end

function MissionSelect.start()
	local gui = UI.screenGui("MissionSelectGui", 25)
	panel = UI.new("ScrollingFrame", {
		BackgroundColor3 = UI.C.panel, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.92, 0.9),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 5,
		Visible = false, Parent = gui,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(660, 760), Parent = panel })
	UI.corner(panel, 14)
	UI.pad(panel, 16)
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	UI.text(panel, { Text = "MISSION FLIGHT MANIFEST", TextSize = 22, Weight = Enum.FontWeight.Bold, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 })
	status = UI.text(panel, { TextSize = 15, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	list = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = panel })
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	weight = UI.text(panel, { TextSize = 16, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 4 })
	local track = UI.new("Frame", { BackgroundColor3 = UI.C.panel2, Size = UDim2.new(1, 0, 0, 10), LayoutOrder = 4, Parent = panel })
	UI.corner(track, 5)
	weightFill = UI.new("Frame", { BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = track })
	UI.corner(weightFill, 5)
	ready = UI.text(panel, { TextSize = 15, Weight = Enum.FontWeight.Bold, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 5 })
	ready.Name = "Checklist"
	suitButton = UI.button(panel, { Text = "Put on space suit", Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 6 })
	suitButton.Activated:Connect(function() GS.Remotes.MissionSelect:FireServer({ action = "Suit" }) end)
	local board = UI.button(panel, { Text = "Board and launch ›", Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 7 })
	board.Activated:Connect(function()
		GS.Remotes.MissionSelect:FireServer({ action = "Board", id = selected, items = items })
	end)
	local cancel = UI.button(panel, { Text = "Cancel", Color = UI.C.panel2, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 8 })
	cancel.Activated:Connect(close)
	GS:WaitForChild("Remotes"):WaitForChild("MissionSelect").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then return end
		if data.kind == "Open" then MissionSelect.open(data)
		elseif data.kind == "Feedback" then status.Text = data.text refresh() end
	end)
	player:GetAttributeChangedSignal("SuitOn"):Connect(function() if panel.Visible then refresh() end end)
	player:GetAttributeChangedSignal("RookieMission"):Connect(function() if player:GetAttribute("RookieMission") then close() end end)
end

return MissionSelect
