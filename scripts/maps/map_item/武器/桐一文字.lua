



--物品名称
local mt = ac.skill['桐一文字']

--图标
mt.art = [[BTNattack4.blp]]

--说明
mt.tip = [[
你的每点破防提升%crit_damage%%的暴击伤害，最多提升100%。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1700

--物品唯一
mt.unique = true

mt.crit_damage = 1

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害' (function (trg, damage)
		local pene = damage['破甲']
		if pene > 100 then pene = 100 end
		damage['暴击伤害'] = damage['暴击伤害'] + pene
	end)
end

function mt:on_remove()
	self.trg:remove()
end


