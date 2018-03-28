




--物品名称
local mt = ac.skill['死神契约']

--图标
mt.art = [[BTNdefence16.blp]]

--说明
mt.tip = [[
你获得的治疗会变为对周围敌方英雄的伤害。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.area = 600

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.trg = hero:event '受到治疗开始' (function(trg, heal)
		local group = ac.selector()
			: in_range(hero, self.area)
			: is_enemy(hero)
			: of_hero()
			: get()
		local damage = heal.heal / #group
		for _, u in ipairs(group) do
			u:add_effect('origin', [[Abilities\Spells\Undead\DeathandDecay\DeathandDecayDamage.mdl]]):remove()
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self,
			}
		end
		return true
	end)
end

function mt:on_remove()
	if self.trg then self.trg:remove() end
end


