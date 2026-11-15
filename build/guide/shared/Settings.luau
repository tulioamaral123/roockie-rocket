--[[
	Settings — etapas da apresentação, distâncias e recursos do GuideSystem (docs/guias-spec.md).
]]

local S = {}

-- Ordem das etapas do progresso (servidor é a fonte da verdade, por jogador)
S.Stages = {
	"MeetMarcos", -- seta → Marcos
	"FollowMarcos", -- Marcos acompanha até o museu
	"Museum", -- seta → exposição mais próxima, até selecionar uma
	"Rocket", -- seta → entrada do foguete (via LCC e hangar)
	"FollowAna", -- Ana guia até o elevador da tripulação
	"Elevator", -- subir no elevador
	"TalkAna", -- falar com a Ana no braço de acesso
	"ChooseMission", -- escolha da missão (o trade-off é a Preparação do Rookie Rocket)
	"InMission", -- a bordo: seta e objetivo somem
	"Free", -- depois da primeira missão: exploração livre
}

S.Radius = {
	Talk = 10, -- ProximityPrompt dos NPCs
	Via = 14, -- ponto intermediário da rota considerado atingido
	RocketEntrance = 26, -- chegada à entrada do foguete
	AnaMeet = 16, -- diante da sala de comando do LCC: sirene + Ana
	MuseumArrival = 16, -- chegada ao fim do museu 1 (despedida do Marcos)
	TourNear = 30, -- quem está a até 30 studs do Marcos ouve a fala da parada
	FollowLeash = 28, -- o NPC espera quem ficou para trás
	TopLevel = 40, -- distância horizontal do braço de acesso para "está no topo"
}

-- Seta: altura acima do chão e distância à frente do jogador
S.Arrow = {
	Color = Color3.fromHex("E5302A"),
	Ahead = 5,
	Height = 1.2, -- acima da cintura (HumanoidRootPart)
	Bob = 0.35,
	BeaconHeight = 7, -- seta de destino, acima do alvo
}

S.Repath = {
	Interval = 1.5, -- s entre recálculos do caminho do jogador
	MoveThreshold = 10, -- studs andados para recalcular
}

S.Agent = { AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = false, WaypointSpacing = 5 }

S.Sounds = {
	Siren = { Id = "rbxassetid://9113084658", Volume = 0.8, Duration = 4 }, -- mesmo alarme do Rookie Rocket
	Blip = { Id = "rbxassetid://9119717523", Volume = 0.35 },
}

-- Animações padrão R15 da Roblox
S.Animations = {
	Idle = "rbxassetid://507766388",
	Walk = "rbxassetid://913402848",
	Wave = "rbxassetid://507770239",
}

S.WalkSpeed = { Marcos = 12, Ana = 13 }

return S
