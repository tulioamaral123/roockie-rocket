--[[
	GazeInteractionController — Tarefa 1: detecção dos pontos pelo olhar.
	- A cada quadro (depois da câmera, antes da vibração) mede o ângulo entre a direção da câmera
	  e o ponto ativo; com o ângulo abaixo de FocusAngle por FocusTime, avisa o servidor
	  (MissionAction "Gaze", índice). Fora do ponto o foco cai rápido.
	- Mede também a velocidade angular da câmera e informa o nível de movimento a 4 Hz
	  (MissionAction "Motion": 0 parado, 1 corrigindo, 1..2 excessivo), usado no consumo de combustível.
]]

local RunService = game:GetService("RunService")

local G = {}
local cfg, remote
local active = false
local index, sentFor, sentAt = 0, nil, 0
local worldOf -- function(i) -> Vector3
local onDwell -- function(i, fração)
local dwell = 0
local lastLook
local sumAngle, sumTime, lastLevel, lastReport = 0, 0, -1, 0

function G.init(config, actionRemote)
	cfg, remote = config.Task1, actionRemote
end

-- pontos: worldFn(i) dá a posição no mundo do ponto i; dwellFn(i, f) desenha o foco
function G.begin(worldFn, dwellFn)
	worldOf, onDwell = worldFn, dwellFn
	active, dwell, sentFor, lastLook = true, 0, nil, nil
	sumAngle, sumTime, lastLevel, lastReport = 0, 0, -1, 0
	RunService:UnbindFromRenderStep("F7Gaze")
	RunService:BindToRenderStep("F7Gaze", Enum.RenderPriority.Camera.Value + 1, G.step)
end

function G.setIndex(i)
	if i ~= index then
		index, dwell = i, 0
	end
end

function G.finish()
	if active then RunService:UnbindFromRenderStep("F7Gaze") end
	active, worldOf, onDwell = false, nil, nil
	if remote and lastLevel ~= 0 then remote:FireServer("Motion", 0) end
	lastLevel = 0
end

-- ângulo (graus) entre a câmera e um ponto do mundo
function G.angleTo(cf, p)
	local d = (p - cf.Position).Unit
	return math.deg(math.acos(math.clamp(cf.LookVector:Dot(d), -1, 1)))
end

function G.step(dt)
	if not active or dt <= 0 then return end
	local cam = workspace.CurrentCamera
	local cf = cam.CFrame
	-- movimento da câmera
	local look = cf.LookVector
	if lastLook then
		sumAngle += math.deg(math.acos(math.clamp(look:Dot(lastLook), -1, 1)))
		sumTime += dt
	end
	lastLook = look
	local t = os.clock()
	if sumTime >= 0.25 then
		local speed = sumAngle / sumTime
		sumAngle, sumTime = 0, 0
		local level = 0
		if speed >= cfg.ExcessSpeed then
			level = 1 + math.clamp((speed - cfg.ExcessSpeed) / (cfg.ExcessSpeedMax - cfg.ExcessSpeed), 0, 1)
		elseif speed >= cfg.CorrectionSpeed then
			level = 1
		end
		level = math.floor(level * 10 + 0.5) / 10
		if level ~= lastLevel or t - lastReport > 0.9 then
			lastLevel, lastReport = level, t
			remote:FireServer("Motion", level)
		end
	end
	-- foco no ponto ativo
	if not worldOf or index < 1 then return end
	local p = worldOf(index)
	if not p then return end
	if G.angleTo(cf, p) <= cfg.FocusAngle then
		dwell = math.min(cfg.FocusTime, dwell + dt)
	else
		dwell = math.max(0, dwell - dt * 2.5)
	end
	if onDwell then onDwell(index, dwell / cfg.FocusTime) end
	-- reenvia depois de 1 s se o servidor ainda não avançou (mensagem perdida ou cedo demais)
	if dwell >= cfg.FocusTime and (sentFor ~= index or t - sentAt > 1) then
		sentFor, sentAt = index, t
		remote:FireServer("Gaze", index)
	end
end

return G
