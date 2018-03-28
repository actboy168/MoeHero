
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local collectgarbage = collectgarbage
local unit = require 'types.unit'
local mover = require 'types.mover'
local effect = require 'types.effect'
local math = math
local table = table

local function rawpairs(t)
	return next, t, nil
end

ac.game:event '游戏-开始' (function()
	log.debug(('游戏开始: %.f'):format(ac.clock() / 1000))
end)

ac.loop(30 * 1000, function()
	local lua_memory = collectgarbage 'count'
	log.debug('------------------------定期体检报告------------------------')
	log.debug(('时间: %.f'):format(ac.clock() / 1000))
	log.debug(('内存[%.3fk]'):format(lua_memory))
	log.debug(('jass句柄数[%d],历史最大句柄[%d]'):format(dbg.handlecount(), dbg.handlemax()))
	log.debug(('计时器 正常[%d]'):format(ac.timer_size()))
	local unit_normal_count = 0
	local creature_normal_count = 0
	local unit_dead_count = 0
	local creature_dead_count = 0
	local unit_removed_count = 0
	local creature_removed_count = 0
	for _, u in pairs(unit.all_units) do
		if u:is_alive() then
			if u:get_class() then
				unit_normal_count = unit_normal_count + 1
			else
				creature_normal_count = creature_normal_count + 1
			end
		else
			if u:get_class() then
				unit_dead_count = unit_dead_count + 1
			else
				creature_dead_count = creature_dead_count + 1
			end
		end
	end
	for u in pairs(unit.removed_units) do
		if u:get_class() then
			unit_removed_count = unit_removed_count + 1
		else
			creature_removed_count = creature_removed_count + 1
		end
	end
	log.debug(('单位 正常[%d],死亡[%d],等待释放[%d]'):format(creature_normal_count, creature_dead_count, creature_removed_count))
	log.debug(('马甲 正常[%d],死亡[%d],等待释放[%d]'):format(unit_normal_count, unit_dead_count, unit_removed_count))

	local count1 = 0
	for _ in pairs(mover.mover_group) do
		count1 = count1 + 1
	end
	local count2 = 0
	for _ in pairs(mover.removed_mover) do
		count2 = count2 + 1
	end
	log.debug(('运动器 正常[%d],等待释放[%d]'):format(count1, count2))
	log.debug('-----------------------------------------------------------')
end)

function unit:__gc()
	if self.removed then
		return
	end
	log.warn(('[单位]失去引用但是没有被移除:[%s]'):format(self:get_name()))
end

function mover:__gc()
	if self.removed then
		return
	end
	log.warn(('[运动]失去引用但是没有被移除:[%s][%s]'):format(
		self.source:get_name(),
		self.skill and skill.skill.name
	))
end

function effect:__gc()
	if self.removed then
		return
	end
	log.warn(('[特效]失去引用但是没有被移除:[%s][%s]'):format(
		self.unit and self.unit:get_name(),
		self.model
	))
end

--function trigger:__gc()
--	if self.removed then
--		return
--	end
--	log.error('[触发器]失去引用但是没有被移除')
--	for event in pairs(self.events) do
--		log.error(event.name)
--	end
--end

ac.game:event '游戏-结束' (function()
	collectgarbage()
	--log.debug '=========================='
	--log.debug '统计已经被移除但是依然被引用的触发器'
	--for self in pairs(trigger.removed_triggers) do
	--	log.debug(('++++触发器[%s]'):format(self))
	--	local u = self.unit_event_unit
	--	if u then
	--		log.debug(('单位[%s]'):format(u:get_name()))
	--	else
	--		log.debug('全局')
	--	end
	--	log.debug('曾使用的事件:' .. table.concat(self.event_names, ' '))
	--end
	if not base.release then
		log.debug '=========================='
		log.debug '统计已经被移除但是依然被引用的单位'
		for self in pairs(unit.removed_units) do
			log.debug(('++++单位[%s][%s]'):format(self:get_name(), self.id))
			log.debug('所有者:' .. self:get_owner():get_name())
			if self.model then
				log.debug('模型:' .. self.model)
			end
		end
		log.debug '=========================='
		log.debug '统计已经被移除但是依然被引用的运动器'
		local callback_list = {'on_move', 'on_hit', 'on_remove', 'on_block', 'on_finish'}
		for self in pairs(mover.removed_mover) do
			log.debug(('++++运动器 name[%s] id[%s] model[%s]'):format(self.mover:get_name(), self.id, self.model))
			for i = 1, #callback_list do
				local name = callback_list[i]
				local f = self[name]
				if f then
					local info = debug.getinfo(f, 'S')
					log.debug(('[%s] - %s : %d'):format(name, info.source, info.linedefined))
				end
			end
		end
	end

	unit.__gc = nil
	mover.__gc = nil
	effect.__gc = nil
	--trigger.__gc = nil
end)
