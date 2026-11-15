--[[
	MenuMouse — libera o mouse quando há um menu aberto, mesmo em primeira pessoa.

	Em primeira pessoa (ou com shift-lock) o Roblox prende o cursor no centro. Com o botão direito
	apertado, a câmera volta a girar (dá para olhar em volta durante o diálogo). Um GuiButton
	visível com Modal = true solta o cursor; este módulo mantém um botão invisível assim e só o
	deixa visível enquanto algum menu da lista estiver aberto. "Aberto" = ScreenGui ligado com
	algum botão ou caixa de texto realmente visível (todos os ancestrais visíveis).

	Menus: diálogo e escolha de missão (guias), telas do Rookie Rocket (Preparação, rádio,
	Canadarm, modais, álbum, créditos) e painel do museu. HUDs (objetivo, botões fixos) ficam fora.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local MenuMouse = {}

local MENUS = {
	DialogueGui = true,
	MissionSelectGui = true,
	RookiePreparacao = true,
	RookieRadio = true,
	RookieCanadarm = true,
	RookieModais = true,
	RookieAlbum = true,
	RookieCreditos = true,
	MuseumPanel = true,
}

local function shown(o, gui)
	local x = o
	while x and x ~= gui do
		if x:IsA("GuiObject") and not x.Visible then return false end
		x = x.Parent
	end
	return true
end

local function isOpen(gui)
	if not gui:IsA("ScreenGui") or not gui.Enabled then return false end
	for _, d in gui:GetDescendants() do
		if (d:IsA("GuiButton") or d:IsA("TextBox")) and d.Name ~= "MenuMouseModal"
			and d.AbsoluteSize.X > 0 and shown(d, gui) then
			return true
		end
	end
	return false
end

function MenuMouse.start()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local holder = Instance.new("ScreenGui")
	holder.Name = "MenuMouse"
	holder.ResetOnSpawn = false
	holder.DisplayOrder = 0
	holder.Parent = pg
	local modal = Instance.new("TextButton")
	modal.Name = "MenuMouseModal"
	modal.Text = ""
	modal.BackgroundTransparency = 1
	modal.Size = UDim2.fromOffset(1, 1)
	modal.Position = UDim2.fromScale(0, 1)
	modal.AnchorPoint = Vector2.new(0, 1)
	modal.Active = false
	modal.Selectable = false
	modal.Modal = true
	modal.Visible = false
	modal.Parent = holder

	task.spawn(function()
		while true do
			local open = false
			for _, gui in pg:GetChildren() do
				if MENUS[gui.Name] and isOpen(gui) then
					open = true
					break
				end
			end
			if modal.Visible ~= open then
				modal.Visible = open
				if open then
					UIS.MouseIconEnabled = true
					-- a câmera em primeira pessoa prende o mouse a cada quadro: solta depois dela.
					-- A tela continua mexendo: com o botão direito apertado a câmera gira (em
					-- primeira pessoa ou terceira), e em terceira pessoa nada é forçado.
					RunService:BindToRenderStep("MenuMouseFree", Enum.RenderPriority.Last.Value, function()
						local looking = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
						modal.Modal = not looking
						if not looking and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
							UIS.MouseBehavior = Enum.MouseBehavior.Default
						end
						UIS.MouseIconEnabled = true
					end)
				else
					pcall(function() RunService:UnbindFromRenderStep("MenuMouseFree") end)
					modal.Modal = true
				end
			end
			task.wait(0.2)
		end
	end)
end

return MenuMouse
