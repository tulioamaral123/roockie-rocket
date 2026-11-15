--[[
	Estado local do visitante: cópia do progresso que o servidor mandou (só leitura no
	servidor; aqui serve para desenhar diário, vitrines e configurações).
]]

local State = {
	progress = {
		exhibitsSeen = {}, cards = {}, showsSeen = {},
		settings = { textSize = 2, captions = true, reduceMotion = false, arrows = true, firstPerson = false },
		firstVisit = false, noSave = false,
	},
}

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

function State.set(p)
	if type(p) == "table" then State.progress = p end
	changed:Fire()
end

function State.mark(field, id)
	if not State.progress[field][id] then
		State.progress[field][id] = true
		changed:Fire()
	end
end

function State.settings()
	return State.progress.settings
end

return State
