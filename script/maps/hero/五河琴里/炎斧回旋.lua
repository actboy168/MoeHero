local mt = ac.skill['炎斧回旋']

mt{
	level = 0,
	art = [[BTNqlq.blp]],
	title = '炎斧回旋',
	tip = [[
回旋着甩动巨斧冲向目标地点，对沿途的敌方单位造成%damage_base%(+%damage_plus%)伤害。
	]],
	cool = {12, 8},
	cost = -24,
	range = 9999,
	target_type = ac.skill.TARGET_TYPE_POINT,
	cast_animation = 8,
	cast_animation_speed = 3,
	cast_start_time = 0.0,
	cast_channel_time = 10,
	distance = 500,
	speed = 1200,
	hit_area = 250,
	damage_base = {60, 120},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	proc = 0.5,
}

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	self.eff = hero:add_effect('weapon', [[Abilities\Weapons\PhoenixMissile\Phoenix_Missile.mdl]])
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		speed = self.speed,
		angle = angle,
		distance = self.distance,
		skill = self,
		hit_area = self.hit_area,
		hit_type = ac.mover.HIT_TYPE_ENEMY
	}
	if not mvr then
		self:stop()
		return
	end
	function mvr:on_hit(target)
		target:add_effect('chest', [[Abilities\Weapons\PhoenixMissile\Phoenix_Missile_mini.mdl]]):remove()
		target:damage
		{
			source = hero,
			damage = self.skill.damage,
			skill = self.skill,
			aoe = true,
			attack = true,
		}
	end
	function mvr:on_remove()
		self.skill:finish()
		hero:issue_order('attack', hero:get_point())
	end
end

function mt:on_cast_stop()
	self.eff:remove()
end
