-- Estado e validação no servidor; os prompts funcionam em teclado, toque e controle.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local remote = RS:FindFirstChild("AstronautTrainingFeedback")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AstronautTrainingFeedback"
	remote.Parent = RS
end
local profiles, forces, lastUse, connections = {}, {}, {}, {}
local campus, round
local function feedback(player, text)
	if player.Parent == Players then remote:FireClient(player, text) end
end
local function body(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hum and root and hum.Health > 0 then return root, hum end
	return nil
end
local function inside(zone, pos)
	local p = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end
local function profile(player)
	if not profiles[player] then profiles[player] = { gravity = {}, repair = 0 } end
	return profiles[player]
end
local function clearForce(player)
	local f = forces[player]
	if f then
		f.force:Destroy()
		f.attachment:Destroy()
		if f.hum.Parent then
			f.hum.JumpPower, f.hum.JumpHeight = f.power, f.height
		end
		forces[player] = nil
	end
	player:SetAttribute("TrainingWorld", nil)
end
local function endRound(message, success)
	local r = round
	if not r then return end
	round = nil
	for p in r.people do
		if success then p:SetAttribute("TrainingCrewComplete", true) end
		feedback(p, message)
	end
end
local function eligible(player, part)
	local root = body(player)
	return root and not player:GetAttribute("RookieMission") and not player:GetAttribute("InCutscene")
		and (root.Position - part.Position).Magnitude <= 11
end
local function interact(player, part)
	if not campus or not part:IsDescendantOf(campus) or not eligible(player, part) then return end
	local now = os.clock()
	if now - (lastUse[player] or 0) < 0.3 then return end
	lastUse[player] = now
	local action, p = part:GetAttribute("TrainingAction"), profile(player)
	if action == "Gravity" then
		local lane, step = part:GetAttribute("Lane"), part:GetAttribute("Checkpoint")
		local root = body(player)
		local platform = part.Parent:FindFirstChild("Step" .. step)
		local offset = root.Position - platform.Position
		if math.abs(offset.X) > 4.5 or math.abs(offset.Z) > 3.5 or root.Position.Y < platform.Position.Y + platform.Size.Y / 2 + 2 then
			feedback(player, "Stand on the checkpoint platform, then confirm it.")
			return
		end
		local current = p.gravity[lane] or 0
		if step ~= current + 1 then
			feedback(player, "Follow checkpoints 1 > 2 > 3. Completed lanes can be practiced again from checkpoint 1.")
			if current == 3 and step == 1 then p.gravity[lane] = 1 end
			return
		end
		p.gravity[lane] = step
		feedback(player, lane .. " checkpoint " .. step .. "/3. The same jump impulse travels farther in lower gravity.")
		if p.gravity.Earth == 3 and p.gravity.Moon == 3 and p.gravity.Mars == 3 then
			player:SetAttribute("TrainingGravityComplete", true)
			feedback(player, "Gravity lab complete! Lower gravity changes your weight, not your mass.")
		end
	elseif action == "Repair" then
		local step = part:GetAttribute("Step")
		if step == 1 then
			p.repair = 1
			feedback(player, "Power isolated. Now replace the air filter.")
		elseif p.repair == step - 1 then
			p.repair = step
			if step == 3 then
				player:SetAttribute("TrainingRepairComplete", true)
				feedback(player, "Repair complete! Isolate energy before servicing equipment, then verify operation.")
			else feedback(player, "Filter replaced. Restore power to test the system.") end
		else feedback(player, "Follow the safe procedure: isolate power > replace filter > restore power.") end
	elseif action == "Solo" or action == "Team" then
		if round then feedback(player, "A drill is active. Wait up to 30 seconds, then start again.") return end
		round = { owner = player, team = action == "Team", step = 1, deadline = now + 30, people = { [player] = true }, operators = {} }
		feedback(player, action .. " drill started: Power > Cooling > Communications. You have 30 seconds.")
	elseif action == "Crew" then
		local r = round
		if not r then feedback(player, "Choose Start solo or Start team first.") return end
		if now >= r.deadline then endRound("Time expired. Plan your stations and try again.", false) return end
		if not r.team and r.owner ~= player then feedback(player, "Solo drill in progress. Start your own after this round.") return end
		local participants = 0
		for member in r.people do
			local root = body(member)
			if not root or (root.Position - Vector3.new(541, 3, 181)).Magnitude > 60 or member:GetAttribute("RookieMission") then
				endRound("Crew member left the exercise. Start again.", false)
				return
			end
			participants += 1
		end
		if not r.people[player] and participants >= 4 then feedback(player, "This crew already has four astronauts.") return end
		local step = part:GetAttribute("Step")
		if step ~= r.step then feedback(player, "Next station: " .. ({ "Power", "Cooling", "Communications" })[r.step]) return end
		r.people[player], r.operators[player] = true, true
		if step == 3 then
			local count = 0
			for _ in r.operators do count += 1 end
			if r.team and count < 2 then
				feedback(player, "Team mode needs a second astronaut. Ask them to confirm Communications.")
				return
			end
			endRound("Crew operations complete! Clear roles and ordered checks keep a mission safe.", true)
		else
			r.step += 1
			for member in r.people do feedback(member, "Confirmed. Next: " .. ({ "Power", "Cooling", "Communications" })[r.step]) end
		end
	end
end
local function attach(root)
	for _, c in connections do c:Disconnect() end
	table.clear(connections)
	for player in forces do clearForce(player) end
	endRound("Training reset. Start a new drill.", false)
	campus = root
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("TrainingAction") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name, prompt.ActionText = "TrainingPrompt", "Practice"
			prompt.ObjectText = part:GetAttribute("TrainingLabel")
			prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 8, true
			prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
			prompt.Parent = part
			table.insert(connections, prompt.Triggered:Connect(function(player) interact(player, part) end))
		end
	end
end
local map = workspace:WaitForChild("NASAComplex")
map.ChildAdded:Connect(function(child)
	if child.Name == "AstronautTraining" then
		task.spawn(function()
			local start = os.clock()
			while child.Parent and not child:GetAttribute("TrainingReady") and os.clock() - start < 30 do task.wait(0.1) end
			if child.Parent and child:GetAttribute("TrainingReady") then attach(child) end
		end)
	end
end)
local existing = map:FindFirstChild("AstronautTraining")
if existing and existing:GetAttribute("TrainingReady") then attach(existing) end
local function characterChanged(player)
	clearForce(player)
	local p = profiles[player]
	if p then p.repair = 0 end
	if round and round.people[player] then endRound("Crew member left the exercise. Start again.", false) end
end
local function watch(player)
	player.CharacterRemoving:Connect(function() characterChanged(player) end)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do watch(player) end
Players.PlayerRemoving:Connect(function(player)
	characterChanged(player)
	profiles[player], lastUse[player] = nil, nil
end)
RunService.PreSimulation:Connect(function()
	if round then
		if os.clock() >= round.deadline then endRound("Time expired. Plan your stations and try again.", false)
		else
			for player in round.people do
				local root = body(player)
				if not root or (root.Position - Vector3.new(541, 3, 181)).Magnitude > 60 or player:GetAttribute("RookieMission") then
					endRound("Crew member left the exercise. Start again.", false)
					break
				end
			end
		end
	end
	local lab = campus and campus.Parent and campus:FindFirstChild("GravityLab")
	for _, player in Players:GetPlayers() do
		local root, hum = body(player)
		local lane
		if lab and root and not hum.SeatPart and not player:GetAttribute("RookieMission") then
			for _, candidate in lab:GetChildren() do
				if inside(candidate.Zone, root.Position) then lane = candidate break end
			end
		end
		if not lane then clearForce(player)
		else
			local f = forces[player]
			if f and f.hum ~= hum then clearForce(player) f = nil end
			if not f then
				local attachment = Instance.new("Attachment")
				attachment.Name, attachment.Parent = "TrainingGravity", root
				local force = Instance.new("VectorForce")
				force.Name, force.Attachment0 = "TrainingGravity", attachment
				force.RelativeTo, force.ApplyAtCenterOfMass = Enum.ActuatorRelativeTo.World, true
				force.Parent = root
				f = { attachment = attachment, force = force, hum = hum, power = hum.JumpPower, height = hum.JumpHeight }
				forces[player] = f
			end
			local ratio = lane.Zone:GetAttribute("GravityRatio")
			local gravity = workspace.Gravity
			-- Impulso igual nas três pistas; protege contra massa infinita de assemblies ancorados.
			hum.JumpPower = 28
			hum.JumpHeight = 28 * 28 / (2 * math.max(1, gravity))
			local mass = root.AssemblyMass
			f.force.Force = mass < math.huge and Vector3.new(0, mass * gravity * (1 - ratio), 0) or Vector3.zero
			player:SetAttribute("TrainingWorld", lane.Name)
		end
	end
end)
