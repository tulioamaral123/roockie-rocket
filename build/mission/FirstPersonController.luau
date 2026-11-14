--[[
	FirstPersonController — primeira pessoa durante a missão; restaura o modo anterior ao sair.
	Não altera os controles permanentemente: guarda e devolve CameraMode e zoom do jogador.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local F = {}
local saved

-- lookAt (opcional): ponto para onde a câmera vira ao entrar (o painel fica à vista, §2.1).
-- A câmera padrão parte da direção atual de Camera.CFrame, então basta ajustá-la depois do
-- passo da câmera por alguns quadros (até a primeira pessoa assentar).
function F.enter(lookAt)
	if saved then return end
	saved = { mode = player.CameraMode, minZoom = player.CameraMinZoomDistance, maxZoom = player.CameraMaxZoomDistance }
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	if lookAt then
		task.spawn(function()
			for _ = 1, 6 do
				RunService.RenderStepped:Wait()
				local cam = workspace.CurrentCamera
				cam.CFrame = CFrame.lookAt(cam.CFrame.Position, lookAt)
			end
		end)
	end
end

function F.exit()
	if not saved then return end
	player.CameraMode = saved.mode
	player.CameraMinZoomDistance = saved.minZoom
	player.CameraMaxZoomDistance = saved.maxZoom
	saved = nil
end

return F
