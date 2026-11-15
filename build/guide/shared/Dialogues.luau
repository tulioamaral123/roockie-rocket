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
	MarcosFarewell = {
		{ "Marcos", "Here we are! Take a look around and choose an exhibit to learn more. Good luck, explorer!" },
	},
	MuseumDone = {
		{ "Marcos", "Great choice, {name}! Now follow the red arrow to the rocket entrance, through the Launch Control Center and the hangar." },
	},
	AnaCall = {
		{ "Ana", "Hey, rookie! Over here! That siren means a launch window just opened." },
		{ "Ana", "I'm Ana, operations engineer. You must be {name}. Follow me, we're going to the top of the rocket!" },
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

-- Objetivos do HUD (spec §6.4)
D.Objectives = {
	MeetMarcos = "Meet Marcos Pontes.",
	FollowMarcos = "Follow Marcos to the museum.",
	Museum = "Explore the museum and select an exhibit.",
	Rocket = "Go to the rocket entrance.",
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
