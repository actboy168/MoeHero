




--物品名称
local mt = ac.skill['裂钩刀刃']

--图标
mt.art = [[BTNattack7.blp]]

--说明
mt.tip = [[
你的Q技能造成的伤害提高%q_damage%%。
使用Q技能之后，你造成的伤害提高%all_damage%%，持续%time%秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1600

--物品唯一
mt.unique = true

mt.q_damage = 12
mt.all_damage = 12
mt.time = 5

function mt:on_add()
	local hero = self.owner
	local q_damage = self.q_damage / 100.0
	self.trg1 = hero:event '技能-施法出手' (function (trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		if skill.slotid ~= 1 then
			return
		end
		hero:add_buff '裂钩刀刃'
		{
			damage = self.all_damage,
			time = self.time,
			skill = self,
		}
	end)
	self.trg2 = hero:event '造成伤害' (function(trg, damage)
		if not damage:is_skill() then
			return
		end
		if damage.skill.slotid ~= 1 then
			return
		end
		damage:mul(q_damage)
	end)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
end



local buff = ac.buff['裂钩刀刃']

function buff:on_add()
	local hero = self.target
	hero:addDamageRate(self.damage)
	self.skill:add_stack(self.damage)
end

function buff:on_remove()
	local hero = self.target
	hero:addDamageRate(-self.damage)
	self.skill:add_stack(-self.damage)
end

function buff:on_cover(dest)
	self:set_remaining(dest.time)
	return false
end
