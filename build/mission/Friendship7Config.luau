--[[
	Friendship7Config — todos os valores da missão Friendship 7 (missaoUm.md §10).
	ModuleScript em ReplicatedStorage.MissionSystem.Config, lido pelo servidor e pelo cliente.
	Gerado por build/phase15_friendship7.luau a partir de build/mission/Friendship7Config.luau.
]]

local Config = {}

-- assentos que iniciam a missão (prompt "Start mission" na tela à frente de cada um)
Config.Seats = { "Seat_CDR", "Seat_PLT" }

Config.Transition = 4 -- segundos entre o fim de uma tarefa e o início da seguinte

Config.Task1 = {
	Points = 4, -- pontos de referência no mostrador (o último é sempre o central)
	FocusTime = 0.7, -- segundos com a visão sobre o ponto
	FocusAngle = 3.5, -- graus entre a direção da câmera e o ponto
	FuelStart = 100, -- %
	TimeLimit = 60, -- segundos, do alerta ao último ponto
	-- consumo de combustível (% por segundo) durante o controle manual
	FuelBurnIdle = 0.3, -- parado
	FuelBurnCorrection = 1.2, -- corrigindo (câmera em movimento)
	FuelBurnExcess = 6, -- a mais em movimento excessivo (escala com o excesso)
	CorrectionSpeed = 6, -- graus/s a partir dos quais a câmera conta como corrigindo
	ExcessSpeed = 90, -- graus/s a partir dos quais o movimento é excessivo
	ExcessSpeedMax = 220, -- graus/s em que o excesso chega ao máximo
	PointRadius = 0.72, -- distância máxima do centro do mostrador (fração do raio)
}

Config.Task2 = {
	Duration = 45, -- segundos de blackout para inserir o código
	MaxWrongAttempts = 3, -- 0 = ilimitado
	CodeLetters = "ACDEFHJKLMNPRTUVWXY", -- sem I, O, B, S, G, Q, Z (parecidos com números)
	CodeDigits = "23456789",
}

Config.Task3 = {
	DecisionTime = 10, -- segundos para escolher
	HoldTime = 10, -- segundos segurando MANTER RETROPAQUETE
	ReleaseDecay = 0.6, -- segundos de progresso perdidos por segundo solto
	ShieldReading = 42, -- % exibido pelo sensor (falso)
}

-- sons (licenciados, ProSoundEffects; ver assets/LICENSES.md). false = silêncio proposital
Config.Audio = {
	alarm = { id = 9113084658, volume = 0.9, loop = true }, -- alarme do console (Tarefa 1)
	alarm_fast = { id = 9113865831, volume = 0.45, loop = true }, -- bipes rápidos (Tarefa 3)
	static = { id = 9126160908, volume = 0.4, loop = true }, -- interferência de rádio (Tarefa 2)
	rumble = { id = 9119414082, volume = 0.7, loop = true }, -- motor/atrito da reentrada
	click = { id = 9119717523, volume = 0.3 },
	confirm = { id = 9117060349, volume = 0.9 },
	error = { id = 9113085764, volume = 0.45 },
	squelch = { id = 9118019216, volume = 0.25 },
}

-- textos (inglês, como o resto do mapa)
Config.Text = {
	t1_alert = { "AUTOMATIC CONTROL FAILURE", "The capsule is drifting. Press AUTOPILOT OFF on the console." },
	t1_manual = { "MANUAL CONTROL", "Look at each target on the attitude indicator and hold your view on it." },
	t1_done = { "CONTROL RECOVERED — SYSTEM STABILIZED", "Attitude is steady. Automatic control is back online." },
	t2_blackout = { "REENTRY BLACKOUT — CONTACT WITH EARTH LOST", "Find the emergency procedure sheet. Type its code into the radio terminal and press CONFIRM." },
	t2_done = { "PROCEDURE ACCEPTED — RESTORING COMMUNICATION", "Signal coming back." },
	t2_wrong = "INVALID CODE — CHECK THE DOCUMENT",
	t3_alert = { "WARNING — REENTRY", "DANGER: HEAT SHIELD SENSOR UNSTABLE. Decide what to do with the retropack." },
	t3_reentry = { "ATMOSPHERIC REENTRY", "Hold the RETAIN RETROPACK button to keep the procedure." },
	t3_done = { "HEAT SHIELD STABLE — REENTRY COMPLETE", "The capsule is through the hottest part of reentry." },
	complete = { "MISSION COMPLETE", "You recovered control of the capsule, followed procedure during the communication blackout and made the right call during reentry." },
	results = { { "Manual control", "Recovered" }, { "Communication", "Restored" }, { "Heat shield", "Preserved" } },
	fail = {
		fuel = { "ATTITUDE CONTROL FAILURE", "Control fuel ran out. Make smaller, calmer corrections." },
		t1_time = { "ATTITUDE CONTROL FAILURE", "Time ran out before the capsule was stabilized." },
		eject = { "INCORRECT PROCEDURE — DO NOT ABANDON THE CAPSULE DURING REENTRY", "You interrupted the safety procedure." },
		t2_time = { "BLACKOUT PROCEDURE NOT COMPLETED", "The timer ran out before the code was entered." },
		attempts = { "TOO MANY INVALID CODES", "Read the code on the emergency procedure sheet carefully." },
		jettison = { "CRITICAL FAILURE — RETROPACK JETTISONED", "The sensor signal was false. Keeping the retropack was needed to hold the heat shield in place." },
		t3_time = { "NO DECISION — REENTRY PROCEDURE MISSED", "Mission Control asked you to keep the retropack on." },
	},
	retry = "Press RETRY on the console to try this task again.",
	aborted = "Mission aborted: you left your seat.",
	-- falas de rádio dramatizadas (só legenda; não são transcrições literais)
	radio = {
		t1_alert = "CAPCOM: Friendship 7, we show you drifting. Go to manual control.",
		t2_blackout = "CAPCOM: Friendship 7, Mercury Control… do you rea— [static]",
		t2_done = "CAPCOM: Friendship 7, we read you. Welcome back.",
		t3_alert = "CAPCOM: Friendship 7, we have an indication your heat shield may be loose. Keep the retropack on through reentry.",
		complete = "CAPCOM: Friendship 7, Mercury Control. Good job.",
	},
	note = "Radio lines are dramatized for this experience. Panels are a stylized, educational take on a Mercury cockpit.",
}

return Config
