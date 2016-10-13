




--物品名称
local mt = ac.skill['陨铁大剑']

--图标
mt.art = [[BTNattack2.blp]]

--说明
mt.tip = [[
每次使用技能后，你可以获得一个护盾，吸收相当于你生命值%shield_life%%的伤害，持续%shield_time%秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

mt.shield_life = 5
mt.shield_time = 5

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '技能-施法出手' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		hero:add_buff '陨铁大剑护盾'
		{
			time = self.shield_time,
			life = hero:get '生命上限' * self.shield_life / 100
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end



local mt = ac.shield_buff['陨铁大剑护盾']
