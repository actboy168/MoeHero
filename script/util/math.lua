--计算2个角度之间的夹角
--	@夹角[0, 180]
--	@旋转方向(1 = 逆时针旋转, -1 = 顺时针旋转)
function math.angle(r1, r2)
	local r = (r1 - r2) % 360
	if r >= 180 then
		return 360 - r, 1
	else
		return r, -1
	end
end

--弧度去死吧
local deg = math.deg(1)
local rad = math.rad(1)

--正弦
local sin = math.sin

function math.sin(r)
	return sin(r * rad)
end

--余弦
local cos = math.cos

function math.cos(r)
	return cos(r * rad)
end

--正切
local tan = math.tan

function math.tan(r)
	return tan(r * rad)
end

--反正弦
local asin = math.asin

function math.asin(v)
	return asin(v) * deg
end

--反余弦
local acos = math.acos

function math.acos(v)
	return acos(v) * deg
end

--反正切
local atan = math.atan2 or math.atan

function math.atan(v1, v2)
	return atan(v1, v2) * deg
end

math.atan2 = math.atan
