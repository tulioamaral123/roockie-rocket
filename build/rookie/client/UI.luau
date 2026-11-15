--[[
	UI — tema e construtores das telas do Rookie Rocket (mesmo visual do museu: azul-marinho,
	texto branco, destaque laranja, Montserrat). Tamanhos em Scale + limites em pixels para
	funcionar no celular e no PC (skill roblox-ui-layout: alvo de toque ≥ 44 px).
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local UI = {}

UI.C = {
	panel = Color3.fromHex("0E1A36"),
	panel2 = Color3.fromHex("16284F"),
	text = Color3.fromHex("FFFFFF"),
	muted = Color3.fromHex("AEB9C8"),
	accent = Color3.fromHex("E8892E"),
	yellow = Color3.fromHex("E5B52E"),
	green = Color3.fromHex("3FD17A"),
	red = Color3.fromHex("E5483B"),
	line = Color3.fromHex("2D4373"),
}

local FAMILY = "rbxasset://fonts/families/Montserrat.json"

function UI.font(weight)
	return Font.new(FAMILY, weight or Enum.FontWeight.Medium)
end

function UI.isTouch()
	local ok, pref = pcall(function() return UIS.PreferredInput end)
	if ok and pref ~= nil then return pref == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
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

function UI.screenGui(nome, ordem)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(nome)
	if old then old:Destroy() end
	return UI.new("ScreenGui", {
		Name = nome,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = ordem or 10,
		Parent = pg,
	})
end

function UI.corner(o, px)
	UI.new("UICorner", { CornerRadius = UDim.new(0, px or 8), Parent = o })
	return o
end

function UI.stroke(o, cor, esp)
	UI.new("UIStroke", { Color = cor or UI.C.line, Thickness = esp or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
	return o
end

function UI.pad(o, px)
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = o,
	})
	return o
end

-- painel centralizado com largura máxima em pixels
function UI.painel(parent, props)
	local f = UI.new("Frame", {
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromScale(0.9, 0.8),
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = props.BackgroundTransparency or 0.08,
		Visible = props.Visible ~= false,
		Name = props.Name or "Painel",
		Parent = parent,
	})
	UI.corner(f, 12)
	UI.stroke(f)
	if props.max then UI.new("UISizeConstraint", { MaxSize = props.max, Parent = f }) end
	return f
end

function UI.texto(parent, props)
	local t = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = props.cor or UI.C.text,
		FontFace = UI.font(props.peso),
		TextSize = props.tamanho or 18,
		TextWrapped = true,
		RichText = props.rich == true,
		TextXAlignment = props.alinhar or Enum.TextXAlignment.Left,
		TextYAlignment = props.alinharY or Enum.TextYAlignment.Center,
		Text = props.Text or "",
		Size = props.Size or UDim2.new(1, 0, 0, (props.tamanho or 18) + 8),
		Position = props.Position or UDim2.new(),
		AutomaticSize = props.auto or Enum.AutomaticSize.None,
		LayoutOrder = props.ordem or 0,
		Name = props.Name or "Texto",
		Parent = parent,
	})
	if props.escalar then
		t.TextScaled = true
		UI.new("UITextSizeConstraint", { MaxTextSize = props.tamanho or 18, MinTextSize = 10, Parent = t })
	end
	return t
end

function UI.botao(parent, props)
	local b = UI.new("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = props.cor or UI.C.accent,
		TextColor3 = props.corTexto or UI.C.text,
		FontFace = UI.font(Enum.FontWeight.Bold),
		TextSize = props.tamanho or 18,
		Text = props.Text or "",
		Size = props.Size or UDim2.new(0, 200, 0, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.ordem or 0,
		Name = props.Name or "Botao",
		Parent = parent,
	})
	UI.corner(b, 8)
	if props.aoClicar then b.Activated:Connect(props.aoClicar) end
	return b
end

function UI.lista(parent, px, horizontal, alinhar)
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, px or 8),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		HorizontalAlignment = alinhar or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

-- barra de progresso: devolve (frame, função set(0..1, cor?))
function UI.barra(parent, props)
	local fundo = UI.new("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 18),
		Position = props.Position or UDim2.new(),
		BackgroundColor3 = UI.C.panel2,
		LayoutOrder = props.ordem or 0,
		Name = props.Name or "Barra",
		Parent = parent,
	})
	UI.corner(fundo, 6)
	UI.stroke(fundo)
	local cheio = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = props.cor or UI.C.green, Parent = fundo })
	UI.corner(cheio, 6)
	local function set(v, cor)
		cheio.Size = UDim2.fromScale(math.clamp(v, 0, 1), 1)
		if cor then cheio.BackgroundColor3 = cor end
	end
	return fundo, set
end

-- "mm:ss" ou "12 s"
function UI.segundos(t)
	return ("%d s"):format(math.max(0, math.floor(t + 0.5)))
end

return UI
