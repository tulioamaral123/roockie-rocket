-- Feedback curto, sem cobrir os controles de movimento ou abrir menus.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("AstronautTrainingFeedback")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "AstronautTraining", false, 12
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
local label = Instance.new("TextLabel")
label.AnchorPoint, label.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.24)
label.Size = UDim2.new(0.72, 0, 0, 88)
label.BackgroundColor3 = Color3.fromHex("101D3D")
label.BackgroundTransparency, label.BorderSizePixel = 0.08, 0
label.TextColor3, label.TextSize = Color3.new(1, 1, 1), 18
label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
label.TextWrapped, label.Visible = true, false
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius, corner.Parent = UDim.new(0, 10), label
local padding = Instance.new("UIPadding")
padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
padding.Parent = label
local stroke = Instance.new("UIStroke")
stroke.Color, stroke.Thickness, stroke.Parent = Color3.fromHex("397EC4"), 1, label
gui.Parent = player:WaitForChild("PlayerGui")
local revision = 0
remote.OnClientEvent:Connect(function(text)
	if type(text) ~= "string" then return end
	revision += 1
	local current = revision
	label.Text, label.Visible = text, true
	task.delay(7, function() if revision == current then label.Visible = false end end)
end)
player.CharacterRemoving:Connect(function()
	revision += 1
	label.Visible = false
end)
