--[[
	Validador de conteúdo (museuspec §9.2). Roda no início do servidor.

	Validator.run() -> { [exhibitId] = true } (exposições válidas), { [cardId] = true }
	Validator.checkModel(model, data) confere os Attachments dos componentes.
	Todo problema vira warn("[Content] <id>: <problema>"); exposição inválida não recebe prompt.
]]

local Validator = {}

local TYPES = { original = true, replica = true, reconstrucao_digital = true }

local Photos = nil
local function photos()
	if not Photos then
		local ok, m = pcall(function() return require(script.Parent:WaitForChild("Content"):WaitForChild("Photos")) end)
		Photos = ok and m or {}
	end
	return Photos
end

local function problems(d, kind)
	local p = {}
	local function need(field, t)
		if type(d[field]) ~= t then table.insert(p, string.format("missing %s (%s)", field, t)) end
	end
	need("Id", "string")
	need("Name", "string")
	need("Verified", "boolean")
	if kind == "exhibit" then
		need("History", "string")
		if not TYPES[d.Type] then table.insert(p, "invalid Type (original | replica | reconstrucao_digital)") end
	else
		need("Purpose", "string")
	end
	local hasUrl = false
	if type(d.Sources) == "table" then
		for _, s in d.Sources do
			if type(s) == "table" and type(s.Url) == "string" and s.Url:match("^https://") then hasUrl = true end
		end
	end
	if not hasUrl then table.insert(p, "missing Sources (at least 1 https URL)") end
	if d.Image ~= nil then
		local known = type(d.Image) == "table" and d.Image.NasaId and photos()[d.Image.NasaId]
		if not known and (type(d.Image) ~= "table" or type(d.Image.Credit) ~= "string" or d.Image.Credit == "") then
			table.insert(p, "image without Credit")
		end
	end
	for _, id in d.Gallery or {} do
		local ph = photos()[id]
		if not ph then
			table.insert(p, "gallery photo not uploaded: " .. tostring(id))
		elseif type(ph.Credit) ~= "string" or ph.Credit == "" then
			table.insert(p, "photo without Credit: " .. tostring(id))
		end
	end
	for i, f in d.KeyFacts or {} do
		local src = type(f) == "table" and f.Source
		if type(f) ~= "table" or type(f.Text) ~= "string" then
			table.insert(p, "key fact " .. i .. " without Text")
		elseif not (type(src) == "string" and (photos()[src] or src:match("^https://"))) then
			table.insert(p, "key fact " .. i .. " without a known Source")
		end
	end
	if d.Components ~= nil then
		local seen = {}
		for i, c in d.Components do
			if type(c.Id) ~= "string" or type(c.Name) ~= "string" then
				table.insert(p, "component " .. i .. " without Id/Name")
			elseif seen[c.Id] then
				table.insert(p, "duplicate component " .. c.Id)
			else
				seen[c.Id] = true
			end
		end
	end
	return p
end

function Validator.validate(d, kind: string): (boolean, { string })
	local p = problems(d, kind)
	return #p == 0, p
end

function Validator.run(Content)
	local okExhibits, okCards = {}, {}
	local ids = {}
	for _, d in Content.exhibitList() do
		local ok, p = Validator.validate(d, "exhibit")
		local id = type(d.Id) == "string" and d.Id or ("<" .. tostring(d.__module) .. ">")
		if ids[id] then
			ok = false
			table.insert(p, "duplicate Id")
		end
		ids[id] = true
		if ok then
			okExhibits[id] = true
		else
			for _, msg in p do warn(string.format("[Content] %s: %s", id, msg)) end
		end
	end
	for _, d in Content.cards() do
		local ok, p = Validator.validate(d, "card")
		local id = type(d.Id) == "string" and d.Id or ("<" .. tostring(d.__module) .. ">")
		if ok then
			okCards[id] = true
		else
			for _, msg in p do warn(string.format("[Content] card %s: %s", id, msg)) end
		end
	end
	return okExhibits, okCards
end

-- Todo componente precisa de um Attachment com o mesmo nome no modelo
function Validator.checkModel(model: Instance, d): boolean
	local ok = true
	for _, c in d.Components or {} do
		local a = model:FindFirstChild(c.Id, true)
		if not (a and a:IsA("Attachment")) then
			warn(string.format("[Content] %s: component %s has no Attachment in model %s", d.Id, c.Id, model:GetFullName()))
			ok = false
		end
	end
	return ok
end

return Validator
