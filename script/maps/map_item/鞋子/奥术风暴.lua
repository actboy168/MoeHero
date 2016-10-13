



--物品名称
local mt = ac.skill['奥术风暴']

--图标
mt.art = [[BTNspeed5.blp]]

--说明
mt.tip = [[
你的技能伤害提高%damage_up%%。
你的能量消耗提高%cost_up%%。
]]

--物品类型
mt.item_type = '鞋子'

--附魔价格
mt.gold = 1600

--物品等级
mt.level = 4

--物品唯一
mt.unique = true

mt.damage_up = 30
mt.cost_up = 30

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害' (function(trg, damage)
		if damage:is_skill() then
			damage:mul(self.damage_up / 100.0)
		end
	end)
	hero:add('减耗', -self.cost_up)
end

function mt:on_remove()
	local hero = self.owner
	hero:add('减耗', self.cost_up)
	self.trg:remove()
end


