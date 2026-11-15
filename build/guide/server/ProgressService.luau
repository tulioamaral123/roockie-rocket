--[[
	ProgressService — etapa da apresentação de cada jogador (servidor é a fonte da verdade).
	Progresso por sessão (sem DataStore): cada jogador que entra começa com o Marcos.
	O atributo GuideStage no Player é só informativo (o cliente não decide nada por ele).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Settings = require(RS:WaitForChild("GuideSystem"):WaitForChild("Config"):WaitForChild("Settings"))

local ProgressService = {}

local INDEX = {}
for i, name in Settings.Stages do INDEX[name] = i end

local state = {} -- [player] = { stage, seen = { [dialogueKey] = true }, viaIndex }
local listeners = {}

local function entry(player)
	local s = state[player]
	if not s and not player.Parent then
		-- jogador já saiu (thread atrasada): devolve um estado descartável, sem guardar
		return { stage = "Free", seen = {}, viaIndex = 1 }
	end
	if not s then
		s = { stage = Settings.Stages[1], seen = {}, viaIndex = 1 }
		state[player] = s
		player:SetAttribute("GuideStage", s.stage)
	end
	return s
end

function ProgressService.get(player: Player): string
	return entry(player).stage
end

function ProgressService.is(player: Player, stage: string): boolean
	return entry(player).stage == stage
end

function ProgressService.atLeast(player: Player, stage: string): boolean
	return INDEX[entry(player).stage] >= INDEX[stage]
end

-- muda a etapa; avisa os ouvintes (NavigationService) só quando muda
function ProgressService.set(player: Player, stage: string)
	assert(INDEX[stage], "etapa inválida: " .. tostring(stage))
	local s = entry(player)
	if s.stage == stage or not player.Parent then return end
	local old = s.stage
	s.stage = stage
	s.viaIndex = 1
	player:SetAttribute("GuideStage", stage)
	for _, fn in listeners do task.spawn(fn, player, stage, old) end
end

-- índice do ponto intermediário da rota atual (NavigationService)
function ProgressService.via(player: Player): number
	return entry(player).viaIndex
end
function ProgressService.setVia(player: Player, i: number)
	entry(player).viaIndex = i
end

-- diálogos já vistos (evita repetir a mesma fala para o mesmo jogador)
function ProgressService.seen(player: Player, key: string): boolean
	return entry(player).seen[key] == true
end
function ProgressService.markSeen(player: Player, key: string)
	entry(player).seen[key] = true
end

function ProgressService.onChanged(fn)
	table.insert(listeners, fn)
end

function ProgressService.players(stage: string?)
	local out = {}
	for _, p in Players:GetPlayers() do
		if state[p] and (not stage or state[p].stage == stage) then table.insert(out, p) end
	end
	return out
end

function ProgressService.start()
	Players.PlayerAdded:Connect(entry)
	for _, p in Players:GetPlayers() do entry(p) end
	Players.PlayerRemoving:Connect(function(p) state[p] = nil end)
end

return ProgressService
