local mt = ac.skill['螺旋丸']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNmrq.blp]],

	--技能说明
	title = '螺旋丸',
	
	tip = [[
造成%damage_base%(+%damage_plus%)伤害，击晕%stun%秒并击退%distance%距离，并且对%damage_area%范围造成%damage_percent%%伤害溅射
释放距离%min_range%以内时快速发动
		]],

	--耗蓝
	cost = 100,

	--冷却
	cool = 12,

	--施法距离
	range = 750,

	--最小施法距离，大于则需要引导
	min_range = 300,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--动画
	cast_animation = 6,

	--施法前摇
	cast_start_time = 0.2,

	--引导时间
	cast_channel_time = 10,

	cast_finish_time = 0.45,
	
	cast_channel_2_time = 0.75,

	--速度
	speed = 1000,


	--眩晕时间
	stun = 1,

	--击退距离
	distance = 300,

	--伤害范围
	damage_area = 200,

	--伤害溅射%
	damage_percent = 80,

	--伤害
	damage_base = {100, 300},
	damage_plus = function (self, hero)
		return hero:get_ad() * 3.2
	end,
	damage = function (self, hero)
		return self.damage_base + self.damage_plus
	end,

	break_order = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local point = hero:get_point() - {(hero:get_point()/target:get_point())-40,125}
	hero:set_animation(6)
	if (target:get_point() * hero:get_point()) <= self.min_range then
		self.immediately = true
		self.cast_channel_2_time = 0.05
		ac.effect(hero:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
		self.hand_eff = hero:add_effect('hand', [[modeldekan\ability\DEKAN_Naturo_Q_LXW.mdl]])
	else
		self.immediately = false
		self.dummy = hero:create_dummy(nil, point, target:get_point() / hero:get_point() - 20)
		self.dummy:add_restriction '硬直'
		self.dummy:add_restriction '缴械'
		self.dummy:set_class '马甲'
		self.dummy:set_animation(5)
		ac.effect(self.dummy:get_point(), [[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
		self.hand_eff = hero:add_effect('hand', [[modeldekan\ability\DEKAN_Naturo_Q_LXW_Birth.mdl]])
	end

	self.cast_channel_2_timer = hero:wait(self.cast_channel_2_time*1000, function()
		self:on_cast_channel_2()
	end)
end

function mt:on_cast_channel_2()
	local hero = self.owner
	local target = self.target
	local point = hero:get_point() - {(hero:get_point()/target:get_point())-40, 125}
	local animation_speed = 0.4 / ( math.abs(hero:get_point() * target:get_point() - 150) / self.speed )
	hero:set_animation_speed(animation_speed)
	hero:set_animation(12)

	if not self.immediately then
		ac.effect(self.dummy:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
		self.dummy:remove()
		self.dummy = nil
	end
	
	local mvr = ac.mover.target
	{
		source = hero,
		mover = hero,
		target = target,
		speed = self.speed,
		skill = self,
	}
	if not mvr then
		self:stop()
		return
	end
	function mvr:on_remove()
		local skill = self.skill
		local angle = hero:get_point() / target:get_point()
		ac.effect(target:get_point(), [[modeldekan\ability\DEKAN_Naturo_Q_Blust.mdl]], angle):remove()
		target:add_effect('chest', [[modeldekan\ability\DEKAN_Naturo_Q_Effect.mdl]]):remove()
		target:add_buff '击退'
		{
			angle = angle,
			distance = skill.distance,
			time = skill.stun,
			speed = skill.speed,
			accel = -3,
		}
		hero:add_buff '击退'
		{
			angle = angle,
			distance = skill.distance,
			time = skill.stun,
			speed = skill.speed,
			accel = -3,
		}
		target:damage
		{
			source = hero,
			skill = skill,
			damage = skill.damage,
			attack = true,
		}

		--伤害溅射
		for _, u in ac.selector()
			: in_range(target, skill.damage_area)
			: is_enemy(hero)
			: is_not(target)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				skill = skill,
				damage = skill.damage * skill.damage_percent / 100,
				attack = true,
				aoe = true,
			}
		end
		skill:finish()
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	self.cast_channel_2_timer:remove()
	if self.dummy then
		self.dummy:remove()
	end
	self.hand_eff:remove()
	hero:set_animation_speed(1)
end
