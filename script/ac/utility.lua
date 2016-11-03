function ac.split(str, p)
	local rt = {}
	str:gsub('[^'..p..']+', function (w)
		table.insert(rt, w)
	end)
	return rt
end

--计算2个角度之间的夹角
--	@夹角[0, 180]
--	@旋转方向(1 = 逆时针旋转, -1 = 顺时针旋转)
function ac.math_angle(r1, r2)
	local r = (r1 - r2) % 360
	if r >= 180 then
		return 360 - r, 1
	else
		return r, -1
	end
end
