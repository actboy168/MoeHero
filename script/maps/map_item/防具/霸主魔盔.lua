



--物品名称
local mt = ac.skill['霸主魔盔']

--图标
mt.art = [[BTNdefence7.blp]]

--说明
mt.tip = [[
增加%attack_rate_ex%%最大生命值的攻击力。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1600

--物品唯一
mt.unique = true

--攻击百分比(%)
mt.attack_rate_ex = 1.5

--刷新频率
mt.pulse = 500

mt.timer = nil
mt.changed_attack = 0
mt.eff = nil

function mt:on_add()
	local hero = self.owner
	local rate = self.attack_rate_ex / 100

	self.timer = hero:loop(self.pulse, function()
		local attack = hero:get '生命上限' * rate
		hero:add('攻击', attack - self.changed_attack)
		self.changed_attack = attack
	end)

	self.eff = hero:add_effect('weapon', [[war3mapimported\purgebufftarget.mdl]])
end

function mt:on_remove()
	local hero = self.owner
	
	self.timer:remove()
	hero:add('攻击', - self.changed_attack)
	self.eff:remove()
end


