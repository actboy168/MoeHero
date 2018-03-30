local mt = ac.skill['狗熊暴击']
{
	--暴击率(%)
	crit_chance = 50,
}

function mt:on_add()
	self.owner:add('暴击', self.crit_chance)
end

function mt:on_remove()
	self.owner:add('暴击', -self.crit_chance)
end

local mt = ac.skill['熊皮护盾']
{
	--护盾生命
	life = 150,
	--护盾比例
	rate = 15,
}

function mt:on_add()
	local u = self.owner
	self.trg = u:event '单位-死亡' (function(trg, target, source)
		if not source then
			return
		end

		source:add_buff '熊皮护盾'
		{
			source = u,
			life = self.life + source:get '生命上限' * self.rate / 100
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end


local buff = ac.shield_buff['熊皮护盾']

buff.cover_type = 1

buff.tip = '吸收 |cffffff11%life%|r 点伤害'
buff.send_tip = true
buff.buff = true
