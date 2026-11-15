--[[
	MissionSelect — escolha da missão no topo do foguete (spec §1, §4.5).
	Na primeira experiência só o Project Mercury fica liberado. Ao embarcar, a Preparação do
	Rookie Rocket abre a seleção do trade-off (itens × 60 kg) e o lançamento.
	O servidor valida tudo (etapa, posição, bloqueio); o cliente só manda o id escolhido.
]]

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GS = RS:WaitForChild("GuideSystem")
local Dialogues = require(GS:WaitForChild("Config"):WaitForChild("Dialogues"))
local UI = require(script.Parent:WaitForChild("GuideUI"))

local MissionSelect = {}
local T = Dialogues.MissionSelect

local gui, panel, list, subtitle

local function close()
	if panel then panel.Visible = false end
end

local function card(m, locked, order)
	local f = UI.new("Frame", {
		BackgroundColor3 = UI.C.panel2,
		Size = UDim2.new(1, 0, 0, 78),
		LayoutOrder = order,
		Parent = list,
	})
	UI.corner(f, 12)
	UI.stroke(f, locked and UI.C.line or UI.C.accent, 1.5)
	UI.text(f, {
		Text = m.Name, Weight = Enum.FontWeight.Bold, TextSize = 18,
		Color = locked and UI.C.muted or UI.C.text,
		Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -190, 0, 24),
	})
	UI.text(f, {
		Text = locked and T.Locked or m.Detail, TextSize = 14, Color = UI.C.muted,
		Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -190, 0, 30),
	})
	if locked then
		UI.text(f, {
			Text = "🔒", TextSize = 24, AlignX = Enum.TextXAlignment.Center, AlignY = Enum.TextYAlignment.Center,
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(150, 44),
		})
	else
		local b = UI.button(f, {
			Text = T.Board .. "  ▸",
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(150, 46),
		})
		b.Activated:Connect(function()
			close()
			GS.Remotes.MissionSelect:FireServer(m.Id)
		end)
	end
end

local function build()
	gui = UI.screenGui("MissionSelectGui", 25)
	panel = UI.new("Frame", {
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.02,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	UI.corner(panel, 16)
	UI.stroke(panel, UI.C.accent, 2)
	UI.pad(panel, 18)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(600, 520), Parent = panel })
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	UI.text(panel, {
		Text = T.Title, Weight = Enum.FontWeight.Bold, TextSize = 22, Color = UI.C.accent,
		Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1,
	})
	subtitle = UI.text(panel, {
		Text = T.Subtitle, TextSize = 15, Color = UI.C.muted,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})
	list = UI.new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3, Parent = panel,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local cancel = UI.button(panel, {
		Text = T.Cancel, Color = UI.C.panel2, Size = UDim2.fromOffset(140, 44), LayoutOrder = 4,
	})
	UI.stroke(cancel, UI.C.line)
	cancel.Activated:Connect(function()
		close()
		GS.Remotes.MissionSelect:FireServer("Cancel")
	end)
end

function MissionSelect.open(data)
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then c:Destroy() end
	end
	subtitle.Text = data.first and T.Subtitle or T.SubtitleReturning
	for i, m in T.Missions do card(m, m.Id == 2 and data.issLocked == true, i) end
	panel.Visible = true
	local scale = UI.new("UIScale", { Scale = 0.85, Parent = panel })
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(0.3, function() scale:Destroy() end)
end

function MissionSelect.start()
	build()
	GS:WaitForChild("Remotes"):WaitForChild("MissionSelect").OnClientEvent:Connect(function(data)
		if type(data) == "table" and data.kind == "Open" then MissionSelect.open(data) end
	end)
	-- fecha ao embarcar (o Rookie Rocket assume a tela)
	game:GetService("Players").LocalPlayer:GetAttributeChangedSignal("GuideStage"):Connect(function()
		local s = game:GetService("Players").LocalPlayer:GetAttribute("GuideStage")
		if s == "InMission" then close() end
	end)
end

return MissionSelect
