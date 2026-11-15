--[[
	GuideBoot — NPCs guias e apresentação do complexo (docs/guias-spec.md, docs/guias-contrato.md).
	Cria ReplicatedStorage.GuideSystem.Remotes (NavigationUpdate, DialogueEvent, MissionSelect)
	e inicia ProgressService, NPCService e NavigationService.
]]

local RS = game:GetService("ReplicatedStorage")

local GS = RS:WaitForChild("GuideSystem")

local function ensure(parent, class, name)
	local x = parent:FindFirstChild(name)
	if x and not x:IsA(class) then
		x:Destroy()
		x = nil
	end
	if not x then
		x = Instance.new(class)
		x.Name = name
		x.Parent = parent
	end
	return x
end

local folder = ensure(GS, "Folder", "Remotes")
local remotes = {}
for _, n in { "NavigationUpdate", "DialogueEvent", "MissionSelect" } do
	remotes[n] = ensure(folder, "RemoteEvent", n)
end

local ProgressService = require(script.Parent:WaitForChild("ProgressService"))
local NPCService = require(script.Parent:WaitForChild("NPCService"))
local NavigationService = require(script.Parent:WaitForChild("NavigationService"))

ProgressService.start()
NPCService.start(ProgressService, remotes)
NavigationService.start(ProgressService, remotes, NPCService)

-- Só no Studio: atalho de teste para pular etapas (ServerStorage.GuideDebug.SetStage:Invoke(player, etapa))
if game:GetService("RunService"):IsStudio() then
	local dbg = ensure(game:GetService("ServerStorage"), "Folder", "GuideDebug")
	ensure(dbg, "BindableFunction", "SetStage").OnInvoke = function(player, stage)
		ProgressService.set(player, stage)
		return ProgressService.get(player)
	end
end
