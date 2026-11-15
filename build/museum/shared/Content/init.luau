--[[
	Carrega o conteúdo do museu (museuspec §9): um ModuleScript por exposição, card e show.
	Content.exhibits() -> { [id] = dados }, Content.cards() -> lista ordenada por Order,
	Content.show(id) -> roteiro. Os dados são lidos uma vez e guardados.
]]

local Content = {}

local cache = {}
local Photos = require(script:WaitForChild("Photos"))

-- Foto real da NASA pelo NASA ID (Content/Photos): { AssetId, Credit, Date, Caption, Source, Illustration? }
function Content.photo(nasaId: string)
	return Photos[nasaId]
end

-- Galeria de uma exposição/card: Gallery (lista de NASA IDs) ou, se faltar, Image.NasaId
function Content.gallery(d)
	local out = {}
	for _, id in d.Gallery or {} do
		local ph = Photos[id]
		if ph then table.insert(out, { Id = id, Photo = ph }) end
	end
	if #out == 0 and d.Image and d.Image.NasaId and Photos[d.Image.NasaId] then
		table.insert(out, { Id = d.Image.NasaId, Photo = Photos[d.Image.NasaId] })
	end
	return out
end

local function loadFolder(name: string)
	if cache[name] then return cache[name] end
	local out = {}
	local folder = script:WaitForChild(name)
	for _, m in folder:GetChildren() do
		if m:IsA("ModuleScript") then
			local ok, data = pcall(require, m)
			if ok and type(data) == "table" then
				data.__module = m.Name
				table.insert(out, data)
			else
				warn(string.format("[Content] %s/%s did not load: %s", name, m.Name, tostring(data)))
			end
		end
	end
	cache[name] = out
	return out
end

function Content.exhibitList()
	return loadFolder("Exhibits")
end

function Content.exhibits()
	local byId = {}
	for _, d in loadFolder("Exhibits") do
		if type(d.Id) == "string" then byId[d.Id] = d end
	end
	return byId
end

function Content.exhibit(id: string)
	return Content.exhibits()[id]
end

function Content.cards()
	local list = table.clone(loadFolder("Cards"))
	table.sort(list, function(a, b) return (a.Order or 99) < (b.Order or 99) end)
	return list
end

function Content.card(id: string)
	for _, c in loadFolder("Cards") do
		if c.Id == id then return c end
	end
	return nil
end

function Content.show(id: string)
	for _, s in loadFolder("Shows") do
		if s.Id == id then return s end
	end
	return nil
end

return Content
