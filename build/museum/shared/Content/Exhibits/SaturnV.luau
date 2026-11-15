-- Fatos: museuspec §16.1 (IDs images.nasa.gov citados em Sources)
local components = {
	{ Id = "s_ic", Name = "S-IC first stage", Function = "Lifted the whole rocket off the pad with five F-1 engines.", Details = "42.1 m long, 10.1 m wide. Liquid oxygen + kerosene. More than 7,500,000 lbf of thrust." },
	{ Id = "s_ii", Name = "S-II second stage", Function = "Took over after the first stage dropped away.", Details = "Five J-2 engines, 200,000 lbf each. Liquid hydrogen + liquid oxygen." },
	{ Id = "s_ivb", Name = "S-IVB third stage", Function = "Pushed the spacecraft toward the Moon.", Details = "18 m long, 6.7 m wide. One J-2 engine." },
	{ Id = "iu", Name = "Instrument unit", Function = "The rocket's guidance ring, between the S-IVB and the spacecraft.", Details = "0.9 m tall, 6.4 m wide. Built by IBM." },
	{ Id = "spacecraft", Name = "Apollo spacecraft", Function = "Lunar module, service module and command module: the part that went to the Moon.", Details = "Only the command module returned to Earth." },
	{ Id = "les", Name = "Launch escape system", Function = "A rocket tower that could pull the command module away from the rocket in an emergency.", Details = "Part of the Apollo spacecraft stack." },
	{ Id = "j2_ivb", Name = "J-2 engine (third stage)", Function = "The single engine of the S-IVB.", Details = "Liquid hydrogen + liquid oxygen." },
}
for i = 1, 5 do
	table.insert(components, { Id = "f1_" .. i, Name = "F-1 engine " .. i, Function = "One of five first-stage engines.", Details = "5.8 m tall, 3.8 m wide at the nozzle exit. 1,500,000 lbf of thrust each." })
	table.insert(components, { Id = "j2_ii_" .. i, Name = "J-2 engine " .. i .. " (second stage)", Function = "One of five second-stage engines.", Details = "200,000 lbf of thrust each." })
end

-- "Explore rocket" (docs/museu-foguete-interativo.md): partes que o modelo da Fase 17 de fato
-- representa. Region diz quais peças formam a área clicável:
--   Stage = sub-Model do estágio; Only = só estes filhos; Except = o estágio sem estes filhos;
--   Prefixes = só as peças cujo nome começa com um destes prefixos.
-- Photo = NASA ID em Content/Photos (asset já enviado ao Roblox). Overview = foto da vista geral
-- (usar só quando não houver foto ou ilustração da parte; hoje todas as 11 têm a sua). Fatos: metadados oficiais de
-- images.nasa.gov (Source = NASA ID) e press kits da Apollo (ntrs.nasa.gov).
local F1 = { "F1_1", "F1_2", "F1_3", "F1_4", "F1_5" }
local J2 = { "J2_1", "J2_2", "J2_3", "J2_4", "J2_5" }
local explore = {
	{
		Id = "f1", Name = "F-1 engines",
		Function = "Five huge engines that lifted the whole Saturn V off the launch pad.",
		Facts = {
			{ Text = "Each F-1 was 19 ft (5.8 m) tall, 12.5 ft (3.8 m) wide at the nozzle exit, and produced 1,500,000 pounds of thrust.", Source = "6862832" },
			{ Text = "The four outer engines could swivel to steer the rocket; the center engine was fixed.", Source = "9903033" },
		},
		Photo = "6862832",
		Region = { Stage = "Stage_S_IC", Only = F1 },
	},
	{
		Id = "s_ic", Name = "S-IC first stage",
		Function = "The first stage: its fuel tanks fed the five F-1 engines during the first minutes of flight.",
		Facts = {
			{ Text = "The S-IC was 138 ft (42.1 m) long and 33 ft (10.1 m) wide, with more than 7,500,000 pounds of thrust.", Source = "9903033" },
			{ Text = "It burned kerosene and liquid oxygen.", Source = "0100979" },
		},
		Photo = "9903033",
		Region = { Stage = "Stage_S_IC", Except = F1 },
	},
	{
		Id = "j2_ii", Name = "J-2 engines (second stage)",
		Function = "Five engines that took over when the first stage dropped away.",
		Facts = {
			{ Text = "Each J-2 produced 200,000 pounds of thrust, later uprated to 230,000 pounds from the fourth Apollo Saturn V flight on.", Source = "9801770" },
			{ Text = "The four outer engines could swivel for steering; the fifth, in the center, was fixed.", Source = "9801810" },
		},
		Photo = "9903176",
		Region = { Stage = "Stage_S_II", Only = J2 },
	},
	{
		Id = "s_ii", Name = "S-II second stage",
		Function = "The second stage carried the rocket almost to orbit, burning liquid hydrogen and liquid oxygen.",
		Facts = {
			{ Text = "Its five J-2 engines burned over one ton of propellant per second for about 6 1/2 minutes, reaching about 108 miles (174 km) of altitude.", Source = "9801770" },
		},
		Photo = "9903176",
		Region = { Stage = "Stage_S_II", Except = J2 },
	},
	{
		Id = "s_ivb", Name = "S-IVB third stage",
		Function = "Put the spacecraft into Earth orbit, then fired again to send it toward the Moon.",
		Facts = {
			{ Text = "The S-IVB was 59 ft (18 m) long and 22 ft (6.7 m) wide, powered by a single J-2 engine.", Source = "0600309" },
			{ Text = "It burned for about two minutes to reach Earth orbit and was re-ignited later to reach escape velocity.", Source = "6757813" },
		},
		Photo = "0100983",
		Region = { Stage = "Stage_S_IVB", Except = { "J2" } },
	},
	{
		Id = "j2_ivb", Name = "J-2 engine (third stage)",
		Function = "The single engine of the S-IVB. It could be restarted in space.",
		Facts = {
			{ Text = "The S-IVB's J-2 had a built-in restart capability.", Source = "0100983" },
		},
		Photo = "6520309",
		Region = { Stage = "Stage_S_IVB", Only = { "J2" } },
	},
	{
		Id = "iu", Name = "Instrument unit",
		Function = "The rocket's brain: a ring of computers and guidance equipment that kept the Saturn V on course.",
		Facts = {
			{ Text = "Built by IBM, it was 3 ft (0.9 m) high and 21 ft (6.4 m) in diameter, between the third stage and the spacecraft.", Source = "0100984" },
		},
		Photo = "0100984",
		Region = { Stage = "Stage_IU" },
	},
	{
		Id = "sla", Name = "Lunar module adapter",
		Function = "The cone-shaped shell between the rocket and the service module. The lunar module rode inside it.",
		Facts = {
			{ Text = "The Apollo spacecraft was made of the lunar module, the service module, the command module and the launch escape system.", Source = "0100985" },
			{ Text = "On Apollo 11, the lunar module Eagle landed on the Moon on July 20, 1969.", Source = "6974206" },
		},
		Photo = "0100985",
		Region = { Stage = "Stage_Spacecraft", Prefixes = { "SpacecraftLMAdapter" } },
	},
	{
		Id = "service_module", Name = "Service module",
		Function = "Carried oxygen tanks and fuel cells for the command module. It was let go before the return to Earth.",
		Facts = {
			{ Text = "On Apollo 13, an oxygen tank in the service module exploded; the crew photographed the damage after letting the module go.", Source = "7010516" },
		},
		Photo = "7010516",
		Region = { Stage = "Stage_Spacecraft", Prefixes = { "ServiceModule", "SMRadiator" } },
	},
	{
		Id = "command_module", Name = "Command module",
		Function = "The cabin of the three astronauts and the only part of the Saturn V stack that came back to Earth.",
		Facts = {
			{ Text = "Apollo 11's command module, Columbia, brought the crew back to Earth on July 24, 1969.", Source = "6974206" },
		},
		Photo = "372772main_GPN-2000-001212_full",
		Region = { Stage = "Stage_Spacecraft", Prefixes = { "CommandModule", "DockingCover" } },
	},
	{
		Id = "les", Name = "Launch escape system",
		Function = "A small rocket tower on top. In an emergency during launch it could pull the command module away from the rocket.",
		Facts = {
			{ Text = "If it was not needed, the tower was thrown away (jettisoned) shortly after the second stage ignited.", Source = "Apollo 8 press kit" },
		},
		Photo = "6900547",
		Region = { Stage = "Stage_Spacecraft", Prefixes = { "Escape", "Abort" } },
	},
}

return {
	Id = "saturn_v",
	Island = "apollo",
	Name = "Saturn V",
	Category = "Launch vehicle",
	Program = "Apollo",
	Period = "1967–1973",
	Type = "reconstrucao_digital",
	History = "Saturn V carried the Apollo astronauts to the Moon. It first flew on Apollo 4 on November 7, 1967, and made its last flight on May 14, 1973, launching Skylab. Its three stages fired one after another, each one dropping away when its job was done.",
	Data = {
		{ Label = "Height", Value = "110.6 m (363 ft)" },
		{ Label = "Maximum diameter", Value = "10.1 m (33 ft)" },
		{ Label = "Stages", Value = "3 + instrument unit" },
		{ Label = "First-stage thrust", Value = "more than 7,500,000 lbf" },
		{ Label = "First flight", Value = "Apollo 4, Nov 7, 1967" },
		{ Label = "Last flight", Value = "Skylab 1, May 14, 1973" },
	},
	DidYouKnow = "The first stage burned about 15 tons of propellant every second.",
	Components = components,
	Stages = {
		Stage_S_IC = "S-IC · 1st stage",
		Stage_S_II = "S-II · 2nd stage",
		Stage_S_IVB = "S-IVB · 3rd stage",
		Stage_IU = "Instrument unit",
		Stage_Spacecraft = "Apollo spacecraft",
	},
	Gallery = { "6901001", "KSC-99pp1144", "6862832", "9903033", "9903401" },
	KeyFacts = {
		{ Text = "At 363 feet (110.6 m), the Saturn V stood taller than the Statue of Liberty.", Source = "9903401" },
		{ Text = "Altogether, the Saturn V engines produced as much power as 85 Hoover Dams.", Source = "9903401" },
		{ Text = "Each F-1 engine produced 1,500,000 pounds of thrust; the five together burned 15 tons of liquid oxygen and kerosene every second.", Source = "6862832" },
		{ Text = "Four F-1 engines on the outer ring gimbaled to steer the rocket; the center engine was fixed.", Source = "9903033" },
		{ Text = "NASA compared the roar of the five F-1 engines to the sound of 8,000,000 hi-fi sets.", Source = "9903033" },
		{ Text = "The Saturn V that launched Apollo 11 was vehicle SA-506.", Source = "6901001" },
	},
	Interactions = { "Explore", "Stages" },
	Explore = explore,
	ExploreBack = "f1_1", -- Attachment do lado dos motores (a câmera fica um pouco para trás)
	PromptDistance = 32,
	Image = { NasaId = "6901001", Credit = "NASA", AssetId = nil },
	Sources = {
		{ Title = "Saturn V height (9903401)", Url = "https://images.nasa.gov/details/9903401" },
		{ Title = "S-IC stage (9903033)", Url = "https://images.nasa.gov/details/9903033" },
		{ Title = "F-1 engine (6862832)", Url = "https://images.nasa.gov/details/6862832" },
		{ Title = "S-II stage (9801770)", Url = "https://images.nasa.gov/details/9801770" },
		{ Title = "S-IVB stage (0600309)", Url = "https://images.nasa.gov/details/0600309" },
		{ Title = "Instrument unit (0100984)", Url = "https://images.nasa.gov/details/0100984" },
		{ Title = "Apollo 4, first flight (9903407)", Url = "https://images.nasa.gov/details/9903407" },
		{ Title = "Skylab 1, last flight (S73-23918)", Url = "https://images.nasa.gov/details/S73-23918" },
		{ Title = "S-II cutaway (9801810)", Url = "https://images.nasa.gov/details/9801810" },
		{ Title = "S-IVB stage (6757813)", Url = "https://images.nasa.gov/details/6757813" },
		{ Title = "S-IVB cutaway (0100983)", Url = "https://images.nasa.gov/details/0100983" },
		{ Title = "Saturn V cutaway (0100979)", Url = "https://images.nasa.gov/details/0100979" },
		{ Title = "Apollo spacecraft (0100985)", Url = "https://images.nasa.gov/details/0100985" },
		{ Title = "Apollo 11 mission (6974206)", Url = "https://images.nasa.gov/details/6974206" },
		{ Title = "Apollo 13 service module (7010516)", Url = "https://images.nasa.gov/details/7010516" },
		{ Title = "S-II stage arrives at MSFC (9903176)", Url = "https://images.nasa.gov/details/9903176" },
		{ Title = "J-2 engine (6520309)", Url = "https://images.nasa.gov/details/6520309" },
		{ Title = "Launch escape tower, Apollo 11 (6900547)", Url = "https://images.nasa.gov/details/6900547" },
		{ Title = "Apollo 8 press kit (launch escape tower)", Url = "https://ntrs.nasa.gov/api/citations/19690003059/downloads/19690003059.pdf" },
	},
	Verified = false,
	VerifiedBy = nil,
}
