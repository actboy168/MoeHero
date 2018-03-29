local mt = ac.skill['死亡旋转']
{
	level = 0,
	art = [[btnkryke.blp]],
	title = '死亡旋转',
	tip = [[
|cff00ccff假想体跟随时|r:
黑雪姬施展环月斩，对周围区域造成%damage_base%(+%damage_plus%)伤害。

|cff00ccff假想体游荡时|r:
假想体冲向目标地点施展环月斩，对周围区域造成%damage_base%(+%damage_plus%)伤害。
	]],
	cool = {20, 12},
	cost = 70,
	cast_animation = 'spell one',
	range = 1000,
	area = 400,
	target_type = ac.skill.TARGET_TYPE_POINT,
	damage_base = {160, 240},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	speed = 1500,
}

function mt:on_cast_start()
	if self.target_type == ac.skill.TARGET_TYPE_POINT then
		self.on_cast_finish = self.on_cast_finish_a
	else
		self.on_cast_finish = self.on_cast_finish_b
	end
end

function mt:on_cast_finish_a()
	local hero = self.owner
	local skill = hero:find_skill '假想体'
	local next_target
	if not skill then
		return
	end
	local dummy = skill:create_dummy(self.target)
	if not dummy then
		return
	end
	skill:idle(false)
	local p = dummy:get_point()
	local target = self.target
	local damage = self.damage
	dummy:set_animation(4)
	local mover = ac.mover.line
	{
		source = hero,
		mover = dummy,
		angle = p / target,
		distance = p * target,
		speed = self.speed,
		skill = self,
		super = true,
	}

	if not mover then
		return
	end

	function mover:on_finish()
		local p = self.skill.target
		dummy:set_animation 'spell one'
		for _, u in ac.selector()
			: in_range(p, self.skill.area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = damage,
				aoe = true,
				skill = self.skill,
			}
			if u:is_hero() and u:is_alive() and u:is_in_range(hero, hero:get '攻击范围') then
				next_target = u
			end
		end
		p:add_effect [[epipulse_3_4.mdl]] :remove()
	end

	function mover:on_remove()
		skill:idle(true)
	end
	
	if self['绝对切断'] then
		local p = hero:get_point()
		local target = self.target
		local damage = self.damage
		
		local mover = ac.mover.line
		{
			source = hero,
			mover = hero,
			angle = p / target,
			distance = p * target,
			speed = self.speed,
			skill = self,
		}

		if not mover then
			return
		end

		function mover:on_finish()
			local p = hero:get_point()
			for _, u in ac.selector()
				: in_range(p, self.skill.area)
				: is_enemy(hero)
				: ipairs()
			do
				u:damage
				{
					source = hero,
					damage = damage,
					aoe = true,
					attack = true,
					skill = self.skill,
				}
				if u:is_hero() and u:is_alive() and u:is_in_range(hero, hero:get '攻击范围') then
					next_target = u
				end
			end
			p:add_effect [[epipulse_3_4.mdl]] :remove()
		end
	end
	if next_target then
		hero:issue_order('attack', next_target)
	end
end

function mt:on_cast_finish_b()
	local hero = self.owner
	local skill = hero:find_skill '假想体'
	if not skill then
		return
	end
	local dummy = skill.dummy
	if not dummy then
		return
	end
	local p = hero:get_point()
	local damage = self.damage
	local target
	for _, u in ac.selector()
		: in_range(p, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = damage,
			aoe = true,
			skill = self,
		}
		if u:is_hero() and u:is_alive() and u:is_in_range(hero, hero:get '攻击范围') then
			target = u
		end
	end
	p:add_effect [[epipulse_3_4.mdl]] :remove()

	if self['绝对切断'] then
		hero:wait(500, function()
			local p = hero:get_point()
			local damage = self.damage
			for _, u in ac.selector()
				: in_range(p, self.area)
				: is_enemy(hero)
				: ipairs()
			do
				u:damage
				{
					source = hero,
					damage = damage,
					aoe = true,
					attack = true,
					skill = self,
				}
				if u:is_hero() and u:is_alive() and u:is_in_range(hero, hero:get '攻击范围') then
					target = u
				end
			end
			p:add_effect [[epipulse_3_4.mdl]] :remove()
		end)
	end
	if target then
		hero:issue_order('attack', target)
	end
end
