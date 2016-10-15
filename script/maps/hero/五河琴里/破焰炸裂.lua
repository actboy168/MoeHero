local mt = ac.skill['破焰炸裂']

mt{
	level = 0,
	art = [[BTNqlw.blp]],
	title = '破焰炸裂',
	tip = [[
爆发出一道火焰炸裂，击晕%damage_area1%范围内的敌方单位%stun_time%秒并造成%damage_base1%(+%damage_plus1%)伤害。
%delay%秒后第二道更大的火焰炸裂，对%damage_area2%范围内的敌方单位造成%damage_base2%(+%damage_plus2%)伤害。
	]],
	cool = {24, 16},
	cost = 30,
	cast_animation = 6,
	stun_time = 1,
	delay = 1,
	damage_area1 = 250,
	damage_base1 = {20, 60},
	damage_plus1 = function(self, hero)
		return hero:get_ad() * 0.5
	end,
	damage1 = function(self, hero)
		return self.damage_base1 + self.damage_plus1
	end,
	damage_area2 = 350,
	damage_base2 = {40, 120},
	damage_plus2 = function(self, hero)
		return hero:get_ad() * 1
	end,
	damage2 = function(self, hero)
		return self.damage_base2 + self.damage_plus2
	end,
	proc = 0.2,
}

function mt:on_cast_channel()
	local hero = self.owner
	for _, u in ac.selector()
		: in_range(hero, self.damage_area1)
		: is_enemy(hero)
		: ipairs()
	do
		u:add_buff '晕眩'
		{
			source = hero,
			time = self.stun_time,
		}
		u:damage
		{
			source = hero,
			damage = self.damage1,
			aoe = true,
			skill = self,
			attack = true,
		}
	end

	local eff = ac.effect(hero:get_point(), [[lava crack.mdl]], 0, 0.8)
	hero:wait(800, function()
		eff:remove()
	end)

	hero:get_point():add_effect([[Abilities\Spells\Other\Doom\DoomDeath.mdl]]):remove()
	hero:get_point():add_effect([[Objects\Spawnmodels\Other\NeutralBuildingExplosion\NeutralBuildingExplosion.mdl]]):remove()

	hero:wait(self.delay * 1000, function()
		if not hero:is_alive() then
			return
		end
		for _, u in ac.selector()
			: in_range(hero, self.damage_area2)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = self.damage2,
				aoe = true,
				skill = self,
				attack = true,
			}
		end
		ac.effect(hero:get_point(), [[superbigexplosion.mdl]], 0, 2):remove()
		hero:get_point():add_effect([[Abilities\Spells\Other\Doom\DoomDeath.mdl]]):remove()
	end)
end
