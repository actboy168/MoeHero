local mt = ac.buff['束缚']

mt.cover_type = 1

mt.control = 7
mt.model = nil
mt.eff = nil
mt.debuff = true

function mt:on_add()
	self.target:add_restriction '定身'
	self.target:add_restriction '缴械'
	if self.model then
		self.eff = self.target:add_effect('origin', self.model)
	end
end

function mt:on_remove()
	if self.eff then
		self.eff:remove()
	end
	self.target:remove_restriction '定身'
	self.target:remove_restriction '缴械'
end

function mt:on_cover(new)
	if new.time > self:get_remaining() then
		self:set_remaining(new.time)
	end
	return false
end
