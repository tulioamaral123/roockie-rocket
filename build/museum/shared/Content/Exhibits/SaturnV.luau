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
	Interactions = { "Components", "Stages" },
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
	},
	Verified = false,
	VerifiedBy = nil,
}
