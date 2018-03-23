




--物品名称
local mt = ac.skill['光剑影光']

--图标
mt.art = [[BTNdefence4.blp]]

--说明
mt.tip = [[
格挡后，暴击提升%block_crit%%，持续%time%秒。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1550

--物品唯一
mt.unique = true

mt.block_crit = 30
mt.time = 1.5

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '受到伤害格挡' (function (trg, damage)
		hero:add_buff '光剑影光'
		{
			time = self.time,
			block_crit = self.block_crit,
			skill = self,
		}
	end)
end

function mt:on_remove()
	local hero = self.owner
	self.trg:remove()
end



local buff = ac.buff['光剑影光']

function buff:on_add()
	local hero = self.target
	hero:add('暴击', self.block_crit)
end

function buff:on_remove()
	local hero = self.target
	hero:add('暴击', -self.block_crit)
end

function buff:on_cover()
	self:set_remaining(self.time)
	return false
end

