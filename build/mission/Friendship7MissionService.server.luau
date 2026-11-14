--[[
	Friendship7MissionService — estado da missão Friendship 7 por jogador (missaoUm.md §7.2, §8).

	- Início: ProximityPrompt "Start mission" (atributo MissionStart) nas peças MissionStart_*;
	  só vale para quem está sentado no assento indicado pelo ObjectValue SeatRef.
	- Ordem fixa das tarefas (Task1 → Task2 → Task3); o servidor valida cada ação, código e escolha.
	- Levantar do assento, morrer ou sair do jogo encerra a missão (o cliente restaura câmera e efeitos).
	- Enquanto a missão está ativa o jogador tem o atributo MissionActive (o CrewAccess ignora
	  os prompts dele, então não dá para sair pela escotilha).
	- O cliente só recebe o próprio estado (MissionUpdate:FireClient).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PPS = game:GetService("ProximityPromptService")

local MS = RS:WaitForChild("MissionSystem")
local Config = require(MS:WaitForChild("Config"):WaitForChild("Friendship7Config"))
local Remotes = MS:WaitForChild("Remotes")
local Tasks = {
	require(script:WaitForChild("Task1ControlService")),
	require(script:WaitForChild("Task2CommunicationService")),
	require(script:WaitForChild("Task3ReentryService")),
}

local M = { Config = Config }
local states = {} -- [Player] = estado

function M.now()
	return workspace:GetServerTimeNow()
end

local function snapshot(s)
	local v = {
		active = s.active,
		task = s.task,
		phase = s.phase,
		title = s.title,
		detail = s.detail,
		endsAt = s.endsAt,
		radio = s.radio,
		radioAt = s.radioAt,
		seat = s.seatName,
	}
	for k, x in s.view do v[k] = x end
	return v
end

function M.send(s)
	if s.player.Parent then
		Remotes.MissionUpdate:FireClient(s.player, snapshot(s))
	end
	s.lastSend = os.clock()
end

-- muda a fase: textos de Config.Text[phase], fala de rádio opcional, novo token (invalida esperas)
function M.setPhase(s, phase, opts)
	opts = opts or {}
	s.phase = phase
	s.token += 1
	local t = Config.Text[phase]
	s.title, s.detail = t and t[1] or opts.title, t and t[2] or opts.detail
	if opts.endsAt ~= nil then s.endsAt = opts.endsAt end
	local line = Config.Text.radio[phase]
	if line then
		s.radio, s.radioAt = line, M.now()
	end
	M.send(s)
end

-- executa fn depois de d segundos, se a missão ainda estiver na mesma fase
function M.after(s, d, fn)
	local token = s.token
	task.delay(d, function()
		if states[s.player] == s and s.token == token then fn() end
	end)
end

function M.fail(s, reason)
	local t = Config.Text.fail[reason]
	s.view.failReason = reason
	s.view.holding = false
	s.endsAt = nil
	M.setPhase(s, "failed", { title = t[1], detail = t[2] .. " " .. Config.Text.retry })
end

local function startTask(s, i)
	s.task = i
	s.view = {}
	s.endsAt = nil
	Tasks[i].start(M, s)
end

function M.taskDone(s)
	M.after(s, Config.Transition, function()
		if s.task < #Tasks then
			startTask(s, s.task + 1)
		else
			s.view = { results = Config.Text.results, note = Config.Text.note }
			s.endsAt = nil
			M.setPhase(s, "complete")
			M.stop(s.player, "complete")
		end
	end)
end

-- encerra a missão do jogador; reason: "complete" | "aborted" | "left"
function M.stop(player, reason)
	local s = states[player]
	if not s then return end
	states[player] = nil
	s.token += 1
	s.active = false
	if reason ~= "complete" then
		s.view = {}
		s.phase = "ended"
		s.title, s.detail = nil, reason == "aborted" and Config.Text.aborted or nil
	end
	s.view.endReason = reason
	if s.seatConn then s.seatConn:Disconnect() end
	if player.Parent then
		player:SetAttribute("MissionActive", nil)
		M.send(s)
	end
end

local function start(player, seat)
	if states[player] then return end
	local s = {
		player = player,
		seat = seat,
		seatName = seat.Parent.Name,
		active = true,
		token = 0,
		view = {},
		lastSend = 0,
	}
	states[player] = s
	player:SetAttribute("MissionActive", true)
	-- levantar do assento encerra a missão
	s.seatConn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		if not hum or Players:GetPlayerFromCharacter(hum.Parent) ~= player then
			M.stop(player, "aborted")
		end
	end)
	startTask(s, 1)
end

---------------------------------------------------------------------------------
-- início pelo prompt
---------------------------------------------------------------------------------
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:GetAttribute("MissionStart") then return end
	local ref = prompt.Parent and prompt.Parent:FindFirstChild("SeatRef")
	local seat = ref and ref.Value
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if seat and seat:IsA("Seat") and hum and hum.Health > 0 and seat.Occupant == hum then
		start(player, seat)
	end
end)

---------------------------------------------------------------------------------
-- remotes (cada um valida tipo, estado e taxa)
---------------------------------------------------------------------------------
local RATE, BURST = 12, 24 -- mensagens por segundo por jogador
local buckets = {}
local function allow(player)
	local b = buckets[player]
	local t = os.clock()
	if not b then
		b = { tokens = BURST, at = t }
		buckets[player] = b
	end
	b.tokens = math.min(BURST, b.tokens + (t - b.at) * RATE)
	b.at = t
	if b.tokens < 1 then return false end
	b.tokens -= 1
	return true
end

local function current(player)
	local s = states[player]
	if s and s.active and allow(player) then return s end
	return nil
end

Remotes.MissionAction.OnServerEvent:Connect(function(player, kind, arg)
	if type(kind) ~= "string" or #kind > 24 then return end
	local s = current(player)
	if not s then return end
	if kind == "Retry" then
		if s.phase == "failed" then startTask(s, s.task) end
		return
	end
	local t = Tasks[s.task]
	if t.action then t.action(M, s, kind, arg) end
end)

Remotes.SubmitCode.OnServerEvent:Connect(function(player, text)
	if type(text) ~= "string" or #text > 32 then return end
	local s = current(player)
	if s and s.task == 2 and Tasks[2].submitCode then Tasks[2].submitCode(M, s, text) end
end)

Remotes.SubmitChoice.OnServerEvent:Connect(function(player, choice)
	if choice ~= "Retain" and choice ~= "Jettison" then return end
	local s = current(player)
	if s and s.task == 3 and Tasks[3].submitChoice then Tasks[3].submitChoice(M, s, choice) end
end)

-- StartMission: o cliente pede para encerrar ("abort"); o início é sempre pelo prompt
Remotes.StartMission.OnServerEvent:Connect(function(player, cmd)
	if cmd == "abort" and states[player] then M.stop(player, "aborted") end
end)

---------------------------------------------------------------------------------
-- relógio: tempos limite, combustível, progresso (10 Hz) e reenvio periódico (4 Hz)
---------------------------------------------------------------------------------
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then return end
	local step = acc
	acc = 0
	for _, s in states do
		local t = Tasks[s.task]
		if s.active and t and t.tick then t.tick(M, s, step) end
		if states[s.player] == s and s.dirty and os.clock() - s.lastSend >= 0.25 then
			s.dirty = false
			M.send(s)
		end
	end
end)

local function cleanup(player)
	M.stop(player, "left")
	buckets[player] = nil
end
Players.PlayerRemoving:Connect(cleanup)
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		if states[player] then M.stop(player, "aborted") end
	end)
end)
for _, p in Players:GetPlayers() do
	p.CharacterRemoving:Connect(function()
		if states[p] then M.stop(p, "aborted") end
	end)
end
