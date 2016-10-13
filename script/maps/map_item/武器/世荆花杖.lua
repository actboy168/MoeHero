
--物品名称
local mt = ac.skill['世荆花杖']

--图标
mt.art = [[BTNattack5.blp]]

--说明
mt.tip = [[
没有暴击的伤害提高%damage_plus_rate%%
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1600

--物品唯一
mt.unique = true

--伤害加成(%)
mt.damage_plus_rate = 15

mt.trg = nil

--属性
function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害' (function(trg, damage)
		if not damage:is_crit() then
			damage:mul(self.damage_plus_rate / 100)
		end
	end)
end

function mt:on_remove()
	self.trg:remove()
end


