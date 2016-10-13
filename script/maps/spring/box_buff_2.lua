local buff = ac.buff['贪婪欲望']

buff.time = 90
buff.size = 0.5
buff.life_rate = 30
buff.tip = '%time%秒内增加%life_rate%%生命上限,体型变大50%'
buff.send_tip = true
buff.eff = nil

function buff:on_add()
	local hero = self.target
	hero:add('生命上限%', self.life_rate)
	hero:addSize(self.size)
	self.eff1 = hero:add_effect('hand left', [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]])
	self.eff2 = hero:add_effect('hand right', [[Abilities\Spells\Orc\Bloodlust\BloodlustSpecial.mdl]])
end

function buff:on_remove()
	local hero = self.target
	hero:add('生命上限%', - self.life_rate)
	hero:addSize(- self.size)
	self.eff1:remove()
	self.eff2:remove()
end

function buff:on_cover()
	return true
end
