local japi = require 'jass.japi'
local jass = require 'jass.common'

local math_floor = math.floor
local has_record = not not japi.InitGameCache
log.info('积分环境', has_record)

local names = {
	'FlushGameCache',
	'InitGameCache',
	'StoreInteger',
	'GetStoredInteger',
	'StoreString',
	'SaveGameCache',
	'SyncStoredInteger',
}
for _, name in ipairs(names) do
	if not japi[name] then
		rawset(japi, name, jass[name])
	end
end

local function get_key(player)
	return string.char(('A'):byte() + (player:get() - 1))
end

--获取积分对象
function ac.player.__index:record()
	if not self.record_data then
		if self:is_player() then
			self.record_data = japi.InitGameCache('11SAV@' .. get_key(self))
		else
			self.record_data = japi.InitGameCache('')
		end
	end
	return self.record_data
end
	
--设置积分显示
-- 位置[0-7]
-- 名称
function ac.game:record(n, name)
	for i = 1, 12 do
		japi.StoreString(ac.player(i):record(), '', 'Title@' .. string.char(('A'):byte() + n), name)
	end
	log.info(('设置积分标题[%d]为[%s]'):format(n, name))
end

--获取积分
function ac.player.__index:get_record(name)
	local value = japi.GetStoredInteger(self:record(), '', name)
	log.info(('获取积分:[%s][%s] --> [%s]'):format(self:get_name(), name, value))
	return value
end

--设置积分
function ac.player.__index:set_record(name, value)
	log.info(('设置积分:[%s][%s] <-- [%s]'):format(self:get_name(), name, value))
	return japi.StoreInteger(self:record(), '', name, value)
end

--增加积分
function ac.player.__index:add_record(name, value)
	local old_value = japi.GetStoredInteger(self:record(), '', name)
	local new_value = old_value + value
	log.info(('增加积分:[%s][%s] : [%s] --> [%s]'):format(self:get_name(), name, old_value, new_value))
	return japi.StoreInteger(self:record(), '', name, new_value)
end

--保存积分
function ac.player.__index:save_record()
	log.info(('保存积分:[%s]'):format(self:get_name()))
	return japi.SaveGameCache(self:record())
end

-- RPG积分相关
local score_gc
local function get_score()
	if not score_gc then
		japi.FlushGameCache(japi.InitGameCache("11.x"))
		score_gc = japi.InitGameCache("11.x")
	end
	return score_gc
end

local current_player
local function get_player()
	if current_player and current_player:is_player() then
		return current_player
	end
	for i = 1, 12 do
		if ac.player[i]:is_player() then
			current_player = ac.player[i]
			return current_player
		end
	end
	return ac.player[1]
end

local function write_score(table, key, data)
	japi.StoreInteger(get_score(), table, key, data)
	if get_player():is_self() then
		japi.SyncStoredInteger(get_score(), table, key)
	end
end

local function read_score(table, key)
	return japi.GetStoredInteger(get_score(), table, key)
end

function ac.player.__index:get_score(name)
	local value = read_score(get_key(self), name)
	log.info(('获取RPG积分:[%s][%s] --> [%s]'):format(self:get_name(), name, value))
	return value
end

function ac.player.__index:set_score(name, value)
	log.info(('设置RPG积分:[%s][%s] = [%s]'):format(self:get_name(), name, value))
	if has_record then
		write_score(get_key(self) .. "=", name, value)
	else
		write_score(get_key(self), name, value)
	end
end

function ac.player.__index:add_score(name, value)
	log.info(('增加RPG积分:[%s][%s] + [%s]'):format(self:get_name(), name, value))
	if has_record then
		write_score(get_key(self) .. "+", name, value)
	else
		write_score(get_key(self), name, value + self:get_score(name))
	end
end

function ac.game:score_game_end()
	write_score("$", "GameEnd", 0)
end
