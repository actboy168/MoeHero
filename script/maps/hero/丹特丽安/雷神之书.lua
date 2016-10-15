local mt = ac.skill['雷神之书']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNdantalianW.blp]],
	title = '雷神之书',
	tip = [[
吟唱%cast_channel_time%秒后，对目标区域造成%damage_base%(+%damage_plus%)伤害。

如果吟唱超过%channel_time%秒，你的下一个幻书技能造成的伤害提高%damage_rate%%。
	]],
	cool = {7, 3},
	cost = 40 * 3,
	-- 每秒扣蓝
	cost_channel = 40,
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 1000,
	-- 吟唱时间
	cast_channel_time = 3,
	-- 伤害范围
	area = 300,
	-- 伤害
	damage_base = {200, 400},
	damage_plus = function(self, hero)
		return hero:get_ad() * 2.0
	end,
	-- 获得buff需要的吟唱时间
	channel_time = 2,
	-- 伤害提升
	damage_rate = {24, 40},
}

function mt:on_can_cast()
	local hero = self.owner
	if hero:find_buff '妖精之书' then
		hero:remove_buff '妖精之书'
		self.break_move = 0
	else
		self.break_move = 1
	end
	return true
end

function mt:on_cast_start()
	self.cost = 0
end

function mt:on_cast_channel()
	local hero = self.owner
	self.clock = hero:clock()
	self.effect = hero:add_effect('origin', [[model\dantalian\channel_blue.mdl]])
	self.timer = hero:wait(self.channel_time * 1000, function()
		hero:add_buff '雷神之书'
		{
			skill = self,
			rate = self.damage_rate,
		}
	end)
	self.trigger = hero:event '单位-发布指令' (function(_, _, order)
		if order == 'stop' then
			self:stop()
		end
	end)
	local target_mark
	if hero:get_owner() == ac.player.self then
		target_mark = [[model\dantalian\target_mark.mdl]]
	else
		target_mark = ''
	end
	self.target_mark = ac.effect(self.target, target_mark, 0, self.area / 400)
end

function mt:on_cast_stop()
	local hero = self.owner
	self.effect:remove()
	self.timer:remove()
	self.trigger:remove()
	self.target_mark:remove()
end

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local area = self.area
	local damage = self.damage_base + self.damage_plus
	local mover = ac.mover.line
	{
		source = hero,
		start = target - {angle, - 300},
		angle = angle,
		distance = 200,
		id = 'e00H',
		high = 1000,
		target_high = 100,
		speed = 600,
		accel = 1000,
		skill = self,
	}

	if not mover then
		return
	end

	function mover:on_remove()
		mover.mover:set_animation 'death'
	end

	function mover:on_finish()
		for _, u in ac.selector()
			: in_range(target, area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self.skill,
				aoe = true,
			}
		end
	end
end


local mt = ac.buff['雷神之书']

function mt:on_add()
	local hero = self.target
	local rate = 1 + self.rate / 100
	self.eff = hero:add_effect('origin', [[model\dantalian\speicl_blue.mdx]])
	self.trg = hero:event '技能-施法开始' (function(_, _, skill)
		if skill:get_type() == '英雄' then
			self:remove()
			if skill.damage_base then
				skill.damage_base = skill.damage_base * rate
			end
			if skill.damage_plus then
				skill.damage_plus = skill.damage_plus * rate
			end
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	self.eff:remove()
	self.trg:remove()
end
