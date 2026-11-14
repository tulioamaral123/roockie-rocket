--[[
	Teste de integração Linux → GitHub → Mac → Rojo → Studio (temporário).
	O Rojo cria este Script em ServerScriptService.IntegracaoLinux (ver default.project.json).
	Só lê o place: não cria, move nem apaga nada. Remover do projeto depois do teste.

	No Mac:
	  1. git pull da branch setup/linux-colaboracao (GitHub Desktop ou VS Code).
	  2. rojo serve + Connect no plugin: o Script aparece em ServerScriptService.
	  3. Play: o Output mostra "[integracao] OK".
]]

local ORIGEM = "Linux (ValterCauaAlves)"

local root = workspace:FindFirstChild("NASAComplex")
local parts, phases = 0, {}
if root then
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
		local p = d:GetAttribute("BuildPhase")
		if p ~= nil then
			phases[tostring(p)] = true
		end
	end
end

local list = {}
for p in phases do
	table.insert(list, p)
end
table.sort(list, function(a, b)
	return (tonumber(a) or math.huge) < (tonumber(b) or math.huge)
end)

local mission = game:GetService("ReplicatedStorage"):FindFirstChild("MissionSystem")

print(("[integracao] script escrito em %s rodou no Studio %s"):format(ORIGEM, version()))
print(("[integracao] NASAComplex: %s | %d peças | fases: %s"):format(
	root and "encontrado" or "NÃO encontrado",
	parts,
	#list > 0 and table.concat(list, ", ") or "nenhuma"
))
print(("[integracao] MissionSystem pelo Rojo: %s"):format(
	mission and mission:GetAttribute("RojoManaged") and "sim" or "não"
))
print(root and "[integracao] OK" or "[integracao] FALHOU: abra o Place1.rbxl antes de dar Play")
