-- Fatos: museuspec §16.1 (6100884, KSC-S63-01207)
return {
	Id = "mercury_capsule",
	Island = "pioneers",
	Name = "Mercury capsule",
	Category = "Spacecraft",
	Program = "Mercury",
	Period = "1961–1963",
	Type = "reconstrucao_digital",
	History = "Project Mercury was NASA's first human spaceflight program, with one astronaut per capsule. On May 5, 1961, Alan Shepard flew Freedom 7 on a suborbital flight and became the first American in space. On February 20, 1962, John Glenn flew Friendship 7 on Mercury-Atlas 6.",
	Data = {
		{ Label = "Crew", Value = "1 astronaut" },
		{ Label = "First American in space", Value = "Alan Shepard, Freedom 7, May 5, 1961" },
		{ Label = "Friendship 7", Value = "John Glenn, Mercury-Atlas 6, Feb 20, 1962" },
	},
	DidYouKnow = "Freedom 7 launched on a Mercury-Redstone rocket. You can see one standing in the Rocket Garden.",
	Components = {
		{ Id = "heat_shield", Name = "Heat shield", Function = "Faces forward during reentry and protects the capsule from the heat of the atmosphere." },
		{ Id = "window", Name = "Window", Function = "Lets the astronaut see Earth and check the capsule's attitude." },
		{ Id = "parachute", Name = "Parachutes", Function = "Slow the capsule down for splashdown in the ocean." },
		{ Id = "retrorockets", Name = "Retrorockets", Function = "Fire to slow the capsule so it can leave orbit and come home." },
	},
	Gallery = { "KSC-S63-01207", "KSC-JohnGlenn-0008", "6100884" },
	KeyFacts = {
		{ Text = "On February 20, 1962, John Glenn became the first American to orbit Earth.", Source = "KSC-S63-01207" },
		{ Text = "Friendship 7 orbited Earth 3 times and landed in the Atlantic Ocean 4 hours, 55 minutes and 23 seconds after launch, just east of Grand Turk Island.", Source = "KSC-S63-01207" },
		{ Text = "The Navy destroyer Noa recovered Glenn and his capsule 21 minutes after splashdown.", Source = "KSC-S63-01207" },
		{ Text = "Glenn used binoculars to look at Earth through the capsule window.", Source = "KSC-JohnGlenn-0008" },
		{ Text = "Mercury-Redstone 3 placed Alan Shepard in suborbit on May 5, 1961.", Source = "6100884" },
	},
	Interactions = { "Components" },
	PromptDistance = 14,
	Image = { NasaId = "KSC-S63-01207", Credit = "NASA", AssetId = nil },
	Sources = {
		{ Title = "Freedom 7 launch (6100884)", Url = "https://images.nasa.gov/details/6100884" },
		{ Title = "Glenn enters Friendship 7 (KSC-S63-01207)", Url = "https://images.nasa.gov/details/KSC-S63-01207" },
	},
	Verified = false,
}
