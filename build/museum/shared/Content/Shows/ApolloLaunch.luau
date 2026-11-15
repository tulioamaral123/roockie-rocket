--[[
	Roteiro do show de lançamento (museuspec §6). Fatos: museuspec §16.1 (6901001).
	At = segundos desde o início. Do = ação do ShowController:
	  dim | restore | screen (Text) | caption (Text) | console (Order) | allConsole |
	  countdown (From) | ignite | liftoff (Seconds, Height) | shake (Seconds) |
	  stage (Stage, Label) | stageOff | final
]]

return {
	Id = "apollo_launch",
	Name = "Apollo 11 launch",
	Duration = 78,
	-- Câmera do show: a peça LaunchConsole.ShowCamera (Fase 17) dá posição e direção no mundo;
	-- Position/LookAt abaixo são as coordenadas de projeto, usadas só se a peça faltar.
	-- Em cada evento "stage", a câmera vira para o estágio aceso (instantâneo com "reduzir movimento").
	Camera = { Position = { 300, 7, -16 }, LookAt = { 303, 13, 22 }, FieldOfView = 70 },
	Steps = {
		{ At = 0, Do = "dim" },
		{ At = 1.5, Do = "screen", Text = "APOLLO 11\nLaunch Complex 39A" },
		{ At = 2, Do = "caption", Text = "July 16, 1969. Launch Complex 39A, Florida." },
		{ At = 7, Do = "caption", Text = "On board: Neil Armstrong, Michael Collins and Buzz Aldrin." },
		{ At = 12, Do = "screen", Text = "SYSTEMS CHECK" },
		{ At = 12, Do = "caption", Text = "Launch control: \"All stations, report go or no go for launch.\"" },
		{ At = 15, Do = "console", Order = 1 },
		{ At = 15.5, Do = "caption", Text = "\"Booster: go.\"" },
		{ At = 17, Do = "console", Order = 2 },
		{ At = 17.5, Do = "caption", Text = "\"Guidance: go.\"" },
		{ At = 19, Do = "console", Order = 3 },
		{ At = 19.5, Do = "caption", Text = "\"Spacecraft: go.\"" },
		{ At = 21, Do = "console", Order = 4 },
		{ At = 21.5, Do = "caption", Text = "\"Range: go.\"" },
		{ At = 23, Do = "allConsole" },
		{ At = 23.5, Do = "caption", Text = "\"We are go for launch.\"" },
		{ At = 27, Do = "countdown", From = 10 },
		{ At = 34, Do = "ignite" },
		{ At = 34, Do = "caption", Text = "Ignition: the five F-1 engines come to full power." },
		{ At = 37, Do = "liftoff", Seconds = 14, Height = 28 },
		{ At = 37, Do = "shake", Seconds = 5 },
		{ At = 37, Do = "caption", Text = "Liftoff! 8:32 a.m. CDT." },
		{ At = 37, Do = "screen", Text = "LIFTOFF\n8:32 a.m. CDT" },
		{ At = 42, Do = "stage", Stage = "Stage_S_IC", Label = "S-IC · five F-1 engines" },
		{ At = 42, Do = "caption", Text = "The first stage lifts the whole rocket with more than 7,500,000 pounds of thrust." },
		{ At = 50, Do = "stage", Stage = "Stage_S_II", Label = "First stage separation · S-II ignites" },
		{ At = 50, Do = "caption", Text = "First stage separation. The S-II and its five J-2 engines take over." },
		{ At = 58, Do = "stage", Stage = "Stage_S_IVB", Label = "Second stage separation · S-IVB" },
		{ At = 58, Do = "caption", Text = "Second stage separation. The S-IVB's single J-2 engine places the spacecraft in Earth orbit." },
		{ At = 66, Do = "stage", Stage = "Stage_Spacecraft", Label = "Apollo spacecraft · next stop, the Moon" },
		{ At = 66, Do = "caption", Text = "Later, the S-IVB fires again to send Apollo 11 toward the Moon." },
		{ At = 72, Do = "restore" },
		{ At = 72, Do = "final" },
	},
	Sources = {
		{ Title = "Apollo 11 launch (6901001)", Url = "https://images.nasa.gov/details/6901001" },
	},
	Verified = false,
}
