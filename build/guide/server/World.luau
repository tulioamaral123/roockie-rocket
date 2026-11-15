--[[
	World — pontos do mapa usados pelos guias (docs/guias-contrato.md).

	Fixos (Fase 22): NASAComplex.Guides.NavigationPoints
	  Spawn_Marcos, PrimeiroMuseu, SalaControle, PainelPrincipal, Hangar, RocketEntrance,
	  Ana (onde ela entra em cena), Ana_Route1..N (vestiário → pé da escada do lançador).
	Relativos ao conjunto de transporte (lidos ao vivo, acompanham o lançador):
	  Access_Stairs.Landing (topo da escada), Crew_Elevator.Cab_Lower / Cab_Upper, Arm_Deck.
]]

local RS = game:GetService("ReplicatedStorage")

local Settings = require(RS:WaitForChild("GuideSystem"):WaitForChild("Config"):WaitForChild("Settings"))

local World = {}

local map = workspace:WaitForChild("NASAComplex")
local guides = map:WaitForChild("Guides", 30)
local points = guides and guides:WaitForChild("NavigationPoints", 10)
if not points then warn("[GuideSystem] NASAComplex.Guides.NavigationPoints não existe: rode a Fase 22") end

World.guides = guides
World.points = points

local cache = {}
local function find(name, className)
	local c = cache[name]
	if c and c.Parent then return c end
	local transport = map:FindFirstChild("TransportSystem")
	for _, d in (transport or map):GetDescendants() do
		if d.Name == name and (not className or d:IsA(className)) then
			cache[name] = d
			return d
		end
	end
	return nil
end

function World.point(name: string): Vector3?
	local p = points and points:FindFirstChild(name)
	return p and p.Position
end

function World.pointCF(name: string): CFrame?
	local p = points and points:FindFirstChild(name)
	return p and p.CFrame
end

-- pontos numerados Ana_Route1..N em ordem
function World.route(prefix: string)
	local out = {}
	local i = 1
	while points do
		local p = points:FindFirstChild(prefix .. i)
		if not p then break end
		table.insert(out, p.Position)
		i += 1
	end
	return out
end

-- topo de uma peça (piso), com a altura do HumanoidRootPart (3) acima
local function standOn(part: BasePart, local_: Vector3?)
	local off = local_ or Vector3.zero
	return (part.CFrame * CFrame.new(off.X, part.Size.Y / 2, off.Z)).Position + Vector3.new(0, 3, 0)
end

function World.stairsTop(): Vector3?
	local stairs = find("Access_Stairs", "Model")
	local landing = stairs and stairs:FindFirstChild("Landing")
	return landing and standOn(landing)
end

local function cabFloor(name)
	local elev = find("Crew_Elevator", "Model")
	local cab = elev and elev:FindFirstChild(name)
	return cab and cab.PrimaryPart
end

-- diante da porta da cabine de baixo (porta na face −Z local) e dentro dela
function World.lowerCabFront(): Vector3?
	local f = cabFloor("Cab_Lower")
	return f and standOn(f, Vector3.new(0, 0, -(f.Size.Z / 2 + 2.5)))
end
function World.lowerCabInside(): Vector3?
	local f = cabFloor("Cab_Lower")
	return f and standOn(f)
end
function World.upperCabInside(): Vector3?
	local f = cabFloor("Cab_Upper")
	return f and standOn(f)
end

-- onde a Ana espera no braço de acesso: no início do braço, virada para a torre
-- há quatro peças "Arm_Deck" (umbilicais 40/60, braço de serviço 100, braço da tripulação):
-- só a do Crew_Access_Arm é o topo do foguete
local function crewDeck()
	local arm = find("Crew_Access_Arm", "Model")
	local d = arm and arm:FindFirstChild("Arm_Deck")
	return d and d:IsA("BasePart") and d or nil
end

function World.topSpot(): CFrame?
	local deck = crewDeck()
	if not deck then return nil end
	local pos = standOn(deck, Vector3.new(-deck.Size.X / 2 + 4, 0, 0))
	local cab = World.upperCabInside() or pos + Vector3.new(-10, 0, 0)
	return CFrame.lookAt(pos, Vector3.new(cab.X, pos.Y, cab.Z))
end

function World.armDeck(): BasePart?
	return crewDeck()
end

-- pontos dos prompts de traje (armários do Crew Suit-Up Room, Fase 8)
function World.lockers()
	local out = {}
	local hangar = map:FindFirstChild("VABHangar")
	local room = hangar and hangar:FindFirstChild("CrewSuitUpRoom")
	for _, d in (room and room:GetDescendants() or {}) do
		if d:IsA("ProximityPrompt") and d.Parent:IsA("BasePart") then table.insert(out, d.Parent.Position) end
	end
	return out
end

function World.nearestLocker(pos: Vector3): Vector3?
	local best, bd = nil, math.huge
	for _, p in World.lockers() do
		local d = (p - pos).Magnitude
		if d < bd then best, bd = p, d end
	end
	return best
end

function World.rootOf(player: Player): BasePart?
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then return nil end
	return c:FindFirstChild("HumanoidRootPart")
end

-- jogador está no braço de acesso (topo do foguete)?
function World.isAtTop(player: Player): boolean
	local root = World.rootOf(player)
	local deck = World.armDeck()
	if not root or not deck then return false end
	local d = root.Position - deck.Position
	return d.Y > -12 and Vector2.new(d.X, d.Z).Magnitude <= Settings.Radius.TopLevel
end

-- peças com prompt de exposição do museu (ExhibitService põe o atributo ExhibitId no prompt)
function World.exhibitParts()
	local out = {}
	-- só os modelos marcados como exposição (CollectionService "Exhibit", Fase 17)
	local candidates = {}
	for _, m in game:GetService("CollectionService"):GetTagged("Exhibit") do
		for _, d in m:GetDescendants() do table.insert(candidates, d) end
	end
	for _, d in candidates do
		if d:IsA("ProximityPrompt") and d:GetAttribute("ExhibitId") and d.Enabled then
			local part = d.Parent
			if part and part:IsA("Attachment") then part = part.Parent end
			if part and part:IsA("BasePart") then table.insert(out, part) end
		end
	end
	return out
end

local exhibitCache, exhibitTime = {}, -math.huge
function World.nearestExhibit(pos: Vector3): Vector3?
	if os.clock() - exhibitTime > 10 then
		exhibitCache = World.exhibitParts()
		exhibitTime = os.clock()
	end
	local best, bd = nil, math.huge
	for _, part in exhibitCache do
		if part.Parent then
			local d = (part.Position - pos).Magnitude
			if d < bd then best, bd = part, d end
		end
	end
	return best and best.Position
end

return World
