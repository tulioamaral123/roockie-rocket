--[[
	Carregador das Fases 3–6, 8 e 9 (cole no Command Bar do Roblox Studio, modo Edit).

	Pré-requisito: servir esta pasta localmente, num terminal:
	    cd ~/Documents/nasa/build && python3 -m http.server 8765 --bind 127.0.0.1

	As Fases 1 e 2 são autônomas: cole phase1_structure.luau e depois phase2_architecture.luau
	direto no Command Bar. Reexecutar a Fase 1 apaga e recria o Map inteiro;
	nesse caso, rode também as fases seguintes, em ordem.
]]

local PHASES = { "phase3_elements.luau", "phase4_decoration.luau", "phase5_lighting.luau", "phase6_interactivity.luau", "phase8_crew.luau", "phase9_transport.luau" }

local H = game:GetService("HttpService")
local function get(f) return H:GetAsync("http://127.0.0.1:8765/" .. f .. "?t=" .. os.clock(), true) end
local lib = assert(loadstring(get("lib.luau"), "lib"))()
for _, f in PHASES do
	print(assert(loadstring(get(f), f))(lib))
	task.wait()
end
