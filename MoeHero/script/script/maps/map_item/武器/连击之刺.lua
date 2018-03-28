




--物品名称
local mt = ac.skill['连击之刺']

--图标
mt.art = [[BTNattack10.blp]]

--说明
mt.tip = [[
暴击时随机减少一个技能%cool_down%秒的冷却。
这个效果每%cool%秒只能触发一次。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1450

--物品唯一
mt.unique = true

--属性
mt.cool_down = 3
mt.cool = 1

mt.trg = nil

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害效果' (function(trg, damage)
		if not damage:is_crit() then
			return
		end
		if self:is_cooling() then
			return
		end
		self:active_cd()
		local proc = 1
		if damage.skill then
			proc = damage.skill.proc or 0
		end
		--找到所有正在冷却的技能
		local skills = {}
		for i = 1, 4 do
			local skl = hero:find_skill(i)
			if skl and skl:get_cd() > 0 then
				table.insert(skills, skl)
			end
		end
		if #skills > 0 then
			local skill = skills[math.random(1, #skills)]
			skill:set_cd(skill:get_cd() - self.cool_down * proc)
		end
	end)
end

function mt:on_remove()
	self.trg:remove()
end


