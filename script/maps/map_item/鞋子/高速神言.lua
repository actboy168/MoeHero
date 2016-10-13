




--物品名称
local mt = ac.skill['高速神言']

--图标
mt.art = [[BTNspeed3.blp]]

--说明
mt.tip = [[
使用技能可以降低其他技能的冷却,数值相当于当前技能冷却时间的%cool_down%%
]]

--物品类型
mt.item_type = '鞋子'

--附魔价格
mt.gold = 1600

--物品等级
mt.level = 4

--物品唯一
mt.unique = true

--降低冷却(%)
mt.cool_down = 10

mt.trg = nil

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '技能-施法出手' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		local cool = skill:get_max_cd()
		if not cool or cool == 0 then
			return
		end
		local cool = cool * self.cool_down / 100
		for i = 1, 4 do
			local skl = hero:find_skill(i)
			if skl and skl:get_cd() > 0 and skl:get_name() ~= skill:get_name() then
				skl:set_cd(skl:get_cd() - cool)
			end
		end
	end)
end

function mt:on_remove()
	self.trg:remove()
end


