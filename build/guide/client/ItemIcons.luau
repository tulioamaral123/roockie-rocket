-- Ícones vetoriais locais; todas as peças usam escala dentro de um quadro quadrado.
local UI = require(script.Parent:WaitForChild("GuideUI"))
local ItemIcons = {}

function ItemIcons.make(id, parent, size)
	local root = UI.new("Frame", {
		Name = "ItemIcon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})
	local function piece(x, y, w, h, color, round, rotation, outline)
		local frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(w, h),
			BackgroundColor3 = color,
			BackgroundTransparency = outline and 1 or 0,
			BorderSizePixel = 0,
			Rotation = rotation or 0,
			Parent = root,
		})
		if round then
			UI.new("UICorner", { CornerRadius = UDim.new(round, 0), Parent = frame })
		end
		if outline then
			UI.stroke(frame, color, math.max(1, size * 0.035))
		end
		return frame
	end
	local blue = Color3.fromHex("3B6EA8")
	local green = Color3.fromHex("54E878")
	if id == "gyroscope" then
		piece(0.5, 0.5, 0.76, 0.76, UI.C.muted, 0.5, 0, true)
		piece(0.5, 0.5, 0.72, 0.38, UI.C.accent, 0.5, 30, true)
		piece(0.5, 0.5, 0.04, 0.94, UI.C.text)
		piece(0.5, 0.5, 0.14, 0.14, UI.C.text, 0.5)
	elseif id == "manual" then
		piece(0.5, 0.5, 0.68, 0.84, blue, 0.08)
		piece(0.23, 0.5, 0.14, 0.84, UI.C.line, 0.08)
		for i = 1, 3 do
			piece(0.55, 0.25 + i * 0.14, 0.38, 0.035, UI.C.text, 0.5)
		end
	elseif id == "shield" then
		-- O recorte mostra só a metade superior do círculo, formando a cúpula.
		local dome = piece(0.5, 0.38, 0.84, 0.42, UI.C.panel2)
		dome.BackgroundTransparency = 1
		dome.ClipsDescendants = true
		local curve = UI.new("Frame", {
			Size = UDim2.fromScale(1, 2), BackgroundColor3 = Color3.fromHex("D9822B"),
			BorderSizePixel = 0, Parent = dome,
		})
		UI.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = curve })
		piece(0.5, 0.65, 0.84, 0.14, UI.C.line, 0.08)
		piece(0.36, 0.4, 0.035, 0.18, UI.C.text, 0.5, -18)
		piece(0.62, 0.4, 0.035, 0.18, UI.C.text, 0.5, 18)
	elseif id == "gauge" then
		piece(0.5, 0.5, 0.78, 0.78, UI.C.muted, 0.5, 0, true)
		piece(0.72, 0.3, 0.18, 0.08, green, 0.15, 42)
		piece(0.59, 0.41, 0.035, 0.36, UI.C.accent, 0.5, 45)
		piece(0.5, 0.5, 0.13, 0.13, UI.C.text, 0.5)
	elseif id == "gloves" then
		for i = 1, 4 do
			piece(0.27 + (i - 1) * 0.15, 0.3, 0.13, i == 1 and 0.3 or 0.42, UI.C.muted, 0.5)
		end
		piece(0.5, 0.57, 0.6, 0.46, UI.C.muted, 0.25)
		piece(0.19, 0.56, 0.18, 0.34, UI.C.muted, 0.5, -28)
		piece(0.5, 0.84, 0.48, 0.15, blue, 0.15)
	elseif id == "sealkit" then
		piece(0.34, 0.55, 0.29, 0.6, blue, 0.12, -12)
		piece(0.28, 0.2, 0.19, 0.15, UI.C.muted, 0.1, -12)
		piece(0.34, 0.53, 0.28, 0.18, UI.C.accent, 0.1, -12)
		piece(0.72, 0.64, 0.39, 0.39, UI.C.text, 0.08, 12)
		piece(0.72, 0.64, 0.22, 0.22, UI.C.muted, 0.08, 12)
	else
		-- O chamador acrescenta a inicial do equipamento quando não há ícone conhecido.
		piece(0.5, 0.5, 0.84, 0.84, UI.C.muted, 0.5, 0, true)
		root:SetAttribute("Fallback", true)
	end
	return root
end

return ItemIcons
