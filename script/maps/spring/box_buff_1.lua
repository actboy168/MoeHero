local buff = ac.buff['返老还童']

buff.time = 5
buff.area = 1000
buff.first = true
buff.recover = 100

buff.tip = '在%time%秒内回复%recover%%点生命值与法力值,受到英雄伤害被打断'
buff.send_tip = true

buff.eff = nil
buff.life_recover = 0
buff.mana_recover = 0
buff.trg = nil

function buff:on_add()
	local hero = self.target
	
	if self.first then
		for _, u in ac.selector()
			: in_range(self.source, self.area)
			: of_hero()
			: is_not(hero)
			: is_ally(hero)
			: ipairs()
		do
			u:add_buff(self.name)
			{
				source = self.source,
				first = false
			}
		end
	end

	--
	self.eff = hero:add_effect('chest', [[Abilities\Spells\NightElf\Rejuvenation\RejuvenationTarget.mdl]])
	
	self.life_recover = hero:get '生命上限' * self.recover / 100
	self.mana_recover = hero:get_resource '魔法上限' * self.recover / 100

	hero:add('生命恢复', self.life_recover)
	hero:add('魔法恢复', self.mana_recover)

	self.trg = hero:event '受到伤害效果' (function(trg, damage)
		self:remove()
	end)
	
end

function buff:on_remove()
	local hero = self.target

	self.eff:remove()

	hero:add('生命恢复', - self.life_recover)
	hero:add('魔法恢复', - self.mana_recover)

	self.trg:remove()
end

function buff:on_cover()
	return true
end
