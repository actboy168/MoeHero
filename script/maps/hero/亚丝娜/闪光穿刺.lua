local mt = ac.skill['闪光穿刺']

mt{
	level = 0,
	art = [[BTNasne.blp]],
	title = '闪光穿刺',
	tip = [[
向目标地点冲去，造成%damage_base%(+%damage_plus%)点伤害，并击飞沿途的单位。
	]],

	cool = {22, 14},
	cost = 50,
	range = 9999,
	distance = {650, 750},
	cast_animation = 'spell two',
	cast_animation_speed = 2,
	cast_start_time = 0.2,
	cast_channel_time = 10,
	cast_shot_time = 0.5,
	cast_finish_time = 0.5,
	target_type = ac.skill.TARGET_TYPE_POINT,
	area = 300,
	damage_base = {80, 200},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	break_order = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local distance = math.min(hero:get_point() * self.target, self.distance)
	local angle = hero:get_point() / self.target
	local w_skill = hero:find_skill '狂暴补师'
	hero:set_animation_speed(0.01)
	hero:add_effect('chest', [[model\asuna\e_sprintwind.mdx]]):remove()
	self.eff1 = hero:add_effect('weapon',[[model\asuna\e_sprintribbon.mdl]])
	self.eff2 = hero:add_effect('chest',[[model\asuna\e_sprintribbon.mdl]])
	self.eff3 = hero:add_effect('foot left',[[model\asuna\e_sprintribbon.mdl]])
	self.eff4 = hero:add_effect('origin', [[model\asuna\e_starparticle.mdl]])
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		speed = 600,
		accel = 10000,
		distance = distance + 150,
		target = self.target,
		skill = self,
		hit_area = 200,
	}
	if not mvr then
		self:stop()
		return
	end
	function mvr:on_hit(target)
		local _, r = ac.math_angle(angle, hero:get_point() / target:get_point())
		local angle = angle
		if r > 0 then
			angle = angle + 90
		else
			angle = angle - 90
		end
		target:add_buff '击退'
		{
			source = hero,
			angle = angle,
			speed = 1000,
			time = 0.4,
			accel = -4000,
			high = 300,
		}
	end
	function mvr:on_remove()
		if w_skill then
			w_skill:on_hit()
		end
		self.skill:finish()
		hero:set_facing(hero:get_point() / self.target)
		hero:set_animation('spell one')
		hero:set_animation_speed(1.3)
		--hero:add_effect('origin', [[model\asuna\e_weaponeffect.mdl]]):remove()
	end
end

function mt:on_cast_finish()
	local hero = self.owner
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = self.damage,
			skill = self,
			aoe = true,
			attack = true,
		}
	end
end

function mt:on_cast_stop()
	self.eff1:remove()
	self.eff2:remove()
	self.eff3:remove()
	self.eff4:remove()
end
