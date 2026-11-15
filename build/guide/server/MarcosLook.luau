--[[
	MarcosLook — visual do NPC Marcos Pontes (spec: docs/marcos-pontes-spec.md).

	Referência conferida: foto de evento em 2024 (PANROTAS / Emerson Souza), aparência madura.
	Observado na foto: cabelo curto branco/prateado penteado para trás com um pouco de volume na
	frente e laterais curtas; sobrancelhas cinza-escuras, mais escuras que o cabelo; olhos escuros;
	rosto largo; tom de pele médio; sem óculos, barba ou bigode. Interpretação artística: formato e
	proporções estilizados no padrão R15 do jogo; cor exata dos olhos não definida (escuros neutros).

	Tudo montado com peças soldadas ao rig R15, foscas (sem assets do catálogo):
	- cabelo de baixo volume em blocos (topete discreto, laterais e nuca curtas, variação sutil de cinza);
	- rosto desenhado (SurfaceGui numa placa à frente da cabeça): sobrancelhas naturais, olhos,
	  nariz simples, sorriso leve de boca fechada e marcas de expressão sutis;
	- macacão de voo azul original: gola discreta, zíper claro, plaqueta "M. PONTES", emblema
	  fictício do Rookie Rocket, bandeira do Brasil na manga, bolsos, costuras (ombros, laterais,
	  joelhos), cinto discreto, punhos e botas azul-marinho escuro; mãos na cor da pele.
	Cores em Dialogues.Appearance.Marcos (Skin, Suit, Hair, Brow).
]]

local MarcosLook = {}

local function weld(part, to, cf)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = to.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = part, to
	w.Parent = part
	part.Parent = to.Parent
	return part
end

local function block(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end

local function sphere(name, d, color)
	local p = block(name, Vector3.new(d, d, d), color)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	for k, v in props do
		if k ~= "Round" then f[k] = v end
	end
	if props.Round then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(props.Round, 0)
		c.Parent = f
	end
	f.Parent = parent
	return f
end

local function canvas(part, face, ppS)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppS or 200
	g.LightInfluence = 0.75
	g.ClipsDescendants = true
	g.Parent = part
	return g
end

-- placa invisível colada a uma face, para desenhar com SurfaceGui
local function plate(name, to, size, cf)
	local p = block(name, size, Color3.new(1, 1, 1))
	p.Transparency = 1
	return weld(p, to, cf)
end

local function darker(c, k)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

---------------------------------------------------------------------------------

local function face(head, look)
	-- a cabeça dinâmica padrão traz um rosto pintado na textura e FaceControls: some com os dois
	for _, d in head:GetChildren() do
		if d:IsA("Decal") or d:IsA("FaceControls") then d:Destroy() end
	end
	if head:IsA("MeshPart") then pcall(function() head.TextureID = "" end) end
	head.Color = look.Skin
	local hs = head.Size
	local p = plate("Marcos_Face", head, Vector3.new(hs.X * 0.96, hs.Y * 0.96, 0.02), CFrame.new(0, -hs.Y * 0.02, -hs.Z / 2 - 0.012))
	local g = canvas(p, Enum.NormalId.Front, 220)
	local root = frame(g, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 })
	local brow = look.Brow or Color3.fromHex("5E5853")
	local shade = darker(look.Skin, 0.84)
	-- sobrancelhas naturais, retas com leve curva (sem ar zangado)
	for _, side in { -1, 1 } do
		frame(root, {
			Size = UDim2.fromScale(0.24, 0.06), Position = UDim2.fromScale(0.5 + side * 0.18, 0.3),
			Rotation = side * 4, BackgroundColor3 = brow, Round = 0.5,
		})
	end
	-- olhos escuros, proporcionais ao estilo do jogo, com brilho pequeno
	for _, side in { -1, 1 } do
		local eye = frame(root, {
			Size = UDim2.fromScale(0.09, 0.14), Position = UDim2.fromScale(0.5 + side * 0.17, 0.44),
			BackgroundColor3 = Color3.fromHex("2A1D17"), Round = 0.5,
		})
		frame(eye, { Size = UDim2.fromScale(0.36, 0.24), Position = UDim2.fromScale(0.66, 0.28), BackgroundColor3 = Color3.new(1, 1, 1), Round = 0.5 })
		-- pálpebra superior suave (olhar sereno)
		frame(root, {
			Size = UDim2.fromScale(0.12, 0.025), Position = UDim2.fromScale(0.5 + side * 0.17, 0.375),
			BackgroundColor3 = shade, BackgroundTransparency = 0.25, Round = 0.5,
		})
	end
	-- nariz simples (sombra na ponta)
	frame(root, { Size = UDim2.fromScale(0.12, 0.07), Position = UDim2.fromScale(0.5, 0.6), BackgroundColor3 = shade, BackgroundTransparency = 0.35, Round = 0.5 })
	-- sorriso leve, de boca fechada: arco (borda inferior de uma elipse)
	local mouth = frame(root, {
		Size = UDim2.fromScale(0.3, 0.07), Position = UDim2.fromScale(0.5, 0.735),
		BackgroundTransparency = 1, ClipsDescendants = true,
	})
	local arc = frame(mouth, {
		Size = UDim2.fromScale(1, 2.6), Position = UDim2.fromScale(0.5, -0.3),
		BackgroundTransparency = 1, Round = 0.5,
	})
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromHex("6B3A2E")
	st.Thickness = 4
	st.Parent = arc
	-- marcas de expressão sutis (maturidade, sem caricatura)
	for _, side in { -1, 1 } do
		frame(root, { Size = UDim2.fromScale(0.022, 0.12), Position = UDim2.fromScale(0.5 + side * 0.215, 0.67), Rotation = side * 16, BackgroundColor3 = shade, BackgroundTransparency = 0.5, Round = 0.5 })
	end
end

local function hair(head, look)
	-- curto, branco/prateado, penteado para trás; volume baixo, rente ao contorno da cabeça
	local hs = head.Size
	local light, mid, dark = look.Hair, darker(look.Hair, 0.9), darker(look.Hair, 0.8)
	local w, d = hs.X + 0.08, hs.Z + 0.08
	local top = hs.Y / 2
	local function piece(nm, size, color, cf, round)
		local p = round and sphere(nm, 1, color) or block(nm, size, color)
		p.Size = size
		return weld(p, head, cf)
	end
	-- domo rente ao contorno (metade de baixo fica dentro da cabeça) e topete discreto na frente
	piece("Marcos_Hair", Vector3.new(w * 1.02, 0.6, d * 1.04), light, CFrame.new(0, top - 0.1, 0.03), true)
	piece("Marcos_HairFront", Vector3.new(w * 0.86, 0.3, 0.55), light, CFrame.new(0, top + 0.04, -d / 2 + 0.3), true)
	-- laterais curtas, um pouco mais escuras (grisalho), e nuca
	for _, side in { -1, 1 } do
		piece("Marcos_HairSide", Vector3.new(0.2, hs.Y * 0.42, d * 0.8), mid, CFrame.new(side * (w / 2 - 0.07), top - hs.Y * 0.22, d * 0.1), true)
		piece("Marcos_Sideburn", Vector3.new(0.07, hs.Y * 0.16, 0.14), dark, CFrame.new(side * (w / 2 - 0.03), top - hs.Y * 0.44, -d * 0.12))
	end
	piece("Marcos_HairBack", Vector3.new(w * 0.98, hs.Y * 0.62, 0.3), mid, CFrame.new(0, top - hs.Y * 0.24, d / 2 - 0.1), true)
	return 7
end

local function rookieLogo(parent)
	local g = canvas(parent, Enum.NormalId.Front, 300)
	local red = Color3.fromHex("E5302A")
	frame(g, { Size = UDim2.fromScale(0.2, 1.05), Position = UDim2.fromScale(0.42, 0.5), Rotation = 38, BackgroundColor3 = red, Round = 0.4 })
	frame(g, { Size = UDim2.fromScale(0.14, 0.8), Position = UDim2.fromScale(0.66, 0.58), Rotation = 38, BackgroundColor3 = red, Round = 0.4 })
end

local function brazilFlag(parent)
	local g = canvas(parent, Enum.NormalId.Front, 120)
	local bg = frame(g, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromHex("009B3A") })
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex("0B6E2E")
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = bg
	frame(bg, { Size = UDim2.fromScale(0.5, 0.72), Position = UDim2.fromScale(0.5, 0.5), Rotation = 45, BackgroundColor3 = Color3.fromHex("FEDF00") })
	local globe = frame(bg, { Size = UDim2.fromScale(0.36, 0.52), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromHex("002776"), Round = 0.5 })
	frame(globe, { Size = UDim2.fromScale(1.05, 0.12), Position = UDim2.fromScale(0.5, 0.5), Rotation = -12, BackgroundColor3 = Color3.new(1, 1, 1) })
end

local function suit(model, look)
	local suitC = look.Suit
	local seam = darker(suitC, 0.72)
	local pocket = darker(suitC, 0.88)
	local up = model:FindFirstChild("UpperTorso")
	local lo = model:FindFirstChild("LowerTorso")
	if not (up and lo) then return end
	local us = up.Size
	local fz = -us.Z / 2
	-- gola de camisa: duas pontas na cor do macacão, abertas em V, com borda mais escura
	for _, side in { -1, 1 } do
		local cf = CFrame.new(side * 0.17, us.Y / 2 - 0.13, fz - 0.03) * CFrame.Angles(0, 0, side * math.rad(-28))
		weld(block("Marcos_CollarEdge", Vector3.new(0.44, 0.2, 0.05), seam), up, cf)
		weld(block("Marcos_Collar", Vector3.new(0.4, 0.16, 0.07), darker(suitC, 1.08)), up, cf * CFrame.new(0, 0.01, -0.01))
	end
	weld(block("Marcos_CollarBack", Vector3.new(us.X * 0.42, 0.2, 0.12), darker(suitC, 1.04)), up, CFrame.new(0, us.Y / 2 + 0.05, us.Z * 0.18))
	-- zíper com puxador
	weld(block("Marcos_Zipper", Vector3.new(0.045, us.Y * 0.8, 0.03), Color3.fromHex("C9CED6")), up, CFrame.new(0.06, -us.Y * 0.08, fz - 0.015))
	weld(block("Marcos_ZipPull", Vector3.new(0.09, 0.16, 0.04), Color3.fromHex("DADDE2")), up, CFrame.new(0.06, us.Y / 2 - 0.34, fz - 0.035))
	-- bolsos do peito com lapela
	for _, side in { -1, 1 } do
		local px = side * us.X * 0.25
		weld(block("Marcos_Pocket", Vector3.new(0.5, 0.42, 0.035), pocket), up, CFrame.new(px, -0.08, fz - 0.018))
		weld(block("Marcos_PocketFlap", Vector3.new(0.54, 0.12, 0.05), seam), up, CFrame.new(px, 0.12, fz - 0.03))
	end
	-- logotipo vermelho do Rookie Rocket no peito direito (lado +X do personagem)
	local logo = plate("Marcos_Logo", up, Vector3.new(0.5, 0.36, 0.02), CFrame.new(us.X * 0.27, 0.36, fz - 0.03))
	rookieLogo(logo)
	-- plaqueta com o nome no peito esquerdo (lado −X do personagem), legível de perto
	local tag = block("Marcos_NameTag", Vector3.new(0.62, 0.18, 0.03), Color3.fromHex("EEF0F3"))
	weld(tag, up, CFrame.new(-us.X * 0.25, 0.32, fz - 0.03))
	local tg = canvas(tag, Enum.NormalId.Front, 220)
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = "M. PONTES"
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromHex("14234B")
	tl.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	tl.Parent = tg
	-- costuras laterais e cintura
	for _, side in { -1, 1 } do
		weld(block("Marcos_Seam", Vector3.new(0.04, us.Y * 0.9, us.Z + 0.02), seam), up, CFrame.new(side * (us.X / 2 - 0.01), 0, 0))
	end
	local ls = lo.Size
	weld(block("Marcos_Belt", Vector3.new(ls.X + 0.05, 0.16, ls.Z + 0.05), Color3.fromHex("1B2240")), lo, CFrame.new(0, ls.Y / 2 - 0.09, 0))
	weld(block("Marcos_Buckle", Vector3.new(0.24, 0.14, 0.04), Color3.fromHex("8C939E")), lo, CFrame.new(0.06, ls.Y / 2 - 0.09, -ls.Z / 2 - 0.045))
	-- braços: bandeira + bolso na manga esquerda, bolso de caneta na direita, costuras e punhos
	for _, side in { "Left", "Right" } do
		local ua = model:FindFirstChild(side .. "UpperArm")
		local la = model:FindFirstChild(side .. "LowerArm")
		local hand = model:FindFirstChild(side .. "Hand")
		if ua then
			local s = ua.Size
			weld(block("Marcos_ShoulderSeam", Vector3.new(s.X + 0.04, 0.06, s.Z + 0.04), seam), ua, CFrame.new(0, s.Y / 2 - 0.12, 0))
			if side == "Left" then
				local flag = block("Marcos_Flag", Vector3.new(0.56, 0.4, 0.04), Color3.fromHex("009B3A"))
				weld(flag, ua, CFrame.new(-s.X / 2 - 0.03, s.Y * 0.12, 0) * CFrame.Angles(0, math.rad(90), 0))
				brazilFlag(flag)
				weld(block("Marcos_SleevePocket", Vector3.new(0.035, 0.32, 0.46), pocket), ua, CFrame.new(-s.X / 2 - 0.018, -s.Y * 0.26, 0))
			else
				weld(block("Marcos_PenPocket", Vector3.new(0.035, 0.38, 0.22), pocket), ua, CFrame.new(s.X / 2 + 0.018, -s.Y * 0.1, -0.08))
				weld(block("Marcos_Pen", Vector3.new(0.04, 0.16, 0.05), Color3.fromHex("DADDE2")), ua, CFrame.new(s.X / 2 + 0.035, -s.Y * 0.1 + 0.2, -0.14))
			end
		end
		if la then
			local s = la.Size
			weld(block("Marcos_Cuff", Vector3.new(s.X + 0.06, 0.16, s.Z + 0.06), seam), la, CFrame.new(0, -s.Y / 2 + 0.1, 0))
		end
		if hand then hand.Color = look.Skin end
	end
	-- pernas: bolsos laterais, joelheiras discretas, barras e botas
	for _, side in { "Left", "Right" } do
		local sx = side == "Left" and -1 or 1
		local ul = model:FindFirstChild(side .. "UpperLeg")
		local ll = model:FindFirstChild(side .. "LowerLeg")
		local foot = model:FindFirstChild(side .. "Foot")
		if ul then
			local s = ul.Size
			weld(block("Marcos_LegPocket", Vector3.new(0.035, s.Y * 0.5, s.Z * 0.62), pocket), ul, CFrame.new(sx * (s.X / 2 + 0.018), -s.Y * 0.08, 0))
			weld(block("Marcos_LegPocketFlap", Vector3.new(0.05, 0.1, s.Z * 0.66), seam), ul, CFrame.new(sx * (s.X / 2 + 0.03), s.Y * 0.17, 0))
		end
		if ll then
			local s = ll.Size
			weld(block("Marcos_Knee", Vector3.new(s.X * 0.8, 0.22, 0.03), pocket), ll, CFrame.new(0, s.Y / 2 - 0.16, -s.Z / 2 - 0.015))
			weld(block("Marcos_LegCuff", Vector3.new(s.X + 0.05, 0.14, s.Z + 0.05), seam), ll, CFrame.new(0, -s.Y / 2 + 0.08, 0))
		end
		if foot then foot.Color = Color3.fromHex("161A2B") end -- botas fechadas, azul quase preto
	end
end

function MarcosLook.apply(model, look)
	local head = model:FindFirstChild("Head")
	if not head then return end
	for _, bc in model:GetChildren() do
		if bc:IsA("BodyColors") then bc:Destroy() end -- senão reaplica a cor do braço nas mãos
	end
	face(head, look)
	hair(head, look)
	suit(model, look)
end

return MarcosLook
