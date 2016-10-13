




--物品名称
local mt = ac.skill['风羽长剑']

--图标
mt.art = [[BTNattack3.blp]]

--说明
mt.tip = [[
每次使用技能，你的攻击速度提高%attack_speed_ex%，持续%time%秒。
这个效果最多可以叠加%max_stack%层。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

--属性
mt.attack_speed_ex = 40
mt.max_stack = 5
mt.time = 3

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '技能-施法出手' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		if self:get_stack() >= self.max_stack then
			return
		end
		hero:add_buff '风羽长剑'
		{
			time = self.time,
			value = self.attack_speed_ex,
			skill = self,
		}
	end)
end

function mt:on_remove()
	if self.trg then self.trg:remove() end
end



local buff = ac.buff['风羽长剑']

buff.cover_type = 1

function buff:on_add()
	self.skill:add_stack(1)
	self.target:add('攻击速度', self.value)
end

function buff:on_remove()
	self.skill:add_stack(-1)
	self.target:add('攻击速度', - self.value)
end
