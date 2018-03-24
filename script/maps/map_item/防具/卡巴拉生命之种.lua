




--物品名称
local mt = ac.skill['卡巴拉生命之种']

--图标
mt.art = [[BTNdefence14.blp]]

--说明
mt.tip = [[
受到伤害时，你的攻击速度增加%value%%，能量获取提高%value%%，持续%time%秒。
这个效果可以叠加，最多叠加%max_stack%层。
这个效果每%cool%秒只能触发一次。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.time = 10
mt.max_stack = 10
mt.value = 5
mt.cool = 1

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.trg = hero:event '受到伤害开始' (function(trg, damage)
		if self:is_cooling() then
			return
		end
		if self:get_stack() >= self.max_stack then
			return
		end
		self:active_cd()
		damage.target:add_buff '卡巴拉生命之树'
		{
			source = hero,
			time = self.time,
			value = self.value,
			skill = self,
		}
	end)
end

function mt:on_remove()
	if self.trg then self.trg:remove() end
end



local buff = ac.buff['卡巴拉生命之树']

buff.cover_type = 1

function buff:on_add()
	self.skill:add_stack(1)
	self.target:add('攻击速度', self.value)
	self.target:add('能量获取率', self.value)
end

function buff:on_remove()
	self.skill:add_stack(-1)
	self.target:add('攻击速度', -self.value)
	self.target:add('能量获取率', -self.value)
end

function buff:on_cover()
	if self.skill:get_stack() < 10 then
		return false
	end
	return true
end
