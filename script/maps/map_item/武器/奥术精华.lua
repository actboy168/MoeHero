




--物品名称
local mt = ac.skill['奥术精华']

--图标
mt.art = [[BTNattack1.blp]]

--说明
mt.tip = [[
你拥有的每%mana_rate%点法力可使你的伤害提升1%。
你的技能命中时，法力消耗减少%cost_rate%%，持续2秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1650

--物品唯一
mt.unique = true

--属性
mt.cost_rate = 40
mt.mana_rate = 90

function mt:on_add()
	local hero = self.owner
	self.trg1 = hero:event '造成伤害' (function(trg, damage)
		damage:mul(hero:get '魔法' / self.mana_rate / 100)
	end)
	self.trg2 = hero:event '造成伤害效果' (function(trg, damage)
		if not damage:is_skill() then
			return
		end
		hero:add_buff '奥术精华'
		{
			time = 2,
			val = self.cost_rate,
		}
	end)
	self.timer = hero:loop(500, function()
		local stack = hero:get '魔法' / self.mana_rate
		self:add_stack(stack - self:get_stack())
	end)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
	self.timer:remove()
end

local buff = ac.buff['奥术精华']

function buff:on_add()
	self.target:add('减耗', self.val)
	self.eff = self.target:add_effect('overhead', [[Abilities\Spells\Human\InnerFire\InnerFireTarget.mdl]])
end

function buff:on_remove()
	self.eff:remove()
	self.target:add('减耗', -self.val)
end

function buff:on_cover()
	return false
end


