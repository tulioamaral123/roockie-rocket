--[[
	Boot do servidor do museu: cria os remotes e liga os serviços.
	ReplicatedStorage.MuseumSystem.Remotes:
	  OpenExhibit, OpenCard, StartShow, CardUnlocked (servidor → cliente)
	  ShowWatched, SaveSettings (cliente → servidor, validados)
	  GetProgress (RemoteFunction: o cliente pede só o próprio progresso)
	ReplicatedStorage.MuseumSystem.Events.LeaveMuseum: BindableEvent disparado no cliente
	pelo portal de saída; o time do jogo decide o que fazer (museuspec §7.2).
]]

local RS = game:GetService("ReplicatedStorage")
local MS = RS:WaitForChild("MuseumSystem")

local function ensure(parent, class, name)
	local x = parent:FindFirstChild(name)
	if x and not x:IsA(class) then x:Destroy() x = nil end
	if not x then
		x = Instance.new(class)
		x.Name = name
		x.Parent = parent
	end
	return x
end

local remotesFolder = ensure(MS, "Folder", "Remotes")
local remotes = {}
for _, n in { "OpenExhibit", "OpenCard", "StartShow", "CardUnlocked", "ShowWatched", "SaveSettings" } do
	remotes[n] = ensure(remotesFolder, "RemoteEvent", n)
end
remotes.GetProgress = ensure(remotesFolder, "RemoteFunction", "GetProgress")
ensure(ensure(MS, "Folder", "Events"), "BindableEvent", "LeaveMuseum")

local Progress = require(script.Parent:WaitForChild("ProgressService"))
local Exhibits = require(script.Parent:WaitForChild("ExhibitService"))
local Cards = require(script.Parent:WaitForChild("CardService"))

Progress.start()
local okCards = Exhibits.start(Progress, remotes)
Cards.start(Progress, remotes, okCards)

remotes.GetProgress.OnServerInvoke = function(player)
	local data, noSave = Progress.get(player)
	if not data then return nil end
	local firstVisit = data.firstVisit
	Progress.setFirstVisitDone(player)
	return {
		exhibitsSeen = table.clone(data.exhibitsSeen),
		cards = table.clone(data.cards),
		showsSeen = table.clone(data.showsSeen),
		settings = table.clone(data.settings),
		firstVisit = firstVisit,
		noSave = noSave,
	}
end

local lastSettings = {}
remotes.SaveSettings.OnServerEvent:Connect(function(player, s)
	local t = os.clock()
	if lastSettings[player] and t - lastSettings[player] < 0.5 then return end
	lastSettings[player] = t
	Progress.setSettings(player, s)
end)

game:GetService("Players").PlayerRemoving:Connect(function(p) lastSettings[p] = nil end)

-- Ponto de chegada do museu não é o spawn padrão (museuspec §7.2)
task.spawn(function()
	local hall = workspace:WaitForChild("NASAComplex"):WaitForChild("SpaceMuseumHall", 30)
	local arrival = hall and hall:FindFirstChild("MuseumArrival", true)
	if arrival and arrival:IsA("SpawnLocation") then arrival.Neutral = false end
end)

print("[Museum] server ready")
