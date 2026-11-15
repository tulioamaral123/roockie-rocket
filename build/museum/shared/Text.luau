--[[
	Textos de interface (museuspec §9.3), em inglês (decisão de 14/11/2026).
	Uso: Text.get("panel.close"). Outros idiomas = outra tabela com as mesmas chaves.
]]

local enUS = {
	["prompt.examine"] = "Examine",
	["prompt.watchShow"] = "Watch the launch",
	["prompt.card"] = "View mission card",
	["prompt.cardLocked"] = "Locked mission",

	["panel.close"] = "Close",
	["panel.components"] = "View components",
	["panel.stages"] = "View stages",
	["panel.stagesBack"] = "Join stages",
	["panel.doors"] = "Open/close bay doors",
	["panel.sources"] = "Sources",
	["panel.back"] = "Back",
	["panel.history"] = "History",
	["panel.data"] = "Technical data",
	["panel.didYouKnow"] = "Did you know?",
	["panel.keyFacts"] = "Key facts",
	["panel.photosReal"] = "Real NASA photos",
	["panel.unverified"] = "UNVERIFIED CONTENT — under review",
	["panel.componentsHint"] = "Drag to orbit · scroll or pinch to zoom · tap a marker",
	["panel.showInMuseum"] = "Show in museum",

	["type.original"] = "Original artifact",
	["type.replica"] = "Replica",
	["type.reconstrucao_digital"] = "Digital reconstruction",

	["card.locked"] = "Locked",
	["card.unlockHint"] = "Unlocked by: %s",
	["card.new"] = "A new mission card is lit on the Mission Wall!",
	["card.purpose"] = "What it does",
	["card.commonWithYou"] = "In common with your mission",

	["show.exit"] = "Exit show",
	["show.simplified"] = "This is a simplified educational representation.",

	["hud.diary"] = "Diary",
	["hud.settings"] = "Settings",
	["diary.title"] = "Visitor diary",
	["diary.exhibits"] = "Exhibits seen: %d of %d",
	["diary.cards"] = "Mission cards: %d of %d",
	["diary.shows"] = "Shows watched: %d",
	["settings.title"] = "Settings",
	["settings.textSize"] = "Text size",
	["settings.small"] = "S",
	["settings.medium"] = "M",
	["settings.large"] = "L",
	["settings.captions"] = "Captions",
	["settings.reduceMotion"] = "Reduce camera motion",
	["settings.arrows"] = "Navigation arrows",
	["settings.firstPerson"] = "First person camera",
	["settings.on"] = "On",
	["settings.off"] = "Off",

	["save.failed"] = "Progress could not be loaded. This visit will not be saved.",
}

local Text = {}

function Text.get(key: string, ...): string
	local s = enUS[key]
	if not s then
		warn("[Text] missing key: " .. key)
		return key
	end
	if select("#", ...) > 0 then
		return string.format(s, ...)
	end
	return s
end

return Text
