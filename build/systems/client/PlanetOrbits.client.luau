-- Rotação lenta dos planetas (NASA Space Adventure, Fase 6)
-- Efeito apenas visual no cliente. Lê os atributos OrbitRadius, OrbitAngle (graus),
-- OrbitSpeed (graus/s) e OrbitCenter de cada Model em Space_Adventure/Solar_System.
local RunService = game:GetService("RunService")

local solar = workspace:WaitForChild("NASAComplex"):WaitForChild("CapeCanaveralMuseum"):WaitForChild("Solar_System")
local planets = {}

local function track(m)
	if m:IsA("Model") and m:GetAttribute("OrbitRadius") then planets[m] = true end
end
for _, c in solar:GetChildren() do track(c) end
solar.ChildAdded:Connect(track)
solar.ChildRemoved:Connect(function(c) planets[c] = nil end)

local start = os.clock()
RunService.RenderStepped:Connect(function()
	local t = os.clock() - start
	for m in planets do
		local body = m.PrimaryPart
		if body and m.Parent then
			local r = m:GetAttribute("OrbitRadius")
			local a = math.rad(m:GetAttribute("OrbitAngle") + m:GetAttribute("OrbitSpeed") * t)
			local c = m:GetAttribute("OrbitCenter")
			local target = Vector3.new(c.X + r * math.cos(a), c.Y, c.Z + r * math.sin(a))
			m:PivotTo(m:GetPivot() + (target - body.Position))
		end
	end
end)
