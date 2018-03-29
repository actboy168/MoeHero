local mt = ac.buff['击退']

mt.cover_type = 1

mt.keep = true

mt.angle = 0
mt.high = 0
mt.accel = 0
mt.skill = false
mt.dummy_buff = nil
mt.control = 10

function mt:on_add()
	local source, target = self.source, self.target
	local buff = self
	local time, speed, distance = self.time, self.speed, self.distance
	if time == 0 then
		time = distance / speed
	elseif not speed then
		speed = distance / time
	elseif not distance then
		distance = speed * time
	end

	self.mover = ac.mover.line
	{
		source = source,
		start = target,
		mover = target,
		angle = self.angle,
		distance = distance,
		speed = speed,
		height = self.high,
		accel = self.accel,
		keep = true,
		skill = self.skill,
		block = true,
	}

	if not self.mover then
		self:remove()
		return
	end

	function self.mover:on_remove()
		if buff.event_remove then
			buff:event_remove()
		end
		buff:remove()
	end
	
	target:add_restriction '晕眩'
end

function mt:on_remove()
	if self.mover then
		self.target:remove_restriction '晕眩'
		self.mover:remove()
	end
end
