--[[
	Dialogues — falas dos NPCs guias (Marcos Pontes e Ana), objetivos do HUD e aparência.
	Spec: docs/guias-spec.md. Textos visíveis em inglês. Diálogos fictícios: Marcos Pontes é um
	personagem ficcional do jogo, sem participação ou endosso oficial.

	Para mudar um texto, edite só este arquivo (o Rojo leva ao Studio).
	{name} é trocado pelo DisplayName do jogador.
]]

local D = {}

D.Speakers = {
	Marcos = { Name = "Marcos Pontes", Role = "Astronaut · Guide", Color = Color3.fromHex("3B7BE0") },
	Ana = { Name = "Ana", Role = "Operations Engineer", Color = Color3.fromHex("E8892E") },
}

-- Cada diálogo: lista de falas { speaker, text }
D.Lines = {
	MarcosWelcome = {
		{ "Marcos", "Welcome to Rookie Rocket! I'm Marcos Pontes, and I'll help you get started." },
		{ "Marcos", "Before your mission, let's visit the museum and explore the history of spaceflight." },
		{ "Marcos", "Follow me. There's plenty to discover along the way!" },
	},
	MarcosJoin = {
		{ "Marcos", "Hi, {name}! We're heading to the museum. Follow me!" },
	},
	MarcosWait = {
		{ "Marcos", "This way, {name}! The museum is just ahead." },
	},
	MarcosMuseumIntro = {
		{ "Marcos", "This is the Space Adventure planetarium, our first museum. Stay with me, I'll show you around!" },
	},
	MarcosTour1 = {
		{ "Marcos", "Science is where every mission begins. Physics, chemistry and math tell us how to leave Earth and how to come back safely." },
	},
	MarcosTour2 = {
		{ "Marcos", "A rocket pushes hot gas down at high speed, and the gas pushes the rocket up. Each stage drops away to save weight." },
	},
	MarcosTour3 = {
		{ "Marcos", "Look up: that's our Solar System. Every probe we send out helps us understand these worlds a little better." },
	},
	MarcosTour4 = {
		{ "Marcos", "Mars is one of the next big goals. Robotic rovers already explore its surface, and one day people may walk there." },
	},
	MarcosTour5 = {
		{ "Marcos", "Astronauts train for years: flying, studying and working as a team. The suit is a small spacecraft that keeps them alive." },
	},
	MarcosFarewell = {
		{ "Marcos", "Here we are, at the end of the planetarium! The main hall is right through here." },
		{ "Marcos", "Take a look around and choose an exhibit to learn more. Good luck, explorer!" },
	},
	MuseumDone = {
		{ "Marcos", "Great choice, {name}! Now follow the red arrow to the rocket entrance, through the Launch Control Center and the hangar." },
	},
	AnaCall = {
		{ "Ana", "Hey, rookie! Over here! That siren means a launch window just opened." },
		{ "Ana", "I'm Ana, operations engineer, from the command room. You must be {name}." },
		{ "Ana", "Follow me to the rocket hangar. We're going all the way to the top of the rocket!" },
	},
	AnaElevator = {
		{ "Ana", "Step into the crew elevator and press the panel. I'll meet you at the top!" },
	},
	AnaBusy = {
		{ "Ana", "{name}, I'm up at the crew access arm! Climb the launcher stairs and take the crew elevator." },
	},
	AnaTop = {
		{ "Ana", "Welcome to the crew access arm, {name}! From here you can see the whole hangar." },
		{ "Ana", "On your first flight, the first mission is mandatory: Project Mercury, just like the first American astronauts." },
		{ "Ana", "Then comes the trade-off: every item helps one task, but the rocket only carries 60 kg. Choose with your crew!" },
	},
	AnaTopReturning = {
		{ "Ana", "Welcome back, {name}! Pick your next mission. Remember the trade-off: every kilogram counts." },
	},
}

-- Visita guiada do Marcos pelo museu 1: ponto de parada (Fase 22) → fala
D.Tour = {
	{ Point = "Tour1", Key = "MarcosTour1" },
	{ Point = "Tour2", Key = "MarcosTour2" },
	{ Point = "Tour3", Key = "MarcosTour3" },
	{ Point = "Tour4", Key = "MarcosTour4" },
	{ Point = "Tour5", Key = "MarcosTour5" },
}

-- Objetivos do HUD (spec §6.4)
D.Objectives = {
	MeetMarcos = "Meet Marcos Pontes.",
	FollowMarcos = "Follow Marcos through the museum.",
	Museum = "Explore the museum and select an exhibit.",
	Rocket = "Go to the command room at the Launch Control Center.",
	FollowAna = "Follow Ana to the top of the rocket.",
	Elevator = "Take the crew elevator to the top.",
	TalkAna = "Talk to Ana at the crew access arm.",
	ChooseMission = "Choose your mission and trade-off.",
}

D.Prompts = {
	TalkMarcos = { Action = "Talk", Object = "Marcos Pontes" },
	TalkAna = { Action = "Talk", Object = "Ana" },
}

D.MissionSelect = {
	Title = "CHOOSE YOUR MISSION",
	Subtitle = "First flight: Project Mercury is mandatory. After launch prep you'll pick the trade-off: up to 60 kg on the rocket.",
	SubtitleReturning = "Pick a mission. In launch prep, choose the items that fit the 60 kg limit.",
	Locked = "Complete Project Mercury first",
	Board = "Board",
	Cancel = "Not now",
	Missions = {
		{ Id = 1, Name = "Project Mercury", Detail = "Friendship 7 · 1962 · first steps in orbit" },
		{ Id = 2, Name = "International Space Station", Detail = "Assembly in orbit · EVA" },
	},
}

-- Aparência (R15). Para trocar por itens do catálogo, preencha os ids (números) em Accessories,
-- Shirt, Pants e Face; vazios usam a aparência montada pelo script (cores + peças).
D.Appearance = {
	Marcos = {
		Style = "Marcos", -- visual em server/MarcosLook.luau (docs/marcos-pontes-spec.md, foto de referência de 2024)
		Skin = Color3.fromHex("D6A07E"), -- tom médio, conferido na foto
		Suit = Color3.fromHex("233F8F"), -- macacão de voo azul médio-escuro (releitura original)
		Accent = Color3.fromHex("E5302A"),
		Hair = Color3.fromHex("E2E2E0"), -- branco/prateado, conferido na foto
		Brow = Color3.fromHex("5E5853"), -- sobrancelhas cinza-escuras
		Female = false,
		Shirt = 0, Pants = 0, Face = 0, Accessories = "",
	},
	Ana = {
		Skin = Color3.fromHex("A8714F"),
		Suit = Color3.fromHex("F2F4F7"), -- uniforme branco
		Accent = Color3.fromHex("1F4FA8"), -- detalhes azuis
		Hair = Color3.fromHex("3A2418"),
		Female = true,
		Shirt = 0, Pants = 0, Face = 0, Accessories = "",
	},
}

return D
