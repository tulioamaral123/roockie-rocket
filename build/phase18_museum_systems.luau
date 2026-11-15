--[[
	NASA Space Adventure — Fase 18: sistemas do museu (docs/museu-contrato.md)

	Instala os scripts de build/museum/ pelo mesmo servidor HTTP (como a Fase 15), espelhando
	as pastas, com as regras do Rojo:
	- pasta com init.luau → ModuleScript (os outros arquivos viram filhos); senão → Folder
	- *.server.luau → Script, *.client.luau → LocalScript, *.luau → ModuleScript
	Destinos:
	- build/museum/shared → ReplicatedStorage.MuseumSystem.Shared
	- build/museum/server → ServerScriptService.MuseumSystem
	- build/museum/client → StarterPlayer.StarterPlayerScripts.MuseumClient
	Com o Rojo conectado (default.project.json), ReplicatedStorage.MuseumSystem tem o atributo
	RojoManaged e esta fase não reinstala nada. Não cria peças.
	Executar depois das Fases 16 e 17 (o run_in_studio.luau já inclui esta fase).
]]

local H = game:GetService("HttpService")
local BASE = "http://127.0.0.1:8765/museum/"

local function get(path)
	return H:GetAsync(BASE .. path .. "?t=" .. os.clock(), true)
end

-- Lista de arquivos da página de diretório do http.server do Python
local function listing(dir)
	local html = get(dir)
	local out = {}
	for href in html:gmatch('<a href="([^"]+)"') do
		href = href:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
		if not href:match("^%.") and not href:match("^/") then table.insert(out, href) end
	end
	table.sort(out)
	return out
end

local count = 0

local function scriptFor(file)
	local name, class = file:match("^(.-)%.server%.luau$"), "Script"
	if not name then name, class = file:match("^(.-)%.client%.luau$"), "LocalScript" end
	if not name then name, class = file:match("^(.-)%.luau$"), "ModuleScript" end
	return name, class
end

local function install(dir, parent, name)
	local entries = listing(dir)
	local node
	if table.find(entries, "init.luau") then
		node = Instance.new("ModuleScript")
		node.Source = get(dir .. "init.luau")
		count += 1
	else
		node = Instance.new("Folder")
	end
	node.Name = name
	for _, e in entries do
		if e:sub(-1) == "/" then
			install(dir .. e, node, e:sub(1, -2))
		elseif e ~= "init.luau" then
			local n, class = scriptFor(e)
			if n then
				local s = Instance.new(class)
				s.Name = n
				s.Source = get(dir .. e)
				s.Parent = node
				count += 1
			end
		end
	end
	node.Parent = parent
	return node
end

local RS = game:GetService("ReplicatedStorage")
local existing = RS:FindFirstChild("MuseumSystem")
if existing and existing:GetAttribute("RojoManaged") == true then
	return "Fase 18: sistemas do museu gerenciados pelo Rojo (não reinstalados)"
end

local function fresh(parent, name)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
end

fresh(RS, "MuseumSystem")
local ms = Instance.new("Folder")
ms.Name = "MuseumSystem"
install("shared/", ms, "Shared")
ms.Parent = RS

local SSS = game:GetService("ServerScriptService")
fresh(SSS, "MuseumSystem")
install("server/", SSS, "MuseumSystem")

local sps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
fresh(sps, "MuseumClient")
install("client/", sps, "MuseumClient")

return string.format("Fase 18: sistemas do museu — %d scripts instalados de build/museum/", count)
