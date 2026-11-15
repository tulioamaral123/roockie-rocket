--!nonstrict
-- verificar_museu.luau
-- Verificação somente leitura do museu (Fases 16-18, revisão 2). Colar via execute_luau no modo Edit
-- depois de rodar as fases 1-18. RETORNA um relatório em string. Não usa require nem HttpService.

local CollectionService = game:GetService("CollectionService")

local linhas = {}
local falhas = 0

-- ===== utilitários de relatório =====
local function titulo(t) linhas[#linhas + 1] = "" linhas[#linhas + 1] = "== " .. t .. " ==" end
local function info(t) linhas[#linhas + 1] = "[INFO] " .. t end
local function check(ok, t)
	if not ok then falhas += 1 end
	linhas[#linhas + 1] = (ok and "[OK] " or "[FALHA] ") .. t
end
local function f1(n) return string.format("%.1f", n) end
local function f2(n) return string.format("%.2f", n) end
local function v3(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
-- lista no máximo n itens de uma tabela de strings
local function listar(t, n)
	for i = 1, math.min(#t, n) do linhas[#linhas + 1] = "    - " .. t[i] end
	if #t > n then linhas[#linhas + 1] = "    ... +" .. (#t - n) .. " itens" end
end

local NASA = workspace:FindFirstChild("NASAComplex")
if not NASA then return "FALHA: workspace.NASAComplex não existe" end
local Hall = NASA:FindFirstChild("SpaceMuseumHall")
local Exh = NASA:FindFirstChild("SpaceMuseumExhibits")

-- ===== utilitários geométricos =====
-- Caixa alinhada aos eixos (minX,maxX,minY,maxY,minZ,maxZ) de uma peça
local function aabb(part)
	local cf, s = part.CFrame, part.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ex = math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z
	local ey = math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z
	local ez = math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
	local p = cf.Position
	return p.X - ex, p.X + ex, p.Y - ey, p.Y + ey, p.Z - ez, p.Z + ez
end

-- Caixa do museu no mundo (salão, átrio, galeria de entrada), com margem
local CAIXAS_MUSEU = {
	{ 132.5, 277.5, 85, 349 }, -- salão
	{ 82.5, 132.5, 149, 279 }, -- átrio
	{ 180, 230, 68, 85 }, -- galeria de entrada
}
local function dentroMuseu(p, margem)
	for _, c in ipairs(CAIXAS_MUSEU) do
		if p.X >= c[1] - margem and p.X <= c[2] + margem and p.Z >= c[3] - margem and p.Z <= c[4] + margem then
			return true
		end
	end
	return false
end

-- Raio de cima para baixo ignorando tudo acima de stopY (teto, vigas, exposições)
local function raioBaixo(x, z, y0, stopY)
	local ignorar = {}
	for _ = 1, 15 do
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = ignorar
		rp.RespectCanCollide = true
		local r = workspace:Raycast(Vector3.new(x, y0, z), Vector3.new(0, -(y0 + 20), 0), rp)
		if not r then return nil end
		if r.Position.Y <= stopY then return r end
		ignorar[#ignorar + 1] = r.Instance
	end
	return nil
end

local function topoY(p)
	local _, _, _, y1 = aabb(p)
	return y1
end

-- ===== 1. Raízes e orçamentos =====
local function secao1()
	titulo("1. Raízes e orçamentos")
	check(Hall ~= nil, "SpaceMuseumHall existe")
	check(Exh ~= nil, "SpaceMuseumExhibits existe")
	for _, par in ipairs({ { "SpaceMuseumHall", Hall }, { "SpaceMuseumExhibits", Exh } }) do
		local r = par[2]
		if r then
			local p, l, s = 0, 0, 0
			for _, d in ipairs(r:GetDescendants()) do
				if d:IsA("BasePart") then p += 1
				elseif d:IsA("Light") then
					l += 1
					if d.Shadows then s += 1 end
				end
			end
			info(par[1] .. ": " .. p .. " BaseParts, " .. l .. " luzes, " .. s .. " com sombra")
			if par[1] == "SpaceMuseumHall" then
				check(l <= 60, "salão: luzes " .. l .. " (meta <= 60)")
				check(s <= 3, "salão: luzes com sombra " .. s .. " (meta 3)")
			end
		end
	end
end

-- ===== 2. Exposições =====
local function secao2()
	titulo("2. Exposições (tag Exhibit)")
	local ms = CollectionService:GetTagged("Exhibit")
	local n, ruins = 0, {}
	for _, m in ipairs(ms) do
		if m:IsA("Model") then
			n += 1
			local id = m:GetAttribute("ExhibitId")
			local erros = {}
			if type(id) ~= "string" or id == "" then erros[#erros + 1] = "sem ExhibitId" end
			if not m.PrimaryPart then erros[#erros + 1] = "sem PrimaryPart" end
			if not m:FindFirstChild("PromptAnchor", true) then erros[#erros + 1] = "sem PromptAnchor" end
			local cf, size = m:GetBoundingBox()
			if not dentroMuseu(cf.Position, 2) then
				erros[#erros + 1] = "fora da caixa do museu, centro " .. v3(cf.Position)
			end
			if #erros > 0 then ruins[#ruins + 1] = m:GetFullName() .. ": " .. table.concat(erros, "; ") end
		end
	end
	check(n > 0, "Models com tag Exhibit: " .. n)
	check(#ruins == 0, "exposições com problema: " .. #ruins)
	listar(ruins, 20)
end

-- ===== 3. Saturn V =====
local function secao3()
	titulo("3. Saturn V")
	local sat
	for _, m in ipairs(CollectionService:GetTagged("Exhibit")) do
		if m:GetAttribute("ExhibitId") == "saturn_v" then sat = m break end
	end
	check(sat ~= nil, "Model saturn_v encontrado")
	if not sat then return end
	local nomes = { "Stage_S_IC", "Stage_S_II", "Stage_S_IVB", "Stage_IU", "Stage_Spacecraft" }
	local zs, faltam = {}, {}
	local icMinZ
	for i, nm in ipairs(nomes) do
		local st = sat:FindFirstChild(nm, true)
		if st and st:IsA("Model") then
			local cf = st:GetBoundingBox()
			zs[i] = cf.Position.Z
			if i == 1 then
				local mn = math.huge
				for _, d in ipairs(st:GetDescendants()) do
					if d:IsA("BasePart") then
						local _, _, _, _, z0 = aabb(d)
						mn = math.min(mn, z0)
					end
				end
				icMinZ = mn
			end
		else
			faltam[#faltam + 1] = nm
		end
	end
	check(#faltam == 0, "estágios presentes; faltam: " .. (#faltam == 0 and "nenhum" or table.concat(faltam, ", ")))
	if #faltam == 0 then
		local cres = true
		for i = 2, 5 do if zs[i] <= zs[i - 1] then cres = false end end
		local txt = {}
		for i = 1, 5 do txt[i] = nomes[i]:gsub("Stage_", "") .. "=" .. f1(zs[i]) end
		check(cres, "Z dos estágios crescente do S-IC para a espacionave (" .. table.concat(txt, ", ") .. ")")
		check(icMinZ and math.abs(icMinZ - 125) <= 10, "Z mínimo do S-IC " .. f1(icMinZ or 0) .. " (esperado perto de 125)")
		-- eixo ao longo de Z: extensão total do modelo
		local mnX, mxX, mnZ, mxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, d in ipairs(sat:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "PromptAnchor" then
				local a, b, _, _, c, e = aabb(d)
				mnX, mxX, mnZ, mxZ = math.min(mnX, a), math.max(mxX, b), math.min(mnZ, c), math.max(mxZ, e)
			end
		end
		check((mxZ - mnZ) > 2 * (mxX - mnX), "eixo ao longo de Z: extensão Z " .. f1(mxZ - mnZ) .. " x X " .. f1(mxX - mnX))
	end
	-- attachments
	local att = {}
	for _, d in ipairs(sat:GetDescendants()) do
		if d:IsA("Attachment") then att[d.Name] = d end
	end
	local les, sic = att["les"], att["s_ic"]
	if les then
		local maxZ = -math.huge
		for _, a in pairs(att) do maxZ = math.max(maxZ, a.WorldPosition.Z) end
		check(les.WorldPosition.Z >= maxZ - 1, "torre de escape (les) no extremo sul: Z " .. f1(les.WorldPosition.Z) .. " (máx " .. f1(maxZ) .. ")")
	else
		check(false, "attachment 'les' não existe")
	end
	local f1z, nf = 0, 0
	for i = 1, 5 do
		local a = att["f1_" .. i]
		if a then f1z += a.WorldPosition.Z nf += 1 end
	end
	check(nf == 5, "attachments f1_1..f1_5: " .. nf)
	if nf > 0 and sic then
		local med = f1z / nf
		check(med < sic.WorldPosition.Z, "F-1 na extremidade norte (Z médio " .. f1(med) .. " < s_ic " .. f1(sic.WorldPosition.Z) .. "), voltados para a entrada em Z 85")
	end
	if att["f1_1"] then info("f1_1 LookVector " .. v3(att["f1_1"].WorldCFrame.LookVector) .. " XVector " .. v3(att["f1_1"].WorldCFrame.XVector)) end
end

-- ===== 4. Circulação =====
local function gradeChao(nome, x0, x1, z0, z1)
	local total, ruins, n = 0, {}, 0
	local x = x0 + 3
	while x <= x1 - 3 do
		local z = z0 + 3
		while z <= z1 - 3 do
			total += 1
			local r = raioBaixo(x, z, 45, 0.5)
			if not r then
				ruins[#ruins + 1] = "(" .. f1(x) .. ", " .. f1(z) .. ") sem piso"
			else
				local y = r.Position.Y
				if not (math.abs(y) <= 0.2 or math.abs(y + 3) <= 0.2) then
					ruins[#ruins + 1] = "(" .. f1(x) .. ", " .. f1(z) .. ") Y " .. f2(y) .. " em " .. r.Instance:GetFullName()
				end
			end
			n += 1
			if n % 150 == 0 then task.wait() end
			z += 6
		end
		x += 6
	end
	check(#ruins == 0, nome .. ": " .. total .. " raios, " .. #ruins .. " sem piso em Y -0,2..0,2 (ou -3)")
	listar(ruins, 10)
end

local function varreCaixas(nome, pts, tam)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = {}
	local achados, vistos = {}, {}
	for i, p in ipairs(pts) do
		local cf = CFrame.new(p)
		for _, part in ipairs(workspace:GetPartBoundsInBox(cf, tam, op)) do
			if part.CanCollide and not vistos[part] and not part.Name:find("Baseplate") and topoY(part) > 0.3 then
				vistos[part] = true
				achados[#achados + 1] = part:GetFullName() .. " perto de " .. v3(p)
			end
		end
		if i % 20 == 0 then task.wait() end
	end
	check(#achados == 0, nome .. ": " .. #pts .. " caixas, " .. #achados .. " peças com CanCollide")
	listar(achados, 12)
end

local function secao4()
	titulo("4. Circulação")
	gradeChao("piso do salão", 132.5, 277.5, 85, 349)
	gradeChao("piso do átrio", 82.5, 132.5, 149, 279)
	-- eixo de entrada: X 205, Z 70..140 (caixa 9 x 7 x 6, base em Y 0,3)
	local pts = {}
	for z = 70, 140, 5 do pts[#pts + 1] = Vector3.new(205, 3.8, z) end
	varreCaixas("eixo de entrada X 205", pts, Vector3.new(9, 7, 6))
	-- corredor A (Z 157, X 6..82,5) e B (Z 119, X 6..132,5), caixas com largura 9 em Z
	local pa, pb = {}, {}
	for x = 6, 82.5, 5 do pa[#pa + 1] = Vector3.new(x, 3.8, 157) end
	for x = 6, 132.5, 5 do pb[#pb + 1] = Vector3.new(x, 3.8, 119) end
	varreCaixas("corredor A (Z 157)", pa, Vector3.new(6, 7, 9))
	varreCaixas("corredor B (Z 119)", pb, Vector3.new(6, 7, 9))
end

-- ===== 5. Baseplate e fosso do memorial =====
local function secao5()
	titulo("5. Baseplate e memorial")
	local splits, pit, todos = 0, nil, 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Name == "Baseplate" then
				todos += 1
				if d:GetAttribute("MemorialSplit") ~= nil then splits += 1 end
			elseif d.Name == "Baseplate_Pit" then
				pit = pit or d
			end
		end
	end
	check(splits == 1, "peças 'Baseplate' com atributo MemorialSplit: " .. splits .. " (de " .. todos .. " 'Baseplate')")
	check(pit ~= nil, "Baseplate_Pit existe")
	if pit then
		local p = pit.Position
		local r = raioBaixo(p.X, p.Z, 10, 0.5)
		local mf = workspace:FindFirstChild("MemorialFloor", true)
		check(mf ~= nil, "MemorialFloor existe" .. (mf and (" em " .. mf:GetFullName()) or ""))
		if r then
			local ok = r.Instance.Name == "MemorialFloor" and math.abs(r.Position.Y + 3) <= 0.3
			check(ok, "raio no centro do fosso (" .. f1(p.X) .. ", " .. f1(p.Z) .. ") acerta " .. r.Instance:GetFullName() .. " em Y " .. f2(r.Position.Y))
		else
			check(false, "raio no centro do fosso não acerta nada")
		end
	end
end

-- ===== 6. MuseumExit =====
local function secao6()
	titulo("6. MuseumExit")
	local ex = CollectionService:GetTagged("MuseumExit")
	check(#ex >= 3, "peças com tag MuseumExit: " .. #ex .. " (esperado 3)")
	-- entradas e sentido esperado de saída (para fora do museu)
	local ent = {
		{ "norte", Vector3.new(205, 0, 85), Vector3.new(0, 0, -1) },
		{ "corredor A", Vector3.new(82.5, 0, 157), Vector3.new(-1, 0, 0) },
		{ "corredor B", Vector3.new(132.5, 0, 119), Vector3.new(-1, 0, 0) },
	}
	for _, e in ipairs(ex) do
		if e:IsA("BasePart") then
			local d = e:GetAttribute("ExitDirection")
			if typeof(d) ~= "Vector3" then
				check(false, e:GetFullName() .. ": ExitDirection ausente ou não é Vector3")
			else
				local melhor, dist = nil, math.huge
				for _, en in ipairs(ent) do
					local dd = (Vector3.new(e.Position.X, 0, e.Position.Z) - en[2]).Magnitude
					if dd < dist then melhor, dist = en, dd end
				end
				local unit = math.abs(d.Magnitude - 1) < 0.01
				local fora = d:Dot(melhor[3]) > 0.7
				check(unit and fora, e:GetFullName() .. " em " .. v3(e.Position) .. " dir " .. v3(d) .. " |d|=" .. f2(d.Magnitude) .. " entrada mais próxima '" .. melhor[1] .. "' (" .. f1(dist) .. " studs), dot " .. f2(d:Dot(melhor[3])))
			end
		end
	end
end

-- ===== 7. Câmera do show =====
local function secao7()
	titulo("7. LaunchConsole.ShowCamera")
	local con = workspace:FindFirstChild("LaunchConsole", true)
	local dio = workspace:FindFirstChild("LaunchDiorama", true)
	check(con ~= nil, "LaunchConsole existe")
	check(dio ~= nil, "LaunchDiorama existe")
	if not (con and dio) then return end
	local cam = con:FindFirstChild("ShowCamera", true)
	check(cam ~= nil and cam:IsA("BasePart"), "ShowCamera existe")
	if cam and cam:IsA("BasePart") then
		local alvo = dio:IsA("Model") and dio:GetBoundingBox().Position or dio.Position
		local dir = (alvo - cam.Position).Unit
		local ang = math.deg(math.acos(math.clamp(cam.CFrame.LookVector:Dot(dir), -1, 1)))
		check(ang < 30, "ângulo ShowCamera -> diorama " .. f1(ang) .. " graus (< 30); câmera " .. v3(cam.Position) .. ", alvo " .. v3(alvo))
	end
end

-- ===== 8. Juntas de parede =====
local function secao8()
	titulo("8. Juntas e linhas de parede")
	local W = {}
	local n = 0
	for _, d in ipairs(NASA:GetDescendants()) do
		n += 1
		if n % 3000 == 0 then task.wait() end
		if d:IsA("Part") and d.Shape == Enum.PartType.Block and d.Transparency < 1 then
			local nm = d.Name .. " " .. (d.Parent and d.Parent.Name or "")
			local lower = nm:lower()
			if not (lower:find("door") or lower:find("gate") or lower:find("leaf") or lower:find("glass")) and not d:GetFullName():find("TransportSystem") then
				-- alinhada aos eixos?
				local cf = d.CFrame
				local ok = true
				for _, v in ipairs({ cf.RightVector, cf.UpVector, cf.LookVector }) do
					if math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z)) < 0.9999 then ok = false end
				end
				if ok then
					local x0, x1, y0, y1, z0, z1 = aabb(d)
					local wx, wy, wz = x1 - x0, y1 - y0, z1 - z0
					local fino = math.min(wx, wz)
					if wy >= 6 and fino <= 3 and math.max(wx, wz) >= 2 * fino then
						local w = { nome = (d.Parent and d.Parent.Name or "?") .. "." .. d.Name, y0 = y0, y1 = y1 }
						if wx > wz then
							w.o, w.a0, w.a1, w.t0, w.t1 = "x", x0, x1, z0, z1
						else
							w.o, w.a0, w.a1, w.t0, w.t1 = "z", z0, z1, x0, x1
						end
						W[#W + 1] = w
					end
				end
			end
		end
	end
	info("paredes candidatas (Block vertical fino, alinhado): " .. #W)
	local juntas, linhasDes = {}, {}
	for i = 1, #W do
		local a = W[i]
		for j = 1, #W do
			if i ~= j then
				local b = W[j]
				local yov = math.min(a.y1, b.y1) - math.max(a.y0, b.y0)
				if yov >= 3 then
					if a.o ~= b.o then
						-- junta em T: ponta de 'a' perto da face de 'b'
						local ac = (a.t0 + a.t1) / 2
						if ac >= b.a0 - 0.05 and ac <= b.a1 + 0.05 then
							local g1, g2 = b.t0 - a.a1, a.a0 - b.t1
							for _, g in ipairs({ g1, g2 }) do
								if g >= 0.02 and g <= 1.5 then
									juntas[#juntas + 1] = a.nome .. " -> " .. b.nome .. " vão " .. f2(g)
								end
							end
						end
					elseif i < j then
						-- mesma linha: paredes consecutivas com faces desencontradas
						local gap = math.max(a.a0, b.a0) - math.min(a.a1, b.a1)
						local sobreT = math.min(a.t1, b.t1) - math.max(a.t0, b.t0)
						if gap >= -0.05 and gap <= 1.5 and sobreT > 0 then
							local d = math.max(math.abs(a.t0 - b.t0), math.abs(a.t1 - b.t1))
							if d > 0.04 and d <= 3 then
								linhasDes[#linhasDes + 1] = a.nome .. " x " .. b.nome .. " desencontro " .. f2(d)
							end
						end
					end
				end
			end
		end
		if i % 25 == 0 then task.wait() end
	end
	check(#juntas == 0, "juntas em T com vão 0,02..1,5: " .. #juntas)
	listar(juntas, 25)
	check(#linhasDes == 0, "linhas de parede com faces desencontradas > 0,04: " .. #linhasDes)
	listar(linhasDes, 25)
end

-- ===== 9. Envelope do transporte =====
local function secao9()
	titulo("9. Envelope do transporte (X -34..34, Y 0..133, Z 234..321)")
	local op = OverlapParams.new()
	local partes = workspace:GetPartBoundsInBox(CFrame.new(0, 66.5, 277.5), Vector3.new(68, 133, 87), op)
	local museu, grupos = {}, {}
	for _, p in ipairs(partes) do
		local top = p
		while top.Parent and top.Parent ~= NASA and top.Parent ~= workspace do top = top.Parent end
		local g = (top.Parent == NASA) and top.Name or "(fora de NASAComplex: " .. top.Name .. ")"
		grupos[g] = (grupos[g] or 0) + 1
		if g:find("SpaceMuseum") then museu[#museu + 1] = p:GetFullName() end
	end
	check(#museu == 0, "peças de SpaceMuseum* dentro do envelope: " .. #museu)
	listar(museu, 15)
	local nomes = {}
	for g, c in pairs(grupos) do nomes[#nomes + 1] = g .. "=" .. c end
	table.sort(nomes)
	info("peças na caixa por raiz: " .. (#nomes > 0 and table.concat(nomes, ", ") or "nenhuma"))
end

-- ===== execução em blocos, cada seção protegida por pcall =====
local secoes = { secao1, secao2, secao3, secao4, secao5, secao6, secao7, secao8, secao9 }
for i, fn in ipairs(secoes) do
	local ok, err = pcall(fn)
	if not ok then
		falhas += 1
		linhas[#linhas + 1] = "[FALHA] erro na seção " .. i .. ": " .. tostring(err)
	end
	task.wait()
end

table.insert(linhas, 1, "RELATÓRIO verificar_museu: " .. falhas .. " falha(s)")
return table.concat(linhas, "\n")
