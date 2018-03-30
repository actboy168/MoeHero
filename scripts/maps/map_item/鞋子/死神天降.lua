




--物品名称
local mt = ac.skill['死神天降']

--图标
mt.art = [[BTNspeed2.blp]]

--说明
mt.tip = [[
普通攻击对野怪造成%damage_rate%点额外伤害
受到野怪的伤害减少%damage_reduce%%
击杀野怪时回复生命与法力值
]]

--物品类型
mt.item_type = '打野鞋'

--附魔价格
mt.gold = 500

--物品等级
mt.level = 1

--物品唯一
mt.unique = true

--伤害提升
mt.damage_rate = 60

--受伤减少(%)
mt.damage_reduce = 20

--回复比例(%)
mt.life_recover_rate = 20
mt.mana_recover_rate = 10

mt.trg = nil

function mt:on_add()
	local hero = self.owner
	local life_recover_rate = self.life_recover_rate / 100
	local mana_recover_rate = self.mana_recover_rate / 100
	self.trg1 = hero:event '单位-杀死单位' (function(trg, killer, target)
		if not hero:is_alive() or target.unit_type ~= '野怪' then
			return
		end
		local dest_life = target:get '生命上限'
		local life_rate = 1 - hero:get '生命' / hero:get '生命上限'
		local mana_rate = 1 - hero:get '魔法' / hero:get '魔法上限'
		hero:heal
		{
			source = hero,
			heal = dest_life * life_rate * life_recover_rate,
			skill = self,
		}
		hero:add('魔法', dest_life * mana_rate * mana_recover_rate)
		hero:add_effect('origin', [[Abilities\Spells\Undead\VampiricAura\VampiricAuraTarget.mdl]]):remove()
	end)

	local damage_rate = self.damage_rate
	self.trg2 = hero:event '造成伤害效果' (function(trg, damage)
		if damage:is_common_attack() and damage.target.unit_type == '野怪' then
			damage.target:damage
			{
				source = hero,
				damage = damage_rate,
				skill = self,
			}
		end
	end)

	local damage_reduce = self.damage_reduce / 100
	self.trg3 = hero:event '受到伤害' (function(trg, damage)
		if damage.source and damage.source.unit_type == '野怪' then
			damage:div(damage_reduce)
		end
	end)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
	self.trg3:remove()
end

function mt:canBuy(hero)
	if hero and hero:find_buff '鞋-加速' then
		return '你只能拥有一双鞋子'
	end
end


