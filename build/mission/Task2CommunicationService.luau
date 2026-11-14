--[[
	Task2CommunicationService — blackout de comunicação (missaoUm.md §4).

	Fases: t2_blackout (cronômetro, papel com o código, terminal) → t2_done.
	- O código (formato M7-42-K9) é sorteado a cada tentativa e guardado aqui; vai só para o
	  cliente do próprio jogador, que o desenha no papel.
	- Validação no servidor: ignora maiúsculas/minúsculas, espaços e hífens.
	- Falhas: botão EJECT, tempo esgotado ou erros demais (MaxWrongAttempts; 0 = ilimitado).
]]

local T = {}

local function pick(rng, set)
	local i = rng:NextInteger(1, #set)
	return string.sub(set, i, i)
end

local function genCode(cfg)
	local rng = Random.new()
	local L, D = cfg.CodeLetters, cfg.CodeDigits
	return pick(rng, L) .. pick(rng, D) .. "-" .. pick(rng, D) .. pick(rng, D) .. "-" .. pick(rng, L) .. pick(rng, D)
end

local function normalize(text)
	return (string.gsub(string.upper(text), "[%s%-]", ""))
end

function T.start(M, s)
	local cfg = M.Config.Task2
	s.t2 = { code = genCode(cfg), wrong = 0 }
	s.view = { code = s.t2.code, wrong = 0, maxWrong = cfg.MaxWrongAttempts }
	M.setPhase(s, "t2_blackout", { endsAt = M.now() + cfg.Duration })
end

function T.submitCode(M, s, text)
	if s.phase ~= "t2_blackout" then return end
	local st, cfg = s.t2, M.Config.Task2
	if normalize(text) == normalize(st.code) then
		s.endsAt = nil
		s.view.result = "ok"
		M.setPhase(s, "t2_done")
		M.taskDone(s)
		return
	end
	st.wrong += 1
	s.view.wrong = st.wrong
	s.view.error = M.Config.Text.t2_wrong
	s.view.errorAt = M.now()
	if cfg.MaxWrongAttempts > 0 and st.wrong >= cfg.MaxWrongAttempts then
		M.fail(s, "attempts")
	else
		M.send(s)
	end
end

function T.action(M, s, kind)
	if kind == "Eject" and s.phase == "t2_blackout" then
		M.fail(s, "eject")
	end
end

function T.tick(M, s)
	if s.phase == "t2_blackout" and s.endsAt and M.now() >= s.endsAt then
		M.fail(s, "t2_time")
	end
end

return T
