
local std_pairs = pairs
local next = next
local type = type
local getmetatable = getmetatable
local debug = debug
local log = log

function pairs(t)
	local mt = getmetatable(t)

	if not mt then
		local first = next(t)
		if first and type(first) == 'table' and not first.gchash then
			log.error('危险的遍历')
		end
	end
	return std_pairs(t)
end