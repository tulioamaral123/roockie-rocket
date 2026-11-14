--[[
	NASA Space Adventure — Fase 13: acabamento (spec-v3, Etapa 6)

	1. SafetyZones (spec-v3 §11): volumes invisíveis, sem colisão/query/touch, com atributos
	   descritivos. Preparam o PlayerSafetyController futuro (fora do escopo desta versão, §15).
	   - VABObservationZone        sala de observação do VAB + passarela (área segura fora do envelope)
	   - VABEnvelopeZone           envelope do conjunto de transporte no VAB
	   - RouteExclusionZone        rota do crawler (VAB → plataforma)
	   - CrawlerParkingZone        baia do estacionamento do crawler (centro 90, 0, 620)
	   - LaunchPadObservationZone  área de observação da plataforma (Visitor_Paths.Pad_Observation)
	2. Sinalização do percurso dentro do VAB (placas DECOR, sem colisão, fora do envelope e da rota):
	   quadro de direções suspenso na treliça da entrada, linha de piso até o vestiário, placa do
	   elevador de serviço, placa da saída de pedestres e painel "One rocket, one journey".
	3. Otimização: CastShadow = false em peças pequenas (< 2 studs) e decorativas sem colisão;
	   CanTouch = false em peças ancoradas (nenhum script usa Touched). CanCollide e CanQuery
	   não são alterados. O TransportAssembly fica de fora do passe.

	Executar depois das Fases 1–12. Idempotente: B.clear remove o que a fase criou, e o passe de
	otimização só define propriedades como false (reaplicar não tem efeito cumulativo).
]]

local lib = ...
local B = lib.builder(13)

local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–12 antes")
B.clear(Map)

local Hangar = Map.VABHangar
local DECOR_NS = { collide = false, shadow = false }
local N = Enum.NormalId

---------------------------------------------------------------------------------
-- 1. SafetyZones
---------------------------------------------------------------------------------
local Zones = Map:FindFirstChild("SafetyZones")
if Zones and Zones:GetAttribute("BuildPhase") == nil then
	-- pasta antiga sem dono: recriada por esta fase
	Zones:Destroy()
	Zones = nil
end
Zones = Zones or B.group(Map, "SafetyZones", "Folder")

local function zone(name, x0, x1, y0, y1, z0, z1, kind, purpose, color)
	local p = B.box(Zones, name, x0, x1, y0, y1, z0, z1, color, "SmoothPlastic",
		{ collide = false, shadow = false, transparency = 1 })
	p:SetAttribute("SafetyZone", true)
	p:SetAttribute("ZoneType", kind) -- "Safe" | "Exclusion" | "Restricted"
	p:SetAttribute("Purpose", purpose)
	p:SetAttribute("Min", Vector3.new(x0, y0, z0))
	p:SetAttribute("Max", Vector3.new(x1, y1, z1))
	return p
end

zone("VABObservationZone", 44, 70, 34, 46, 238, 277, "Safe",
	"Sala de observação do VAB e passarela (fora do envelope do conjunto). Ponto seguro para assistir à montagem e à saída do crawler.",
	"#2E9E4F")
zone("VABEnvelopeZone", -34, 34, 0, 133, 230, 320, "Restricted",
	"Envelope do conjunto crawler + mobile launcher + SLS dentro do VAB. Acesso só pela tripulação (escada lateral, elevador e braço).",
	"#E5B52E")
zone("RouteExclusionZone", -40, 40, 0, 140, 320, 722, "Exclusion",
	"Rota do crawler entre o VAB e a plataforma. Visitantes devem sair desta faixa quando o conjunto estiver em movimento.",
	"#D33D32")
zone("CrawlerParkingZone", 67, 113, 0, 40, 594, 646, "Restricted",
	"Baia de estacionamento do crawler depois de deixar o conjunto na plataforma (centro 90, 0, 620).",
	"#D9822B")
zone("LaunchPadObservationZone", -140, -95, 0, 15, 640, 720, "Safe",
	"Área de observação da plataforma de lançamento (Visitor_Paths.Pad_Observation). Ponto seguro para assistir ao lançamento.",
	"#2E9E4F")

---------------------------------------------------------------------------------
-- 2. Sinalização do percurso (VAB)
---------------------------------------------------------------------------------
local Sig = B.group(Hangar, "Wayfinding_VAB")

-- 2a. Quadro de direções suspenso na treliça da entrada (Roof_Truss Z 221.2..222.8, Y 143).
--     Fica sobre o corredor de entrada, entre o portão (Z 213.5) e o envelope (Z 230).
--     Quem entra olha para +Z, então −X (vestiário, elevador, saída) fica à direita.
--     Deslocado para X −24..−4: no eixo ele tapava o estágio central visto do portão
--     (spec-v3 §2.3); a esta distância a silhueta do SLS ocupa só |X| ≤ 2,2.
local DX0, DX1 = -24, -4
local dir = B.group(Sig, "Entrance_Directory")
local board = B.box(dir, "Board", DX0, DX1, 10.5, 16.5, 221.8, 222.2, "space", "SmoothPlastic", DECOR_NS)
B.sign(board, "VEHICLE ASSEMBLY BUILDING",
	"CREW SUIT-UP ROOM  →\nSERVICE ELEVATOR · LEVEL 60  →\nPEDESTRIAN EXIT · PAD OBSERVATION  →\nOBSERVATION ROOM  ←",
	{ face = N.Front, accent = "nasaBlue", titleColor = "lightBlue", titleScale = 0.22, maxBody = 60 })
B.sign(board, "VEHICLE ASSEMBLY BUILDING", "EXIT TO CONTROL CENTER  ↓", { face = N.Back, accent = "nasaBlue", titleScale = 0.3 })
B.box(dir, "Frame_Top", DX0 - 0.2, DX1 + 0.2, 16.5, 16.8, 221.7, 222.3, "metalGray", "Metal", DECOR_NS)
B.box(dir, "Frame_Bottom", DX0 - 0.2, DX1 + 0.2, 10.2, 10.5, 221.7, 222.3, "metalGray", "Metal", DECOR_NS)
for _, x in { DX0 + 2, DX1 - 2 } do
	B.cyl(dir, "Hanger_Cable", x, 222, 16.8, 143, 0.15, "darkGray", "Metal", DECOR_NS)
end

-- 2b. Linha de piso até o vestiário (fora do envelope: Z < 230 e depois X < −34)
local crew = B.group(Sig, "Crew_Floor_Guide")
B.box(crew, "Guide_Line", -41.25, -12.6, 0.02, 0.08, 225.75, 226.25, "lightBlue", "SmoothPlastic", DECOR_NS)
B.box(crew, "Guide_Line", -41.25, -40.75, 0.02, 0.08, 226.25, 244, "lightBlue", "SmoothPlastic", DECOR_NS)
-- girada 90° em Y para o texto ficar de pé para quem vem do portão (olhando +Z)
local label = B.part(crew, "Floor_Label", CFrame.new(-26, 0.055, 228.1) * CFrame.Angles(0, math.pi / 2, 0),
	Vector3.new(2.6, 0.07, 12), "nasaBlue", "SmoothPlastic", DECOR_NS)
B.sign(label, "CREW SUIT-UP ROOM  →", nil, { face = N.Top, bg = "nasaBlue", titleColor = "white" })

-- 2c. Elevador de serviço: placa na face −Z do poço (postes em Z 262..262.5), acima do teto do vestiário (Y 9.3)
local svc = B.box(Sig, "Service_Elevator_Sign", -45.5, -40.2, 14, 17, 261.7, 261.95, "safety", "SmoothPlastic", DECOR_NS)
B.sign(svc, "SERVICE ELEVATOR", "Level 60 · doors on the far side of the tower", {
	face = N.Front, bg = "safety", titleColor = "black", bodyColor = "black", titleScale = 0.4, maxBody = 50,
})

-- 2d. Saída de pedestres: placa na parede esquerda (X −70), entre os pilares Z 267..287.
--     Quem olha para −X tem +Z (a porta, Z 296..302) à esquerda.
local ped = B.box(Sig, "Pedestrian_Exit_Sign", -70, -69.8, 5.5, 10, 274, 286, "#2E9E4F", "SmoothPlastic", DECOR_NS)
B.sign(ped, "←  PEDESTRIAN EXIT", "Pad Observation · visitor path", {
	face = N.Right, bg = "#2E9E4F", titleColor = "white", bodyColor = "white", titleScale = 0.4, maxBody = 60,
})

-- 2e. Painel do conjunto de transporte: entre os pilares da sala de observação (X 45, Z 240.5..259.5)
local info = B.group(Sig, "Transport_Assembly_Panel")
local panel = B.box(info, "Panel", 44.8, 45, 3, 13, 241, 259, "space", "SmoothPlastic", DECOR_NS)
B.sign(panel, "ONE ROCKET, ONE JOURNEY",
	"Here the SLS is stacked on the Mobile Launcher, and both ride on the Crawler-Transporter.\n"
		.. "The crawler carries the whole assembly out of the back gate, along the crawlerway, and sets it down on the launch pad.\n"
		.. "Stay behind the yellow lines: the assembly zone and the crawler route are off-limits to visitors.",
	{ face = N.Left, accent = "red", titleColor = "lightBlue", titleScale = 0.18, maxBody = 34 })
B.box(info, "Trim_Top", 44.7, 45, 13, 13.3, 240.8, 259.2, "nasaBlue", "Metal", DECOR_NS)
B.box(info, "Trim_Bottom", 44.7, 45, 2.7, 3, 240.8, 259.2, "nasaBlue", "Metal", DECOR_NS)

---------------------------------------------------------------------------------
-- 3. Otimização (CastShadow / CanTouch)
---------------------------------------------------------------------------------
local skip = Map:FindFirstChild("TransportSystem") and Map.TransportSystem:FindFirstChild("TransportAssembly")
local stats = { scanned = 0, shadowOff = 0, touchOff = 0 }
for _, d in Map:GetDescendants() do
	if d:IsA("BasePart") and not (skip and d:IsDescendantOf(skip)) then
		stats.scanned += 1
		local s = d.Size
		local small = math.max(s.X, s.Y, s.Z) < 2
		if d.CastShadow and (small or not d.CanCollide) then
			d.CastShadow = false
			stats.shadowOff += 1
		end
		if d.Anchored and d.CanTouch then
			d.CanTouch = false
			stats.touchOff += 1
		end
	end
end

---------------------------------------------------------------------------------
-- Resumo
---------------------------------------------------------------------------------
local parts, guis = 0, 0
for _, d in Map:GetDescendants() do
	if d:GetAttribute("BuildPhase") == 13 then
		if d:IsA("BasePart") then parts += 1 end
	end
	if d:IsA("SurfaceGui") and d.Parent and d.Parent:GetAttribute("BuildPhase") == 13 then guis += 1 end
end
return string.format("Fase 13: %d peças, %d SurfaceGuis, 0 luzes | otimização: %d peças varridas, CastShadow→false %d, CanTouch→false %d",
	parts, guis, stats.scanned, stats.shadowOff, stats.touchOff)
