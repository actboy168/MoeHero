local mt = ac.buff['减攻速']

mt.control = 2
mt.cover_type = 1
mt.cover_max = 1
mt.effect = nil
mt.ref = 'origin'
mt.model = [[Abilities\Spells\Human\slow\slowtarget.mdl]]

function mt:on_add()
	self.effect = self.target:add_effect(self.ref, self.model)
	self.target:add('攻击速度', - self.attack_speed)
end

function mt:on_remove()
	self.effect:remove()
	self.target:add('攻击速度', self.attack_speed)
end

function mt:on_cover(new)
	return new.attack_speed > self.attack_speed
end
