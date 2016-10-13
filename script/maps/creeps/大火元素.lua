local mt = ac.skill['火元素爆炸']
	
function mt:on_add()
	local u = self.owner
	
	self.trg = u:event '单位-死亡' (function(trg, target, source)
		for _, dest in ac.selector()
			: in_range(u, 200)
			: is_not(u)
			: ipairs()
		do
			if dest == source then
				source = u
			end
			dest:damage
			{
				source = source,
				skill = self,
				damage = 25,
				aoe = true
			}
		end

		u:add_effect('origin', [[Abilities\Spells\Other\Volcano\VolcanoDeath.mdl]]):remove()
	end)
end

function mt:on_remove()
	self.trg:remove()
end
