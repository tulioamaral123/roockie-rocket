--[[
	Task3ReentryService — alarme falso do escudo térmico (missaoUm.md §5).

	Fases: t3_alert (10 s para decidir) → t3_reentry (segurar MANTER por HoldTime) → t3_done.
	- A escolha chega por SubmitChoice ("Retain" | "Jettison") e só vale em t3_alert.
	- Na reentrada o cliente avisa quando aperta e solta o botão ("Hold", true/false); o servidor
	  conta o tempo: segurando sobe, solto desce (ReleaseDecay).
]]

local T = {}

function T.start(M, s)
	local cfg = M.Config.Task3
	s.t3 = { progress = 0, holding = false }
	s.view = { shield = cfg.ShieldReading, progress = 0, holding = false, holdTime = cfg.HoldTime }
	M.setPhase(s, "t3_alert", { endsAt = M.now() + cfg.DecisionTime })
end

function T.submitChoice(M, s, choice)
	if s.phase ~= "t3_alert" then return end
	if choice == "Jettison" then
		M.fail(s, "jettison")
	else
		s.endsAt = nil
		s.view.choice = "Retain"
		M.setPhase(s, "t3_reentry")
	end
end

function T.action(M, s, kind, arg)
	if kind == "Hold" and s.phase == "t3_reentry" and type(arg) == "boolean" then
		s.t3.holding = arg
		s.view.holding = arg
		M.send(s)
	end
end

function T.tick(M, s, dt)
	local cfg = M.Config.Task3
	if s.phase == "t3_alert" then
		if s.endsAt and M.now() >= s.endsAt then M.fail(s, "t3_time") end
	elseif s.phase == "t3_reentry" then
		local st = s.t3
		if st.holding then
			st.progress = math.min(cfg.HoldTime, st.progress + dt)
		else
			st.progress = math.max(0, st.progress - dt * cfg.ReleaseDecay)
		end
		s.view.progress = math.floor(st.progress / cfg.HoldTime * 1000) / 1000
		s.dirty = true
		if st.progress >= cfg.HoldTime then
			st.holding = false
			s.view.holding = false
			s.view.progress = 1
			M.setPhase(s, "t3_done")
			M.taskDone(s)
		end
	end
end

return T
