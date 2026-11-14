--[[
	AudioController — sons da missão pela Audio API (skill roblox-audio §3).
	AudioPlayer → Wire → bus AudioFader (Alarm / SFX / UI) → Master → AudioDeviceOutput.
	Tudo é criado no cliente (só o jogador da missão ouve). Ids e volumes: Config.Audio.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local A = {}
local players, base = {}, {}
local root

local BUS = { alarm = "Alarm", alarm_fast = "Alarm", static = "SFX", rumble = "SFX", squelch = "SFX", click = "UI", confirm = "UI", error = "UI" }

local function wire(source, target)
	local w = Instance.new("Wire")
	w.SourceInstance = source
	w.TargetInstance = target
	w.Parent = target
end

function A.init(config)
	if root then return end
	root = Instance.new("Folder")
	root.Name = "MissionAudio"
	root.Parent = SoundService
	local output = Instance.new("AudioDeviceOutput")
	output.Parent = root
	local function fader(name, volume, target)
		local f = Instance.new("AudioFader")
		f.Name = name
		f.Volume = volume
		f.Parent = root
		wire(f, target)
		return f
	end
	local master = fader("Master", 1, output)
	local buses = { Alarm = fader("Alarm", 0.7, master), SFX = fader("SFX", 0.85, master), UI = fader("UI", 0.7, master) }
	for event, c in config.Audio do
		if c then
			local p = Instance.new("AudioPlayer")
			p.Name = event
			p.Asset = "rbxassetid://" .. c.id
			p.Looping = c.loop == true
			p.Volume = c.volume or 1
			p.Parent = root
			wire(p, buses[BUS[event] or "SFX"])
			players[event] = p
			base[event] = p.Volume
		end
	end
end

-- toca um efeito curto do início
function A.play(event, speed)
	local p = players[event]
	if not p then return end -- false ou ausente no mapa: silêncio proposital
	p.PlaybackSpeed = speed or 1
	p.TimePosition = 0
	p:Play()
end

-- liga/desliga um som contínuo com fade
function A.loop(event, on, fade)
	local p = players[event]
	if not p then return end
	fade = fade or 0.6
	if on then
		if not p.IsPlaying then
			p.Volume = 0
			p.TimePosition = 0
			p:Play()
		end
		TweenService:Create(p, TweenInfo.new(fade), { Volume = base[event] }):Play()
	elseif p.IsPlaying then
		local tw = TweenService:Create(p, TweenInfo.new(fade), { Volume = 0 })
		tw.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and p.Volume == 0 then p:Stop() end
		end)
		tw:Play()
	end
end

-- deixa tocando só os sons contínuos da lista (os outros saem com fade)
function A.setLoops(set, fade)
	for event, p in players do
		if p.Looping then A.loop(event, set[event] == true, fade) end
	end
end

function A.stopAll()
	for _, p in players do p:Stop() end
end

return A
