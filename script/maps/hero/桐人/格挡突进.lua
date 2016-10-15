local mt = ac.skill['格挡突进']

mt{
	level = 0,
	art = [[BTNtrq.blp]],
	title = '格挡突进',
	tip = [[
提高%move_speed%移动速度，向目标单位快速移动。
期间格挡所有来自于目标的伤害，下一次普通攻击附加额外伤害并减少敌人移动速度%move_rate%%，持续%time_rate%秒。
额外伤害根据移动的距离决定，最多%damage_base%(+%damage_plus%)伤害。
	]],
	break_order = 1,
	range = {900, 1100},
	cost = 70,
	cool = 9,
	target_type = mt.TARGET_TYPE_UNIT,
	move_speed = 1000,
	damage_base = {140, 300},
	damage_plus = function(self, hero)
		return hero:get_ad() * 2.0
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	move_rate = 80,
	time_rate = 1,
	max_range = 1000,
	time = 5,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	hero:add_buff '格挡突进'
	{
		time = self.time,
		skill_target = target,
		move_speed = self.move_speed,
		damage = self.damage,
		skill = self,
		pulse = 0.1,
	}
end

local mt = ac.orb_buff['格挡突进']

mt.orb_count = 1

function mt:on_start(damage)
	return not damage:is_common_attack()
end

function mt:on_hit(damage)
	local hero = self.target
	local target = damage.target
	hero:add_effect('origin', [[basicstrike01.mdl]]):remove()
	local damage = self.skill.damage
	if self.moved < self.skill.max_range then
		damage = damage * (1 + self.moved / self.skill.max_range) / 2
	else
		damage = damage
	end
	target:add_buff '减速'
	{
		source = hero,
		move_speed_rate = self.skill.move_rate,
		time = self.skill.time_rate,
	}
	target:damage
	{
		source = hero,
		skill = self.skill,
		damage = damage,
	}
end

function mt:on_add()
	local hero = self.target
	self.last_point = hero:get_point()
	self.moved = 0
	hero:add('移动速度', self.move_speed)
	hero:add_restriction '飞行'
	hero:issue_order('attack', self.skill_target)
	hero:add_animation_properties('defend')
	hero:add_effect('chest',[[ModelDEKAN\Ability\DEKAN_Kirito_Q_SprintWind.mdl]]):remove()
	if hero:find_buff '二刀流' then
		hero:add_effect('chest', [[ModelDEKAN\Ability\DEKAN_Kirito_Q_SprintWind_blue.mdl]]):remove()
	end
	self.trg1 = hero:event '单位-发布指令' (function(_, _, order, target)
		if (order ~= 'smart' and order ~= 'attack') or self.skill_target ~= target then
			self:remove()
		end
	end)
	self.trg2 = hero:event '受到伤害前效果' (function(_, damage)
		if self.skill_target == damage.target then
			damage['格挡'] = damage['格挡'] + 100
			damage['格挡伤害'] = damage['格挡伤害'] + 100
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	hero:add('移动速度', -self.move_speed)
	hero:remove_restriction '飞行'
	hero:remove_animation_properties('defend')
	self.trg1:remove()
	self.trg2:remove()
end

function mt:on_pulse()
	local hero = self.target
	if hero:getOrder() ~= 'attack' then
		self:remove()
		return
	end

	self.moved = self.moved + hero:get_point() * self.last_point
	self.last_point = hero:get_point()
end
