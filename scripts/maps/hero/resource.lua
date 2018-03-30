local mt = ac.resource['魔法']
-- 上限提升比例
mt.add_max_rate = 1
-- 回复提升比例
mt.add_recover_rate = 1
-- 减耗比例
mt.get_cost_save_rate = 1
-- 颜色
mt.color = '3399ff'
-- 复活时恢复的能量(0:变成0 1:维持上一次死亡的值 2:回满)
mt.reborn_type = 2

local mt = ac.resource['怒气']
mt.add_max_rate = 0.1
mt.add_recover_rate = 0.1
mt.get_cost_save_rate = 1
mt.color = 'ffff7f'
mt.reborn_type = 0

function mt:on_add()
	self:event '造成伤害效果' (function(trg, damage)
		local fury = 8
		if damage:is_common_attack() then
			if damage.skill then
				fury = fury * damage.skill.proc
			else
				fury = fury * damage.source.proc
			end
		elseif damage:is_skill() then
			fury = fury * damage.skill.proc
			if damage.target:is_hero() then
				fury = fury * 2
			end
		else
			return
		end
		self:add_resource('怒气', fury)
	end)
	self:event '受到伤害效果' (function(trg, damage)
		local fury = damage.damage / self:get '生命上限' * 1.1 * 100
		self:add_resource('怒气', fury)
	end)
end

local mt = ac.resource['子弹']
mt.add_max_rate = 0
mt.add_recover_rate = 0
mt.get_cost_save_rate = 0
mt.color = '7fff7f'
mt.reborn_type = 1

local mt = ac.resource['体力']
mt.add_max_rate = 0.1
mt.add_recover_rate = 0
mt.get_cost_save_rate = 1
mt.color = 'ffffbf'
mt.reborn_type = 2

local mt = ac.resource['魔力']
mt.add_max_rate = 0.05
mt.add_recover_rate = 0
mt.get_cost_save_rate = 0
mt.color = 'ff3333'
mt.reborn_type = 1
