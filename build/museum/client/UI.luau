--[[
	UI — tema e construtores do museu (museuspec §5.2): azul-marinho translúcido, texto branco,
	destaque laranja, cantos pouco arredondados, Montserrat. Tamanho do texto em 3 níveis:
	todo texto criado aqui guarda BaseTextSize e é reescalado por UI.setTextLevel.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local UI = {}

UI.C = {
	panel = Color3.fromHex("0E1A36"),
	panel2 = Color3.fromHex("16284F"),
	text = Color3.fromHex("FFFFFF"),
	muted = Color3.fromHex("AEB9C8"),
	accent = Color3.fromHex("E8892E"),
	warn = Color3.fromHex("E5B52E"),
	green = Color3.fromHex("3FD17A"),
	line = Color3.fromHex("2D4373"),
}

local FAMILY = "rbxasset://fonts/families/Montserrat.json"
local LEVELS = { 0.85, 1, 1.25 }
UI.textLevel = 2

function UI.font(weight)
	return Font.new(FAMILY, weight or Enum.FontWeight.Medium)
end

function UI.playerGui()
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Entrada principal é toque? (PreferredInput; TouchEnabled dá falso positivo em notebook com tela de toque)
function UI.isTouch()
	local ok, pref = pcall(function() return UIS.PreferredInput end)
	if ok and pref ~= nil then return pref == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

-- Celular ou janela estreita/baixa: painel embaixo (ou quase tela cheia) em vez de à direita
function UI.isCompact()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1000, 800)
	return v.X < 760 or v.Y < 500 or UI.isTouch()
end

function UI.new(class, props, children)
	local o = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in children or {} do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end

function UI.screenGui(name, order)
	local old = UI.playerGui():FindFirstChild(name)
	if old then old:Destroy() end
	return UI.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 10,
		Parent = UI.playerGui(),
	})
end

function UI.corner(parent, r)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

function UI.pad(parent, px)
	return UI.new("UIPadding", {
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px),
		Parent = parent,
	})
end

local function sized(o, base)
	o:SetAttribute("BaseTextSize", base)
	o.TextSize = math.floor(base * LEVELS[UI.textLevel] + 0.5)
	return o
end

-- Texto que quebra linhas e cresce na vertical (para listas)
function UI.label(parent, text, base, weight, color, order)
	return sized(UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		FontFace = UI.font(weight),
		TextColor3 = color or UI.C.text,
		LayoutOrder = order or 0,
		Parent = parent,
	}), base or 17)
end

function UI.button(parent, text, onClick, opts)
	opts = opts or {}
	local b = sized(UI.new("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = opts.color or UI.C.panel2,
		Size = opts.size or UDim2.new(0, 0, 0, 44),
		AutomaticSize = opts.size and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
		Text = text,
		FontFace = UI.font(Enum.FontWeight.SemiBold),
		TextColor3 = opts.textColor or UI.C.text,
		LayoutOrder = opts.order or 0,
		Parent = parent,
	}), opts.textSize or 16)
	UI.corner(b, 5)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = b })
	if not opts.size then UI.new("UISizeConstraint", { MinSize = Vector2.new(44, 44), Parent = b }) end
	UI.new("UIStroke", { Color = UI.C.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	if onClick then b.Activated:Connect(onClick) end
	return b
end

function UI.list(parent, gap, horizontal)
	return UI.new("UIListLayout", {
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Wraps = horizontal or false,
		Parent = parent,
	})
end

function UI.setTextLevel(level)
	UI.textLevel = math.clamp(level or 2, 1, 3)
	for _, o in UI.playerGui():GetDescendants() do
		local base = o:GetAttribute("BaseTextSize")
		if base and (o:IsA("TextLabel") or o:IsA("TextButton")) then
			o.TextSize = math.floor(base * LEVELS[UI.textLevel] + 0.5)
		end
	end
end

-- Aviso curto no topo da tela. Os avisos empilham numa coluna (não se sobrepõem).
local toastGui, toastList
function UI.toast(text, seconds)
	if not toastGui or not toastGui.Parent then
		toastGui = UI.screenGui("MuseumToast", 30)
		toastList = UI.new("Frame", {
			Name = "Stack", BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64),
			Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = toastGui,
		})
		UI.list(toastList, 6).HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
	local f = UI.new("Frame", {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.1,
		LayoutOrder = os.clock() * 1000 // 1,
		Parent = toastList,
	})
	f:SetAttribute("KitTransient", true)
	UI.corner(f, 6)
	UI.pad(f, 12)
	local st = UI.new("UIStroke", { Color = UI.C.accent, Thickness = 1, Parent = f })
	local l = sized(UI.new("TextLabel", {
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(),
		Text = text, FontFace = UI.font(Enum.FontWeight.SemiBold), TextColor3 = UI.C.text, Parent = f,
	}), 17)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(520, 200), Parent = f })
	l.TextWrapped = true
	task.delay(seconds or 4, function()
		if f.Parent then
			local ti = TweenInfo.new(0.3)
			TweenService:Create(f, ti, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(l, ti, { TextTransparency = 1 }):Play()
			TweenService:Create(st, ti, { Transparency = 1 }):Play()
			task.wait(0.35)
			f:Destroy()
		end
	end)
end

return UI
