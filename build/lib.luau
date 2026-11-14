--[[
	Helpers compartilhados pelos geradores das Fases 3–6.
	Uso: local B = lib.builder(3)  -- toda peça criada recebe o atributo BuildPhase = 3
]]

local lib = {}

lib.C = {
	-- Base (spec §3.5)
	white = "#FFFFFF", lightGray = "#E7E9EA", midGray = "#AAB3BB", nasaBlue = "#244B70", red = "#D33D32",
	-- Museu (spec §5.5)
	space = "#080D20", darkBlue = "#101D3D", deepBlue = "#153D72", midBlue = "#397EC4", lightBlue = "#8ECDFB",
	-- Hangar (spec §7.7)
	darkGray = "#555B60", metalGray = "#8A9298", paleGray = "#D5D7D8", safety = "#E5B52E", rust = "#B94C2B",
	-- Complementares
	glass = "#CFE8F7", black = "#1B1D20", orange = "#D9822B", orangeDark = "#A85A1C", gold = "#D4A83A",
}

function lib.builder(phase)
	local B = {}
	local C = lib.C

	local function finish(p, parent, name, color, material, o)
		o = o or {}
		p.Name = name
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Color = Color3.fromHex(C[color] or color)
		p.Material = Enum.Material[material or "SmoothPlastic"]
		if o.transparency then p.Transparency = o.transparency end
		if o.reflectance then p.Reflectance = o.reflectance end
		if o.shadow == false then p.CastShadow = false end
		if o.collide == false then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
		p:SetAttribute("BuildPhase", phase)
		p.Parent = parent
		return p
	end

	-- Remove tudo o que esta fase criou antes (idempotência)
	function B.clear(root)
		local list = {}
		for _, d in root:GetDescendants() do
			if d:GetAttribute("BuildPhase") == phase then table.insert(list, d) end
		end
		for _, d in list do
			if d.Parent then d:Destroy() end
		end
	end

	function B.group(parent, name, class)
		local m = Instance.new(class or "Model")
		m.Name = name
		m:SetAttribute("BuildPhase", phase)
		m.Parent = parent
		return m
	end

	-- Caixa por limites (x0..x1, y0..y1, z0..z1)
	function B.box(parent, name, x0, x1, y0, y1, z0, z1, color, material, o)
		local p = Instance.new("Part")
		p.Size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
		p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
		return finish(p, parent, name, color, material, o)
	end

	-- Peça com CFrame e tamanho livres; shape opcional ("Ball", "Cylinder", "Wedge")
	function B.part(parent, name, cf, size, color, material, o, shape)
		local p
		if shape == "Wedge" then
			p = Instance.new("WedgePart")
		else
			p = Instance.new("Part")
			if shape then p.Shape = Enum.PartType[shape] end
		end
		p.Size = size
		p.CFrame = cf
		return finish(p, parent, name, color, material, o)
	end

	-- Cilindro vertical centrado em (cx, cz), de y0 a y1
	function B.cyl(parent, name, cx, cz, y0, y1, dia, color, material, o)
		return B.part(parent, name, CFrame.new(cx, (y0 + y1) / 2, cz) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(y1 - y0, dia, dia), color, material, o, "Cylinder")
	end

	-- Cilindro entre dois pontos
	function B.cylBetween(parent, name, p0, p1, dia, color, material, o)
		local mid = (p0 + p1) / 2
		local cf = CFrame.lookAt(mid, p1) * CFrame.Angles(0, math.pi / 2, 0)
		return B.part(parent, name, cf, Vector3.new((p1 - p0).Magnitude, dia, dia), color, material, o, "Cylinder")
	end

	-- Viga retangular entre dois pontos (seção w × h)
	function B.beam(parent, name, p0, p1, w, h, color, material, o)
		local mid = (p0 + p1) / 2
		return B.part(parent, name, CFrame.lookAt(mid, p1), Vector3.new(w, h, (p1 - p0).Magnitude), color, material, o)
	end

	function B.ball(parent, name, pos, dia, color, material, o)
		return B.part(parent, name, CFrame.new(pos), Vector3.new(dia, dia, dia), color, material, o, "Ball")
	end

	-- Cone aproximado por fatias cilíndricas (de baixo para cima)
	function B.cone(parent, name, cx, cz, y0, y1, d0, d1, slices, color, material, o)
		local h = (y1 - y0) / slices
		for i = 0, slices - 1 do
			local t = (i + 0.5) / slices
			B.cyl(parent, name, cx, cz, y0 + i * h, y0 + (i + 1) * h, d0 + (d1 - d0) * t, color, material, o)
		end
	end

	-- Anel horizontal (CSG): raio médio r, largura w, espessura th
	function B.ring(parent, name, center, r, w, th, color, material, o)
		local outer = Instance.new("Part")
		outer.Anchored = true
		outer.Shape = Enum.PartType.Cylinder
		outer.Size = Vector3.new(th, 2 * r + w, 2 * r + w)
		outer.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2)
		local inner = outer:Clone()
		inner.Size = Vector3.new(th + 1, 2 * r - w, 2 * r - w)
		outer.Parent = workspace
		inner.Parent = workspace
		local ok, u = pcall(function() return outer:SubtractAsync({ inner }) end)
		outer:Destroy()
		inner:Destroy()
		assert(ok, "CSG do anel falhou: " .. tostring(u))
		u.UsePartColor = true
		pcall(function() u.RenderFidelity = Enum.RenderFidelity.Precise end)
		return finish(u, parent, name, color, material, o)
	end

	-- Painel com SurfaceGui: título + corpo opcional
	-- opts: face, bg, accent, titleColor, bodyColor, ppu, titleScale
	function B.sign(part, title, body, opts)
		opts = opts or {}
		local gui = Instance.new("SurfaceGui")
		gui.Face = opts.face or Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = opts.ppu or 50
		gui.LightInfluence = 0
		gui.Brightness = opts.brightness or 1
		gui.Parent = part
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromHex(C[opts.bg or "space"] or opts.bg)
		bg.BorderSizePixel = 0
		bg.Parent = gui
		if opts.accent then
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(1, 0, 0.05, 0)
			bar.BackgroundColor3 = Color3.fromHex(C[opts.accent] or opts.accent)
			bar.BorderSizePixel = 0
			bar.Parent = bg
		end
		local titleH = body and (opts.titleScale or 0.3) or 0.8
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.06, body and 0.1 or 0.1)
		t.Size = UDim2.fromScale(0.88, titleH)
		t.Text = title
		t.TextScaled = true
		t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
		t.TextXAlignment = body and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
		t.TextColor3 = Color3.fromHex(C[opts.titleColor or "lightBlue"] or opts.titleColor)
		t.Parent = bg
		if body then
			local b = Instance.new("TextLabel")
			b.BackgroundTransparency = 1
			b.Position = UDim2.fromScale(0.06, 0.14 + titleH)
			b.Size = UDim2.fromScale(0.88, 0.8 - titleH)
			b.Text = body
			b.TextScaled = true
			b.TextWrapped = true
			b.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextYAlignment = Enum.TextYAlignment.Top
			b.TextColor3 = Color3.fromHex(C[opts.bodyColor or "white"] or opts.bodyColor)
			b.Parent = bg
			local lim = Instance.new("UITextSizeConstraint")
			lim.MaxTextSize = opts.maxBody or 40
			lim.Parent = b
		end
		return gui
	end

	-- Luz anexada a uma peça
	function B.light(part, class, props)
		local l = Instance.new(class)
		for k, v in props do l[k] = v end
		l.Parent = part
		return l
	end

	return B
end

return lib
