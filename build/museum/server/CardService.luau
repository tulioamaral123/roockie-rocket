--[[
	CardService — contrato com o jogo (museuspec §7.3).

	CardService.Unlock(player, cardId) -> boolean
	CardService.Has(player, cardId) -> boolean
	CardService.List(player) -> { string }

	Só o servidor desbloqueia; o cliente nunca pede um card. O módulo fica em
	ServerScriptService.MuseumSystem.CardService para o time do jogo usar com require.
	Também cria os prompts das vitrines da Parede de missões (CardSlot_i ↔ card de Order i).
]]

local RS = game:GetService("ReplicatedStorage")

local MS = RS:WaitForChild("MuseumSystem")
local Shared = MS:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))

local CardService = {}

local Progress, Remotes, validCards
local lastUse = {}

-- Outra cópia deste módulo (ex.: Command Bar do Studio, que tem cache de require próprio)
-- não tem o estado do servidor: encaminha para a cópia ativa pela BindableFunction CardServiceAPI.
local function forward(action, ...)
	local api = script.Parent:FindFirstChild("CardServiceAPI")
	assert(api, "[CardService] server not started")
	return api:Invoke(action, ...)
end

function CardService.Unlock(player: Player, cardId: string): boolean
	if not Progress then return forward("Unlock", player, cardId) end
	if typeof(player) ~= "Instance" or not player:IsA("Player") or type(cardId) ~= "string" then return false end
	if not (validCards and validCards[cardId]) then
		warn("[CardService] unknown card: " .. tostring(cardId))
		return false
	end
	local data = Progress.get(player)
	if not data then
		warn("[CardService] progress not loaded for " .. player.Name .. "; card " .. cardId .. " not granted")
		return false
	end
	if Progress.markCard(player, cardId) then Remotes.CardUnlocked:FireClient(player, cardId) end
	return true
end

function CardService.Has(player: Player, cardId: string): boolean
	if not Progress then return forward("Has", player, cardId) end
	return Progress.hasCard(player, cardId)
end

function CardService.List(player: Player): { string }
	if not Progress then return forward("List", player) end
	local data = Progress.get(player)
	local out = {}
	if data then
		for id in data.cards do table.insert(out, id) end
	end
	return out
end

game:GetService("Players").PlayerRemoving:Connect(function(p) lastUse[p] = nil end)

local function setupWall()
	local wall
	for _ = 1, 60 do
		local hall = workspace:FindFirstChild("NASAComplex") and workspace.NASAComplex:FindFirstChild("SpaceMuseumHall")
		wall = hall and hall:FindFirstChild("MissionWall", true)
		if wall then break end
		task.wait(1)
	end
	if not wall then
		warn("[Museum] MissionWall not found")
		return
	end
	for i, card in Content.cards() do
		local slot = wall:FindFirstChild("CardSlot_" .. i)
		local anchor = slot and (slot:FindFirstChild("Glass") or slot:FindFirstChildWhichIsA("BasePart", true))
		if anchor and validCards[card.Id] and (Config.MODE ~= "demo" or card.Verified) and not anchor:FindFirstChild("MuseumPrompt") then
			local p = Instance.new("ProximityPrompt")
			p.Name = "MuseumPrompt"
			p.ActionText = Text.get("prompt.card")
			p.ObjectText = card.Name
			p.MaxActivationDistance = 10
			p.RequiresLineOfSight = false
			p.Parent = anchor
			p.Triggered:Connect(function(player)
				local t = os.clock()
				if lastUse[player] and t - lastUse[player] < 0.4 then return end
				lastUse[player] = t
				Remotes.OpenCard:FireClient(player, card.Id)
			end)
		end
	end
end

function CardService.start(progress, remotes, okCards)
	Progress, Remotes, validCards = progress, remotes, okCards
	local api = script.Parent:FindFirstChild("CardServiceAPI") or Instance.new("BindableFunction")
	api.Name = "CardServiceAPI"
	api.OnInvoke = function(action, ...)
		local f = CardService[action]
		if action == "Unlock" or action == "Has" or action == "List" then return f(...) end
		return nil
	end
	api.Parent = script.Parent
	task.spawn(setupWall)
end

return CardService
