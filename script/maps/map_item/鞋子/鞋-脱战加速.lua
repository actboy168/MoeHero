local mt = ac.buff['鞋-脱战加速']

mt.keep = true

--每层增加的移动速度(%)
mt.move_rate = 5

--最大叠加层数
mt.max_stack = 10

mt.pulse = 1

function mt:on_add()
	local hero = self.target
	if self:get_stack() < self.max_stack then
		self:add_stack()
		hero:add('移动速度%', self.move_rate)
	end
end

function mt:on_remove()
	local hero = self.target
	hero:add('移动速度%', - self.move_rate * self:get_stack())
end

function mt:on_pulse()
	self:on_add()
end

function mt:on_cover(dest)
	return false
end

local mt = ac.buff['鞋-加速']

mt.cover_type = 1
mt.cover_max = 1

function mt:on_add()
	local hero = self.target
	if not self.trg1 then
		self.trg1 = hero:event '单位-进入战斗' (function(trg, hero)
			if self.buff then
				self.buff:remove()
				self.buff = nil
			end
		end)
	end
	if not self.trg2 then
		self.trg2 = hero:event '单位-脱离战斗' (function(trg, hero)
			self.buff = hero:add_buff '鞋-脱战加速' {}
		end)
	end
	if not self.buff then
		self.buff = hero:add_buff '鞋-脱战加速' {}
	end
end

function mt:on_remove(new)
	local hero = self.target
	if new then
		new.trg1 = self.trg1
		new.trg2 = self.trg2
		new.buff = self.buff
	else
		self.trg1:remove()
		self.trg2:remove()
		if self.buff then
			self.buff:remove()
			self.buff = nil
		end
	end
end
