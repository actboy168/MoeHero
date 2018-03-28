local buff = ac.buff['无限火力']

buff.time = 45
buff.tip = '%time%秒内获得%cool%%冷却缩减(达到上限),技能无消耗'
buff.send_tip = true
buff.cool = 80
buff.cost = 100
buff.eff = nil
buff.changed_max_cool_save = 0

function buff:on_add()
	local hero = self.target
	hero:add('冷却缩减', self.cool)
	hero:add('减耗', self.cost)
	self.eff = hero:add_effect('origin', [[war3mapimported\dustwave.mdl]])
end

function buff:on_remove()
	local hero = self.target
	hero:add('冷却缩减', - self.cool)
	hero:add('减耗', - self.cost)
	self.eff:remove()
end

function buff:on_cover()
	return true
end
