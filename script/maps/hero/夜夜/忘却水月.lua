local mt = ac.skill['忘却水月']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNYayaQ.blp]],
	title = '忘却水月',
	tip = [[
夜夜向前飞踹%distance%距离，对命中的敌人造成%damage_base%(+%damage_plus%)伤害，在命中一名敌方英雄后停下。
		]],
	cost = 60,
	cool = {17, 9},
	range = 9999,
	distance = 600,
	target_type = ac.skill.TARGET_TYPE_POINT,
	cast_animation = 'spell channel two',
	cast_channel_time = 10,
	speed = 1500,
	area = 200,
	damage_base = {60, 220},
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
	self.eff = hero:add_effect("foot left", [[Abilities\Weapons\FaerieDragonMissile\FaerieDragonMissile.mdl]])
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = hero:get_point() / self.target,
		distance = math.min(self.distance, hero:get_point() * self.target),
		speed = self.speed,
		skill = self,
		hit_area = self.area,
	}
	if not mvr then
		self:stop()
		return
	end
	function mvr:on_hit(target)
		target:damage
		{
			source = hero,
			damage = self.skill.damage,
			skill = self.skill,
			aoe = true,
			attack = true,
		}
		if target:is_hero() then
			target:add_effect('origin', [[war3mapimported\explosion.mdl]]):remove()
			return true
		end
	end
	function mvr:on_remove()
		self.skill:finish()
		hero:issue_order('attack', hero:get_point())
	end
end

function mt:on_cast_stop()
	self.eff:remove()
end
