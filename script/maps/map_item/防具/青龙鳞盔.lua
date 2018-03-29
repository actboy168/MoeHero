




--物品名称
local mt = ac.skill['青龙鳞盔']

--图标
mt.art = [[BTNdefence9.blp]]

--说明
mt.tip = [[
受到暴击伤害时，回复该伤害%heal%%的生命值。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1200

--物品唯一
mt.unique = true

mt.heal = 30

function mt:on_add()
	local hero = self.owner
	local heal = self.heal / 100.0
	self.trg = hero:event '受到伤害效果' (function(trg, damage)
		if not damage:is_crit() then
			return
		end
		hero:heal
		{
			heal = damage:get_current_damage() * heal,
			skill = self,
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end


