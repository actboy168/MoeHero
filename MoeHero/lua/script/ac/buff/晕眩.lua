local mt = ac.buff['晕眩']

mt.cover_type = 1
mt.cover_max = 1

mt.control = 10
mt.debuff = true
mt.model = [[Abilities\Spells\Human\Thunderclap\ThunderclapTarget.mdl]]

function mt:on_add()
	if not self.eff and self.model then
		self.eff = self.target:add_effect('overhead', self.model)
	end
	self.target:add_restriction '晕眩'
	self.target:cast_stop()
end

function mt:on_remove(new)
	if self.eff then
		if new then
			new.eff = self.eff
		else
			self.eff:remove()
		end
	end
	self.target:remove_restriction '晕眩'
end
