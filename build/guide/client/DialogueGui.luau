--[[
	DialogueGui — caixa de diálogo dos NPCs (spec §5): nome, função, retrato ao vivo do NPC
	(ViewportFrame com uma cópia do modelo), texto com animação de digitação, botão Continue.
	Clique/toque/Enter: completa o texto; de novo: próxima fala. Ao fechar avisa o servidor (Done).
	Também: Toast (aviso curto no topo), Bubble (balão sobre o NPC) e Sound (sirene).
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local GS = RS:WaitForChild("GuideSystem")
local Dialogues = require(GS:WaitForChild("Config"):WaitForChild("Dialogues"))
local Settings = require(GS.Config:WaitForChild("Settings"))
local UI = require(script.Parent:WaitForChild("GuideUI"))

local player = Players.LocalPlayer
local DialogueGui = {}

local CPS = 45 -- caracteres por segundo
local queue, current = {}, nil
local ui = {}

local function fill(text)
	return (string.gsub(text, "{name}", player.DisplayName))
end

---------------------------------------------------------------------------------
-- Retrato: cópia do NPC num ViewportFrame, câmera no rosto
---------------------------------------------------------------------------------

local function portrait(vp, npc)
	for _, c in vp:GetChildren() do
		if not c:IsA("UICorner") and not c:IsA("UIStroke") then c:Destroy() end
	end
	if not (npc and npc:IsA("Model")) then return end
	local ok, copy = pcall(function()
		npc.Archivable = true
		return npc:Clone()
	end)
	if not ok or not copy then return end
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("ProximityPrompt") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local hum = copy:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	local world = Instance.new("WorldModel")
	world.Parent = vp
	copy:PivotTo(CFrame.new(0, 0, 0))
	copy.Parent = world
	local head = copy:FindFirstChild("Head")
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	if head then
		local hp = head.Position + Vector3.new(0, -0.15, 0)
		cam.CFrame = CFrame.lookAt((head.CFrame * CFrame.new(0.6, 0.2, -4.2)).Position, hp)
	end
end

---------------------------------------------------------------------------------
-- Caixa de diálogo
---------------------------------------------------------------------------------

local function build()
	local gui = UI.screenGui("DialogueGui", 20)
	local touch = UI.isTouch()
	local panel = UI.new("TextButton", {
		Name = "Panel",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.04,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, touch and -120 or -24),
		Size = UDim2.new(touch and 0.62 or 0.6, 0, 0, 150),
		Visible = false,
		Parent = gui,
	})
	UI.corner(panel, 16)
	UI.stroke(panel, UI.C.line, 2)
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 130), MaxSize = Vector2.new(720, 190), Parent = panel })
	local vp = UI.new("ViewportFrame", {
		Name = "Portrait",
		BackgroundColor3 = UI.C.panel2,
		Ambient = Color3.fromRGB(170, 170, 185),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(0, 112, 1, -24),
		Parent = panel,
	})
	UI.corner(vp, 12)
	local stroke = UI.new("UIStroke", { Color = UI.C.accent, Thickness = 2, Parent = vp })
	local name = UI.text(panel, {
		Text = "", Weight = Enum.FontWeight.Bold, TextSize = 19,
		Position = UDim2.fromOffset(136, 12), Size = UDim2.new(1, -148, 0, 22),
	})
	local role = UI.text(panel, {
		Text = "", Color = UI.C.muted, TextSize = 13,
		Position = UDim2.fromOffset(136, 34), Size = UDim2.new(1, -148, 0, 16),
	})
	local body = UI.text(panel, {
		Text = "", TextSize = touch and 16 or 17,
		Position = UDim2.fromOffset(136, 54), Size = UDim2.new(1, -148, 1, -108),
	})
	local cont = UI.button(panel, {
		Text = "Continue  ▸", TextSize = 16,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.fromOffset(150, 44),
	})
	local hint = UI.text(panel, {
		Text = touch and "" or "Enter", Color = UI.C.muted, TextSize = 12, AlignX = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -170, 1, -22), Size = UDim2.fromOffset(60, 16),
	})
	ui = { gui = gui, panel = panel, vp = vp, stroke = stroke, name = name, role = role, body = body, cont = cont, hint = hint }

	-- aviso curto (Toast) no topo
	local toast = UI.new("Frame", {
		Name = "Toast",
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.06,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0.5, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	UI.corner(toast, 12)
	UI.stroke(toast, UI.C.accent, 1.5)
	UI.pad(toast, 10)
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 0), MaxSize = Vector2.new(560, 200), Parent = toast })
	UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = toast })
	ui.toastName = UI.text(toast, { Text = "", Weight = Enum.FontWeight.Bold, TextSize = 14, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1 })
	ui.toastBody = UI.text(toast, { Text = "", TextSize = 16, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	ui.toast = toast
end

local typing = nil -- tween da digitação

local function showLine()
	local c = current
	local line = c.lines[c.i]
	local spk = Dialogues.Speakers[line[1]] or { Name = line[1], Role = "", Color = UI.C.accent }
	ui.name.Text = spk.Name
	ui.name.TextColor3 = spk.Color
	ui.role.Text = spk.Role
	ui.stroke.Color = spk.Color
	if c.portraitFor ~= line[1] then
		c.portraitFor = line[1]
		portrait(ui.vp, c.npcs[line[1]])
	end
	local text = fill(line[2])
	ui.body.Text = text
	ui.body.MaxVisibleGraphemes = 0
	ui.cont.Text = c.i < #c.lines and "Continue  ▸" or "Close"
	if typing then typing:Cancel() end
	local n = utf8.len(text) or #text
	typing = TweenService:Create(ui.body, TweenInfo.new(n / CPS, Enum.EasingStyle.Linear), { MaxVisibleGraphemes = n })
	typing:Play()
	c.typingDone = false
	typing.Completed:Once(function(st)
		if st == Enum.PlaybackState.Completed and current == c then
			c.typingDone = true
			ui.body.MaxVisibleGraphemes = -1
		end
	end)
end

local openNext

local function close()
	local c = current
	current = nil
	ui.panel.Visible = false
	if c and c.token then
		GS.Remotes.DialogueEvent:FireServer({ kind = "Done", token = c.token })
	end
	task.defer(openNext)
end

local function advance()
	local c = current
	if not c then return end
	if not c.typingDone then
		if typing then typing:Cancel() end
		ui.body.MaxVisibleGraphemes = -1
		c.typingDone = true
		return
	end
	if c.i < #c.lines then
		c.i += 1
		showLine()
	else
		close()
	end
end

openNext = function()
	if current or #queue == 0 then return end
	current = table.remove(queue, 1)
	current.i = 1
	ui.panel.Visible = true
	ui.panel.Position = UDim2.new(0.5, 0, 1, ui.panel.Position.Y.Offset + 40)
	local y = UI.isTouch() and -120 or -24
	TweenService:Create(ui.panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, y),
	}):Play()
	showLine()
end

local toastId = 0
local function toast(speaker, text)
	local spk = Dialogues.Speakers[speaker] or { Name = speaker or "", Color = UI.C.accent }
	toastId += 1
	local id = toastId
	ui.toastName.Text = spk.Name
	ui.toastName.TextColor3 = spk.Color
	ui.toastBody.Text = fill(text)
	ui.toast.Visible = true
	task.delay(7, function()
		if toastId == id then ui.toast.Visible = false end
	end)
end

local function bubble(npc, text)
	local head = npc and npc:FindFirstChild("Head")
	if not head then return end
	local ok = pcall(function() TextChatService:DisplayBubble(head, text) end)
	if not ok then
		pcall(function() game:GetService("Chat"):Chat(head, text) end)
	end
end

local function sound(key)
	local cfg = Settings.Sounds[key]
	if not cfg then return end
	local s = Instance.new("Sound")
	s.SoundId = cfg.Id
	s.Volume = cfg.Volume
	s.Looped = (cfg.Duration or 0) > 0
	s.Parent = SoundService
	s:Play()
	task.delay(cfg.Duration or 6, function()
		if cfg.Duration then
			TweenService:Create(s, TweenInfo.new(0.8), { Volume = 0 }):Play()
			task.wait(0.9)
		end
		s:Destroy()
	end)
end

---------------------------------------------------------------------------------

function DialogueGui.start()
	build()
	ui.panel.Activated:Connect(advance)
	ui.cont.Activated:Connect(advance)
	UIS.InputBegan:Connect(function(input, processed)
		if processed or not current then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter
			or input.KeyCode == Enum.KeyCode.ButtonX then
			advance()
		end
	end)
	GS:WaitForChild("Remotes"):WaitForChild("DialogueEvent").OnClientEvent:Connect(function(msg)
		if type(msg) ~= "table" then return end
		if msg.kind == "Dialogue" then
			local lines = Dialogues.Lines[msg.key]
			if not lines then return end
			local npcs = {}
			if msg.speaker and msg.npc then npcs[msg.speaker] = msg.npc end
			-- o retrato de cada orador é o NPC com o atributo GuideNPC = nome
			local map = workspace:FindFirstChild("NASAComplex")
			local folder = map and map:FindFirstChild("Guides")
			folder = folder and folder:FindFirstChild("NPCs")
			for _, l in lines do
				if not npcs[l[1]] and folder then
					for _, d in folder:GetChildren() do
						if d:IsA("Model") and d:GetAttribute("GuideNPC") == l[1] then
							npcs[l[1]] = d
							break
						end
					end
				end
			end
			table.insert(queue, { token = msg.token, lines = lines, npcs = npcs })
			openNext()
		elseif msg.kind == "Toast" then
			local lines = msg.key and Dialogues.Lines[msg.key]
			if lines then
				local parts = {}
				for _, l in lines do table.insert(parts, l[2]) end
				toast(lines[1][1], table.concat(parts, " "))
			elseif msg.text then
				toast(msg.speaker, msg.text)
			end
			if msg.token then GS.Remotes.DialogueEvent:FireServer({ kind = "Done", token = msg.token }) end
		elseif msg.kind == "Bubble" then
			bubble(msg.npc, msg.text)
		elseif msg.kind == "Sound" then
			sound(msg.sound)
		end
	end)
end

return DialogueGui
