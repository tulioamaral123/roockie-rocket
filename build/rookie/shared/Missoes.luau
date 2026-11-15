--[[
	Rookie Rocket — configuração ÚNICA das missões (docs/rookie-rocket-spec.md §6).

	ATENÇÃO: todos os pesos, tempos, velocidades e efeitos de equipamentos abaixo são VALORES
	DIDÁTICOS simplificados para jogabilidade e aprendizado. Isso aparece na tela de Créditos.

	Textos visíveis em inglês (decisão do usuário, 15/11/2026). Os nomes das chaves seguem a spec.
	Peças usadas pelos scripts: docs/rookie-contrato.md.
]]

local Missoes = {}

Missoes.RegrasGerais = {
	PesoNave = 20, -- kg
	LimiteFoguete = 60, -- kg
	KgPorBonus = 10, -- a cada 10 kg livres...
	SegundosBonusPorFaixa = 2, -- ...desconta 2 segundos do tempo final
	MaxJogadoresPorNave = 4,
	FaixasEstrelas = {
		TresEstrelas = 45, -- até 45 s
		DuasEstrelas = 70, -- até 70 s
		UmaEstrela = 100, -- até 100 s (acima disso: 0 estrelas, falha "Took too long")
	},
	-- barra de peso da Preparação
	PesoVerdeAte = 50, -- <= 50 kg verde, 51..60 amarela, > 60 vermelha
	-- contagem antes da Task 1 (não entra no tempo)
	SegundosLancamento = 4,
	-- distância máxima (studs) do jogador até a estação para aceitar uma ação crítica
	DistanciaAcao = 14,
}

Missoes.Lista = {
	[1] = {
		Id = 1,
		Chave = "Mercury",
		Nave = "Mercury", -- NASAComplex.RookieRocket.Mercury
		Nome = "Project Mercury (Friendship 7)",
		Tagline = "America's first orbit around Earth",
		Descricao = "In 1962, John Glenn became the first American to orbit Earth on Friendship 7. During the flight he steered the capsule by hand, flew through a radio blackout and faced a heat shield alarm.",
		Guia = {
			"Task 1 · Keep the + on the red markers until each circle fills.",
			"Task 2 · Read the code on the clipboard and type it on the radio.",
			"Task 3 · Hold the retropack button until the bar fills.",
		},
		Card = "Friendship7",
		Equipamentos = {
			Giroscopio = {
				Icone = "gyroscope",
				Nome = "Gyroscope",
				Peso = 15,
				TaskAlvo = 1,
				TempoSegurar = 1.2,
				Efeito = "Task 1: hold time on each target 2.0 s → 1.2 s",
			},
			ManualBordo = {
				Icone = "manual",
				Nome = "Flight Manual",
				Peso = 20,
				TaskAlvo = 2,
				BonusTempo = 15,
				Efeito = "Task 2: highlights the code on the clipboard and adds +15 s (30 s → 45 s)",
			},
			EscudoReforcado = {
				Icone = "shield",
				Nome = "Reinforced Shield",
				Peso = 25,
				TaskAlvo = 3,
				TempoSegurar = 6.0,
				MultiplicadorTremor = 0.5,
				Efeito = "Task 3: hold the retropack 10 s → 6 s and less camera shake",
			},
		},
		OrdemEquipamentos = { "Giroscopio", "ManualBordo", "EscudoReforcado" },
		-- tela de parabéns + "o que você aprendeu" ao concluir a missão (antes do resultado)
		Aprendizado = {
			Titulo = "CONGRATULATIONS, ROOKIE!",
			Fala = "You completed your first mission! Every task you solved uses real science and engineering. Here is what you practiced today:",
			Itens = {
				{
					Task = "Task 1 · The Autopilot Failure",
					Areas = { "Physics (Inertia / Mechanics)", "Automation and Control Engineering" },
					Ciencia = "In space nothing slows a spin: by inertia, a small drift keeps growing until a thruster pushes back. A control system closes the loop: sensor → decision → thruster.",
					Real = "On Friendship 7, when the capsule drifted out of attitude, John Glenn steered it back by hand.",
				},
				{
					Task = "Task 2 · The Communication Blackout",
					Areas = { "Physics (Electromagnetic Waves)", "Telecommunications Engineering" },
					Ciencia = "During reentry the air around the capsule turns into hot ionized gas (plasma), which blocks radio waves until the capsule slows down.",
					Real = "Glenn's planned radio blackout lasted 4 minutes and 20 seconds.",
				},
				{
					Task = "Task 3 · The Heat Shield Alarm",
					Areas = { "Physics (Thermodynamics)", "Materials Engineering" },
					Ciencia = "Air squeezed in front of the capsule gets extremely hot. The heat shield is made to absorb that heat and carry it away as its surface burns off slowly.",
					Real = "A faulty signal suggested the heat shield was loose, so controllers kept the retropack strapped on during reentry. The signal was false.",
				},
			},
		},
		Tasks = {
			[1] = {
				Tipo = "Mira",
				Nome = "The Autopilot Failure",
				Alerta = "AUTOMATIC CONTROL FAILURE",
				Objetivo = "Take the attitude control panel in front of the seats and keep the + on each of the 4 red markers until the circle fills.",
				LimiteTempo = 40,
				TempoBaseSegurar = 2.0,
				TotalPontos = 4,
				AnguloMira = 3.5, -- graus entre o centro da tela e o ponto
			},
			[2] = {
				Tipo = "Codigo",
				Nome = "The Communication Blackout",
				Alerta = "LOSS OF CONTACT WITH EARTH",
				Objetivo = "Read the code on the navigation clipboard and type it on the radio keypad.",
				LimiteTempo = 30,
				DigitosCodigo = 4,
				FalaAcerto = "Friendship 7, we read you. Welcome back.",
			},
			[3] = {
				Tipo = "Retropack",
				Nome = "The Heat Shield Alarm",
				Alerta = "DANGER: HEAT SHIELD SENSOR UNSTABLE",
				Objetivo = "Decide in 10 s! Hold HOLD RETROPACK until the bar fills. Releasing only pauses it.",
				TempoDecisao = 10,
				TempoBaseSegurar = 10.0,
			},
		},
	},
	[2] = {
		Id = 2,
		Chave = "ISS",
		Nave = "ISS", -- NASAComplex.RookieRocket.ISS
		Nome = "International Space Station (ISS)",
		Tagline = "Build and repair the space station",
		Descricao = "In 1998 the first two ISS modules were joined with a robotic arm. Later, crews fixed slack solar array cables and sealed a tiny 2 mm leak.",
		Guia = {
			"Task 1 · Line up the 4 spheres and keep the pressure green.",
			"Task 2 · Go outside and drag the cables to their pulleys.",
			"Task 3 · Close the hatch, find the leak and seal it.",
		},
		Card = "UnityZarya",
		Equipamentos = {
			SensorPressao = {
				Icone = "gauge",
				Nome = "Pressure Sensor",
				Peso = 15,
				TaskAlvo = 1,
				MultiplicadorZonaVerde = 1.5,
				Efeito = "Task 1: green zone of the pressure slider +50%",
			},
			LuvasAderentes = {
				Icone = "gloves",
				Nome = "Grip Gloves",
				Peso = 20,
				TaskAlvo = 2,
				MultiplicadorVelocidade = 2.0,
				Efeito = "Task 2: drag the loose cables 2x faster without slipping",
			},
			KitVedacao = {
				Icone = "sealkit",
				Nome = "Sealing Kit",
				Peso = 25,
				TaskAlvo = 3,
				ReducaoPerdaAr = 0.6,
				TempoSegurar = 2.0,
				Efeito = "Task 3: air loss −40% and sealing time 3.0 s → 2.0 s",
			},
		},
		OrdemEquipamentos = { "SensorPressao", "LuvasAderentes", "KitVedacao" },
		Aprendizado = {
			Titulo = "CONGRATULATIONS, CREW!",
			Fala = "You kept the space station safe! Each task was inspired by a real moment in the history of the ISS. Here is the science behind it:",
			Itens = {
				{
					Task = "Task 1 · The Docking",
					Areas = { "Physics (Forces / Action and Reaction)", "Robotics Engineering" },
					Ciencia = "Every push the arm gives a module pushes back on the arm (Newton's third law). Gentle, steady force lines parts up without damaging them.",
					Real = "On STS-88 (December 1998) the shuttle's robotic arm captured Zarya and joined it to Unity. The fittings did not line up at first, so the arm released Zarya and tried again.",
				},
				{
					Task = "Task 2 · The Stuck Solar Panel",
					Areas = { "Physics (Mass and Momentum)", "Mechanical Engineering" },
					Ciencia = "In orbit a cable has no weight, but it still has mass: if you move it fast, its momentum makes it hard to stop and it slips away.",
					Real = "On STS-97 (December 2000) a new P6 solar array blanket was slack. On the third spacewalk, Joe Tanner and Carlos Noriega pulled its tensioning cables back into their reels.",
				},
				{
					Task = "Task 3 · The 2 mm Leak",
					Areas = { "Physics (Pressure of Gases)", "Life Support Engineering" },
					Ciencia = "Air always flows from high to low pressure. A tiny hole to the vacuum of space lets cabin air escape slowly, and closing hatches isolates the leaking module.",
					Real = "In August 2018 the crew found a hole about 2 mm across in the Soyuz MS-09 orbital module. Commander Sergey Prokopyev plugged it with epoxy on a gauze wipe.",
				},
			},
		},
		Tasks = {
			[1] = {
				Tipo = "Acoplamento",
				Nome = "The Docking (STS-88)",
				Alerta = "ARM PRESSURE TOO HIGH",
				Objetivo = "At the Canadarm console: line up the 4 spheres on the X marks and keep the pressure in the green zone.",
				LimiteTempo = 40,
				TempoPressaoMaxFalha = 3.0,
				TotalEsferas = 4,
				ZonaVerdeCentro = 0.5, -- pressão normalizada 0..1
				ZonaVerdeMeiaLargura = 0.1, -- × MultiplicadorZonaVerde com o Sensor
				PressaoMaxima = 0.95, -- acima disto conta como "pressão no máximo"
				RespostaPressao = 1.3, -- quão rápido a pressão segue a válvula (1/s)
				Perturbacao = 0.32, -- amplitude da deriva que obriga a reajustar
			},
			[2] = {
				Tipo = "EVA",
				Nome = "The Stuck Solar Panel (STS-97)",
				Alerta = "SOLAR ARRAY CABLES LOOSE",
				Objetivo = "Go out through the Airlock and drag each loose cable to its green pulley. Too fast and it slips!",
				LimiteTempo = 45,
				TotalCabos = 2,
				VelocidadeMaxCabo = 6, -- studs/s carregando o cabo (× MultiplicadorVelocidade com as Luvas)
				VelocidadeEVA = 12, -- velocidade máxima dos propulsores
				ToleranciaEscorregar = 0.3, -- segundos acima do limite até o cabo escorregar
				DistanciaPolia = 4.5,
			},
			[3] = {
				Tipo = "Vazamento",
				Nome = "The 2 mm Leak (Soyuz MS-09)",
				Alerta = "CABIN PRESSURE DROPPING",
				Objetivo = "Close the hatch to the next module, find the leak (air being sucked in), take the epoxy gauze and hold on the hole.",
				TempoBaseSegurar = 3.0,
				TaxaPerdaArBase = 2.5, -- % por segundo
				MultiplicadorEscotilhaFechada = 0.5,
			},
		},
	},
}

-- Falas do guia (fictícias, didáticas; aparecem com o aviso nos Créditos)
Missoes.Guia = {
	Nome = "Marcos Pontes",
	Papel = "Mission guide · fictional lines",
	Foto = "", -- rbxassetid de foto oficial da NASA, quando houver; vazio = monograma
}

Missoes.FalasMarcos = {
	ExcessoPeso = "{name}, the rocket can only carry 60 kg and the ship weighed {weight} kg. It never left the pad! In space engineering every kilogram counts: choose together only what helps the most.",
	EjetarBlackout = "Ejecting during reentry would be fatal. John Glenn went about 4 minutes without radio and trusted his training. Sometimes the right answer is to stay calm and follow the procedure.",
	EjetarEscudo = "It was a sensor error! The heat shield was still in place. Ejecting in panic loses the mission. Keeping the retropack on was NASA's real decision.",
	PressaoMaximaAcoplamento = "Too much force crushes the module! On STS-88, the fix was to ease the pressure on the arm, not to push harder.",
	FaltaTempoSemItem = "Out of time, {name}. The {equipment} would have helped right here. Next time, talk it over and decide which task is hardest for your team.",
	FaltaTempoComItem = "So close, {name}! Even with the {equipment}, time ran short. Split the ship's stations better and try again.",
	DemorouDemais = "Mission complete, but it took too long, {name}: {total} s is over the 100 s limit. Plan who goes to each station before the alarms start.",
	Sucesso = "Excellent work, team! You made decisions like real NASA astronauts. Check the historical record of this mission in your album!",
}

-- Botões e textos de interface
Missoes.Textos = {
	CodigoInvalido = "Invalid code",
	TentarTask = "Retry task",
	RecomecarMissao = "Restart mission",
	VoltarLCC = "Return to LCC",
	VoarDeNovo = "Fly again",
	Lancar = "LAUNCH",
	Sair = "Leave ship",
	Preparacao = "Mission Preparation",
	BarraPeso = "Weight {x} / 60 kg · Free {free} kg",
	Bonus = "Lightness bonus: −{s} s",
	EquacaoResultado = "T1 {t1} s + T2 {t2} s + T3 {t3} s − {bonus} s lightness = {total} s · {stars}",
	DemorouDemais = "Took too long",
	MissaoEmAndamento = "This mission is already in flight. Wait for the crew to land.",
	NaveCheia = "The crew is full (4 astronauts).",
	JaEmMissao = "You are already on a mission.",
	EscorregouCabo = "The cable slipped! Move slower while carrying it.",
	ForaZonaVerde = "Pressure outside the green zone: the sphere slipped.",
	FecheEscotilha = "Close the hatch to the next module first!",
	PrecisaGaze = "Take the epoxy gauze from the toolbox first.",
	Medalhas = { [3] = "Gold", [2] = "Silver", [1] = "Bronze", [0] = "Failed" },
	MissaoReal = "The real mission",
	ValoresJogo = "Game values: weights, times and equipment effects are simplified for the game, not historical data.",
	Creditos = {
		"All weights, times, speeds and equipment effects are simplified teaching values for gameplay and learning.",
		"Marcos Pontes's lines are fictional, written for teaching.",
		"Historical photos: NASA (images.nasa.gov).",
		"Made for the NASA Space Apps Challenge 2026: Space Mission Design Game.",
	},
}

-- Cards do Álbum (fatos históricos; fotos oficiais da NASA, ver build/museum/shared/Content/Photos.luau)
Missoes.Cards = {
	Friendship7 = {
		Titulo = "Friendship 7",
		Missao = "Mercury-Atlas 6",
		Data = "February 20, 1962",
		Foto = "rbxassetid://133540020610757",
		Legenda = "John Glenn looks at Earth from Friendship 7.",
		Credito = "NASA · images.nasa.gov/details/KSC-JohnGlenn-0008",
		Texto = "John Glenn became the first American to orbit Earth: three orbits in 4 hours and 55 minutes. When the capsule drifted out of attitude he steered it by hand. A signal suggested the heat shield was loose, so Mission Control had him keep the retropack strapped on during reentry; the signal was a faulty switch. During reentry the radio was silent for 4 minutes and 20 seconds, and Friendship 7 splashed down safely in the Atlantic.",
		Relacao = "Your three tasks follow this flight: manual attitude control (Task 1), the reentry radio blackout (Task 2) and the heat shield alarm with the retropack kept on (Task 3).",
		TradeOff = "Every kilogram launched needs more rocket fuel, so early capsules carried only what was essential. In the game, items help one task each but cost weight and lightness bonus.",
		Fontes = {
			"nasa.gov/mission/mercury-atlas-6-friendship-7",
			"nasa.gov/history/60-years-ago-john-glenn-the-first-american-to-orbit-the-earth-aboard-friendship-7",
		},
	},
	UnityZarya = {
		Titulo = "Building the ISS",
		Missao = "STS-88 · STS-97 · Soyuz MS-09",
		Data = "1998 · 2000 · 2018",
		Foto = "rbxassetid://97971381370173",
		Legenda = "The International Space Station's P4, P5 and P6 trusses.",
		Credito = "NASA · images.nasa.gov/details/iss020e005813",
		Texto = "In December 1998 the STS-88 crew used the shuttle's robotic arm to join the U.S. Unity node to the Russian Zarya module: the first two pieces of the ISS. In December 2000 the STS-97 crew installed the P6 truss with the station's first U.S. solar arrays, and spacewalkers re-tensioned a slack array blanket. In August 2018 a 2 mm hole in the Soyuz MS-09 caused a slow pressure leak; the crew found it and sealed it with epoxy on gauze.",
		Relacao = "Task 1 is the Unity–Zarya docking, Task 2 the solar array cables of STS-97 and Task 3 the Soyuz MS-09 leak.",
		TradeOff = "Everything on the station was launched from Earth, so each tool and spare part competes for mass with food, water and science. In the game, the 60 kg limit makes the crew choose only two items.",
		Fontes = {
			"nasa.gov/mission/sts-88",
			"nasa.gov/mission/sts-97",
			"nasa.gov/blogs/spacestation/2018/08/30/international-space-station-status-3",
		},
	},
}

-- Sons (Audio API; ids já usados no projeto)
Missoes.Audio = {
	alarm = { id = 9113084658, volume = 0.9, loop = true },
	alarm_fast = { id = 9113865831, volume = 0.45, loop = true },
	static = { id = 9126160908, volume = 0.4, loop = true },
	rumble = { id = 9119414082, volume = 0.7, loop = true },
	click = { id = 9119717523, volume = 0.3 },
	confirm = { id = 9117060349, volume = 0.9 },
	error = { id = 9113085764, volume = 0.45 },
	squelch = { id = 9118019216, volume = 0.25 },
}

---------------------------------------------------------------------------------
-- Funções puras (servidor e cliente usam as mesmas contas)
---------------------------------------------------------------------------------

function Missoes.pesoTotal(missao, itens)
	local peso = Missoes.RegrasGerais.PesoNave
	for chave, on in itens do
		local eq = on and missao.Equipamentos[chave]
		if eq then peso += eq.Peso end
	end
	return peso
end

function Missoes.bonusLeveza(peso)
	local r = Missoes.RegrasGerais
	local livre = r.LimiteFoguete - peso
	if livre <= 0 then return 0 end
	return math.floor(livre / r.KgPorBonus) * r.SegundosBonusPorFaixa
end

-- tempos já arredondados (segundos inteiros) → total e estrelas, para a equação bater na tela
function Missoes.resultado(t1, t2, t3, bonus)
	local total = math.max(0, t1 + t2 + t3 - bonus)
	local f = Missoes.RegrasGerais.FaixasEstrelas
	local estrelas = 0
	if total <= f.TresEstrelas then
		estrelas = 3
	elseif total <= f.DuasEstrelas then
		estrelas = 2
	elseif total <= f.UmaEstrela then
		estrelas = 1
	end
	return total, estrelas
end

function Missoes.equacao(t1, t2, t3, bonus, total, estrelas)
	local s = estrelas > 0 and string.rep("⭐", estrelas) or ("0 stars · " .. Missoes.Textos.DemorouDemais)
	return Missoes.formatar(Missoes.Textos.EquacaoResultado, { t1 = t1, t2 = t2, t3 = t3, bonus = bonus, total = total, stars = s })
end

-- troca {chave} pelos valores (sem padrões Lua no texto do usuário)
function Missoes.formatar(texto, valores)
	return (string.gsub(texto, "{(%w+)}", function(k)
		local v = valores[k]
		if v == nil then return "{" .. k .. "}" end
		return tostring(v)
	end))
end

-- equipamento que ajuda a task i da missão (ou nil)
function Missoes.itemDaTask(missao, i)
	for chave, eq in missao.Equipamentos do
		if eq.TaskAlvo == i then return chave, eq end
	end
	return nil
end

return Missoes
