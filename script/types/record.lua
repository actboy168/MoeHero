local japi = require 'jass.japi'
local jass = require 'jass.common'

if not japi.InitGameCache then
	local names = {
		'InitGameCache',
		'StoreInteger',
		'GetStoredInteger',
		'StoreString',
		'SaveGameCache',
	}
	for _, name in ipairs(names) do
		rawset(japi, name, jass[name])
	end
end

--获取积分对象
function ac.player.__index:record()
	if not self.record_data then
		if self:isPlayer() then
			self.record_data = japi.InitGameCache('11SAV@' .. string.char(('A'):byte() + (self:get() - 1)))
		else
			self.record_data = japi.InitGameCache('')
		end
	end
	return self.record_data
end

local keys = {}
local function get_key(name)
	if not keys[name] then
		if ac.game.new_record then
			keys[name] = name
		else
			keys[name] = name:match '^(.*)-%d*$' or name
		end
	end
	return keys[name]
end
	
--设置积分显示
-- 位置[0-7]
-- 名称
function ac.game:record(n, name)
	local key = get_key(name)
	for i = 1, 12 do
		japi.StoreString(ac.player(i):record(), '', 'Title@' .. string.char(('A'):byte() + n), key)
	end
	log.info(('设置积分标题[%d]为[%s]'):format(n, key))
end

--获取积分
function ac.player.__index:get_record(name)
	local key = get_key(name)
	local value = japi.GetStoredInteger(self:record(), '', key)
	log.info(('获取积分:[%s][%s] --> [%d]'):format(self:get_name(), key, value))
	return value
end

--设置积分
function ac.player.__index:set_record(name, value)
	local key = get_key(name)
	log.info(('设置积分:[%s][%s] <-- [%d]'):format(self:get_name(), key, value))
	return japi.StoreInteger(self:record(), '', key, value)
end

--增加积分
function ac.player.__index:add_record(name, value)
	local key = get_key(name)
	local old_value = japi.GetStoredInteger(self:record(), '', key)
	local new_value = old_value + value
	log.info(('增加积分:[%s][%s] : [%d] --> [%d]'):format(self:get_name(), key, old_value, new_value))
	return japi.StoreInteger(self:record(), '', key, new_value)
end

--保存积分
function ac.player.__index:save_record()
	log.info(('保存积分:[%s]'):format(self:get_name()))
	return japi.SaveGameCache(self:record())
end
