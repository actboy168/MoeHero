local mt = ac.buff['缩放']

mt.origin_size = 1
mt.target_size = 1

mt.pulse = 0.02

function mt:on_add()
	self.target:set_size(self.origin_size)
end

function mt:on_pulse()
	local u = self.target
	local time = self:get_remaining()
	if time <= 0.02 then
		u:set_size(self.target_size)
		self:remove()
		return
	end

	self.origin_size = self.origin_size + (self.target_size - self.origin_size) * (self.pulse / time)
	u:set_size(self.origin_size)
end
