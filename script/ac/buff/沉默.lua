local mt = ac.buff['沉默']

mt.cover_type = 1
mt.cover_max = 1

mt.debuff = true
mt.control = 7
mt.model = [[Abilities\Spells\Other\Silence\SilenceTarget.mdl]]
mt.eff = nil

function mt:on_add()
	self.target:add_restriction '禁魔'
	if self.model then
		self.eff = self.target:add_effect('overhead', self.model)
	end
end

function mt:on_remove()
	if self.eff then
		self.eff:remove()
	end
	self.target:remove_restriction '禁魔'
end

function mt:on_cover(new)
	if new.time > self:get_remaining() then
		self:set_remaining(new.time)
	end
	return false
end
