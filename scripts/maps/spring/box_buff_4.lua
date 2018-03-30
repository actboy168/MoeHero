local buff = ac.buff['奥能涌动']

buff.tip = '你的Q技能会代替普通攻击，但伤害只有%damage%%，持续%time%秒'
buff.send_tip = true

buff.damage = 40
buff.time = 30
buff.q_passive = false

function buff:on_add()
	local hero = self.target
	self.eff = hero:add_effect('origin', [[222.mdl]])
	self.trg1 = hero:event '单位-发动攻击' (function(trg, damage)
		local skl = hero:find_skill(1, '英雄')
		if not skl then
			return
		end
		if damage.skill and damage.skill.name == skl.name then
			return
		end
		local target = nil
		if skl.target_type == ac.skill.TARGET_TYPE_NONE then
			target = nil
		elseif skl.target_type == ac.skill.TARGET_TYPE_UNIT then
			target = damage.target
		elseif skl.target_type == ac.skill.TARGET_TYPE_POINT then
			target = damage.target:get_point()
		else
			target = damage.target
		end
		skl:cast(target, {instant = 1, force_cast = 1, cost = 0, cool = 0, cast_start_time = 0 })
		return true
	end)
	self.trg2 = hero:event '造成伤害' (function(trg, damage)
		if not damage:is_skill() then
			return
		end
		if damage.skill.slotid ~= 1 then
			return
		end
		damage:div(1-self.damage/100.0)
	end)
	
	local skl = hero:find_skill(1)
	if skl then
		self.skl = skl
		skl:set_option('passive', true)
	end
end

function buff:on_remove()
	self.eff:remove()
	self.trg1:remove()
	self.trg2:remove()
	local hero = self.target
	local skl = self.skl
	if skl then
		skl:set_option('passive', false)
	end
end

function buff:on_cover()
	return true
end
