--[[
	WorldController — o que o cliente desenha no salão:
	- Placas (Board / Board_N) das exposições: BoardText, ou a linha do tempo (Timeline).
	  Face: atributo DisplayFace (nome de Enum.NormalId) na peça; padrão Front.
	- Parede de missões: CardSlot_i ↔ card de Order i; conquistado acende (SlotLight) e mostra
	  nome/foto; bloqueado mostra "?".
	- Caminho no chão até uma exposição ("Show in museum").
	- Portal de saída (MuseumExit) → Events.LeaveMuseum (BindableEvent local).
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local MS = RS:WaitForChild("MuseumSystem")
local Shared = MS:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))

local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))

local World = {}

local function faceOf(part, attr)
	local name = part:GetAttribute(attr or "DisplayFace") or part:GetAttribute("DisplayFace")
	local ok, face = pcall(function() return Enum.NormalId[name] end)
	return ok and face or Enum.NormalId.Front
end

local function surface(part, attr)
	local old = part:FindFirstChild("MuseumSurface")
	if old then old:Destroy() end
	local g = UI.new("SurfaceGui", {
		Name = "MuseumSurface",
		Face = faceOf(part, attr),
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 40,
		LightInfluence = 0.2,
		Brightness = 1.4,
		Parent = part,
	})
	local bg = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHex("0B1530"), BorderSizePixel = 0, Parent = g })
	UI.new("Frame", { Size = UDim2.new(1, 0, 0.025, 0), BackgroundColor3 = UI.C.accent, BorderSizePixel = 0, Parent = bg })
	return bg
end

local function boardText(part, title, body, memorial, photo)
	local bg = surface(part)
	if memorial then bg.BackgroundColor3 = Color3.fromHex("161616") end
	if photo then
		-- foto real à esquerda (moldura escura), texto na direita
		local holder = UI.new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
			Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.44, 0.8), Parent = bg,
		})
		UI.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.88), Image = photo.AssetId, ScaleType = Enum.ScaleType.Fit, Parent = holder })
		UI.new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.89), Size = UDim2.fromScale(1, 0.1),
			Text = (photo.Illustration and "Illustration: " or "Photo: ") .. photo.Credit, TextScaled = true, TextWrapped = true,
			FontFace = UI.font(Enum.FontWeight.Medium), TextColor3 = Color3.fromHex("9AA5B5"), Parent = holder,
		}, { UI.new("UITextSizeConstraint", { MaxTextSize = 28 }) })
		local inner = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.5, 1), Parent = bg })
		bg = inner
	end
	if memorial then bg.BackgroundColor3 = Color3.fromHex("161616") end
	local t = UI.new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.07), Size = UDim2.fromScale(0.88, 0.2),
		Text = title, TextScaled = true, TextWrapped = true, FontFace = UI.font(Enum.FontWeight.Bold),
		TextColor3 = memorial and Color3.fromHex("E9D9B5") or UI.C.text, TextXAlignment = memorial and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Parent = bg,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 96 }) })
	if body then
		local b = UI.new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.32), Size = UDim2.fromScale(0.88, 0.62),
			Text = body, TextScaled = true, TextWrapped = true, FontFace = UI.font(Enum.FontWeight.Medium),
			TextColor3 = memorial and Color3.fromHex("D8D2C4") or UI.C.muted,
			TextXAlignment = memorial and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, Parent = bg,
		})
		UI.new("UITextSizeConstraint", { MaxTextSize = 60, Parent = b })
	end
	return t
end

local function renderExhibit(model)
	local id = model:GetAttribute("ExhibitId")
	local d = id and Content.exhibit(id)
	if not d or (Config.MODE == "demo" and not d.Verified) then return end
	if d.Timeline then
		for i, step in d.Timeline do
			local b = model:FindFirstChild("Board_" .. i, true)
			if b and b:IsA("BasePart") then
				boardText(b, string.format("%d · %s", i, string.upper(step.Title)), (step.Date or "") .. "\n\n" .. (step.Text or ""))
			end
		end
	end
	local board = model:FindFirstChild("Board", true)
	if board and board:IsA("BasePart") then
		local first = Content.gallery(d)[1]
		local photo = first and first.Photo or nil
		if d.Memorial then
			local title, rest = (d.BoardText or d.Name):match("^([^\n]*)\n?(.*)$")
			boardText(board, title, rest, true, photo)
		else
			boardText(board, string.upper(d.Name), d.BoardText or d.History, false, photo)
		end
	end
end

---------------------------------------------------------------------------------
-- Parede de missões
---------------------------------------------------------------------------------
local wall
local function findWall()
	local hall = workspace:FindFirstChild("NASAComplex") and workspace.NASAComplex:FindFirstChild("SpaceMuseumHall")
	return hall and hall:FindFirstChild("MissionWall", true)
end

local function currentWall()
	if not (wall and wall:IsDescendantOf(workspace)) then wall = findWall() end
	return wall
end

function World.cardSlotAnchor(cardId)
	currentWall()
	if not wall then return nil end
	for i, c in Content.cards() do
		if c.Id == cardId then
			local slot = wall:FindFirstChild("CardSlot_" .. i)
			return slot and (slot:FindFirstChild("Glass") or slot:FindFirstChildWhichIsA("BasePart", true))
		end
	end
	return nil
end

local function renderWall()
	currentWall()
	if not wall then return end
	for i, c in Content.cards() do
		local slot = wall:FindFirstChild("CardSlot_" .. i)
		if slot then
			-- modo demo: card não verificado aparece como bloqueado (sem nome nem foto)
			local owned = State.progress.cards[c.Id] == true and (Config.MODE ~= "demo" or c.Verified == true)
			local frameP = slot:FindFirstChild("PhotoFrame", true)
			if frameP and frameP:IsA("BasePart") then
				local bg = surface(frameP, "PhotoFace")
				local first = Content.gallery(c)[1]
				local asset = first and first.Photo.AssetId
				if owned and asset then
					UI.new("ImageLabel", { Size = UDim2.fromScale(1, 0.78), Position = UDim2.fromScale(0, 0.03), BackgroundTransparency = 1, Image = asset, ScaleType = Enum.ScaleType.Fit, Parent = bg })
				end
				UI.new("TextLabel", {
					BackgroundTransparency = 1,
					Position = owned and UDim2.fromScale(0.05, asset and 0.8 or 0.3) or UDim2.fromScale(0.05, 0.12),
					Size = owned and UDim2.fromScale(0.9, asset and 0.17 or 0.4) or UDim2.fromScale(0.9, 0.6),
					Text = owned and (c.Name .. (c.Year and ("  ·  " .. c.Year) or "")) or "?",
					TextScaled = true, TextWrapped = owned, FontFace = UI.font(Enum.FontWeight.Bold),
					TextColor3 = owned and UI.C.text or Color3.fromHex("5A6788"), Parent = bg,
				})
				if not owned then
					UI.new("TextLabel", {
						BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.76), Size = UDim2.fromScale(0.9, 0.16),
						Text = string.upper(Text.get("card.locked")), TextScaled = true, FontFace = UI.font(Enum.FontWeight.SemiBold),
						TextColor3 = Color3.fromHex("8C99AB"), Parent = bg,
					})
				end
			end
			for _, l in slot:GetDescendants() do
				if l:IsA("Light") and l.Parent and l.Parent.Name == "SlotLight" then l.Enabled = owned end
			end
		end
	end
end

---------------------------------------------------------------------------------
-- Caminho até uma exposição
---------------------------------------------------------------------------------
local pathFolder
function World.showPath(exhibitId)
	if pathFolder then pathFolder:Destroy() end
	local target
	for _, m in CollectionService:GetTagged("Exhibit") do
		if m:GetAttribute("ExhibitId") == exhibitId then
			target = m:FindFirstChild("PromptAnchor", true) or m.PrimaryPart
		end
	end
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (target and root) then return end
	pathFolder = Instance.new("Folder")
	pathFolder.Name = "MuseumGuidePath"
	pathFolder.Parent = workspace
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, -2.6, 0)
	a0.Parent = root
	local endPart = Instance.new("Part")
	endPart.Anchored, endPart.CanCollide, endPart.CanQuery, endPart.CanTouch, endPart.Transparency = true, false, false, false, 1
	endPart.Size = Vector3.one
	endPart.Position = Vector3.new(target.Position.X, 0.2, target.Position.Z)
	endPart.Parent = pathFolder
	local a1 = Instance.new("Attachment")
	a1.Parent = endPart
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Width0, beam.Width1 = 1.2, 1.2
	beam.FaceCamera = false
	beam.Color = ColorSequence.new(UI.C.accent)
	beam.LightEmission = 0.8
	beam.Transparency = NumberSequence.new(0.15)
	beam.Segments = 2
	beam.Parent = pathFolder
	local beacon = Instance.new("PointLight")
	beacon.Color, beacon.Range, beacon.Brightness = UI.C.accent, 16, 3
	beacon.Parent = endPart
	local folder = pathFolder
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local r = char.Parent and char:FindFirstChild("HumanoidRootPart")
		if not folder.Parent or not r or os.clock() - t0 > 40 or (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(endPart.Position.X, 0, endPart.Position.Z)).Magnitude < 14 then
			conn:Disconnect()
			a0:Destroy()
			folder:Destroy()
		end
	end)
end

---------------------------------------------------------------------------------
-- Portal de saída
---------------------------------------------------------------------------------
-- Não usa Touched (a peça do portal pode ter CanTouch = false). A cada quadro compara a
-- posição anterior com a atual: dispara quando o segmento cruza o plano do portal (pelo
-- centro da peça, perpendicular a ExitDirection) no sentido de ExitDirection, dentro da
-- abertura. Sem ExitDirection, usa o eixo X local da peça e dispara nos dois sentidos.
-- Quem só entra no museu não dispara.
local function setupExit(part)
	local leave = MS:WaitForChild("Events"):WaitForChild("LeaveMuseum")
	local prev
	local last = 0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not part.Parent then
			conn:Disconnect()
			return
		end
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			prev = nil
			return
		end
		local now = root.Position
		if prev and (now - prev).Magnitude < 30 then -- teleporte não conta
			local attr = part:GetAttribute("ExitDirection")
			local dir = typeof(attr) == "Vector3" and attr.Unit or part.CFrame.RightVector
			local center = part.Position
			local d0, d1 = (prev - center):Dot(dir), (now - center):Dot(dir)
			local crossed = typeof(attr) == "Vector3" and (d0 < 0 and d1 >= 0) or (d0 * d1 < 0)
			if crossed and os.clock() - last > 3 then
				local t = d0 / (d0 - d1)
				local hit = prev:Lerp(now, t)
				local rel = part.CFrame:PointToObjectSpace(hit)
				local half = part.Size / 2 + Vector3.new(1, 4, 1)
				-- dentro da abertura (ignora a espessura, que é o eixo do cruzamento)
				local lp = part.CFrame:VectorToObjectSpace(dir)
				local okX = math.abs(lp.X) > 0.7 or math.abs(rel.X) <= half.X
				local okY = math.abs(lp.Y) > 0.7 or math.abs(rel.Y) <= half.Y
				local okZ = math.abs(lp.Z) > 0.7 or math.abs(rel.Z) <= half.Z
				if okX and okY and okZ then
					last = os.clock()
					leave:Fire()
				end
			end
		end
		prev = now
	end)
end

function World.start()
	for _, m in CollectionService:GetTagged("Exhibit") do task.spawn(renderExhibit, m) end
	CollectionService:GetInstanceAddedSignal("Exhibit"):Connect(renderExhibit)
	for _, p in CollectionService:GetTagged("MuseumExit") do setupExit(p) end
	CollectionService:GetInstanceAddedSignal("MuseumExit"):Connect(setupExit)
	State.Changed:Connect(renderWall)
	task.spawn(function()
		for _ = 1, 120 do
			wall = findWall()
			if wall then break end
			task.wait(1)
		end
		renderWall()
		-- a parede (Atomic) pode sair e voltar com o streaming: o salão (Persistent) avisa
		local hall = workspace:FindFirstChild("NASAComplex") and workspace.NASAComplex:FindFirstChild("SpaceMuseumHall")
		if hall then hall.DescendantAdded:Connect(function(d)
			if d.Name == "MissionWall" or d.Name == "PhotoFrame" then task.defer(renderWall) end
		end) end
	end)
end

return World
