--[[
	PanelDisplays — o que o jogador da missão vê nos painéis físicos (só no cliente dele).
	- SurfaceGuis em PlayerGui com Adornee nas peças da cápsula: as três telas do console
	  (DU 1 controle de atitude, DU 2 rádio/terminal, DU 3 reentrada), as folhas de procedimento
	  e as janelas (Terra; plasma na reentrada). As SurfaceGuis originais dessas peças ficam
	  desligadas localmente durante a missão e voltam ao sair.
	- HUD mínimo (ScreenGui): faixa de aviso no topo, legenda das falas de rádio, mira central e
	  o resumo final. Os instrumentos em si ficam nos painéis 3D (missaoUm.md §9.1).
	Canvas das telas: 3,3 × 2,3 studs a 120 px/stud = 396 × 276 px. Face Front da peça:
	x da GUI cresce para −X local, y da GUI cresce para −Y local.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local D = {}

local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local FONT_H = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local FONT_M = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
local MONO = Font.fromEnum(Enum.Font.Code)

local C = {
	bg = Color3.fromHex("#0A0F1C"), panel = Color3.fromHex("#141C2C"), dim = Color3.fromHex("#2A3446"),
	text = Color3.fromHex("#E8EEF6"), sub = Color3.fromHex("#93A2B8"), cyan = Color3.fromHex("#8ECDFB"),
	amber = Color3.fromHex("#FFB547"), orange = Color3.fromHex("#FF8A2E"), red = Color3.fromHex("#FF4B3E"),
	green = Color3.fromHex("#46E07A"), paper = Color3.fromHex("#F3EEDC"), ink = Color3.fromHex("#1D2330"),
}

local W, H, PPU = 396, 276, 120
local DIAL = { cx = 262, cy = 160, r = 100 }

local cfg
local guis, hidden = {}, {}
local ui = {} -- referências dos elementos
local snap
local clock = 0
local parts

-------------------------------------------------------------------------------
-- utilidades
-------------------------------------------------------------------------------
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local function box(parent, x, y, w, h, color, z)
	return new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z or 1 }, parent)
end

local function label(parent, text, x, y, w, h, size, color, font, align, z)
	return new("TextLabel", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
		Text = text, TextSize = size, TextColor3 = color, FontFace = font or FONT, TextWrapped = true,
		TextXAlignment = align or Enum.TextXAlignment.Left, ZIndex = z or 2,
	}, parent)
end

local function round(o, r)
	new("UICorner", { CornerRadius = r or UDim.new(0.5, 0) }, o)
	return o
end

local function stroke(o, color, th)
	new("UIStroke", { Color = color, Thickness = th or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	return o
end

local function surface(part, face, ppu, name)
	for _, c in part:GetChildren() do
		if c:IsA("SurfaceGui") and c.Enabled then
			c.Enabled = false
			table.insert(hidden, c)
		end
	end
	local g = new("SurfaceGui", {
		Name = name, Adornee = part, Face = face, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = ppu, LightInfluence = 0, Brightness = 1.5, ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, MaxDistance = 60,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	table.insert(guis, g)
	return g
end

local function mmss(sec)
	sec = math.max(0, math.ceil(sec))
	return string.format("%02d:%02d", sec // 60, sec % 60)
end

local function header(bg, title)
	local h = box(bg, 0, 0, W, 34, C.dim)
	local t = label(h, title, 12, 0, 260, 34, 19, C.text, FONT_H)
	t.TextYAlignment = Enum.TextYAlignment.Center
	return h, t
end

local function lamp(parent, text, x)
	local l = round(box(parent, x, 7, 40, 20, C.panel, 3), UDim.new(0, 4))
	local t = label(l, text, 0, 0, 40, 20, 12, C.sub, FONT_H, Enum.TextXAlignment.Center, 4)
	t.TextYAlignment = Enum.TextYAlignment.Center
	return { frame = l, text = t }
end

local function setLamp(l, on, color)
	l.frame.BackgroundColor3 = on and color or C.panel
	l.text.TextColor3 = on and C.bg or C.sub
end

-------------------------------------------------------------------------------
-- DU 1 · controle de atitude
-------------------------------------------------------------------------------
local function buildControl(part)
	local g = surface(part, Enum.NormalId.Front, PPU, "F7_Control")
	local bg = box(g, 0, 0, W, H, C.bg)
	ui.ctlHeader, ui.ctlTitle = header(bg, "ATTITUDE CONTROL")
	ui.lampAuto = lamp(ui.ctlHeader, "AUTO", 296)
	ui.lampMan = lamp(ui.ctlHeader, "MAN", 344)
	-- combustível de controle
	label(bg, "CONTROL\nFUEL", 6, 40, 104, 40, 15, C.cyan, FONT_H, Enum.TextXAlignment.Center)
	local bar = stroke(box(bg, 38, 84, 40, 148, C.panel), C.dim, 2)
	ui.fuelFill = box(bar, 0, 148, 40, 0, C.green, 2)
	ui.fuelFill.AnchorPoint = Vector2.new(0, 1)
	ui.fuelText = label(bg, "100%", 6, 236, 104, 34, 24, C.text, MONO, Enum.TextXAlignment.Center)
	-- mostrador
	local r = DIAL.r
	local dial = stroke(round(box(bg, DIAL.cx - r, DIAL.cy - r, 2 * r, 2 * r, Color3.fromHex("#060A14"))), C.dim, 3)
	ui.dial = dial
	stroke(round(new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, dial)), C.dim, 1)
	box(dial, 0, r - 1, 2 * r, 2, C.dim, 2)
	box(dial, r - 1, 0, 2, 2 * r, C.dim, 2)
	-- alvo de referência (centro) e cruz da atitude (desvia)
	stroke(round(new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 3 }, dial)), C.cyan, 2)
	local marker = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, ZIndex = 5 }, dial)
	box(marker, 0, 15, 34, 4, C.orange, 5)
	box(marker, 15, 0, 4, 34, C.orange, 5)
	ui.marker = marker
	ui.markerPos = Vector2.zero
	ui.targets = {}
	ui.ctlTimer = label(bg, "", 110, 40, 96, 22, 17, C.amber, MONO)
	ui.ctlInfo = label(bg, "", 110, 236, 286, 34, 14, C.sub, FONT_M, Enum.TextXAlignment.Center)
	ui.ctlInfo.TextYAlignment = Enum.TextYAlignment.Center
end

local function setTargets(points)
	for _, t in ui.targets do t.frame:Destroy() end
	ui.targets = {}
	for i, p in points or {} do
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(DIAL.r + p[1] * DIAL.r, DIAL.r - p[2] * DIAL.r),
			Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 6,
		}, ui.dial)
		round(f)
		local st = new("UIStroke", { Color = C.dim, Thickness = 3 }, f)
		local fill = round(new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 0), BackgroundColor3 = C.amber, BorderSizePixel = 0, ZIndex = 7 }, f))
		local n = label(f, tostring(i), 0, 0, 28, 28, 13, C.sub, FONT_H, Enum.TextXAlignment.Center, 8)
		n.TextYAlignment = Enum.TextYAlignment.Center
		ui.targets[i] = { frame = f, stroke = st, fill = fill, num = n }
	end
end

-- posição no mundo de um ponto do canvas da tela DU 1
local function ctlWorld(px, py)
	local part = parts.displays[1]
	local s = part.Size
	return (part.CFrame * CFrame.new((0.5 - px / W) * s.X, (0.5 - py / H) * s.Y, -s.Z / 2)).Position
end

function D.gazeWorld(i)
	local p = snap and snap.points and snap.points[i]
	if not p then return nil end
	return ctlWorld(DIAL.cx + p[1] * DIAL.r, DIAL.cy - p[2] * DIAL.r)
end

function D.setDwell(i, f)
	local t = ui.targets[i]
	if t then t.fill.Size = UDim2.fromScale(0.85 * f, 0.85 * f) end
end

-------------------------------------------------------------------------------
-- DU 2 · rádio e terminal
-------------------------------------------------------------------------------
local onSubmit
local function buildComm(part)
	local g = surface(part, Enum.NormalId.Front, PPU, "F7_Comm")
	local bg = box(g, 0, 0, W, H, C.bg)
	ui.comHeader = header(bg, "RADIO · COMM")
	ui.lampSig = lamp(ui.comHeader, "SIG", 344)
	ui.comStatus = label(bg, "", 12, 40, 250, 40, 17, C.text, FONT_H)
	ui.comStatus.TextYAlignment = Enum.TextYAlignment.Center
	ui.comTimer = label(bg, "", 250, 38, 136, 44, 36, C.amber, MONO, Enum.TextXAlignment.Right)
	-- tela de estática
	local scr = stroke(box(bg, 12, 86, 372, 60, Color3.fromHex("#05070C")), C.dim, 2)
	scr.ClipsDescendants = true
	ui.static = {}
	local cs = 12
	for yy = 0, 4 do
		for xx = 0, 30 do
			local cell = box(scr, xx * cs, yy * cs, cs, cs, Color3.new(1, 1, 1), 2)
			cell.BackgroundTransparency = 1
			table.insert(ui.static, cell)
		end
	end
	ui.staticLabel = label(scr, "", 0, 0, 372, 60, 22, C.text, FONT_H, Enum.TextXAlignment.Center, 4)
	ui.staticLabel.TextYAlignment = Enum.TextYAlignment.Center
	ui.staticLabel.TextStrokeTransparency = 0.4
	label(bg, "PROCEDURE CODE:", 12, 152, 250, 22, 15, C.cyan, FONT_H)
	ui.code = new("TextBox", {
		Position = UDim2.fromOffset(12, 176), Size = UDim2.fromOffset(372, 44), BackgroundColor3 = C.panel,
		BorderSizePixel = 0, Text = "", PlaceholderText = "CLICK OR TAP HERE TO TYPE", PlaceholderColor3 = C.sub,
		TextColor3 = C.text, TextSize = 30, FontFace = MONO, ClearTextOnFocus = false, ZIndex = 3, TextEditable = false,
	}, bg)
	stroke(ui.code, C.dim, 2)
	ui.code.FocusLost:Connect(function(enter)
		if enter and onSubmit then onSubmit(ui.code.Text) end
	end)
	ui.code:GetPropertyChangedSignal("Text"):Connect(function()
		local t = string.upper(ui.code.Text)
		if #t > 12 then t = string.sub(t, 1, 12) end
		if t ~= ui.code.Text then ui.code.Text = t end
	end)
	ui.comInfo = label(bg, "", 12, 222, 372, 24, 15, C.sub, FONT_M)
	ui.comFoot = label(bg, "CONFIRM sends the code · EJECT CAPSULE is on the console", 12, 248, 372, 24, 12, C.sub, FONT_M)
end

function D.onCodeSubmit(fn) onSubmit = fn end
function D.codeText() return ui.code and ui.code.Text or "" end
function D.focusCode()
	if ui.code and ui.code.TextEditable then ui.code:CaptureFocus() end
end

-------------------------------------------------------------------------------
-- DU 3 · reentrada
-------------------------------------------------------------------------------
local function buildReentry(part)
	local g = surface(part, Enum.NormalId.Front, PPU, "F7_Reentry")
	local bg = box(g, 0, 0, W, H, C.bg)
	ui.reeHeader, ui.reeTitle = header(bg, "REENTRY")
	ui.reeAlert = label(bg, "", 12, 38, 372, 36, 16, C.red, FONT_H)
	ui.reeAlert.TextYAlignment = Enum.TextYAlignment.Center
	ui.reeTimer = label(bg, "", 12, 76, 160, 58, 48, C.amber, MONO)
	label(bg, "SHIELD INTEGRITY", 184, 76, 200, 18, 13, C.cyan, FONT_H)
	ui.shield = label(bg, "—", 184, 94, 200, 36, 32, C.text, MONO)
	ui.temp = label(bg, "TEMP —", 184, 132, 200, 22, 16, C.text, MONO)
	ui.reeProc = label(bg, "", 12, 160, 372, 22, 16, C.text, FONT_H)
	local bar = stroke(box(bg, 12, 186, 372, 30, C.panel), C.dim, 2)
	ui.holdFill = box(bar, 0, 0, 0, 30, C.green, 2)
	ui.reeLeft = label(bg, "", 12, 220, 372, 24, 16, C.text, MONO)
	label(bg, "JETTISON RETROPACK · RETAIN RETROPACK — on the console", 12, 248, 372, 24, 12, C.sub, FONT_M)
end

-------------------------------------------------------------------------------
-- folhas de procedimento (face Back das peças Paper)
-------------------------------------------------------------------------------
local function buildPaper(part, i)
	local s = part.Size
	local ppu = 150
	local pw, ph = s.X * ppu, s.Y * ppu
	local g = surface(part, Enum.NormalId.Back, ppu, "F7_Paper_" .. i)
	local bg = box(g, 0, 0, pw, ph, C.paper)
	label(bg, "EMERGENCY PROCEDURE", 14, 12, pw - 28, 34, 21, Color3.fromHex("#B3261E"), FONT_H, Enum.TextXAlignment.Center)
	label(bg, "MERCURY CONTROL · FRIENDSHIP 7", 14, 48, pw - 28, 20, 13, C.ink, FONT_M, Enum.TextXAlignment.Center)
	box(bg, 14, 74, pw - 28, 2, C.ink)
	label(bg, "RESTORATION CODE:", 14, 90, pw - 28, 26, 20, C.ink, FONT_H, Enum.TextXAlignment.Center)
	local code = label(bg, "— — —", 6, 122, pw - 12, 84, 62, C.ink, MONO, Enum.TextXAlignment.Center)
	code.TextYAlignment = Enum.TextYAlignment.Center
	label(bg, "ENTER THE CODE AT THE RADIO TERMINAL.", 14, 214, pw - 28, 60, 19, C.ink, FONT_H, Enum.TextXAlignment.Center)
	ui.paperCodes = ui.paperCodes or {}
	table.insert(ui.paperCodes, code)
end

-------------------------------------------------------------------------------
-- janelas: a Terra em órbita; plasma laranja na reentrada
-------------------------------------------------------------------------------
local function buildWindow(part, i)
	local g = surface(part, Enum.NormalId.Back, 60, "F7_Window_" .. i)
	local px = part.Size.X * 60
	local bg = box(g, 0, 0, px, px, Color3.fromHex("#02030A"))
	bg.ClipsDescendants = true
	local rng = Random.new(i * 17)
	for _ = 1, 10 do
		local sz = rng:NextInteger(1, 3)
		box(bg, rng:NextInteger(4, px - 6), rng:NextInteger(4, math.floor(px * 0.5)), sz, sz, Color3.new(1, 1, 1))
	end
	local d = px * 3.6
	local earth = round(box(bg, px / 2 - d / 2, px * (0.5 + 0.06 * ((i % 3) - 1)), d, d, Color3.new(1, 1, 1), 2))
	earth.Rotation = (i - 3) * 6
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#7FC4F5")),
		ColorSequenceKeypoint.new(0.04, Color3.fromHex("#2F7FD0")),
		ColorSequenceKeypoint.new(0.12, Color3.fromHex("#2A6E6A")),
		ColorSequenceKeypoint.new(0.3, Color3.fromHex("#0E3A73")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#061A3A")),
	}) }, earth)
	new("UIStroke", { Color = Color3.fromHex("#9FD8FF"), Thickness = 5, Transparency = 0.25 }, earth)
	local plasma = box(bg, 0, 0, px, px, Color3.new(1, 1, 1), 5)
	plasma.BackgroundTransparency = 1
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("#FFD27A"), Color3.fromHex("#FF4A1C")) }, plasma)
	ui.plasma = ui.plasma or {}
	table.insert(ui.plasma, plasma)
end

-------------------------------------------------------------------------------
-- HUD (faixa de aviso, legenda, mira, resumo)
-------------------------------------------------------------------------------
local function buildHud()
	local g = new("ScreenGui", { Name = "F7_Hud", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, Players.LocalPlayer:WaitForChild("PlayerGui"))
	table.insert(guis, g)
	local banner = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64), Size = UDim2.new(0.62, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0,
	}, g)
	round(banner, UDim.new(0, 8))
	new("UISizeConstraint", { MaxSize = Vector2.new(720, 400) }, banner)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, banner)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, banner)
	ui.bannerStroke = new("UIStroke", { Color = C.amber, Thickness = 2 }, banner)
	ui.banner = banner
	ui.bTitle = new("TextLabel", { Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true, TextSize = 20, FontFace = FONT_H, TextColor3 = C.amber, LayoutOrder = 1, Text = "" }, banner)
	ui.bDetail = new("TextLabel", { Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true, TextSize = 16, FontFace = FONT_M, TextColor3 = C.text, LayoutOrder = 2, Text = "" }, banner)
	-- legenda
	ui.sub = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.new(0.7, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
		TextWrapped = true, TextSize = 18, FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Italic),
		TextColor3 = C.cyan, Text = "", Visible = false,
	}, g)
	new("UISizeConstraint", { MaxSize = Vector2.new(760, 300) }, ui.sub)
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, ui.sub)
	round(ui.sub, UDim.new(0, 6))
	-- mira
	ui.reticle = round(new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, g))
	stroke(ui.reticle, Color3.new(0, 0, 0), 1)
	ui.hud = g
	-- os botões Diary/Settings do museu ficam no topo à direita e batem na faixa de aviso no celular
	local mh = Players.LocalPlayer.PlayerGui:FindFirstChild("MuseumHud")
	if mh and mh.Enabled then
		mh.Enabled = false
		ui.museumHud = mh
	end
end

function D.setBanner(title, detail, color)
	if not ui.banner then return end
	ui.banner.Visible = title ~= nil and title ~= ""
	ui.bTitle.Text = title or ""
	ui.bTitle.TextColor3 = color or C.amber
	ui.bannerStroke.Color = color or C.amber
	ui.bDetail.Text = detail or ""
	ui.bDetail.Visible = detail ~= nil and detail ~= ""
end

local subToken = 0
function D.subtitle(text)
	if not ui.sub then return end
	subToken += 1
	local my = subToken
	ui.sub.Text = text
	ui.sub.Visible = true
	task.delay(math.clamp(#text / 14, 4, 9), function()
		if subToken == my and ui.sub then ui.sub.Visible = false end
	end)
end

function D.setReticle(on)
	if ui.reticle then ui.reticle.Visible = on end
end

-------------------------------------------------------------------------------
-- ciclo de vida
-------------------------------------------------------------------------------
function D.create(config, p)
	cfg, parts = config, p
	ui = {}
	buildControl(p.displays[1])
	buildComm(p.displays[2])
	buildReentry(p.displays[3])
	for i, paper in p.papers do buildPaper(paper, i) end
	for i, w in p.windows do buildWindow(w, i) end
	buildHud()
end

function D.destroy()
	if ui.museumHud and ui.museumHud.Parent then ui.museumHud.Enabled = true end
	for _, g in guis do g:Destroy() end
	table.clear(guis)
	for _, g in hidden do
		if g.Parent then g.Enabled = true end
	end
	table.clear(hidden)
	ui = {}
	snap = nil
end

local SEVERITY = {
	t1_alert = C.amber, t1_manual = C.amber, t1_done = C.green, t2_blackout = C.amber, t2_done = C.green,
	t3_alert = C.red, t3_reentry = C.orange, t3_done = C.green, failed = C.red, complete = C.green,
}

-- novo estado do servidor
function D.render(s)
	local prev = snap
	snap = s
	if not ui.dial then return end
	local ph = s.phase
	-- na conclusão o cartão de resumo já mostra o texto: sem faixa repetida
	if ph == "complete" then D.setBanner(nil) else D.setBanner(s.title, s.detail, SEVERITY[ph]) end
	-- DU 1
	-- cada envio chega como tabela nova: compara os pontos pelo conteúdo
	local sig = ""
	for _, p in s.points or {} do sig ..= p[1] .. "," .. p[2] .. ";" end
	if s.task == 1 and sig ~= ui.pointsSig then
		ui.pointsSig = sig
		setTargets(s.points)
	elseif s.task ~= 1 and ui.pointsSig ~= "" then
		ui.pointsSig = ""
		setTargets(nil)
	end
	for i, t in ui.targets do
		local done = (s.index or 0) > i or ph == "t1_done"
		local act = s.index == i and ph == "t1_manual"
		t.stroke.Color = done and C.green or act and C.amber or C.dim
		t.fill.BackgroundColor3 = done and C.green or C.amber
		if done then t.fill.Size = UDim2.fromScale(0.85, 0.85) elseif not act then t.fill.Size = UDim2.fromScale(0, 0) end
		t.num.TextColor3 = (done or act) and C.bg or C.sub
	end
	local manual = s.task == 1 and s.manual
	setLamp(ui.lampAuto, not manual or ph == "t1_done" or s.task > 1, C.green)
	setLamp(ui.lampMan, manual and ph ~= "t1_done", C.amber)
	if s.fuel then
		local f = math.clamp(s.fuel / cfg.Task1.FuelStart, 0, 1)
		ui.fuelFill.Size = UDim2.fromOffset(40, math.floor(148 * f))
		ui.fuelFill.BackgroundColor3 = f > 0.5 and C.green or f > 0.2 and C.amber or C.red
		ui.fuelText.Text = string.format("%d%%", math.floor(s.fuel + 0.5))
	end
	ui.ctlInfo.Text = ph == "t1_alert" and "AUTOPILOT FAILURE — PRESS AUTOPILOT OFF"
		or ph == "t1_manual" and string.format("LOOK AT TARGET %d OF %d", s.index or 1, #(s.points or {}))
		or (ph == "t1_done" or s.task > 1) and "ATTITUDE STABLE"
		or ""
	-- DU 2
	local blackout = ph == "t2_blackout"
	ui.code.TextEditable = blackout
	if s.task == 2 and prev and prev.task ~= 2 then ui.code.Text = "" end
	if not blackout and ui.code:IsFocused() then ui.code:ReleaseFocus() end
	ui.comStatus.Text = blackout and "CONTACT WITH EARTH LOST" or (s.task == 2 and ph == "failed") and "PROCEDURE INTERRUPTED"
		or (s.task > 2 or ph == "t2_done") and "SIGNAL ACQUIRED" or "COMM NOMINAL"
	ui.comStatus.TextColor3 = blackout and C.amber or (ph == "failed" and s.task == 2) and C.red or C.green
	setLamp(ui.lampSig, not blackout and not (s.task == 2 and ph == "failed"), C.green)
	ui.staticLabel.Text = blackout and "NO SIGNAL" or (ph == "t2_done" or s.task > 2) and "MERCURY CONTROL · LINK OK" or ""
	if s.error and s.errorAt and (not prev or prev.errorAt ~= s.errorAt) then
		ui.comInfo.Text = s.error .. (s.maxWrong and s.maxWrong > 0 and string.format("  (%d/%d)", s.wrong or 0, s.maxWrong) or "")
		ui.comInfo.TextColor3 = C.red
	elseif ph == "t2_done" then
		ui.comInfo.Text = "PROCEDURE ACCEPTED"
		ui.comInfo.TextColor3 = C.green
	elseif blackout and (not prev or prev.phase ~= ph) then
		ui.comInfo.Text = "Find the procedure sheet beside the console."
		ui.comInfo.TextColor3 = C.sub
	elseif not blackout and s.task ~= 2 then
		ui.comInfo.Text = ""
	end
	for _, c in ui.paperCodes or {} do
		c.Text = (s.task == 2 and s.code) or "— — —"
	end
	-- DU 3
	local t3 = s.task == 3
	ui.reeAlert.Text = (t3 and ph == "t3_alert") and "DANGER: HEAT SHIELD SENSOR UNSTABLE"
		or (t3 and ph == "t3_reentry") and "REENTRY — HOLD THE PROCEDURE"
		or (t3 and ph == "t3_done") and "HEAT SHIELD STABLE"
		or (t3 and ph == "failed") and "RETROPACK LOST"
		or "STANDBY"
	ui.reeAlert.TextColor3 = (ph == "t3_done") and C.green or (t3 and ph ~= "failed") and C.red or (t3 and C.red) or C.sub
	ui.shield.Text = t3 and (ph == "t3_done" and "STABLE" or string.format("%d%%", s.shield or cfg.Task3.ShieldReading)) or "—"
	ui.shield.TextColor3 = ph == "t3_done" and C.green or t3 and C.red or C.text
	ui.reeProc.Text = ph == "t3_reentry" and (s.holding and "HOLDING — KEEP IT PRESSED" or "HOLD RETAIN RETROPACK") or ""
	ui.holdFill.Size = UDim2.fromOffset(math.floor(372 * math.clamp(s.progress or 0, 0, 1)), 30)
end

-- animação por quadro (cronômetros, estática, mostrador, plasma, luzes das telas)
function D.step(dt, now)
	if not snap or not ui.dial then return end
	clock += dt
	local s, ph = snap, snap.phase
	local left = s.endsAt and (s.endsAt - now) or nil
	-- cabeçalhos piscando nas emergências
	local flash = (math.sin(clock * 7) > 0)
	ui.ctlHeader.BackgroundColor3 = (ph == "t1_alert" or ph == "t1_manual") and (flash and C.orange or C.dim) or C.dim
	ui.comHeader.BackgroundColor3 = ph == "t2_blackout" and C.amber or C.dim
	ui.reeHeader.BackgroundColor3 = ph == "t3_alert" and (flash and C.red or C.dim) or ph == "t3_reentry" and C.orange or C.dim
	-- cronômetros
	ui.ctlTimer.Text = (s.task == 1 and left) and mmss(left) or ""
	ui.comTimer.Text = (ph == "t2_blackout" and left) and mmss(left) or (s.task == 2 and ph == "t2_done") and "STOP" or ""
	ui.reeTimer.Text = (ph == "t3_alert" and left) and mmss(left) or ""
	if ph == "t3_reentry" then
		ui.reeLeft.Text = string.format("TIME LEFT: %02d", math.ceil(cfg.Task3.HoldTime * (1 - (s.progress or 0))))
	else
		ui.reeLeft.Text = ""
	end
	-- temperatura (cosmética): sobe no alerta e na reentrada, cai ao terminar
	ui.temp.Text = s.task == 3 and string.format("TEMP %d °F", math.floor(
		ph == "t3_alert" and (1200 + 45 * (cfg.Task3.DecisionTime - (left or 0)))
		or ph == "t3_reentry" and (1650 + 350 * (s.progress or 0) + 40 * math.sin(clock * 9))
		or ph == "t3_done" and 900 or 1400)) or "TEMP —"
	-- estática (Tarefa 2): forte no blackout, some na restauração
	if ph == "t2_blackout" then
		ui.staticOn = true
		local k = math.floor(clock * 14)
		if k ~= ui.staticK then
			ui.staticK = k
			for _, c in ui.static do c.BackgroundTransparency = math.random() * 0.9 + 0.05 end
		end
	elseif ui.staticOn then
		-- sinal restaurado: a estática some de uma vez
		ui.staticOn = false
		for _, c in ui.static do c.BackgroundTransparency = 1 end
	end
	-- mostrador: desvia no alerta, oscila no manual, volta ao centro ao estabilizar
	local target
	if ph == "t1_alert" then
		target = Vector2.new(0.55 + 0.08 * math.sin(clock * 1.3), 0.12 * math.sin(clock * 0.9))
	elseif ph == "t1_manual" then
		local n = #(s.points or {})
		local amp = 0.45 * (1 - ((s.index or 1) - 1) / math.max(n, 1))
		target = Vector2.new(amp * math.sin(clock * 1.7), amp * 0.7 * math.sin(clock * 2.3 + 1))
	else
		target = Vector2.zero
	end
	ui.markerPos = ui.markerPos:Lerp(target, math.min(1, dt * 2))
	ui.marker.Position = UDim2.fromOffset(DIAL.r + ui.markerPos.X * DIAL.r, DIAL.r - ui.markerPos.Y * DIAL.r)
	-- plasma nas janelas
	local heat = ph == "t3_reentry" and (0.25 + 0.1 * math.sin(clock * 17) + 0.06 * math.sin(clock * 41)) or 1
	if ph == "t3_reentry" or ui.heatOn then
		ui.heatOn = ph == "t3_reentry"
		for _, p in ui.plasma or {} do p.BackgroundTransparency = heat end
	end
end

-- resumo final
function D.showSummary(s, onClose)
	-- área segura padrão (abaixo da barra do Roblox): o cartão não fica sob os botões do topo
	local g = new("ScreenGui", { Name = "F7_Summary", ResetOnSpawn = false, DisplayOrder = 30 }, Players.LocalPlayer:WaitForChild("PlayerGui"))
	local card = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.8, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.bg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
	}, g)
	new("UISizeConstraint", { MaxSize = Vector2.new(520, 600) }, card)
	round(card, UDim.new(0, 10))
	stroke(card, C.green, 2)
	new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, card)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, card)
	local function line(text, size, color, font, order)
		return new("TextLabel", { Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true, Text = text, TextSize = size, TextColor3 = color, FontFace = font, LayoutOrder = order }, card)
	end
	local t = cfg.Text.complete
	line(t[1], 26, C.green, FONT_H, 1)
	line(t[2], 16, C.text, FONT_M, 2)
	for i, r in s.results or cfg.Text.results do
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = 2 + i }, card)
		round(row, UDim.new(0, 6))
		local k = label(row, r[1], 12, 0, 0, 34, 17, C.text, FONT)
		k.Size = UDim2.new(0.6, -12, 1, 0)
		k.TextYAlignment = Enum.TextYAlignment.Center
		local v = label(row, r[2], 0, 0, 0, 34, 17, C.green, FONT_H, Enum.TextXAlignment.Right)
		v.Position = UDim2.fromScale(0.6, 0)
		v.Size = UDim2.new(0.4, -12, 1, 0)
		v.TextYAlignment = Enum.TextYAlignment.Center
	end
	line(s.note or cfg.Text.note, 12, C.sub, FONT_M, 10)
	local btn = new("TextButton", { Size = UDim2.new(0, 180, 0, 46), BackgroundColor3 = C.green, Text = "CLOSE", TextSize = 18, FontFace = FONT_H, TextColor3 = C.bg, LayoutOrder = 11, AutoButtonColor = true, Modal = true }, card)
	round(btn, UDim.new(0, 8))
	-- celular deitado: o cartão pode passar da altura da tela; reduz por inteiro até caber
	local fit = new("UIScale", {}, card)
	local function refit()
		local avail = g.AbsoluteSize.Y - 16
		local h = card.AbsoluteSize.Y / fit.Scale
		fit.Scale = (h > avail and avail > 0) and avail / h or 1
	end
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	g:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	task.defer(refit)
	btn.Activated:Connect(function()
		g:Destroy()
		if onClose then onClose() end
	end)
	return g
end

-- aviso rápido fora da missão (ex.: missão abortada)
function D.toast(text)
	local g = new("ScreenGui", { Name = "F7_Toast", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 30 }, Players.LocalPlayer:WaitForChild("PlayerGui"))
	local l = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64), Size = UDim2.new(0.6, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, TextWrapped = true,
		Text = text, TextSize = 18, FontFace = FONT, TextColor3 = C.amber,
	}, g)
	new("UISizeConstraint", { MaxSize = Vector2.new(640, 200) }, l)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, l)
	round(l, UDim.new(0, 8))
	task.delay(4, function()
		TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.6)
		g:Destroy()
	end)
end

return D
