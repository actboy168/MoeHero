
local rawset = rawset
local rawget = rawget

local mt = {}

setmetatable(_G, mt)

function mt:__index(k)
	log.error('读取不存在的全局变量:' .. k)
	return nil
end

function mt:__newindex(k, v)
	log.error(('保存全局变量[%s][%s]'):format(k, v))
	rawset(_G, k, v)
end