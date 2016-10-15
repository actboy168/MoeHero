
local jass = require 'jass.common'

local mt = ac.skill['空间震']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNtonkaE.blp]],

	--技能说明
	title = '空间震',
	
	tip = [[
在前方制造一个%area%范围的力场，阻挡所有单位的通行，持续%time%秒。在力场内，你受到的伤害减少%damaged_rate%%。

|cff888888消耗30%怒气，每点怒气会使你受到的伤害减少0.5%伤害。如果消耗超过20怒气，|cff00ccff空间震|cff888888会造成|r%damage%(+%damage_plus%)|cff888888伤害。|r
	]],

	--冷却
	cool = {30, 18},

	cost = 0,

	range = 9999,
	target_type = ac.skill.TARGET_TYPE_POINT,
	area = 400,

	--动画
	cast_animation = 'stand',
	cast_start_time = 0.2,
	cast_shot_time = 0.4,
	cast_finish_time = 0.6,
 
	--伤害
	damage = {60, 120},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,
	
	time = {3, 5},

	damaged_rate = {24, 40},

	--触发系数
	proc = 0.4,
}

function mt:on_cast_shot()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local damage = self.damage + self.damage_plus
	local fury = hero:get_resource '怒气' * 0.3
	hero:add_resource('怒气', -fury)
	
	hero:set_animation(6)
	self:set_option('show_cd', 0)
	self:set_option('passive', true)

	if fury > 20 then
		local target = hero:get_point() - {angle, 200}
		for _, u in ac.selector()
			: in_range(target, self.area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self,
				aoe = true,
				attack = true,
			}
		end
	end

	hero:add_buff '空间震'
	{
		source = hero,
		time = self.time,
		area = self.area,
		skill = self,
		data = {
			damaged_rate = self.damaged_rate + fury * 0.5,
		},
		selector = ac.selector()
			: in_range(hero:get_point(), self.area)
			: add_filter(function (u)
				return hero == u
			end)
			,
	}
end

function mt:on_cast_stop()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local target = hero:get_point() - {angle, 200} 
	local eff =  target:effect
	{
		model = [[model\tohka\effect_e.mdx]],
		size = 2,
	}
	local blocks = {}
	local points = {}
	for angle = 0, 360, 12 do
		local point = target - { angle, 288 }
		table.insert(blocks, jass.CreateDestructable(base.string2id('YTfb'), point[1], point[2], angle, 1, 0))
		point:add_block(64, 64, true)
		table.insert(points, point)
	end
	hero:wait(self.time * 1000, function()
		self:active_cd()
		self:set_option('show_cd', 1)
		self:set_option('passive', false)

		eff:remove()
		for _, block in ipairs(blocks) do
			jass.RemoveDestructable(block)
		end
		for _, point in ipairs(points) do
			point:remove_block()
		end
	end)
end

local mt = ac.aura_buff['空间震']

mt.cover_type = 1
mt.cover_max = 1

function mt:on_add()
	local hero = self.target
	local damaged_rate = self.data.damaged_rate / 100
	self.trg = hero:event '受到伤害' (function(trg, damage)
		damage:div(damaged_rate)
	end)
end

function mt:on_remove()
	self.trg:remove()
end
