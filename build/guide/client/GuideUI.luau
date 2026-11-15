--[[
	GuideUI — tema e construtores das telas dos guias (mesmo visual do museu e do Rookie Rocket:
	azul-marinho, texto branco, destaque laranja, Montserrat; toque ≥ 44 px).
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
	red = Color3.fromHex("E5302A"),
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

function UI.screenGui(name, order)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(name)
	if old then old:Destroy() end
	return UI.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 10,
		Parent = pg,
	})
end

function UI.corner(o, px)
	UI.new("UICorner", { CornerRadius = UDim.new(0, px or 12), Parent = o })
end

function UI.stroke(o, color, th)
	UI.new("UIStroke", { Color = color or UI.C.line, Thickness = th or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end

function UI.pad(o, px)
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px), Parent = o,
	})
end

function UI.text(parent, props)
	local t = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = props.Color or UI.C.text,
		FontFace = UI.font(props.Weight),
		TextSize = props.TextSize or 18,
		TextWrapped = true,
		TextXAlignment = props.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = props.AlignY or Enum.TextYAlignment.Top,
		Text = props.Text or "",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = parent,
	})
	return t
end

function UI.button(parent, props)
	local b = UI.new("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = props.Color or UI.C.accent,
		TextColor3 = props.TextColor or UI.C.text,
		FontFace = UI.font(Enum.FontWeight.Bold),
		TextSize = props.TextSize or 18,
		Text = props.Text or "",
		Size = props.Size or UDim2.fromOffset(160, 46),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = parent,
	})
	UI.corner(b, 10)
	return b
end

return UI
