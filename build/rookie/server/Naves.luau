--[[
	Naves — acesso às peças do contrato (docs/rookie-contrato.md) e utilitários do servidor:
	achar peça por caminho, criar ProximityPrompt, testar "jogador a bordo", teleportar.
]]

local Players = game:GetService("Players")

local Naves = {}

-- peça por caminho "Stations/Radio/Keypad" (espera até 10 s; erro claro se faltar)
function Naves.peca(raiz, caminho)
	local atual = raiz
	for nome in string.gmatch(caminho, "[^/]+") do
		local prox = atual:FindFirstChild(nome) or atual:WaitForChild(nome, 10)
		if not prox then
			error(("[RookieRocket] peça ausente: %s/%s (ver docs/rookie-contrato.md)"):format(raiz:GetFullName(), caminho))
		end
		atual = prox
	end
	return atual
end

-- peça opcional (nil se não existir)
function Naves.talvez(raiz, caminho)
	local atual = raiz
	for nome in string.gmatch(caminho, "[^/]+") do
		atual = atual and atual:FindFirstChild(nome)
	end
	return atual
end

-- filhos numerados em ordem: Point1, Point2, ...
function Naves.numerados(pasta, prefixo)
	local lista = {}
	local i = 1
	while true do
		local p = pasta:FindFirstChild(prefixo .. i)
		if not p then break end
		lista[i] = p
		i += 1
	end
	return lista
end

-- posição de uma peça ou modelo
function Naves.posicao(x)
	if x:IsA("BasePart") then return x.Position end
	return x:GetPivot().Position
end

-- ProximityPrompt numa peça (o gerador não cria prompts)
function Naves.prompt(peca, acao, objeto, opcoes)
	opcoes = opcoes or {}
	local alvo = peca
	if peca:IsA("Model") then alvo = peca.PrimaryPart or peca:FindFirstChildWhichIsA("BasePart", true) end
	local p = Instance.new("ProximityPrompt")
	p.Name = "RookiePrompt"
	p.ActionText = acao
	p.ObjectText = objeto or ""
	p.HoldDuration = opcoes.segurar or 0
	p.MaxActivationDistance = opcoes.distancia or 7
	p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = opcoes.tecla or Enum.KeyCode.E
	p.Enabled = opcoes.ligado ~= false
	if opcoes.painel then p:SetAttribute("RookiePainel", opcoes.painel) end -- o cliente abre a UI
	p.Parent = alvo
	return p
end

-- ponto dentro de uma caixa (Part orientada)
function Naves.dentro(caixa, ponto, folga)
	folga = folga or 0
	local local_ = caixa.CFrame:PointToObjectSpace(ponto)
	local meia = caixa.Size / 2 + Vector3.new(folga, folga, folga)
	return math.abs(local_.X) <= meia.X and math.abs(local_.Y) <= meia.Y and math.abs(local_.Z) <= meia.Z
end

function Naves.raiz(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

function Naves.vivo(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

-- teleporta o personagem para um CFrame (com streaming: pede a região antes)
function Naves.teleportar(player, cf, stillValid)
	local char = player.Character
	if not char or not char.PrimaryPart then return false end
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 5)
	end)
	if player.Parent ~= Players or player.Character ~= char or (stillValid and not stillValid()) then return false end
	-- sentado: solta do assento antes (a solda arrastaria o assento junto)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart then
		local weld = hum.SeatPart:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end
		hum.Sit = false
	end
	char:PivotTo(cf + Vector3.new(0, 3, 0))
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	return true
end

-- distância do jogador até uma peça (math.huge se sem personagem)
function Naves.distancia(player, peca)
	local root = Naves.raiz(player)
	if not root then return math.huge end
	return (root.Position - Naves.posicao(peca)).Magnitude
end

return Naves
