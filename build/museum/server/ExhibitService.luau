--[[
	ExhibitService — tags → prompts (museuspec §5.1, §9.2, §11.3).

	Para cada Model com a tag Exhibit e atributo ExhibitId válido, cria um ProximityPrompt
	"Examine <nome>" na peça PromptAnchor (ou no PrimaryPart). No modo demo, exposições com
	Verified = false não recebem prompt. Ao acionar, o servidor confere a distância, registra
	a visita e manda o cliente abrir o painel (Remotes.OpenExhibit).
	Também cria o prompt do show (LaunchConsole.ShowPromptAnchor → Remotes.StartShow).
]]

local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local MS = RS:WaitForChild("MuseumSystem")
local Shared = MS:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))
local Validator = require(Shared:WaitForChild("ContentValidator"))

local ExhibitService = {}

local Progress, Remotes, valid
local lastUse = {} -- [Player] = os.clock()
local startedShows = {} -- [Player] = { id, finishAt } (o show só conta se começou por aqui)
game:GetService("Players").PlayerRemoving:Connect(function(p)
	lastUse[p] = nil
	startedShows[p] = nil
end)
local done = setmetatable({}, { __mode = "k" })

local function visible(d)
	return Config.MODE ~= "demo" or d.Verified == true
end

local function closeEnough(player, part, maxDist)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	return (root.Position - part.Position).Magnitude <= maxDist + Config.PROMPT_DISTANCE_SLACK
end

local function throttled(player)
	local t = os.clock()
	if lastUse[player] and t - lastUse[player] < 0.4 then return true end
	lastUse[player] = t
	return false
end

local function makePrompt(parent, action, object, dist)
	local old = parent:FindFirstChild("MuseumPrompt")
	if old then old:Destroy() end
	local p = Instance.new("ProximityPrompt")
	p.Name = "MuseumPrompt"
	p.ActionText = action
	p.ObjectText = object
	p.MaxActivationDistance = dist
	p.RequiresLineOfSight = false
	p.HoldDuration = 0
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.Style = Enum.ProximityPromptStyle.Default
	p.Parent = parent
	return p
end

local function setup(model)
	if done[model] or not model:IsA("Model") then return end
	local id = model:GetAttribute("ExhibitId")
	local d = id and Content.exhibit(id)
	if not d then
		warn(string.format("[Content] model %s has tag Exhibit but no content (ExhibitId=%s)", model:GetFullName(), tostring(id)))
		return
	end
	if not valid[id] or not visible(d) then return end
	local anchor = model:FindFirstChild("PromptAnchor", true) or model.PrimaryPart
	if not (anchor and anchor:IsA("BasePart")) then
		warn("[Content] " .. id .. ": model without PromptAnchor/PrimaryPart")
		return
	end
	done[model] = true
	Validator.checkModel(model, d)
	local dist = d.PromptDistance or Config.PROMPT_DEFAULT_DISTANCE
	local prompt = makePrompt(anchor, Text.get("prompt.examine"), d.Name, dist)
	prompt:SetAttribute("ExhibitId", id)
	prompt.Triggered:Connect(function(player)
		if throttled(player) or not closeEnough(player, anchor, dist) then return end
		Progress.markExhibit(player, id)
		Remotes.OpenExhibit:FireClient(player, id)
	end)
end

local function setupShow()
	local anchor
	for _ = 1, 60 do
		local exhibits = workspace:FindFirstChild("NASAComplex") and workspace.NASAComplex:FindFirstChild("SpaceMuseumExhibits")
		anchor = exhibits and exhibits:FindFirstChild("ShowPromptAnchor", true)
		if anchor then break end
		task.wait(1)
	end
	if not anchor then
		warn("[Museum] ShowPromptAnchor not found: the launch show has no prompt")
		return
	end
	local show = Content.show("apollo_launch")
	if not show or not visible(show) then return end
	local prompt = makePrompt(anchor, Text.get("prompt.watchShow"), show.Name, 14)
	prompt.Triggered:Connect(function(player)
		if throttled(player) or not closeEnough(player, anchor, 14) then return end
		-- folga de 10 s para quem pula o fim; o roteiro tem show.Duration segundos
		startedShows[player] = { id = show.Id, finishAt = os.clock() + math.max(0, (show.Duration or 60) - 10) }
		Remotes.StartShow:FireClient(player, show.Id)
	end)
end

function ExhibitService.start(progress, remotes)
	Progress, Remotes = progress, remotes
	local okCards
	valid, okCards = Validator.run(Content)
	local n = 0
	for _ in valid do n += 1 end
	print(string.format("[Content] %d valid exhibits, mode %s", n, Config.MODE))
	for _, m in CollectionService:GetTagged("Exhibit") do task.spawn(setup, m) end
	CollectionService:GetInstanceAddedSignal("Exhibit"):Connect(setup)
	task.spawn(setupShow)

	-- Fim do show: registra (só ids conhecidos, com limite de frequência)
	remotes.ShowWatched.OnServerEvent:Connect(function(player, showId)
		if type(showId) ~= "string" then return end
		local session = startedShows[player]
		if not session or session.id ~= showId or os.clock() < session.finishAt then return end
		startedShows[player] = nil
		Progress.markShow(player, showId)
	end)
	return okCards
end

return ExhibitService
