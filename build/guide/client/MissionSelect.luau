-- Painel único de voo: missão, traje e trade-off antes do embarque. Servidor valida tudo.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GS = RS:WaitForChild("GuideSystem")
local Missoes = require(RS:WaitForChild("RookieRocket"):WaitForChild("Config"):WaitForChild("Missoes"))
local UI = require(script.Parent:WaitForChild("GuideUI"))
local player = Players.LocalPlayer
local MissionSelect = {}
local panel, list, status, weight, suitButton, weightFill
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
			Text = (selected == id and "● " or "○ ") .. Missoes.Lista[id].Nome .. (id == 2 and locked and " · LOCKED" or ""),
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
	for index, key in mission.OrdemEquipamentos do
		local eq = mission.Equipamentos[key]
		local b = UI.button(list, {
			Text = (items[key] and "✓ " or "+ ") .. eq.Nome .. " · " .. eq.Peso .. " kg\n" .. eq.Efeito,
			TextSize = 14, Color = items[key] and UI.C.accent or UI.C.panel2,
			Size = UDim2.new(1, 0, 0, 72), LayoutOrder = 2 + index,
		})
		b.TextWrapped = true
		b.Activated:Connect(function() items[key] = not items[key] or nil refresh() end)
	end
	local total = Missoes.pesoTotal(mission, items)
	weight.Text = ("Weight %d / 60 kg · Free %d kg · Lightness bonus %d s"):format(total, 60 - total, Missoes.bonusLeveza(total))
	weight.TextColor3 = total > 60 and UI.C.red or (total > 50 and Color3.fromHex("FFE14D") or Color3.fromHex("54E878"))
	weightFill.Size = UDim2.fromScale(math.clamp(total / 60, 0, 1), 1)
	weightFill.BackgroundColor3 = weight.TextColor3
	suitButton.Text = player:GetAttribute("SuitOn") and "✓ Space suit ready" or "Put on space suit"
end

function MissionSelect.open(data)
	locked = data.issLocked == true
	selected, items = 1, {}
	status.Text = "20 kg capsule + equipment. Put on your suit before boarding.\nCo-op: choose the same shared manifest and board during the 12 s countdown."
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
	suitButton = UI.button(panel, { Text = "Put on space suit", Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 5 })
	suitButton.Activated:Connect(function() GS.Remotes.MissionSelect:FireServer({ action = "Suit" }) end)
	local board = UI.button(panel, { Text = "Board and launch ▸", Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 6 })
	board.Activated:Connect(function()
		GS.Remotes.MissionSelect:FireServer({ action = "Board", id = selected, items = items })
	end)
	local cancel = UI.button(panel, { Text = "Cancel", Color = UI.C.panel2, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 7 })
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
