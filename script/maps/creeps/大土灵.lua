local mt = ac.skill['大土灵-减速']

function mt:on_add()
	local u = self.owner

	self.trg = u:event '造成伤害效果' (function(trg, damage)
		if not damage:is_attack() then
			return
		end

		damage.target:add_buff '减速'
		{
			source = u,
			time = 2,
			move_speed_rate = 20,
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end
