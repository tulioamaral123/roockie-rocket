-- Executar em Edit depois da Fase 25. Não modifica o mapa.
local map = assert(workspace:FindFirstChild("NASAComplex"), "NASAComplex missing")
local root = assert(map:FindFirstChild("AstronautTraining"), "Run phase 25 first")
assert(root:GetAttribute("TrainingReady"), "Training generation incomplete")
local count, prompts = 0, 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
		assert(d.Anchored and d.Size.X > 0 and d.Size.Y > 0 and d.Size.Z > 0, d:GetFullName())
		assert(d:GetAttribute("BuildPhase") == 25, d:GetFullName())
		if d:GetAttribute("TrainingAction") then prompts += 1 end
	end
end
assert(count <= 250, "Training part budget exceeded")
assert(prompts == 17, "Expected 9 checkpoints, 3 repair, 2 start and 3 crew stations")
for _, name in { "Earth", "Moon", "Mars" } do
	local lane = assert(root.GravityLab:FindFirstChild(name), name)
	assert(lane.Zone:GetAttribute("GravityRatio") > 0 and lane.Zone:GetAttribute("GravityRatio") <= 1)
	assert(not lane.Zone.CanCollide and not lane.Zone.CanQuery and lane.Zone.Transparency == 1)
	for i = 1, 3 do
		assert(lane:FindFirstChild("Checkpoint" .. i) and lane:FindFirstChild("Step" .. i))
	end
end
local pathService = game:GetService("PathfindingService")
for _, goal in { Vector3.new(520, 3, 100), Vector3.new(481, 3, 178), Vector3.new(541, 3, 181) } do
	local path = pathService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
	path:ComputeAsync(Vector3.new(0, 3, -95), goal)
	assert(path.Status == Enum.PathStatus.Success, "No visitor path to " .. tostring(goal))
end
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { root }
params.RespectCanCollide = true
for _, area in {
	{ Vector3.new(520, 12, 146), Vector3.new(122, 24, 114) },
	{ Vector3.new(264.5, 3, -95), Vector3.new(519, 5, 8) },
	{ Vector3.new(520, 3, -0.5), Vector3.new(8, 5, 181) },
} do
	for _, p in workspace:GetPartBoundsInBox(CFrame.new(area[1]), area[2], params) do
		local top = p.Position.Y + p.Size.Y / 2
		assert(top <= 0.1, "Existing obstacle in training area: " .. p:GetFullName())
	end
end
print("Training checks passed:", count, "parts;", prompts, "stations; visitor paths and existing obstacles checked")
return count
