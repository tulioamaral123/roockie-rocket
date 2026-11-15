--[[
	NASA Space Adventure — Fase 22: NPCs guias e apresentação do complexo
	Spec: docs/guias-spec.md · contrato: docs/guias-contrato.md

	1. Cria NASAComplex.Guides com as pastas NPCs (os scripts montam Marcos e Ana em Play) e
	   NavigationPoints (peças de marcação invisíveis, na altura do HumanoidRootPart = piso + 3):
	   Spawn_Marcos, PrimeiroMuseu, Tour1..5, Museum1End, PainelPrincipal, SalaControle, AnaMeet,
	   AnaStartLCC, Hangar, RocketEntrance, Ana,
	   Ana_Route1..5. Cada ponto é conferido: piso por raio para baixo e folga de 3 × 5 × 3 sem
	   peças colidíveis; se o lugar estiver ocupado, procura o lugar livre mais próximo (até 10).
	   Os pontos sobre o lançador (escada, elevador, braço de acesso) não são criados aqui: os
	   scripts leem as peças do TransportSystem ao vivo (regra das referências relativas).
	2. Sem Rojo, instala os scripts de build/guide/ pelo HTTP (como as Fases 18 e 21):
	   shared → ReplicatedStorage.GuideSystem.Config · server → ServerScriptService.GuideSystem ·
	   client → StarterPlayerScripts.GuideClient.
	Executar depois das Fases 1–21 (o run_in_studio.luau já inclui esta fase).
]]

local lib = ...
local B = lib.builder(22)
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–21 antes")
B.clear(Map)

-- celular e tablet: jogo sempre na horizontal (o GuideClient também garante no PlayerGui)
game:GetService("StarterGui").ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

local Root = B.group(Map, "Guides", "Folder")
B.group(Root, "NPCs", "Folder")
local Points = B.group(Root, "NavigationPoints", "Folder")

local HRP = 3 -- altura do HumanoidRootPart acima do piso
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { Root }
rayParams.RespectCanCollide = true
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.FilterDescendantsInstances = { Root }
overlap.RespectCanCollide = true

local function floorAt(x, z, yHint)
	local hit = workspace:Raycast(Vector3.new(x, (yHint or 0) + 6, z), Vector3.new(0, -24, 0), rayParams)
	return hit and hit.Position.Y
end

local function free(pos)
	-- caixa do corpo, 0,3 acima do piso
	local parts = workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 0.3, 0)), Vector3.new(3, 5, 3), overlap)
	return #parts == 0
end

local report = {}

-- acha o lugar livre mais próximo de (x, z) com piso perto de yHint
local function place(name, x, z, lookAt, yHint)
	local function try(px, pz)
		local fy = floorAt(px, pz, yHint)
		if not fy or math.abs(fy - (yHint or 0)) > 4 then return nil end
		local p = Vector3.new(px, fy + HRP, pz)
		return free(p) and p or nil
	end
	local pos = try(x, z)
	local moved = 0
	if not pos then
		for r = 2, 10, 2 do
			for a = 0, 330, 30 do
				local px, pz = x + r * math.cos(math.rad(a)), z + r * math.sin(math.rad(a))
				pos = try(px, pz)
				if pos then moved = r break end
			end
			if pos then break end
		end
	end
	if not pos then
		pos = Vector3.new(x, (yHint or 0) + HRP, z)
		table.insert(report, name .. ": SEM PISO/FOLGA (conferir)")
	elseif moved > 0 then
		table.insert(report, ("%s: deslocado %d studs"):format(name, moved))
	end
	local look = lookAt and Vector3.new(lookAt.X, pos.Y, lookAt.Z) or pos + Vector3.new(0, 0, 1)
	if (look - pos).Magnitude < 0.1 then look = pos + Vector3.new(0, 0, 1) end
	local p = B.part(Points, name, CFrame.lookAt(pos, look), Vector3.new(1, 1, 1), "red", "Neon",
		{ collide = false, transparency = 1, shadow = false })
	return p
end

-- Recepção: Marcos ao lado do Spawn, virado para ele
local spawn = Map:FindFirstChild("SpawnLocation", true)
local sp = spawn and spawn.Position or Vector3.new(0, 0, 12)
place("Spawn_Marcos", sp.X + 7, sp.Z + 7, sp)

-- Primeiro museu: entrada do planetário (fim do corredor da ala leste, Fase 14)
place("PrimeiroMuseu", 54, 27.5, Vector3.new(40, 0, 27.5))

-- Visita guiada do Marcos pelo museu 1 (planetário, X 44..136, Z −13..68): uma parada diante de
-- cada exposição, virado para ela; termina na porta sul (fim do museu 1, passagem para o salão).
place("Tour1", 66, 4, Vector3.new(63, 0, -6)) -- Science_Exhibition
place("Tour2", 85, 3, Vector3.new(85, 0, -11)) -- Rocket_Exhibition
place("Tour3", 82, 26, Vector3.new(93, 0, 22)) -- Solar_System (no alto da cúpula)
place("Tour4", 66, 54, Vector3.new(60, 0, 63)) -- Mars_Exhibition
place("Tour5", 100, 48, Vector3.new(104, 0, 56)) -- Astronaut_Exhibition
place("Museum1End", 90, 61, Vector3.new(90, 0, 80)) -- porta sul do planetário

-- Sala de controle (LCC): eixo de passagem X = 0, no meio do saguão; painel = quiosque Mission Briefing
local lcc = Map:FindFirstChild("LaunchControlCenter")
local lccZ = 130
if lcc then
	local cf = lcc:GetBoundingBox()
	lccZ = cf.Position.Z
end
local kiosk = Map:FindFirstChild("RookieRocket") and Map.RookieRocket:FindFirstChild("Kiosk")
local ret = kiosk and kiosk:FindFirstChild("ReturnPoint")
if ret then
	place("PainelPrincipal", ret.Position.X, ret.Position.Z, kiosk:FindFirstChild("Screen") and kiosk.Screen.Position, ret.Position.Y)
else
	place("PainelPrincipal", 0, lccZ - 10, Vector3.new(0, 0, lccZ + 20))
end
place("SalaControle", 0, lccZ + 12, Vector3.new(0, 0, lccZ + 40))

-- Ana encontra o jogador diante da sala de comando (Firing Room, lado oeste do saguão do LCC)
-- e sai de dentro dela; os consoles ficam em X ≈ −28.
place("AnaMeet", -3, lccZ - 3, Vector3.new(-28, 0, lccZ - 3))
place("AnaStartLCC", -22, lccZ - 3, Vector3.new(0, 0, lccZ - 3))

-- Hangar (VAB): logo depois do portão frontal (Z 210)
place("Hangar", 0, 224, Vector3.new(-41, 0, 240))

-- Entrada do foguete: diante do vestiário da tripulação (vão de entrada X −44..−38, Z 244; Fase 8)
-- o vestiário é fixo no piso do VAB (não acompanha o conjunto), então vale a coordenada da Fase 8
local ex, ez = -41, 244
place("RocketEntrance", ex, ez - 6, Vector3.new(0, 0, 220))

-- Ana: entra em cena pelo fundo do vestiário; rota até o pé da escada do lançador (Fase 9)
place("Ana", ex - 7, ez + 10, Vector3.new(ex, 0, ez - 6))
place("Ana_Route1", ex, ez + 4)
place("Ana_Route2", ex + 1, ez + 7)
place("Ana_Route3", ex + 7, ez + 7)
place("Ana_Route4", -31.5, 240)
place("Ana_Route5", -27, 232)

---------------------------------------------------------------------------------
-- Espelho no Crew Suit-Up Room (parede do fundo, Z 258, entre os armários e o banco).
-- A reflexão é desenhada pelo cliente (GuideClient/Mirror) num SurfaceGui do vidro.
---------------------------------------------------------------------------------
local hangar = Map:FindFirstChild("VABHangar")
local suitRoom = hangar and hangar:FindFirstChild("CrewSuitUpRoom")
if suitRoom then
	local mirror = B.group(suitRoom, "Mirror")
	local MX0, MX1, MY0, MY1, MZ = -55, -47, 0.6, 8.6, 258
	B.box(mirror, "Mirror_Glass", MX0, MX1, MY0, MY1, MZ - 0.12, MZ, "#C9D6DF", "SmoothPlastic", { reflectance = 0.1 })
	for _, f in {
		{ MX0 - 0.35, MX1 + 0.35, MY1, MY1 + 0.35 }, { MX0 - 0.35, MX1 + 0.35, MY0 - 0.35, MY0 },
		{ MX0 - 0.35, MX0, MY0, MY1 }, { MX1, MX1 + 0.35, MY0, MY1 },
	} do
		B.box(mirror, "Mirror_Frame", f[1], f[2], f[3], f[4], MZ - 0.25, MZ, "metalGray", "Metal")
	end
	local tag = B.box(mirror, "Mirror_Sign", -53.5, -48.5, MY1 + 0.6, MY1 + 1.6, MZ - 0.1, MZ, "space", "SmoothPlastic", { collide = false })
	B.sign(tag, "CHECK YOUR SUIT", nil, { face = Enum.NormalId.Front, titleColor = "white", accent = "orange" })
end

---------------------------------------------------------------------------------
-- Scripts (sem Rojo)
---------------------------------------------------------------------------------

local RS = game:GetService("ReplicatedStorage")
local existing = RS:FindFirstChild("GuideSystem")
local installed = "gerenciados pelo Rojo"
if not (existing and existing:GetAttribute("RojoManaged") == true) then
	local H = game:GetService("HttpService")
	local BASE = "http://127.0.0.1:8765/guide/"
	local function get(path) return H:GetAsync(BASE .. path .. "?t=" .. os.clock(), true) end
	local function listing(dir)
		local out = {}
		for href in get(dir):gmatch('<a href="([^"]+)"') do
			href = href:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
			if not href:match("^%.") and not href:match("^/") then table.insert(out, href) end
		end
		table.sort(out)
		return out
	end
	local count = 0
	local function install(dir, parent, name)
		local node = Instance.new("Folder")
		node.Name = name
		for _, e in listing(dir) do
			local n, class = e:match("^(.-)%.server%.luau$"), "Script"
			if not n then n, class = e:match("^(.-)%.client%.luau$"), "LocalScript" end
			if not n then n, class = e:match("^(.-)%.luau$"), "ModuleScript" end
			if n then
				local s = Instance.new(class)
				s.Name = n
				s.Source = get(dir .. e)
				s.Parent = node
				count += 1
			end
		end
		node.Parent = parent
	end
	local function fresh(parent, name)
		local old = parent:FindFirstChild(name)
		if old then old:Destroy() end
	end
	fresh(RS, "GuideSystem")
	local gs = Instance.new("Folder")
	gs.Name = "GuideSystem"
	install("shared/", gs, "Config")
	gs.Parent = RS
	local SSS = game:GetService("ServerScriptService")
	fresh(SSS, "GuideSystem")
	install("server/", SSS, "GuideSystem")
	local sps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	fresh(sps, "GuideClient")
	install("client/", sps, "GuideClient")
	installed = count .. " scripts instalados de build/guide/"
end

return ("Fase 22: guias — %d pontos de navegação, %s%s"):format(#Points:GetChildren(), installed,
	#report > 0 and ("\n  " .. table.concat(report, "\n  ")) or "")
