function ac.split(str, p)
	local rt = {}
	str:gsub('[^'..p..']+', function (w)
		table.insert(rt, w)
	end)
	return rt
end
