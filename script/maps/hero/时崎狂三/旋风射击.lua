local mt = ac.skill['旋风射击']

mt{
	--初始等级
	level = 0,
	--技能图标
	art = [[model\Kurumi\BTNKurumiQ.blp]],

	--技能说明
	title = '旋风射击',
	
	tip = [[
召唤分身扫射目标范围的敌人，造成%damage_base%(+%damage_plus%)的伤害。

|cffff8811旋风射击[刻]|r：
扫射范围变大，并对外圈的伤害提高%damage_rate%%。
	]],

	--目标类型
	target_type = function(self, hero)
		if hero:find_buff '四之弹-时' then
			return ac.skill.TARGET_TYPE_NONE
		else
			return ac.skill.TARGET_TYPE_POINT
		end
	end,
	base_range = 300,
	area = function(self, hero)
		if hero:find_buff '四之弹' then
			return 600
		else
			return 400
		end
	end,
	cost = {100, 60},
	charge_cool = {18, 10},
	charge_max_stack = 1,
	cooldown_mode = 1,
	show_stack = 0,
	show_charge = 0,
	--施法距离
	range = 800,
	--施法动画
	cast_animation = 'spell three',
	cast_animation_speed = 7.5,
	--施法前摇
	cast_start_time = 0.1,
	cast_shot_time = 0.4,
	cast_finish_time = 0.4,
	-- 伤害
	damage_base = {80, 200},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	-- 额外伤害(%)
	damage_rate = {60, 100},
}

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local damage = self.damage
	local damage_power = damage * (1 + self.damage_rate / 100)
	local power1 = hero:find_buff '四之弹'
	local power2 = hero:find_buff '四之弹-时'
	hero:set_animation_speed(1.5)
	if power1 then
		power1:remove()
	end
	if power2 then
		target = power2.cent
	end

	hero:force_cast('八之弹', target, {call_back = function(_, dummy)
		dummy:set_animation 'spell four'
		dummy:add_animation 'stand'
		dummy:add_restriction '缴械'
		ac.wait(1500, function()
			dummy:remove_restriction '缴械'
		end)
	end})

	ac.wait(300, function()
		if power1 then
			local effect = target:effect
			{
				model = [[model\Kurumi\W.mdl]],
				size = 1.8,
			}
			effect:kill()
		else
			local effect = target:effect
			{
				model = [[model\Kurumi\W.mdl]],
				size = 1.2,
			}
			effect:kill()
		end
		ac.timer(100, 10, function()
			for _, u in ac.selector()
				: in_range(target, self.area)
				: is_enemy(hero)
				: ipairs()
			do
				local damage = damage
				if power1 and u:get_point() * target >= 300 then
					damage = damage_power
				end

				u:damage
				{
					source = hero,
					skill = self,
					aoe = true,
					attack = true,
					damage = damage / 10,
				}
			end
		end)

		if power2 then
			local buff = hero:find_buff '食时之城'
			if buff then
				buff:power()
			end
		end
	end)
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:set_animation_speed(1)
	hero:set_animation('stand')
end
