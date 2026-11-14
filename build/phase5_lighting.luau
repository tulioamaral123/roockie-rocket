--[[
	NASA Space Adventure — Fase 5: iluminação e atmosfera (spec §3.5, §5.5, §7.7, §11)
	- Recepção: branca e uniforme (painéis de teto com SurfaceLight).
	- Museu: mais escuro, azul indireto, céu estrelado na cúpula, focos nas exposições.
	- Corredor 2: luminárias industriais + luzes de emergência.
	- Hangar: luminárias de grande altura, focos no SLS, luz de serviço nas paredes.
	Poucas luzes com sombra (spec §11). LightingStyle = Realistic e bloom suave (opção B,
	escolhida por comparação medida; skill roblox-feel-audio-vfx §4). A antiga propriedade
	Lighting.Technology não existe mais: o LightingStyle a substituiu e é gravável por script.
]]

local lib = ...
local B = lib.builder(5)
local C = lib.C
local Map = workspace:FindFirstChild("NASAComplex")
assert(Map, "Execute as Fases 1–4 antes")
B.clear(Map)
local LO = workspace:FindFirstChild("Lighting_Objects")
B.clear(LO)
local AO = workspace:FindFirstChild("Atmosphere_Objects")
B.clear(AO)

local Museum, Hangar = Map.CapeCanaveralMuseum, Map.VABHangar
local FIX = { collide = false, shadow = false }
local HIDDEN = { collide = false, shadow = false, transparency = 1 }
local N = Enum.NormalId
local function rgb(hex) return Color3.fromHex(C[hex] or hex) end

-- Serviço Lighting ------------------------------------------------------------------
local L = game:GetService("Lighting")
-- Realistic tira o preenchimento difuso do Soft: sem Ambient mais alto a recepção caía de
-- claridade média 0,53 para 0,30. Com (105, 108, 118) ela volta a 0,54 (medido).
L.Ambient = Color3.fromRGB(105, 108, 118)
L.OutdoorAmbient = Color3.fromRGB(120, 122, 130)
L.Brightness = 2
L.ClockTime = 13
L.EnvironmentDiffuseScale = 0.4
L.EnvironmentSpecularScale = 0.5
L.GlobalShadows = true
pcall(function() L.LightingStyle = Enum.LightingStyle.Realistic end)
local atm = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", L)
atm.Density = 0.04
atm.Offset = 0
atm.Haze = 0
atm.Glare = 0
local dof = L:FindFirstChildOfClass("DepthOfFieldEffect")
if dof then dof.Enabled = false end
local bloom = L:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", L)
bloom.Intensity = 0.25
bloom.Size = 10
bloom.Threshold = 2
local cc = L:FindFirstChild("MapColorCorrection") or Instance.new("ColorCorrectionEffect")
cc.Name = "MapColorCorrection"
cc.Contrast = 0.06
cc.Saturation = 0.06
cc.Parent = L

-- 1. Recepção -----------------------------------------------------------------------------
local lb = LO.Base
local WARM = Color3.fromRGB(255, 246, 232)
for _, x in { -18, 0, 18 } do
	for _, z in { 14, 38 } do
		local p = B.box(lb, "Ceiling_Panel", x - 5, x + 5, 23.8, 24, z - 3, z + 3, "white", "Neon", FIX)
		B.light(p, "SurfaceLight", { Face = N.Bottom, Range = 24, Brightness = 1.4, Angle = 110, Color = WARM,
			Shadows = (x == 0 and z == 38) })
	end
end

-- 2. Corredor 1 ----------------------------------------------------------------------------
local strip = B.box(LO.Corridor_01, "Light_Strip", -0.6, 0.6, 11.85, 12, 57, 88, "white", "Neon", FIX)
B.light(strip, "SurfaceLight", { Face = N.Bottom, Range = 13, Brightness = 1.3, Angle = 130, Color = WARM })

-- 3. Museu -----------------------------------------------------------------------------------
local lm = LO.Museum
local sun = Museum.Solar_System:FindFirstChild("Sun")
if sun then
	for _, l in sun:GetChildren() do if l:IsA("Light") then l:Destroy() end end
	local sl = B.light(sun, "PointLight", { Range = 28, Brightness = 2, Color = Color3.fromRGB(255, 190, 110), Shadows = false })
	sl:SetAttribute("BuildPhase", 5)
end
-- luz azul indireta na base da cúpula
for _, a in { 45, 135, 225, 315 } do
	local r = math.rad(a)
	local p = B.box(lm, "Dome_Cove_Light", math.cos(r) * 30 - 0.5, math.cos(r) * 30 + 0.5, 19, 20, 130 + math.sin(r) * 30 - 0.5, 130 + math.sin(r) * 30 + 0.5, "midBlue", "SmoothPlastic", HIDDEN)
	B.light(p, "PointLight", { Range = 30, Brightness = 1.3, Color = rgb("midBlue"), Shadows = false })
end
-- óculo luminoso
local oculus = Museum.Dome:FindFirstChild("Oculus")
if oculus then
	oculus.Material = Enum.Material.Neon
	oculus.Color = rgb("lightBlue")
end
-- focos nas exposições
local spots = {
	{ "Spot_Astronauts", -38, 130, 95, 2.4 }, { "Spot_Rockets", 38, 130, 95, 2.4 }, { "Spot_Mars", -34, 101, 85, 2.2 },
	{ "Spot_Science", 33, 102, 85, 2.2 }, { "Spot_Moon", 36, 160, 55, 2.2 }, { "Spot_EVA", -34, 160, 70, 2 },
	{ "Spot_Timeline", 21, 165, 70, 1.6 },
}
for _, s in spots do
	local p = B.box(lm, s[1], s[2] - 0.6, s[2] + 0.6, 17.4, 17.9, s[3] - 0.6, s[3] + 0.6, "darkGray", "Metal", FIX)
	B.light(p, "SpotLight", { Face = N.Bottom, Range = 22, Angle = s[4], Brightness = s[5], Color = Color3.fromRGB(235, 242, 255), Shadows = false })
end
-- céu estrelado + nebulosas na face interna dos painéis da cúpula (só UI, sem luzes)
local shell = Museum.Dome:FindFirstChild("Dome_Shell")
if shell then
	local rng = Random.new(2026)
	local nebulaColors = { "#6B3FA0", "#2B5FA8", "#A83F7A" }
	for i, panel in shell:GetChildren() do
		if panel:IsA("BasePart") then
			local old = panel:FindFirstChild("StarField")
			if old then old:Destroy() end
			local gui = Instance.new("SurfaceGui")
			gui.Name = "StarField"
			gui.Face = N.Back -- face interna (voltada para o centro da cúpula)
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 12
			gui.LightInfluence = 0
			gui:SetAttribute("BuildPhase", 5)
			gui.Parent = panel
			if i % 9 == 0 then
				local neb = Instance.new("Frame")
				neb.AnchorPoint = Vector2.new(0.5, 0.5)
				neb.Position = UDim2.fromScale(rng:NextNumber(0.3, 0.7), rng:NextNumber(0.3, 0.7))
				neb.Size = UDim2.fromScale(1.1, 0.9)
				neb.BackgroundColor3 = Color3.fromHex(nebulaColors[(i // 9) % 3 + 1])
				neb.BorderSizePixel = 0
				neb.Parent = gui
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0.5, 0)
				corner.Parent = neb
				local g = Instance.new("UIGradient")
				g.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 1) })
				g.Rotation = rng:NextInteger(0, 180)
				g.Parent = neb
			end
			for _ = 1, 14 do
				local s = Instance.new("Frame")
				local px = rng:NextInteger(1, 3)
				s.Size = UDim2.fromOffset(px, px)
				s.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
				s.BackgroundColor3 = Color3.fromRGB(255, 255, rng:NextInteger(215, 255))
				s.BackgroundTransparency = rng:NextNumber(0, 0.4)
				s.BorderSizePixel = 0
				s.Parent = gui
			end
		end
	end
end

-- 4. Corredor 2 ----------------------------------------------------------------------------
local l2 = LO.Corridor_02
for _, z in { 182, 192, 202 } do
	local p = B.box(l2, "Cage_Lamp", -0.6, 0.6, 11.9, 12.2, z - 0.6, z + 0.6, "#FFD596", "Neon", FIX)
	B.light(p, "PointLight", { Range = 15, Brightness = 1.3, Color = Color3.fromRGB(255, 214, 150), Shadows = false })
end
for _, e in { { -7.7, 180 }, { 7.7, 206 } } do
	local p = B.box(l2, "Emergency_Light", e[1] - 0.2, e[1] + 0.2, 13, 13.6, e[2] - 0.3, e[2] + 0.3, "red", "Neon", FIX)
	B.light(p, "PointLight", { Range = 7, Brightness = 0.8, Color = rgb("red"), Shadows = false })
end

-- 5. Hangar --------------------------------------------------------------------------------
local lh = LO.Hangar
local COOL = Color3.fromRGB(230, 238, 255)
-- luminárias de grande altura sob as treliças
for _, z in { 222, 244, 266, 288, 310 } do
	for _, x in { -38, 38 } do
		local p = B.box(lh, "High_Bay", x - 1.5, x + 1.5, 142.2, 142.8, z - 1.5, z + 1.5, "white", "Neon", FIX)
		B.light(p, "SpotLight", { Face = N.Bottom, Range = 60, Angle = 110, Brightness = 2.2, Color = COOL, Shadows = false })
	end
end
-- luz de serviço nas paredes (pilastras), altura 26
for _, z in { 222, 266, 310 } do
	for _, sx in { -1, 1 } do
		local pos = Vector3.new(sx * 68, 26, z)
		local p = B.part(lh, "Wall_Flood", CFrame.lookAt(pos, Vector3.new(0, 0, z)), Vector3.new(2, 1.2, 0.6), "white", "Neon", FIX)
		B.light(p, "SpotLight", { Face = N.Front, Range = 55, Angle = 100, Brightness = 1.8, Color = COOL, Shadows = false })
	end
end
-- focos no foguete: cantos da plataforma (base → estágio central) e topo das torres (Orion/LAS)
local ROCKET = Vector3.new(0, 0, 265)
for i, c in { { -23, 247 }, { 23, 247 }, { -23, 283 }, { 23, 283 } } do
	local pos = Vector3.new(c[1], 10.8, c[2])
	local p = B.part(lh, "Rocket_Flood", CFrame.lookAt(pos, ROCKET + Vector3.new(0, 55, 0)), Vector3.new(1.6, 1.2, 0.8), "white", "Neon", FIX)
	B.light(p, "SpotLight", { Face = N.Front, Range = 60, Angle = 40, Brightness = 4, Color = COOL, Shadows = (i <= 2) })
end
for _, sx in { -1, 1 } do
	local pos = Vector3.new(sx * 20, 105.6, 262)
	local p = B.part(lh, "Tower_Flood", CFrame.lookAt(pos, ROCKET + Vector3.new(0, 112, 0)), Vector3.new(1.4, 1, 0.8), "white", "Neon", FIX)
	B.light(p, "SpotLight", { Face = N.Front, Range = 30, Angle = 55, Brightness = 3, Color = COOL, Shadows = false })
end

-- Partículas de poeira no hangar (Atmosphere_Objects) --------------------------------------
local dustSrc = B.box(AO, "Hangar_Dust", -60, 60, 40, 41, 220, 310, "white", "SmoothPlastic", HIDDEN)
local dust = Instance.new("ParticleEmitter")
dust.Name = "Dust"
dust.Rate = 6
dust.Lifetime = NumberRange.new(14, 20)
dust.Speed = NumberRange.new(0.2, 0.6)
dust.SpreadAngle = Vector2.new(180, 180)
dust.Size = NumberSequence.new(0.15)
dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 1) })
dust.LightEmission = 0.3
dust.Color = ColorSequence.new(Color3.fromRGB(230, 225, 210))
dust.Parent = dustSrc

local lights, shadows = 0, 0
for _, root in { Map, LO } do
	for _, d in root:GetDescendants() do
		if d:IsA("Light") then
			lights += 1
			if d.Shadows then shadows += 1 end
		end
	end
end
return ("Fase 5 aplicada: %d luzes (%d com sombra)"):format(lights, shadows)
