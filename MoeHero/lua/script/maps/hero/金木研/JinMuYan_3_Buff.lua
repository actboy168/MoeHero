local mt = ac.buff['JinMuYan_3_Buff']

function mt:on_add()
	local hero = self.target
	hero:add('格挡', self.dodge_chance)
	self.trg = hero:event '受到伤害格挡' (function (_, _)
		self.trg:disable()
		hero:wait(self.cool * 1000, function()
			self.trg:enable()
		end)
		hero:get_point():add_effect([[war3mapimported\redshockwave_weak.mdl]]):remove()
		for _, u in ac.selector()
			: in_range(hero, self.area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = self.damage,
				aoe = true,
				skill = self.skill
			}
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	self.trg:remove()
	hero:add('格挡', -self.dodge_chance)
end
