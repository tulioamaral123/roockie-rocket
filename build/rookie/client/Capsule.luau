-- Gravidade apenas no personagem local e orientação usando a seta 3D dos guias.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Capsule = {}
local state, model, navigation
local humanoid, saved, attachment, force

local function inside(part, position)
	if not part then return false end
	local p = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

local function find(path)
	local node = model
	for name in path:gmatch("[^/]+") do node = node and node:FindFirstChild(name) end
	return node
end

local function restore()
	if force then force:Destroy() force = nil end
	if attachment then attachment:Destroy() attachment = nil end
	if humanoid and humanoid.Parent and saved then
		humanoid.JumpPower = saved.power
		humanoid.JumpHeight = saved.height
	end
	humanoid, saved = nil, nil
end

local function target(root)
	if not state or state.fase ~= "Task" then return nil end
	local d = state.dados or {}
	local path
	if state.missao == 1 then
		if state.task == 1 then
			-- painel de atitude em frente aos assentos
			path = "Stations/FlightPanel"
		elseif state.task == 2 then
			local read = d.lidos and d.lidos[tostring(player.UserId)]
			path = read and "Stations/Radio/Keypad" or "Stations/NavTable/Clipboard"
		else path = "Stations/Reentry/RetainButtonA" end
	else
		-- Primeiro sai da cápsula e atravessa o túnel; depois segue à estação da task.
		if inside(find("CapsuleBounds"), root.Position) then return find("Capsule/DockingHatch").Position end
		local origin = model.Origin.Position
		local localPos = root.Position - origin
		if not player:GetAttribute("RookieEVA") then
			if localPos.X < -17 then return origin + Vector3.new(-12, 3, -12) end
			if state.task == 1 and localPos.Z > -24 and (math.abs(localPos.X) > 3 or localPos.Z > -20) then
				return origin + Vector3.new(0, 3, -23)
			end
			if state.task ~= 1 and localPos.Z < -24 then return origin + Vector3.new(0, 3, -20) end
			if state.task == 2 and localPos.X < 18 then return origin + Vector3.new(23, 3, 0) end
			if state.task == 3 and localPos.X > 18 then return origin + Vector3.new(12, 3, 0) end
		end
		if state.task == 1 then path = "Stations/CanadarmConsole"
		elseif state.task == 2 then
			if not player:GetAttribute("RookieEVA") then path = "Airlock/InnerHatch"
			else
				for i = 1, 2 do
					if d.carregando and d.carregando[tostring(i)] == player.UserId then path = "Exterior/Pulleys/Pulley" .. i break end
				end
				if not path then
					local best = math.huge
					for i = 1, 2 do
						if not (d.presos and d.presos[i]) and not (d.carregando and d.carregando[tostring(i)]) then
							local candidate = "Exterior/Cables/Cable" .. i
							local distance = (find(candidate).Position - root.Position).Magnitude
							if distance < best then best, path = distance, candidate end
						end
					end
				end
			end
		else
			if not d.fechada then path = "Stations/AdjacentHatch/Prompt"
			elseif not player:GetAttribute("RookieGaze") then path = "Stations/Toolbox"
			else path = "LeakSpots/Spot" .. (d.furo or 1) end
		end
	end
	local part = path and find(path)
	return part and part.Position
end

function Capsule.update(e, ship)
	state, model = e, ship
end

function Capsule.clear()
	state, model = nil, nil
	restore()
	if navigation then navigation.missionTarget(false) end
end

function Capsule.start()
	-- Não bloqueia o RookieClient se os guias ainda estiverem carregando.
	task.spawn(function()
		local guides = script.Parent.Parent:WaitForChild("GuideClient", 30)
		if guides then navigation = require(guides:WaitForChild("NavigationClient")) end
	end)
	player.CharacterRemoving:Connect(Capsule.clear)
	RunService.PreSimulation:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local inCapsule = root and model and inside(find("CapsuleBounds"), root.Position)
		local active = state ~= nil and hum and hum.Health > 0
		if active and inCapsule and not player:GetAttribute("RookieEVA") then
			if humanoid ~= hum then
				restore()
				humanoid = hum
				saved = { power = hum.JumpPower, height = hum.JumpHeight }
				hum.JumpPower = 19
				hum.JumpHeight = 19 ^ 2 / (2 * workspace.Gravity)
				attachment = Instance.new("Attachment")
				attachment.Name = "CapsuleGravity"
				attachment.Parent = root
				force = Instance.new("VectorForce")
				force.Attachment0 = attachment
				force.ApplyAtCenterOfMass = true
				force.RelativeTo = Enum.ActuatorRelativeTo.World
				force.Parent = root
			end
			force.Force = Vector3.new(0, root.AssemblyMass * math.max(0, workspace.Gravity - 35), 0)
		else restore() end
		if navigation then navigation.missionTarget(state ~= nil, active and root and target(root) or nil, root and root.Position) end
	end)
end

return Capsule
