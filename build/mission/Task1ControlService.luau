--[[
	Task1ControlService — falha do piloto automático (missaoUm.md §3).

	Fases: t1_alert (desligar o piloto automático) → t1_manual (pontos de referência) → t1_done.
	- Os pontos são sorteados aqui, em coordenadas do mostrador (x, y em −1..1, y para cima);
	  o cliente só detecta o olhar e avisa ("Gaze", índice). O servidor exige a ordem e o tempo
	  mínimo de foco desde a ativação do ponto.
	- Combustível: o cliente informa o nível de movimento da câmera ("Motion", 0..2) a 4 Hz;
	  o servidor limita o valor e calcula o consumo (sem relato recente conta como parado).
	- Falhas: combustível em 0 ou tempo limite (desde o alerta).
]]

local T = {}

-- regiões dos pontos: quadrantes (sorteados) e, por último, o centro
local QUADS = { { 1, 1 }, { 1, -1 }, { -1, -1 }, { -1, 1 } }

local function genPoints(cfg)
	local rng = Random.new()
	local order = table.clone(QUADS)
	for i = #order, 2, -1 do
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local pts = {}
	local r = cfg.PointRadius
	for i = 1, math.max(cfg.Points - 1, 0) do
		local q = order[(i - 1) % #order + 1]
		-- dentro do quadrante, entre 45 % e 100 % de r em cada eixo, e no máximo r do centro
		local x = q[1] * rng:NextNumber(0.45, 1) * r
		local y = q[2] * rng:NextNumber(0.45, 1) * r
		local d = math.sqrt(x * x + y * y)
		if d > r then x, y = x * r / d, y * r / d end
		table.insert(pts, { math.floor(x * 100) / 100, math.floor(y * 100) / 100 })
	end
	table.insert(pts, { math.floor(rng:NextNumber(-0.08, 0.08) * 100) / 100, math.floor(rng:NextNumber(-0.08, 0.08) * 100) / 100 })
	return pts
end

function T.start(M, s)
	local cfg = M.Config.Task1
	s.t1 = { fuel = cfg.FuelStart, points = genPoints(cfg), index = 0, motion = 0, motionAt = 0, activeSince = 0 }
	s.view = { fuel = cfg.FuelStart, points = s.t1.points, index = 0, manual = false }
	M.setPhase(s, "t1_alert", { endsAt = M.now() + cfg.TimeLimit })
end

function T.action(M, s, kind, arg)
	local st, cfg = s.t1, M.Config.Task1
	if kind == "Autopilot" and s.phase == "t1_alert" then
		st.index, st.activeSince = 1, M.now()
		s.view.index, s.view.manual = 1, true
		M.setPhase(s, "t1_manual")
	elseif kind == "Gaze" and s.phase == "t1_manual" then
		if arg ~= st.index then return end
		-- tempo mínimo de foco (com folga para latência e arredondamento do cliente)
		if M.now() - st.activeSince < cfg.FocusTime - 0.15 then return end
		st.index += 1
		st.activeSince = M.now()
		s.view.index = st.index
		if st.index > #st.points then
			s.view.fuel = math.floor(st.fuel * 10) / 10
			s.endsAt = nil
			M.setPhase(s, "t1_done")
			M.taskDone(s)
		else
			M.send(s)
		end
	elseif kind == "Motion" and s.phase == "t1_manual" then
		if type(arg) ~= "number" or arg ~= arg then return end
		st.motion = math.clamp(arg, 0, 2)
		st.motionAt = M.now()
	end
end

function T.tick(M, s, dt)
	local st, cfg = s.t1, M.Config.Task1
	if not st then return end
	if (s.phase == "t1_alert" or s.phase == "t1_manual") and s.endsAt and M.now() >= s.endsAt then
		M.fail(s, "t1_time")
		return
	end
	if s.phase ~= "t1_manual" then return end
	local m = (M.now() - st.motionAt < 1) and st.motion or 0
	local burn = cfg.FuelBurnIdle + cfg.FuelBurnCorrection * math.min(m, 1) + cfg.FuelBurnExcess * math.max(m - 1, 0)
	st.fuel = math.max(0, st.fuel - burn * dt)
	s.view.fuel = math.floor(st.fuel * 10) / 10
	s.view.burn = burn
	s.dirty = true
	if st.fuel <= 0 then M.fail(s, "fuel") end
end

return T
