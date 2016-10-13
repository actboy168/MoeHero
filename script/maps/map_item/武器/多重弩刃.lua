



--物品名称
local mt = ac.skill['多重弩刃']

--图标
mt.art = [[BTNattack14.blp]]

--说明
mt.tip = [[
你的普攻命中时，你造成的伤害提高12%，持续%time%秒。
你的技能命中时，你造成的伤害提高12%，持续%time%秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

--持续时间
mt.time = 5

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害效果' (function (trg, damage)
		if damage:is_common_attack() then
			hero:add_buff '多重弩刃-普攻'
			{
				time = self.time,
				skill = self,
			}
		else
			hero:add_buff '多重弩刃-技能'
			{
				time = self.time,
				skill = self,
			}
		end
	end)
end

function mt:on_remove(dest)
	self.trg:remove()
end



local buff = ac.buff['多重弩刃-普攻']

function buff:on_add()
	local hero = self.target
	hero:addDamageRate(12)
	self.skill:add_stack(12)
end

function buff:on_remove()
	local hero = self.target
	hero:addDamageRate(-12)
	self.skill:add_stack(-12)
end

function buff:on_cover(dest)
	self:set_remaining(dest.time)
	return false
end

local buff = ac.buff['多重弩刃-技能']

function buff:on_add()
	local hero = self.target
	hero:addDamageRate(12)
	self.skill:add_stack(12)
end

function buff:on_remove()
	local hero = self.target
	hero:addDamageRate(-12)
	self.skill:add_stack(-12)
end

function buff:on_cover(dest)
	self:set_remaining(dest.time)
	return false
end
