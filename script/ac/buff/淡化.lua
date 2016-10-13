
local mt = ac.buff['淡化']
mt.keep = true
mt.pulse = 0.02
mt.remove_when_hit = true
mt.alpha = 100

function mt:on_add()
	local count = self.time / self.pulse
	--self.alpha = self.target:getAlpha()
	self.alpha_change = self.alpha / count

	self:on_pulse()
end

function mt:on_pulse()
	self.alpha = self.alpha - self.alpha_change
	self.target:setAlpha(self.alpha)
end

function mt:on_finish()
	if self.remove_when_hit then
		self.target:remove()
	end
end

--淡化*改
local mt = ac.buff['淡化*改']
mt.keep = true
mt.pulse = 0.02
mt.remove_when_hit = true
mt.source_alpha = nil
mt.target_alpha = 0
mt.change_alpha = nil

function mt:on_add()
	local count = self.time / self.pulse
	if not self.source_alpha then
		self.source_alpha = self.target:getAlpha()
	end
	self.change_alpha = (self.target_alpha - self.source_alpha) / count
	self:on_pulse()
end

function mt:on_pulse()
	self.source_alpha = self.source_alpha + self.change_alpha
	self.target:setAlpha(self.source_alpha)
end

function mt:on_finish()
	if self.remove_when_hit then
		self.target:remove()
	end
end
