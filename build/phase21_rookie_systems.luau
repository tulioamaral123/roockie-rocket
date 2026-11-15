--[[
	NASA Space Adventure — Fase 21: sistemas do Rookie Rocket (docs/rookie-contrato.md)

	Instala os scripts de build/rookie/ pelo servidor HTTP, com as mesmas regras do Rojo
	(igual à Fase 18):
	- build/rookie/shared → ReplicatedStorage.RookieRocket.Config (Missoes)
	- build/rookie/server → ServerScriptService.RookieRocket (GerenciadorMissao + módulos)
	- build/rookie/client → StarterPlayer.StarterPlayerScripts.RookieClient
	Com o Rojo conectado, ReplicatedStorage.RookieRocket tem o atributo RojoManaged e esta fase
	não reinstala nada. Não cria peças. Executar depois das Fases 19 e 20.
]]

local H = game:GetService("HttpService")
local BASE = "http://127.0.0.1:8765/rookie/"

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
local existing = RS:FindFirstChild("RookieRocket")
if existing and existing:GetAttribute("RojoManaged") == true then
	return "Fase 21: sistemas do Rookie Rocket gerenciados pelo Rojo (não reinstalados)"
end

local function fresh(parent, name)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
end

-- ReplicatedStorage.RookieRocket.Config (Missoes); os Remotes são criados pelo GerenciadorMissao
fresh(RS, "RookieRocket")
local rr = Instance.new("Folder")
rr.Name = "RookieRocket"
install("shared/", rr, "Config")
rr.Parent = RS

local SSS = game:GetService("ServerScriptService")
fresh(SSS, "RookieRocket")
install("server/", SSS, "RookieRocket")

local sps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
fresh(sps, "RookieClient")
install("client/", sps, "RookieClient")

return string.format("Fase 21: Rookie Rocket — %d scripts instalados de build/rookie/", count)
