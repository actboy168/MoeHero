



--物品名称
local mt = ac.skill['奥能迸发']

--图标
mt.art = [[BTNattack9.blp]]

--说明
mt.tip = [[
每有一个技能在冷却，你的造成的伤害提高%value%%。
每有一个被动技能，你的造成的伤害提高%value%%。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

mt.gold = 1500

--物品唯一
mt.unique = true

mt.value = 7

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害' (function(trg, damage)
		local stack = 0
		for i = 1, 4 do
			local skl = hero:find_skill(i)
			if skl and (skl:is_cooling() or skl.passive) then
				stack = stack + self.value
			end
		end
		damage:mul(stack / 100.0)
	end)
	self.timer = hero:loop(500, function()
		local stack = 0
		for i = 1, 4 do
			local skl = hero:find_skill(i)
			if skl and (skl:is_cooling() or skl.passive) then
				stack = stack + self.value
			end
		end
		self:add_stack(stack - self:get_stack())
	end)
end

function mt:on_remove()
	self.trg:remove()
	self.timer:remove()
end


