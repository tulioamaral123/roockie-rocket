-- Fatos: nasa.gov/history/60-years-ago-nasa-introduces-mercury-7-astronauts (conferido em 14/11/2026).
-- A spec §16.1 diz 27/4/1959; a página da NASA diz que a apresentação foi em 9/4/1959.
return {
	Id = "mercury_seven",
	Island = "pioneers",
	Name = "The Mercury Seven",
	Category = "History panel",
	Program = "Mercury",
	Period = "1959",
	Type = "reconstrucao_digital",
	History = "On April 9, 1959, NASA formally introduced its first seven astronauts: Scott Carpenter, Gordon Cooper, John Glenn, Gus Grissom, Wally Schirra, Alan Shepard and Deke Slayton. They became known as the Mercury Seven.",
	Data = {
		{ Label = "Introduced", Value = "April 9, 1959" },
		{ Label = "Astronauts", Value = "7" },
	},
	BoardText = "Carpenter · Cooper · Glenn · Grissom\nSchirra · Shepard · Slayton",
	Gallery = { "8772553", "8772558", "8892072", "8772556" },
	KeyFacts = {
		{ Text = "Alan Shepard flew Freedom 7 on the first U.S. crewed suborbital flight and became the first American in space.", Source = "8772553" },
		{ Text = "Gus Grissom flew the second suborbital flight; his capsule, Liberty Bell 7, sank into the sea after splashdown.", Source = "8772558" },
		{ Text = "Wally Schirra's Sigma 7 made six orbits in 9 1/4 hours on the third U.S. orbital flight.", Source = "8892072" },
		{ Text = "Gordon Cooper's Faith 7 was the last flight of Project Mercury and orbited Earth 22 times.", Source = "8772556" },
	},
	Interactions = {},
	PromptDistance = 12,
	Image = { NasaId = "8772556", Credit = "NASA", AssetId = nil },
	Sources = {
		{ Title = "60 Years Ago: NASA Introduces Mercury 7 Astronauts", Url = "https://www.nasa.gov/history/60-years-ago-nasa-introduces-mercury-7-astronauts/" },
		{ Title = "Mercury Seven (8772556)", Url = "https://images.nasa.gov/details/8772556" },
	},
	Verified = false,
}
