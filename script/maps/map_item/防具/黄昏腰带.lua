

--物品名称
local mt = ac.skill['黄昏腰带']

--图标
mt.art = [[BTNdefence11.blp]]

--说明
mt.tip = [[
你的生命大于%life%%时，你受到的伤害减少%damage_sub%%。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

mt.life = 50

mt.damage_sub = 30

function mt:on_add()
	local hero = self.owner
	local life = self.life / 100.0
	local damage_sub = self.damage_sub / 100.0
	self.trg = hero:event '受到伤害' (function(trg, damage)
		if hero:get '生命' / hero:get '生命上限' <= life then
			return
		end
		damage:div(damage_sub)
	end)
end

function mt:on_remove()
	self.trg:remove()
end


