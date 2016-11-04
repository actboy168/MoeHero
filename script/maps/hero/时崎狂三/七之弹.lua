local mt = ac.skill['七之弹']

mt{
	--初始等级
	level = 0,
	--技能图标
	art = [[model\Kurumi\BTNKurumiW.blp]],

	--技能说明
	title = '七之弹',
	
	tip = [[
召唤分身，将目标区域的敌人|cffffcc00时停|r并拖入影空间，持续%pause_time%秒。随后造成%damage_base%(+%damage_plus%)伤害。

|cffff8811七之弹[刻]|r:
敌人离开影空间后会继续被时停%power_time%秒。
	]],

	--目标类型
	target_type = function(self, hero)
		if hero:find_buff '四之弹-时' then
			return ac.skill.TARGET_TYPE_NONE
		else
			return ac.skill.TARGET_TYPE_POINT
		end
	end,
	area = function(self, hero)
		if hero:find_buff '四之弹-时' then
			return 600
		else
			return 250
		end
	end,
	cost = {120, 80},
	charge_cool = {18, 14},
	charge_max_stack = 1,
	cooldown_mode = 1,
	show_stack = 0,
	show_charge = 0,
	--施法距离
	range = 800,
	--施法动画
	cast_animation = 'spell two',
	cast_animation_speed = 2.5,
	--施法前摇
	cast_start_time = 0.8,
	cast_finish_time = 0.5,
	-- 弹道飞行速度
	speed = 2000,
	-- 时停时间
	pause_time = {1.2, 1.6},
	-- 伤害
	damage_base = {80, 200},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	-- 额外时停
	power_time = {0.5, 0.9},
}

function mt:on_cast_start()
	local hero = self.owner
	local buff = hero:find_buff '四之弹-时'
	if buff then
		self.target = buff.cent
		ac.wait(0, function()
			hero:set_facing(hero:get_point() / self.target)
		end)
	end
end

function mt:on_cast_shot()
	local hero = self.owner
	local skill = self
	local start = hero:get_launch_point()
	local target = self.target
	local power1 = hero:find_buff '四之弹'
	local power2 = hero:find_buff '四之弹-时'
	local mover = nil
	if power1 then
		power1:remove()
	end
	if power2 then
		mover = ac.mover.line
		{
			source = hero,
			start = start,
			skill = self,
			target = target,
			speed = self.speed,
			model = [[model\kurumi\ball_big.mdl]],
			high = 220,
			size = 2,
		}
	else
		mover = ac.mover.line
		{
			source = hero,
			start = start,
			skill = self,
			target = target,
			speed = self.speed,
			model = [[model\kurumi\ball.mdl]],
			size = 2,
		}
	end

	if not mover then
		return
	end

	local function deal_damage(u)
		u:add_effect('chest', [[model\kurumi\ball.mdl]]):remove()
		u:damage
		{
			source = hero,
			skill = self,
			damage = self.damage,
			aoe = true,
			attack = true,
		}
	end

	function mover:on_finish()
		local g = ac.selector()
			: in_range(target, skill.area)
			: is_enemy(hero)
			: get()

		local dummys = {}
		for i, u in ipairs(g) do
			if not u:is_type('建筑') then
				u:add_restriction '时停'
				u:add_restriction '阿卡林'
				u:add_restriction '无敌'
				local dummy = hero:create_unit('e00O', u:get_point(), u:get_facing())
				dummys[i] = dummy
				local size = u:get_slk('modelScale', 0) * u:get_size()
				dummy:set_size(size)
				dummy:set_high(200 * size)
				dummy:add_effect('origin', u:get_slk('file', ''))
				local time = skill.pause_time - 0.3
				dummy:add_buff '高度'
				{
					skill = skill,
					speed = - 200 * size / time,
					time = time,
				}
			else
				deal_damage(u)
			end
		end

		ac.wait(skill.pause_time * 1000 - 300, function()
			for i, u in ipairs(g) do
				local dummy = dummys[i]
				if dummy then
					local size = u:get_slk('modelScale', 0) * u:get_size()
					local distance = math.random(100, 300)
					local mover = ac.mover.line
					{
						source = hero,
						mover = dummy,
						target_high = 200 * size,
						height = 200 * size,
						speed = distance / 0.3,
						distance = distance,
						angle = math.random(360),
						skill = skill,
					}

					if not mover then
						u:set_position(dummy:get_point())
						u:remove_restriction '时停'
						u:remove_restriction '阿卡林'
						u:remove_restriction '无敌'
						dummy:remove()
						deal_damage(u)
						return
					end

					function mover:on_remove()
						u:set_position(dummy:get_point())
						if power1 then
							ac.wait(skill.power_time * 1000, function()
								u:remove_restriction '时停'
							end)
						else
							u:remove_restriction '时停'
						end
						u:remove_restriction '阿卡林'
						u:remove_restriction '无敌'
						dummy:remove()
						deal_damage(u)
					end
				end
			end
		end)

		ac.wait(skill.pause_time * 1000, function()
			hero:force_cast('八之弹', target, {call_back = function(_, dummy)
				dummy:set_animation 'spell channel two'
				dummy:add_animation 'stand'
				dummy:set_size(0)
				ac.wait(100, function()
					dummy:set_size(1)
				end)
				dummy:add_restriction '缴械'
				ac.wait(600, function()
					dummy:remove_restriction '缴械'
				end)
			end})
		end)
	end
end
