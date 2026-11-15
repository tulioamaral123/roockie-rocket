--[[
	HudController — interface mínima da visita (museuspec §8.1, §8.2): dois botões no canto
	superior direito (diário e configurações). Nada de barras permanentes.
	Configurações: tamanho do texto (3 níveis), legendas, reduzir movimento de câmera.
]]

local RS = game:GetService("ReplicatedStorage")

local MS = RS:WaitForChild("MuseumSystem")
local Shared = MS:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))

local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))

local Hud = {}

local gui, window

local function count(t)
	local n = 0
	for _ in t do n += 1 end
	return n
end

local function closeWindow()
	if window then
		window:Destroy()
		window = nil
	end
end

local function openWindow(title, kind)
	closeWindow()
	if Hud.onWindowOpen then Hud.onWindowOpen() end
	-- Cabe na tela (inclusive celular na horizontal): largura até 340, altura até o fim
	-- da tela; o conteúdo rola abaixo do cabeçalho fixo.
	local outer = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.new(1, -24, 1, -72),
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.08,
		Parent = gui,
	})
	outer:SetAttribute("Kind", kind)
	UI.corner(outer, 8)
	UI.new("UIStroke", { Color = UI.C.line, Parent = outer })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(340, 560), Parent = outer })
	local head = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 44), Parent = outer })
	local content = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -64),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, Parent = outer,
	})
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingBottom = UDim.new(0, 12), Parent = content })
	UI.list(content, 10)
	window = outer
	local t = UI.label(head, string.upper(title), 18, Enum.FontWeight.Bold, UI.C.text)
	t.Size = UDim2.new(1, -52, 0, 0)
	t.Position = UDim2.fromOffset(0, 10)
	local x = UI.button(head, "X", closeWindow, { size = UDim2.fromOffset(44, 44) })
	x.AnchorPoint = Vector2.new(1, 0)
	x.Position = UDim2.new(1, 0, 0, 0)
	return content
end

local function diary()
	local w = openWindow(Text.get("diary.title"), "diary")
	local p = State.progress
	local exhibits = Content.exhibitList()
	UI.label(w, string.format(Text.get("diary.exhibits"), count(p.exhibitsSeen), #exhibits), 16, Enum.FontWeight.SemiBold, UI.C.accent, 1)
	local scroll = UI.new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = w,
	})
	UI.list(scroll, 4)
	local sorted = table.clone(exhibits)
	table.sort(sorted, function(a, b) return a.Name < b.Name end)
	for i, d in sorted do
		local seen = p.exhibitsSeen[d.Id] == true
		UI.label(scroll, (seen and "✓  " or "·  ") .. d.Name, 15, Enum.FontWeight.Medium, seen and UI.C.text or UI.C.muted, i)
	end
	UI.label(w, string.format(Text.get("diary.cards"), count(p.cards), #Content.cards()), 16, Enum.FontWeight.SemiBold, UI.C.text, 3)
	UI.label(w, string.format(Text.get("diary.shows"), count(p.showsSeen)), 16, Enum.FontWeight.SemiBold, UI.C.text, 4)
end

-- Debounce: manda só o estado final de uma sequência de cliques (o servidor limita a 2/s)
local pending = 0
local function save()
	pending += 1
	local token = pending
	task.delay(0.6, function()
		if token == pending then MS.Remotes.SaveSettings:FireServer(State.settings()) end
	end)
end

local function settings()
	local w = openWindow(Text.get("settings.title"), "settings")
	local s = State.settings()
	local function row(label, order)
		local r = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = w })
		UI.list(r, 6)
		UI.label(r, label, 15, Enum.FontWeight.SemiBold, UI.C.muted, 0)
		local btns = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1, Parent = r })
		UI.list(btns, 6, true)
		return btns
	end
	local function pick(btns, options, current, onPick)
		for i, o in options do
			UI.button(btns, o.label, function()
				onPick(o.value)
				save()
				settings()
			end, { order = i, color = (o.value == current) and UI.C.accent or UI.C.panel2 })
		end
	end
	pick(row(Text.get("settings.textSize"), 1), {
		{ label = Text.get("settings.small"), value = 1 },
		{ label = Text.get("settings.medium"), value = 2 },
		{ label = Text.get("settings.large"), value = 3 },
	}, s.textSize, function(v)
		s.textSize = v
		UI.setTextLevel(v)
	end)
	local onOff = { { label = Text.get("settings.on"), value = true }, { label = Text.get("settings.off"), value = false } }
	pick(row(Text.get("settings.captions"), 2), onOff, s.captions, function(v) s.captions = v end)
	pick(row(Text.get("settings.reduceMotion"), 3), onOff, s.reduceMotion, function(v) s.reduceMotion = v end)
end

Hud.closeWindow = closeWindow
Hud.onWindowOpen = nil -- MuseumClient liga: fecha o painel de exposição (mesmo canto da tela)

function Hud.start()
	gui = UI.screenGui("MuseumHud", 15)
	local bar = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.new(0, 0, 0, 44), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = gui,
	})
	UI.list(bar, 8, true).HorizontalAlignment = Enum.HorizontalAlignment.Right
	UI.button(bar, Text.get("hud.diary"), function()
		if window and window:GetAttribute("Kind") == "diary" then return closeWindow() end
		diary()
	end, { order = 1 })
	UI.button(bar, Text.get("hud.settings"), function()
		if window and window:GetAttribute("Kind") == "settings" then return closeWindow() end
		settings()
	end, { order = 2 })
end

return Hud
