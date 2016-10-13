
local j_unit

function ac.unit(handle)
	return j_unit(handle)
end

return function(f)
	j_unit = f
end