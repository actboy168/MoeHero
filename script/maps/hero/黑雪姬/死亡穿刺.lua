local mt = ac.skill['死亡穿刺']
{
	level = 0,
	art = [[btnkrykq.blp]],
	title = '死亡穿刺',
	tip = [[
|cff00ccff假想体跟随时|r:
假想体向目标地点冲刺，对沿途的敌人造成%damage_base%(+%damage_plus%)伤害。

|cff00ccff假想体游荡时|r:
黑雪姬冲向假想体，对沿途的敌人造成%damage_base%(+%damage_plus%)伤害。

|cffffff11可以储存%charge_max_stack%次|r
	]],
	cool = 0.2,
	charge_cool = {20, 8},
	cost = 60,
	cast_start_time = 0.3,
	cast_channel_time = 10,
	cast_animation = 'spell one',
	range = 800,
	target_type = ac.skill.TARGET_TYPE_NONE,
	hit_area = 200,
	damage_base = {80, 160},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	speed = 2000,
	cooldown_mode = 1,
	charge_max_stack = 2,
}

function mt:on_cast_start()
	if self.target_type == ac.skill.TARGET_TYPE_NONE then
		self.on_cast_channel = self.on_cast_channel_a
	else
		self.on_cast_channel = self.on_cast_channel_b
	end
end

function mt:on_cast_stop()
	if self.mover then
		self.mover:remove()
	end
end

function mt:on_cast_channel_a()
	local hero = self.owner
	local skill = hero:find_skill '假想体'
	if not skill then
		return
	end
	local dummy = skill.dummy
	if not dummy then
		return
	end
	local target = dummy:get_point()
	local angle = hero:get_point() / target
	local distance = hero:get_point() * target
	local damage = self.damage
	local eff = hero:add_effect('origin', [[distorsionnewsfxbydeckai_nodeath.mdl]])
	hero:set_facing(angle)
	local mover = ac.mover.target
	{
		source = hero,
		mover = hero,
		target = target,
		skill = self,
		speed = self.speed,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
		hit_area = self.hit_area,
		max_distance = 5000,
	}

	if not mover then
		eff:remove()
		self:stop()
		return
	end
	self.mover = mover
	
	function mover:on_hit(target)
		target:add_effect('chest', [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
		target:damage
		{
			source = hero,
			skill = self.skill,
			damage = damage,
			aoe = true,
			attack = true,
		}
		if target:is_hero() then
			hero:issue_order('attack', target)
		end
	end

	if not self['绝对切断'] then
		function mover:on_finish()
			skill:follow()
		end
	end

	function mover:on_remove()
		self.skill:finish()
		eff:remove()
	end

	if self['绝对切断'] then
		local dummy = skill:create_dummy(hero)
		if not dummy then
			return
		end
		local target = hero:get_point()
		local damage = self.damage
		local angle = dummy:get_point() / target
		local distance = dummy:get_point() * target
		local eff = dummy:add_effect('origin', [[distorsionnewsfxbydeckai_nodeath.mdl]])
		
		dummy:set_animation 'spell'
		dummy:add_animation 'stand'
		skill:idle(false)
		local mover = ac.mover.line
		{
			source = hero,
			mover = dummy,
			angle = angle,
			distance = distance,
			speed = self.speed,
			skill = self,
			super = true,
			hit_type = ac.mover.HIT_TYPE_ENEMY,
			hit_area = self.hit_area,
		}

		if not mover then
			eff:remove()
			return
		end

		function mover:on_hit(target)
			target:add_effect('chest', [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
			target:damage
			{
				source = hero,
				damage = damage,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
		end

		function mover:on_remove()
			skill:idle(true)
			eff:remove()
		end
	end
end

function mt:on_cast_channel_b()
	local hero = self.owner
	local skill = hero:find_skill '假想体'
	if not skill then
		return
	end
	local dummy = skill:create_dummy()
	if not dummy then
		return
	end

	local damage = self.damage
	local angle = dummy:get_point() / self.target
	local distance = dummy:get_point() * self.target
	local eff = dummy:add_effect('origin', [[distorsionnewsfxbydeckai_nodeath.mdl]])
	
	dummy:set_animation 'spell'
	dummy:add_animation 'stand'
	skill:idle(false)
	local mover = ac.mover.line
	{
		source = hero,
		mover = dummy,
		angle = angle,
		distance = distance,
		speed = self.speed,
		skill = self,
		super = true,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
		hit_area = self.hit_area,
	}

	if not mover then
		eff:remove()
		self:stop()
		return
	end

	function mover:on_hit(target)
		target:add_effect('chest', [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
		target:damage
		{
			source = hero,
			damage = damage,
			skill = self.skill,
			aoe = true,
		}
	end

	function mover:on_remove()
		self.skill:finish()
		skill:idle(true)
		eff:remove()
	end

	if self['绝对切断'] then
		hero:wait(200, function()
			local damage = self.damage
			local eff = hero:add_effect('origin', [[distorsionnewsfxbydeckai_nodeath.mdl]])
			hero:set_facing(angle)
			local mover = ac.mover.line
			{
				source = hero,
				mover = hero,
				angle = angle,
				distance = distance,
				skill = self,
				speed = self.speed,
				hit_type = ac.mover.HIT_TYPE_ENEMY,
				hit_area = self.hit_area,
			}

			if not mover then
				eff:remove()
				return
			end

			function mover:on_hit(target)
				target:add_effect('chest', [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
				target:damage
				{
					source = hero,
					skill = self.skill,
					damage = damage,
					aoe = true,
				}
				if target:is_hero() then
					hero:issue_order('attack', target)
				end
			end

			function mover:on_remove()
				eff:remove()
			end
		end)
	end
end
