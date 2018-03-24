local mt = ac.buff['减速']

mt.cover_type = 1
mt.cover_max = 1

mt.control = 2
mt.debuff = true
mt.effect = nil
mt.ref = 'origin'
mt.model = [[Abilities\Spells\Human\slow\slowtarget.mdl]]

function mt:on_add()
	self.effect = self.target:add_effect(self.ref, self.model)
	self.target:add('移动速度%', - self.move_speed_rate)
end

function mt:on_remove()
	self.effect:remove()
	self.target:add('移动速度%', self.move_speed_rate)
end

function mt:on_cover(new)
	return new.move_speed_rate > self.move_speed_rate
end
