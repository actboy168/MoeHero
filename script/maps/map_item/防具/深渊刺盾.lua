



--物品名称
local mt = ac.skill['深渊刺盾']

--图标
mt.art = [[BTNdefence2.blp]]

--说明
mt.tip = [[
承受伤害的同时反弹%damage%%伤害给周围的单位
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

--影响范围
mt.area = 400

mt.damage = 50

function mt:on_add()
	local hero = self.owner
	local area = self.area
	local dmg = 0
	local maxdmg = 500
	self.trg = hero:event '受到伤害效果' (function(trg, damage)
		local source = damage.source
		if damage:is_skill() and damage.skill.name == self.name then
			return
		end
		dmg = dmg + damage:get_current_damage()
		if dmg > maxdmg then
			hero:get_point():add_effect([[modeldekan\weapon\dekan_weapon_rebound.mdl]]):remove()
			dmg = dmg - maxdmg
			for _, u in ac.selector()
				: in_range(hero, area)
				: is_enemy(hero)
				: ipairs()
			do
				u:add_effect('chest', [[Abilities\Weapons\VengeanceMissile\VengeanceMissile.mdl]]):remove()
				u:damage
				{
					source = hero,
					damage = maxdmg * self.damage / 100.0,
					skill = self,
					aoe = true,
				}
			end
		end
	end)
end

function mt:on_remove()
	self.trg:remove()
end


