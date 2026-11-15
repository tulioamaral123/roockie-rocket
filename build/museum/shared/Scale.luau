--[[
	Escala: toda medida real passa por aqui (museuspec §3.1, contrato: 0,7 m/stud).
]]

local Config = require(script.Parent:WaitForChild("Config"))

local Scale = {}

function Scale.meters(m: number): number
	return m / Config.METERS_PER_STUD
end

function Scale.feet(ft: number): number
	return Scale.meters(ft * 0.3048)
end

function Scale.toMeters(studs: number): number
	return studs * Config.METERS_PER_STUD
end

return Scale
