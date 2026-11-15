--[[
	NavigationClient — seta vermelha 3D e objetivo no HUD (spec §6).

	O servidor manda o caminho (pathfinding) pelo NavigationUpdate; aqui só se desenha:
	- seta flutuando à frente do jogador, apontada para o próximo ponto do caminho (nunca através
	  de paredes: o caminho contorna as paredes, e a seta não entra na parede ao lado do jogador);
	- seta de destino girando acima do alvo (Marcos, Ana, exposição, entrada do foguete);
	- objetivo curto no canto superior esquerdo.
	Tudo é local (peças na câmera): cada jogador vê só a própria seta.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GS = RS:WaitForChild("GuideSystem")
local Settings = require(GS:WaitForChild("Config"):WaitForChild("Settings"))
local UI = require(script.Parent:WaitForChild("GuideUI"))

local player = Players.LocalPlayer
local NavigationClient = {}
local missionMode, missionRoute = false, nil

-- Mesmo desenho/oclusão da seta dos guias; a task fornece a estação atual.
function NavigationClient.missionTarget(active, target, position)
	missionMode = active
	missionRoute = target and { points = { position, target }, idx = 2, target = target, beacon = true } or nil
end

local A = Settings.Arrow
local state = { points = nil, idx = 1, target = nil, beacon = false, objective = nil, stage = nil }

-- Setas desligadas perto do alvo, com histerese: apagam ao chegar (NEAR) e só voltam se o
-- jogador se afastar além de FAR ou se surgir um objetivo novo. Vale para o Marcos e a Ana
-- (alvo que anda) e para a estação da task nas missões.
local NEAR = { guide = 12, mission = 6 }
local FAR = { guide = 22, mission = 12 }
local arrived, arrivedKey = false, nil
local lastRepath = 0

---------------------------------------------------------------------------------
-- Seta 3D (haste + ponta de duas cunhas), apontando para −Z do CFrame
---------------------------------------------------------------------------------

local function arrowModel(name, scale)
	local m = Instance.new("Model")
	m.Name = name
	local parts = {}
	local function part(class, size)
		local p = Instance.new(class)
		p.Size = size * scale
		p.Color = A.Color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = m
		table.insert(parts, p)
		return p
	end
	local shaftLen, headW, headD = 1.6, 1.3, 1.3
	local shaft = part("Part", Vector3.new(0.45, 0.3, shaftLen))
	local headR = part("WedgePart", Vector3.new(0.3, headW / 2, headD))
	local headL = part("WedgePart", Vector3.new(0.3, headW / 2, headD))
	local light = Instance.new("PointLight")
	light.Color = A.Color
	light.Range = 6 * scale
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = shaft
	local offsets = {
		[shaft] = CFrame.new(0, 0, shaftLen * scale / 2),
		[headR] = CFrame.new(headW * scale / 4, 0, -headD * scale / 2) * CFrame.Angles(0, 0, -math.pi / 2),
		[headL] = CFrame.new(-headW * scale / 4, 0, -headD * scale / 2) * CFrame.Angles(0, 0, math.pi / 2),
	}
	return {
		model = m,
		set = function(cf)
			for p, off in offsets do p.CFrame = cf * off end
		end,
		visible = function(v)
			for _, p in parts do p.Transparency = v and 0 or 1 end
			light.Enabled = v
		end,
	}
end

---------------------------------------------------------------------------------
-- HUD do objetivo
---------------------------------------------------------------------------------

local hud = {}

local function buildHud()
	local gui = UI.screenGui("GuideObjective", 8)
	local frame = UI.new("Frame", {
		Name = "Objective",
		BackgroundColor3 = UI.C.panel,
		BackgroundTransparency = 0.12,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	UI.corner(frame, 12)
	UI.stroke(frame, UI.C.line)
	UI.pad(frame, 10)
	UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(340, 200), Parent = frame })
	local head = UI.text(frame, {
		Text = "▶  OBJECTIVE", Color = A.Color, Weight = Enum.FontWeight.Bold, TextSize = 13,
		Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1,
	})
	local body = UI.text(frame, {
		Text = "", TextSize = 17, Weight = Enum.FontWeight.SemiBold,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})
	hud.gui, hud.frame, hud.head, hud.body = gui, frame, head, body
end

local blip
local function playBlip()
	if not blip then
		blip = Instance.new("Sound")
		blip.SoundId = Settings.Sounds.Blip.Id
		blip.Volume = Settings.Sounds.Blip.Volume
		blip.Parent = SoundService
	end
	blip:Play()
end

local function setObjective(text)
	if text == state.objective then return end
	state.objective = text
	if not text then
		hud.frame.Visible = false
		return
	end
	hud.body.Text = text
	hud.frame.Visible = true
	hud.frame.Position = UDim2.fromOffset(-320, 10)
	TweenService:Create(hud.frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(12, 10),
	}):Play()
	playBlip()
end

---------------------------------------------------------------------------------
-- Caminho
---------------------------------------------------------------------------------

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function distToSegment(p, a, b)
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then return (p - a).Magnitude end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- próximo ponto do caminho a seguir (monotônico: nunca volta para trás)
local function nextPoint(pos, route)
	route = route or state
	local pts = route.points
	if not pts or #pts == 0 then return nil end
	local i = math.clamp(route.idx, 1, #pts)
	while i < #pts do
		local d = flat(pts[i] - pos).Magnitude
		local dy = math.abs(pts[i].Y - pos.Y)
		-- só pula para o próximo ponto se ele estiver no mesmo nível (escadas: não pular o lance)
		local nextSameLevel = math.abs(pts[i + 1].Y - pos.Y) < 6
		if (d < 4 and dy < 6) or (nextSameLevel and flat(pts[i + 1] - pos).Magnitude < d) then
			i += 1
		else
			break
		end
	end
	route.idx = i
	-- saiu muito da rota: pede outro caminho ao servidor
	local off = math.huge
	if i > 1 then off = distToSegment(pos, pts[i - 1], pts[i]) else off = 0 end
	if not missionMode and off > 18 and os.clock() - lastRepath > 2.5 then
		lastRepath = os.clock()
		GS.Remotes.NavigationUpdate:FireServer("Repath")
	end
	return pts[i]
end

---------------------------------------------------------------------------------

function NavigationClient.start()
	buildHud()
	local holder = workspace.CurrentCamera
	local arrow = arrowModel("GuideArrow", 1)
	arrow.model.Parent = holder
	local beacon = arrowModel("GuideBeacon", 2.2)
	beacon.model.Parent = holder
	arrow.visible(false)
	beacon.visible(false)
	-- a câmera pode ser trocada (cutscenes do museu/Rookie); recoloca as setas na câmera atual
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		holder = workspace.CurrentCamera
		arrow.model.Parent = holder
		beacon.model.Parent = holder
	end)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true

	GS:WaitForChild("Remotes"):WaitForChild("NavigationUpdate").OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then return end
		setObjective(data.objective)
		state.points = data.points
		state.idx = data.points and math.min(2, #data.points) or 1
		state.target = data.target
		state.beacon = data.beacon == true
		state.stage = data.stage
	end)

	local yaw = nil
	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local t = os.clock()
		local route = state
		if missionMode then route = missionRoute end
		if missionMode then hud.frame.Visible = false end
		if not root or not route or not route.points or not route.target then
			arrow.visible(false)
			beacon.visible(false)
			return
		end
		local pos = root.Position
		local tgt = route.target
		-- chegou perto do alvo: apaga as duas setas até o jogador se afastar ou o objetivo mudar
		local key = missionMode
			and string.format("M:%d:%d:%d", math.floor(tgt.X + 0.5), math.floor(tgt.Y + 0.5), math.floor(tgt.Z + 0.5))
			or ("G:" .. tostring(state.stage) .. ":" .. tostring(state.objective))
		if key ~= arrivedKey then
			arrivedKey = key
			arrived = false
		end
		local kind = missionMode and "mission" or "guide"
		local dist = (tgt - pos).Magnitude
		if not arrived and dist < NEAR[kind] then
			arrived = true
		elseif arrived and dist > FAR[kind] then
			arrived = false
		end
		if arrived then
			arrow.visible(false)
			beacon.visible(false)
			return
		end
		-- seta de destino girando acima do alvo
		local bob = math.sin(t * 2.4) * A.Bob
		local showBeacon = route.beacon and (tgt - pos).Magnitude < 260
		beacon.visible(showBeacon)
		if showBeacon then
			beacon.set(CFrame.new(tgt + Vector3.new(0, A.BeaconHeight + bob * 2, 0)) * CFrame.Angles(0, t * 1.6, 0) * CFrame.Angles(-math.pi / 2, 0, 0))
		end
		local p = nextPoint(pos, route)
		if not p then
			arrow.visible(false)
			return
		end
		local dir = flat(p - pos)
		if dir.Magnitude < 0.5 then dir = flat(tgt - pos) end
		if dir.Magnitude < 0.5 then return end
		dir = dir.Unit
		-- giro suave
		local want = math.atan2(-dir.X, -dir.Z)
		if not yaw then yaw = want end
		local diff = (want - yaw + math.pi) % (2 * math.pi) - math.pi
		yaw += diff * math.clamp(dt * 8, 0, 1)
		local look = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
		local base = pos + Vector3.new(0, A.Height + bob, 0)
		local ahead = A.Ahead
		-- não entra em paredes: encurta até o obstáculo
		rayParams.FilterDescendantsInstances = { char, holder }
		local hit = workspace:Raycast(base, look * (ahead + 1), rayParams)
		if hit then ahead = math.max(1.2, hit.Distance - 1.2) end
		-- inclina levemente para cima/baixo em escadas
		local pitch = math.clamp((p.Y - pos.Y) / math.max(4, (p - pos).Magnitude), -0.5, 0.5)
		local cf = CFrame.lookAt(base + look * ahead, base + look * (ahead + 1) + Vector3.new(0, pitch, 0))
		arrow.set(cf)
		arrow.visible(true)
	end)
end

return NavigationClient
