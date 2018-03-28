



--物品名称
local mt = ac.skill['战跃海锚']

--图标
mt.art = [[BTNattack12.blp]]

--说明
mt.tip = [[
进入战斗时，你的暴击增加30%，持续5秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1700

--物品唯一
mt.unique = true

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '单位-进入战斗' (function(trg, hero)
		hero:add_buff '战跃海锚' { time = 5 }
	end)
end

function mt:on_remove()
	local hero = self.owner
	self.trg:remove()
end



local buff = ac.buff['战跃海锚']

function buff:on_add()
	local hero = self.target
	hero:add('暴击', 30)
end

function buff:on_remove()
	local hero = self.target
	hero:add('暴击', -30)
end

function buff:on_cover()
	self:set_remaining(5)
	return false
end
