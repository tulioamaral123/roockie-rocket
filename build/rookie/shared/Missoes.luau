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
		Card = "Friendship7",
		Equipamentos = {
			Giroscopio = {
				Nome = "Gyroscope",
				Peso = 15,
				TaskAlvo = 1,
				TempoSegurar = 1.2,
				Efeito = "Task 1: hold time on each target 2.0 s → 1.2 s",
			},
			ManualBordo = {
				Nome = "Flight Manual",
				Peso = 20,
				TaskAlvo = 2,
				BonusTempo = 15,
				Efeito = "Task 2: highlights the code on the clipboard and adds +15 s (30 s → 45 s)",
			},
			EscudoReforcado = {
				Nome = "Reinforced Shield",
				Peso = 25,
				TaskAlvo = 3,
				TempoSegurar = 6.0,
				MultiplicadorTremor = 0.5,
				Efeito = "Task 3: hold the retropack 10 s → 6 s and less camera shake",
			},
		},
		OrdemEquipamentos = { "Giroscopio", "ManualBordo", "EscudoReforcado" },
		Tasks = {
			[1] = {
				Tipo = "Mira",
				Nome = "The Autopilot Failure",
				Alerta = "AUTOMATIC CONTROL FAILURE",
				Objetivo = "Go to the windows, aim the + at the 4 red markers and hold until the circle fills.",
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
		Card = "UnityZarya",
		Equipamentos = {
			SensorPressao = {
				Nome = "Pressure Sensor",
				Peso = 15,
				TaskAlvo = 1,
				MultiplicadorZonaVerde = 1.5,
				Efeito = "Task 1: green zone of the pressure slider +50%",
			},
			LuvasAderentes = {
				Nome = "Grip Gloves",
				Peso = 20,
				TaskAlvo = 2,
				MultiplicadorVelocidade = 2.0,
				Efeito = "Task 2: drag the loose cables 2x faster without slipping",
			},
			KitVedacao = {
				Nome = "Sealing Kit",
				Peso = 25,
				TaskAlvo = 3,
				ReducaoPerdaAr = 0.6,
				TempoSegurar = 2.0,
				Efeito = "Task 3: air loss −40% and sealing time 3.0 s → 2.0 s",
			},
		},
		OrdemEquipamentos = { "SensorPressao", "LuvasAderentes", "KitVedacao" },
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
	Papel = "Mission guide",
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
		Titulo = "Friendship 7 (1962)",
		Foto = "rbxassetid://133540020610757",
		Legenda = "John Glenn looks at Earth from Friendship 7.",
		Credito = "NASA · images.nasa.gov/details/KSC-JohnGlenn-0008",
		Texto = "On February 20, 1962, John Glenn became the first American to orbit Earth, circling it three times in just under five hours. When the automatic control system failed he flew the capsule by hand. A sensor wrongly warned that the heat shield was loose, so Mission Control told him to keep the retropack on during reentry. He splashed down safely in the Atlantic.",
	},
	UnityZarya = {
		Titulo = "Building the ISS (1998–2018)",
		Foto = "rbxassetid://97971381370173",
		Legenda = "The International Space Station's P4, P5 and P6 trusses.",
		Credito = "NASA · images.nasa.gov/details/iss020e005813",
		Texto = "In December 1998 the STS-88 crew used the shuttle's robotic arm to join the U.S. Unity node to the Russian Zarya module: the first two pieces of the ISS. In 2000, STS-97 spacewalkers installed and tensioned the P6 solar arrays. In 2018 a 2 mm hole on the Soyuz MS-09 caused a slow pressure leak; the crew found it and sealed it with gauze and epoxy.",
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
