




--物品名称
local mt = ac.skill['圣炎光弩']

--图标
mt.art = [[BTNattack11.blp]]

--说明
mt.tip = [[
你与敌人的距离每隔50码，造成的伤害提高1%，最多提高30%。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害' (function(trg, damage)
		local dis = damage.target:get_point() * hero:get_point()
		local dmg_rate = dis / 5000.0
		if dmg_rate > 0.3 then
			dmg_rate = 0.3
		end
		damage:mul(dmg_rate)
	end)
end

function mt:on_remove()
	self.trg:remove()
end


