--[[
	Efeitos — o que cada jogador vê e ouve a bordo (tudo local, nada replica):
	- céu estrelado no lugar do céu do mapa (restaurado ao sair) e a Terra da ISS só a bordo da ISS;
	- campo de estrelas em volta da Mercury, girando rápido na Task 1;
	- luzes da cabine: vermelho pulsante (M1 T1, M2 T3), laranja de calor (M1 T3);
	- plasma de reentrada nas janelas (M1 T3), botões EJECT piscando (M1 T2 e T3);
	- tremor de câmera (Humanoid.CameraOffset), cabos de segurança da EVA, sons.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Audio = require(script.Parent:WaitForChild("Audio"))

local E = {}

local player = Players.LocalPlayer
local nave, missaoId = nil, nil
local ceuSalvo = nil
local estrelas = nil
local giroEstrelas = 0.01 -- rad/s
local tremor = 0
local tremorPulso, tremorPulsoFim = 0, 0
local modoLuz = "normal"
local luzes = {} -- { luz, cor, brilho }
local plasma = {}
local ejects = {}
local cabos = {} -- [player] = Beam
local terraEscondida = {}
local conexao = nil

---------------------------------------------------------------------------------
-- Terra da ISS: só aparece para quem está a bordo da ISS (ela é enorme e o modelo é Persistent)
---------------------------------------------------------------------------------

local function pecasTerra()
	local iss = workspace:FindFirstChild("NASAComplex")
	iss = iss and iss:FindFirstChild("RookieRocket")
	iss = iss and iss:FindFirstChild("ISS")
	local ext = iss and iss:FindFirstChild("Exterior")
	local lista = {}
	if not ext then return lista end
	for _, nome in { "Earth", "EarthDetail" } do
		local x = ext:FindFirstChild(nome)
		if x then
			if x:IsA("BasePart") then table.insert(lista, x) end
			for _, d in x:GetDescendants() do
				if d:IsA("BasePart") then table.insert(lista, d) end
			end
		end
	end
	return lista
end

function E.mostrarTerra(mostrar)
	for _, p in pecasTerra() do
		if mostrar then
			if terraEscondida[p] then p.Transparency = terraEscondida[p] end
			terraEscondida[p] = nil
		elseif terraEscondida[p] == nil then
			terraEscondida[p] = p.Transparency
			p.Transparency = 1
		end
	end
end

---------------------------------------------------------------------------------
-- Céu
---------------------------------------------------------------------------------

local function ceuDeEspaco()
	if ceuSalvo then return end
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	ceuSalvo = {
		clock = Lighting.ClockTime,
		atm = atm,
		densidade = atm and atm.Density,
		haze = atm and atm.Haze,
		ceus = {},
	}
	for _, s in Lighting:GetChildren() do
		if s:IsA("Sky") then
			ceuSalvo.ceus[s] = s.Parent
			s.Parent = nil
		end
	end
	local sky = Instance.new("Sky")
	sky.Name = "RookieSky"
	sky.StarCount = 5000
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting
	ceuSalvo.novo = sky
	Lighting.ClockTime = 0
	if atm then
		atm.Density = 0
		atm.Haze = 0
	end
end

local function restaurarCeu()
	if not ceuSalvo then return end
	if ceuSalvo.novo then ceuSalvo.novo:Destroy() end
	for s, pai in ceuSalvo.ceus do s.Parent = pai end
	Lighting.ClockTime = ceuSalvo.clock
	if ceuSalvo.atm then
		ceuSalvo.atm.Density = ceuSalvo.densidade
		ceuSalvo.atm.Haze = ceuSalvo.haze
	end
	ceuSalvo = nil
end

---------------------------------------------------------------------------------
-- Campo de estrelas (Mercury): esfera de pontinhos que gira em volta da cápsula
---------------------------------------------------------------------------------

local function criarEstrelas(centro)
	local m = Instance.new("Model")
	m.Name = "RookieStars"
	local rng = Random.new(1962)
	for _ = 1, 160 do
		local dir = rng:NextUnitVector()
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Shape = Enum.PartType.Ball
		p.Color = Color3.fromHSV(0.6, rng:NextNumber(0, 0.25), 1)
		local d = rng:NextNumber(0.6, 1.6)
		p.Size = Vector3.new(d, d, d)
		p.CFrame = CFrame.new(centro + dir * rng:NextNumber(150, 220))
		p.Parent = m
	end
	local pivo = Instance.new("Part")
	pivo.Name = "Pivo"
	pivo.Anchored = true
	pivo.Transparency = 1
	pivo.CanCollide = false
	pivo.CanQuery = false
	pivo.CFrame = CFrame.new(centro)
	pivo.Parent = m
	m.PrimaryPart = pivo
	m.Parent = workspace
	return m
end

---------------------------------------------------------------------------------
-- Entrar / sair da nave
---------------------------------------------------------------------------------

local function pecasDe(pasta, classe)
	local lista = {}
	if not pasta then return lista end
	for _, d in pasta:GetDescendants() do
		if d:IsA(classe) then table.insert(lista, d) end
	end
	return lista
end

function E.entrar(id, modelo)
	if nave == modelo then return end
	E.sair()
	nave, missaoId = modelo, id
	ceuDeEspaco()
	E.mostrarTerra(id == 2)
	luzes = {}
	for _, l in pecasDe(modelo:FindFirstChild("Lights"), "Light") do
		table.insert(luzes, { luz = l, cor = l.Color, brilho = l.Brightness })
	end
	plasma = pecasDe(modelo:FindFirstChild("Exterior") and modelo.Exterior:FindFirstChild("PlasmaEmitters"), "ParticleEmitter")
	ejects = {}
	local st = modelo:FindFirstChild("Stations")
	for _, caminho in { { "Radio", "EjectButton" }, { "Reentry", "EjectButton" } } do
		local m = st and st:FindFirstChild(caminho[1])
		local b = m and m:FindFirstChild(caminho[2])
		if b and b:IsA("BasePart") then ejects[caminho[1]] = { peca = b, cor = b.Color, ligado = false } end
	end
	if id == 1 then
		estrelas = criarEstrelas(modelo:GetPivot().Position)
	end
	conexao = RunService.RenderStepped:Connect(E.quadro)
end

function E.sair()
	if conexao then conexao:Disconnect() conexao = nil end
	if estrelas then estrelas:Destroy() estrelas = nil end
	for _, l in luzes do
		l.luz.Color = l.cor
		l.luz.Brightness = l.brilho
	end
	for _, p in plasma do p.Enabled = false end
	for _, b in ejects do b.peca.Color = b.cor end
	for _, beam in cabos do beam:Destroy() end
	table.clear(cabos)
	luzes, plasma, ejects = {}, {}, {}
	Audio.setLoops({})
	restaurarCeu()
	E.mostrarTerra(false)
	tremor, modoLuz = 0, "normal"
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.CameraOffset = Vector3.zero end
	nave, missaoId = nil, nil
end

---------------------------------------------------------------------------------
-- Estado contínuo (a cada sincronização)
---------------------------------------------------------------------------------

function E.aplicar(estado)
	local fase, n, d = estado.fase, estado.task, estado.dados or {}
	local m1, m2 = estado.missao == 1, estado.missao == 2
	local emTask = fase == "Task"
	tremor, modoLuz, giroEstrelas = 0, "normal", 0.01
	local loops = {}
	for _, b in ejects do b.ligado = false end
	local plasmaOn = false

	if fase == "Lancamento" then
		tremor = 0.35
		loops.rumble = true
	elseif emTask and m1 and n == 1 then
		tremor, modoLuz, giroEstrelas = 0.08, "alerta", 0.9
		loops.alarm = true
	elseif emTask and m1 and n == 2 then
		loops.static = true
		if ejects.Radio then ejects.Radio.ligado = true end
	elseif emTask and m1 and n == 3 then
		loops.alarm_fast = true
		if ejects.Reentry then ejects.Reentry.ligado = true end
		if d.decidiu then
			-- Manter: cabine vermelha de calor, tremor; Escudo e 2+ jogadores reduzem
			modoLuz, plasmaOn = "calor", true
			loops.rumble = true
			tremor = 0.45 * (d.escudo and 0.5 or 1) * ((d.segurando or 0) >= 2 and 0.5 or 1)
		else
			modoLuz = "alerta"
		end
	elseif emTask and m2 and n == 1 then
		loops.alarm_fast = (d.pressao or 0) >= 0.9
	elseif emTask and m2 and n == 3 then
		modoLuz = "alerta"
		loops.alarm = true
	end
	for _, p in plasma do p.Enabled = plasmaOn end
	Audio.setLoops(loops)
end

-- efeitos pontuais
function E.pulso(nome, dados)
	if nome == "Lancamento" then
		tremorPulso, tremorPulsoFim = 0.6, os.clock() + (dados.duracao or 3)
	elseif nome == "PontoTravado" or nome == "CaboPreso" or nome == "EscotilhaFechada" then
		Audio.play("confirm")
	elseif nome == "RadioOk" then
		Audio.play("squelch")
		Audio.play("confirm")
	elseif nome == "Acoplado" or nome == "FuroVedado" or nome == "TaskConcluida" then
		Audio.play("confirm")
	elseif nome == "CaboEscorregou" or nome == "EsferaEscorregou" or nome == "Falha" then
		Audio.play("error")
		tremorPulso, tremorPulsoFim = 0.3, os.clock() + 0.4
	end
end

---------------------------------------------------------------------------------
-- Quadro a quadro
---------------------------------------------------------------------------------

local function atualizarCabos()
	if missaoId ~= 2 or not nave then return end
	local ancora = nave:FindFirstChild("Exterior") and nave.Exterior:FindFirstChild("TetherAnchor")
	if not ancora then return end
	local a0 = ancora:FindFirstChild("RookieTether")
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = "RookieTether"
		a0.Parent = ancora
	end
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local emEva = p:GetAttribute("RookieEVA") == true and root ~= nil
		local beam = cabos[p]
		if emEva and not (beam and beam.Parent and beam.Attachment1 and beam.Attachment1.Parent == root) then
			if beam then beam:Destroy() end
			local a1 = root:FindFirstChild("RookieTether") or Instance.new("Attachment")
			a1.Name = "RookieTether"
			a1.Parent = root
			beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Width0, beam.Width1 = 0.15, 0.15
			beam.Color = ColorSequence.new(Color3.fromHex("F2F2F2"))
			beam.CurveSize0, beam.CurveSize1 = 3, -3
			beam.Segments = 12
			beam.FaceCamera = true
			beam.Parent = ancora
			cabos[p] = beam
		elseif not emEva and beam then
			beam:Destroy()
			cabos[p] = nil
		end
	end
end

function E.quadro(dt)
	local t = os.clock()
	-- luzes
	for _, l in luzes do
		if modoLuz == "alerta" then
			local a = 0.5 + 0.5 * math.sin(t * 6)
			l.luz.Color = Color3.fromHex("FF2A1F")
			l.luz.Brightness = l.brilho * (0.4 + a)
		elseif modoLuz == "calor" then
			l.luz.Color = Color3.fromHex("FF6A1F")
			l.luz.Brightness = l.brilho * (1.1 + 0.25 * math.sin(t * 13))
		else
			l.luz.Color = l.cor
			l.luz.Brightness = l.brilho
		end
	end
	-- botões EJECT piscando
	for _, b in ejects do
		if b.ligado then
			b.peca.Color = (math.floor(t * 3) % 2 == 0) and Color3.fromHex("FF2A1F") or Color3.fromHex("5A0E0A")
		else
			b.peca.Color = b.cor
		end
	end
	-- estrelas
	if estrelas then
		local cf = estrelas:GetPivot()
		estrelas:PivotTo(cf * CFrame.Angles(giroEstrelas * dt * 0.3, giroEstrelas * dt, 0))
	end
	-- tremor de câmera
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		local intensidade = tremor
		if t < tremorPulsoFim then intensidade = math.max(intensidade, tremorPulso) end
		if intensidade > 0 then
			hum.CameraOffset = Vector3.new(
				math.noise(t * 9, 0.3) * intensidade,
				math.noise(0.7, t * 9) * intensidade,
				math.noise(t * 9, 4.1) * intensidade * 0.5
			)
		else
			hum.CameraOffset = Vector3.zero
		end
	end
	atualizarCabos()
end

function E.iniciar(configAudio)
	Audio.init(configAudio)
	-- a Terra da ISS começa escondida (espera a nave chegar pelo streaming)
	task.spawn(function()
		for _ = 1, 30 do
			if #pecasTerra() > 0 then break end
			task.wait(1)
		end
		if missaoId ~= 2 then E.mostrarTerra(false) end
	end)
end

return E
