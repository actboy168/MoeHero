local mt = ac.buff['高度']

mt.pulse = 0.02
mt.changed = 0
mt.target_changed = 0
mt.speed = 0

mt.reduction_when_remove = false

function mt:on_add()
	self.target_changed = self.speed * self.time
end

function mt:on_pulse()
	local changed = self.pulse * self.speed
	self.target:add_high(changed)
	self.changed = self.changed + changed
end

function mt:on_finish()
	self.reduction_when_remove = false
end

function mt:on_remove()
	if self.reduction_when_remove then
		self.target:add_high(- self.changed)
	else
		self.target:add_high(self.target_changed - self.changed)
	end
end
