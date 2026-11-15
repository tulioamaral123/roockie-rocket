--[[
	Config do museu (docs/museu-contrato.md). Nenhum fato aqui: só chaves de comportamento.
]]

return {
	-- "dev": mostra exposições não verificadas com a faixa UNVERIFIED.
	-- "demo": esconde o painel (e o prompt) de quem tem Verified = false.
	MODE = "dev",

	-- Escala do museu (decisão de 14/11/2026): 0,7 m por stud
	METERS_PER_STUD = 0.7,

	-- Marca: uma textura trocável (logo NASA ou Space Apps). Vazio = sem logo.
	Brand = { LogoAssetId = "" },

	PROMPT_DEFAULT_DISTANCE = 14,
	PROMPT_DISTANCE_SLACK = 8, -- folga na validação do servidor (lag)
	PANEL_CLOSE_EXTRA = 12, -- afastar-se além de MaxActivationDistance + isto fecha o painel

	DATASTORE_NAME = "MuseumProgress_v1",
	AUTOSAVE_SECONDS = 60,
	DATA_VERSION = 1,
}
