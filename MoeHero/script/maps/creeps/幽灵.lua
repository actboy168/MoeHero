local mt = ac.skill['幽灵烧蓝']
{
	--烧蓝(%)
	mana_rate = 1,
}

function mt:on_add()
	local u = self.owner
	local rate = self.mana_rate / 100
	
	self.trg = u:event '造成伤害效果' (function(trg, damage)
		if not damage:is_attack() then
			return
		end

		local target = damage.target
		local mana = target:get '魔法上限' * rate
		target:add('魔法', - mana)
		target:add_effect('origin', [[Abilities\Spells\Human\Feedback\ArcaneTowerAttack.mdl]]):remove()
	end)
end

function mt:on_remove()
	self.trg:remove()
end

local mt = ac.skill['幽灵隐身']
{
	--持续时间
	time = 60,
}

function mt:on_add()
	local u = self.owner

	self.trg = u:event '单位-死亡' (function(trg, target, source)
		if not source then
			return
		end

		source:add_buff '隐身'
		{
			source = u,
			time = self.time,
			remove_when_attack = true,
			remove_when_spell = true,
			tip = '隐身%time%秒',
			send_tip = true,
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end
