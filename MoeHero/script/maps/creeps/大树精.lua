local mt = ac.skill['树精破甲']
{
	--减甲(%)
	defence_rate = 5,
	--叠加次数
	stack_max = 5,
	--持续时间
	time = 5,
}

function mt:on_add()
	local u = self.owner

	self.trg = u:event '造成伤害效果' (function(trg, damage)
		if not damage:is_attack() then
			return
		end

		damage.target:add_buff '树精破甲'
		{
			source = u,
			rate = self.defence_rate,
			stack_max = self.stack_max,
			time = self.time,
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end


local buff = ac.buff['树精破甲']

buff.debuff = true
buff.eff = nil
buff.stack_max = 0

function buff:on_add()
	self:set_stack(1)
	self.eff = self.target:add_effect('overhead', [[Abilities\Spells\Undead\UnholyFrenzy\UnholyFrenzyTarget.mdl]])
	self.target:add('护甲%', - self.rate)
end

function buff:on_remove()
	self.eff:remove()
	self.target:add('护甲%', self.rate)
end

function buff:on_cover(dest)
	self:set_remaining(dest.time)
	if self:get_stack() < dest.stack_max then
		self:set_stack(self:get_stack() + 1)
		self.target:add('护甲%', - dest.rate)
		self.rate = self.rate + dest.rate
	end
	return false
end

local mt = ac.skill['树精荆棘甲']
{
	--持续时间
	time = 60,
	--反弹伤害(%)
	life_rate = 25,
}

function mt:on_add()
	local u = self.owner

	self.trg = u:event '单位-死亡' (function(trg, target, source)
		if not source then
			return
		end

		source:add_buff '树精荆棘甲'
		{
			source = u,
			time = self.time,
			rate = self.life_rate,
			skill = self
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end


local buff = ac.buff['树精荆棘甲']

buff.tip = '受到伤害时反馈25%伤害'
buff.send_tip = true
buff.buff = true
buff.trg = nil
buff.eff = nil

function buff:on_add()
	local u = self.target
	local rate = self.rate / 100

	self.eff = u:add_effect('origin', [[Abilities\Spells\NightElf\ThornsAura\ThornsAura.mdl]])

	self.trg = u:event '受到伤害效果' (function(trg, damage)
		local source = damage.source
		if not source then
			return
		end
		
		if not damage:is_attack() then
			return
		end

		damage.source:damage
		{
			source = u,
			damage = damage.damage * rate,
			skill = self.skill
		}
	end)
end

function buff:on_remove()
	self.trg:remove()
	self.eff:remove()
end
