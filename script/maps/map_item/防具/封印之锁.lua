



--物品名称
local mt = ac.skill['封印之锁']

--图标
mt.art = [[BTNdefence1.blp]]

--说明
mt.tip = [[
你造成的伤害可使敌人的伤害降低20%，持续3秒。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1700

--物品唯一
mt.unique = true

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害效果' (function (trg, damage)
		if damage.target:is_enemy(hero) then
			damage.target:add_buff '封印之锁'
			{
				time = 3
			}
		end
	end)
end

function mt:on_remove()
	local hero = self.owner
	self.trg:remove()
end



local buff = ac.buff['封印之锁']

buff.debuff = true

function buff:on_add()
	local hero = self.target
	self.eff = hero:add_effect('origin', [[Abilities\Spells\Undead\Cripple\CrippleTarget.mdl]])
	hero:addDamageRate(-20)
end

function buff:on_remove()
	local hero = self.target
	hero:addDamageRate(20)
	self.eff:remove()
end

function buff:on_cover()
	self:set_remaining(3)
	return false
end
