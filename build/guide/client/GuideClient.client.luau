--[[
	GuideClient — cliente dos NPCs guias (docs/guias-spec.md): seta vermelha + objetivo,
	diálogos e escolha da missão. Não decide progresso: só desenha o que o servidor manda.
]]

local RS = game:GetService("ReplicatedStorage")
RS:WaitForChild("GuideSystem"):WaitForChild("Remotes")

for _, name in { "DialogueGui", "NavigationClient", "MissionSelect" } do
	local ok, err = pcall(function() require(script.Parent:WaitForChild(name)).start() end)
	if not ok then warn("[GuideSystem] " .. name .. ":", err) end
end
