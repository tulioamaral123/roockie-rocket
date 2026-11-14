--[[
	CameraShakeController — vibração da câmera durante as emergências.
	Modelo de "trauma" (0..1): vibração = trauma², ruído suave, só rotação; aplicada depois da
	câmera padrão (RenderPriority.Camera + 2), então não acumula. Muda suavemente de intensidade.
	Com Reduce Motion (GuiService.ReducedMotionEnabled) a amplitude cai para 30 %.
]]

local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local S = {}
local trauma, target = 0, 0
local MAX_DEG = 2.2
local bound = false

function S.set(t)
	target = math.clamp(t or 0, 0, 1)
end

function S.start()
	if bound then return end
	bound = true
	RunService:BindToRenderStep("F7CameraShake", Enum.RenderPriority.Camera.Value + 2, function(dt)
		trauma += (target - trauma) * math.min(1, dt * 2.5)
		if trauma < 0.002 then return end
		local scale = GuiService.ReducedMotionEnabled and 0.3 or 1
		local k = trauma * trauma * MAX_DEG * scale
		local t = os.clock() * 13
		local cam = workspace.CurrentCamera
		cam.CFrame *= CFrame.Angles(
			math.rad(k * math.noise(t, 1.3)),
			math.rad(k * math.noise(t, 7.1)),
			math.rad(k * 0.6 * math.noise(t, 13.7))
		)
	end)
end

function S.stop()
	if bound then
		RunService:UnbindFromRenderStep("F7CameraShake")
		bound = false
	end
	trauma, target = 0, 0
end

return S
