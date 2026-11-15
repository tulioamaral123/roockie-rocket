--[[
	ProgressService — progresso do visitante (museuspec §11.4).

	DataStore Config.DATASTORE_NAME, chave "player_<UserId>". Cache em memória; salva com
	UpdateAsync a cada Config.AUTOSAVE_SECONDS se houve mudança, ao sair e no BindToClose.
	Se o carregamento falhar, o jogador fica com progresso vazio marcado noSave (nunca
	sobrescreve dados bons) e recebe um aviso.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")

local Shared = RS:WaitForChild("MuseumSystem"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ProgressService = {}

local store = nil
do
	local ok, s = pcall(function() return DataStoreService:GetDataStore(Config.DATASTORE_NAME) end)
	if ok then store = s else warn("[Progress] DataStore unavailable: " .. tostring(s)) end
end

local sessions = {} -- [Player] = { data, dirty, noSave, ready, revision, saving }
local ACHIEVEMENTS = { "exhibitsSeen", "cards", "showsSeen" }
local readyEvent = Instance.new("BindableEvent")

local function defaults()
	return {
		version = Config.DATA_VERSION,
		exhibitsSeen = {},
		cards = {},
		showsSeen = {},
		settings = { textSize = 2, captions = true, reduceMotion = false },
		firstVisit = true,
	}
end

local function migrate(d)
	local base = defaults()
	if type(d) ~= "table" then return base end
	for k, v in base do
		if d[k] == nil then d[k] = v end
	end
	if type(d.settings) ~= "table" then d.settings = base.settings end
	for _, f in ACHIEVEMENTS do
		if type(d[f]) ~= "table" then d[f] = {} end
	end
	for k, v in base.settings do
		if d.settings[k] == nil then d.settings[k] = v end
	end
	d.version = Config.DATA_VERSION
	return d
end

local function key(player) return "player_" .. player.UserId end

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local c = {}
	for k, v in t do c[k] = deepCopy(v) end
	return c
end

-- Conquistas nunca regridem: une o que já está salvo (outro servidor pode ter gravado antes)
local function mergeAchievements(snapshot, old)
	if type(old) ~= "table" then return snapshot end
	for _, field in ACHIEVEMENTS do
		if type(old[field]) == "table" then
			for id, v in old[field] do
				if v == true then snapshot[field][id] = true end
			end
		end
	end
	return snapshot
end

local function load(player)
	local s = { data = defaults(), dirty = false, noSave = false, ready = false, revision = 0, saving = false }
	sessions[player] = s
	if not store then
		s.noSave = true
	else
		local ok, result
		for attempt = 1, 3 do
			ok, result = pcall(function() return store:GetAsync(key(player)) end)
			if ok then break end
			task.wait(attempt * 2)
		end
		if ok then
			s.data = migrate(result)
		else
			s.noSave = true
			warn("[Progress] load failed for " .. player.Name .. ": " .. tostring(result))
		end
	end
	s.ready = true
	readyEvent:Fire(player)
end

local function save(player)
	local s = sessions[player]
	if not s or not s.ready or s.noSave or not s.dirty or not store then return end
	-- uma gravação por vez por jogador; a próxima pega o estado mais novo
	while s.saving do task.wait(0.2) end
	if not s.dirty then return end
	s.saving = true
	local revision = s.revision
	local snapshot = deepCopy(s.data)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(old)
				return mergeAchievements(snapshot, old)
			end)
		end)
		if ok then
			s.dirty = s.revision ~= revision -- mudou durante a gravação: continua sujo
			break
		end
		warn("[Progress] save failed (" .. attempt .. "): " .. tostring(err))
		task.wait(attempt * 2)
	end
	s.saving = false
end

-- Espera os dados do jogador (até 15 s)
function ProgressService.get(player: Player)
	local s = sessions[player]
	local t0 = os.clock()
	while (not s or not s.ready) and player.Parent and os.clock() - t0 < 15 do
		task.wait(0.1)
		s = sessions[player]
	end
	if not s or not s.ready then return nil, true end
	return s.data, s.noSave
end

local function mark(player, field, id)
	local s = sessions[player]
	if not s or not s.ready then return false end
	if s.data[field][id] then return false end
	s.data[field][id] = true
	s.dirty = true
	s.revision += 1
	return true
end

function ProgressService.markExhibit(player, id) return mark(player, "exhibitsSeen", id) end
function ProgressService.markCard(player, id) return mark(player, "cards", id) end
function ProgressService.markShow(player, id) return mark(player, "showsSeen", id) end

function ProgressService.hasCard(player, id)
	local s = sessions[player]
	return s ~= nil and s.data.cards[id] == true
end

function ProgressService.setFirstVisitDone(player)
	local s = sessions[player]
	if s and s.ready and s.data.firstVisit then
		s.data.firstVisit = false
		s.dirty = true
		s.revision += 1
	end
end

-- Configurações: só chaves e valores conhecidos (o cliente não é confiável)
function ProgressService.setSettings(player, new)
	local s = sessions[player]
	if not s or not s.ready or type(new) ~= "table" then return end
	local cur = s.data.settings
	if new.textSize == 1 or new.textSize == 2 or new.textSize == 3 then cur.textSize = new.textSize end
	if type(new.captions) == "boolean" then cur.captions = new.captions end
	if type(new.reduceMotion) == "boolean" then cur.reduceMotion = new.reduceMotion end
	s.dirty = true
	s.revision += 1
end

function ProgressService.start()
	Players.PlayerAdded:Connect(load)
	for _, p in Players:GetPlayers() do task.spawn(load, p) end
	Players.PlayerRemoving:Connect(function(p)
		save(p)
		sessions[p] = nil
	end)
	game:BindToClose(function()
		local pending = 0
		for p in sessions do
			pending += 1
			task.spawn(function()
				save(p)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do task.wait(0.2) end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_SECONDS)
			for p in sessions do task.spawn(save, p) end
		end
	end)
end

ProgressService.Ready = readyEvent.Event

return ProgressService
