--[[
	Boot do cliente do museu: carrega o progresso, liga os controladores e escuta o servidor.
]]

local RS = game:GetService("ReplicatedStorage")

local MS = RS:WaitForChild("MuseumSystem")
local Remotes = MS:WaitForChild("Remotes")
local Shared = MS:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("Text"))
local Content = require(Shared:WaitForChild("Content"))

local here = script.Parent
local UI = require(here:WaitForChild("UI"))
local State = require(here:WaitForChild("State"))
local Panel = require(here:WaitForChild("PanelController"))
local Show = require(here:WaitForChild("ShowController"))
local World = require(here:WaitForChild("WorldController"))
local Hud = require(here:WaitForChild("HudController"))

-- Progresso (o servidor espera o DataStore)
local progress
for _ = 1, 3 do
	local ok, p = pcall(function() return Remotes.GetProgress:InvokeServer() end)
	if ok and p then
		progress = p
		break
	end
	task.wait(2)
end
if progress then
	State.set(progress)
	UI.setTextLevel(progress.settings and progress.settings.textSize or 2)
	-- preferência salva das setas de navegação (lida pelo GuideClient)
	game:GetService("Players").LocalPlayer:SetAttribute("GuideArrows", not (progress.settings and progress.settings.arrows == false))
	if progress.noSave then UI.toast(Text.get("save.failed"), 6) end
end

World.start()
Hud.start()
-- painel e janela do HUD ocupam o mesmo canto: abrir um fecha o outro
Panel.onOpen = Hud.closeWindow
Hud.onWindowOpen = Panel.close

Remotes.OpenExhibit.OnClientEvent:Connect(function(id)
	if Show.isRunning() then return end
	Panel.openExhibit(id)
end)

Remotes.OpenCard.OnClientEvent:Connect(function(id)
	if Show.isRunning() then return end
	Panel.openCard(id)
end)

Remotes.StartShow.OnClientEvent:Connect(function(id)
	Show.start(id, Panel.close)
end)

Remotes.CardUnlocked.OnClientEvent:Connect(function(id)
	State.mark("cards", id)
	local c = Content.card(id)
	UI.toast(Text.get("card.new") .. (c and ("  (" .. c.Name .. ")") or ""), 6)
end)
