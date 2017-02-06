




--物品名称
local mt = ac.skill['次元穿梭']

--图标
mt.art = [[BTNspeed6.blp]]

--说明
mt.tip = [[
受到伤害时，你会隐身%time%秒，造成的伤害提高%damage_rate%%，持续%damage_time%秒。
这个效果每%cool%秒可以触发一次。
]]

--物品类型
mt.item_type = '鞋子'

--附魔价格
mt.gold = 1600

--物品等级
mt.level = 4

--物品唯一
mt.unique = true

--属性
mt.time = 1
mt.damage_time = 4
mt.damage_rate = 30
mt.cool = 8

function mt:on_add()
	local hero = self.owner
	self.trg1 = hero:event '受到伤害效果' (function (_, damage)
		if self:is_cooling() then
			return
		end
		self:active_cd()
		hero:add_buff '隐身'
		{
			time = 1,
			remove_when_attack = false,
			remove_when_spell = false,
		}
		hero:add_buff '次元穿梭'
		{
			time = self.damage_time,
			val = self.damage_rate,
		}
	end)
end

function mt:on_remove()
	local hero = self.owner
	if self.trg1 then self.trg1:remove() end
end



local mt = ac.buff['次元穿梭']

function mt:on_add()
	self.target:addDamageRate(self.val)
end

function mt:on_remove()
	self.target:addDamageRate(-self.val)
end
