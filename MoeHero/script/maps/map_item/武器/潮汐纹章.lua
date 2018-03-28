



--物品名称
local mt = ac.skill['潮汐纹章']

--图标
mt.art = [[BTNattack8.blp]]

--说明
mt.tip = [[
你获得的治疗提高50%并同时作用于附近的友方单位
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1400

--物品唯一
mt.unique = true

--搜寻范围
mt.area = 600

--治疗转化(%)
mt.heal_rate = 50

mt.trg = nil

function mt:on_add()
	local hero = self.owner
	local area = self.area
	local heal_rate = self.heal_rate / 100

	self.trg = hero:event '受到治疗效果' (function(trg, heal)
		if heal.skill and heal.skill.name == self.name then
			return
		end

		for _, u in ac.selector()
			: in_range(hero, area)
			: is_ally(hero)
			: ipairs()
		do
			if u:get '生命' < u:get '生命上限' then
				u:heal
				{
					source = hero,
					heal = heal.heal * heal_rate,
					skill = self,
				}
				u:add_effect('origin', [[Abilities\Spells\Undead\ReplenishMana\SpiritTouchTarget.mdl]]):remove()
			end
		end
	end)
end

function mt:on_remove()
	self.trg:remove()
end


