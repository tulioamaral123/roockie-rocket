--[[
	GuideClient — cliente dos NPCs guias (docs/guias-spec.md): seta vermelha + objetivo,
	diálogos e escolha da missão. Não decide progresso: só desenha o que o servidor manda.
]]

local RS = game:GetService("ReplicatedStorage")

-- celular e tablet: jogo sempre na horizontal (vira para os dois lados conforme o aparelho)
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
RS:WaitForChild("GuideSystem"):WaitForChild("Remotes")

for _, name in { "DialogueGui", "NavigationClient", "MissionSelect", "MenuMouse", "Mirror", "MuseumCutscene", "ArrivalCutscene" } do
	local ok, err = pcall(function() require(script.Parent:WaitForChild(name)).start() end)
	if not ok then warn("[GuideSystem] " .. name .. ":", err) end
end
