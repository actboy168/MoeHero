



local mt = ac.skill['JinMuYan_3']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNjmye.blp]],

	--技能说明
	title = '赫包激活',
	
	tip = [[
对最近%count%个敌方单位造成%damage%(+%damage_plus%)伤害并拉到近战距离。增加%dodge_chance%格挡，持续%time%秒，格挡后会周围单位造成%dodge_damage%(+%dodge_damage_plus%)伤害。
持续%time%秒
	]],

	--耗蓝
	cost = 100,

	--冷却
	cool = 20,

	--影响范围
	area = 300,

	--目标上限
	count = 4,

	--伤害
	damage = {70, 250},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,

	--牵引速度
	speed = 1000,

	dodge_chance = 50,
	dodge_area = 175,
	dodge_damage = {40, 100},
	dodge_damage_plus = function(self, hero)
		return hero:get_ad() * 0.4
	end,
	dodge_cool = 0.5,
	time = 5,
}

function mt:on_cast_channel()
	local hero = self.owner
	local damage = self.damage + self.damage_plus
	local p = hero:get_point()
	local speed = self.speed
	local dodge_chance = self.dodge_chance

	hero:get_point():add_effect([[war3mapimported\redshockwave.mdl]]):remove()

	--获得状态
	hero:add_buff 'JinMuYan_3_Buff'
	{
		time = self.time,
		dodge_chance = dodge_chance,
		area = self.dodge_area,
		damage = self.dodge_damage + self.dodge_damage_plus,
		cool = self.dodge_cool,
		skill = self,
	}

	--挑出距离最近的N个单位
	local n = 0
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: sort_nearest_hero(hero)
		: ipairs()
	do
		n = n + 1
		if n > self.count then
			break
		end
		--造成伤害
		u:damage
		{
			source = hero,
			damage = damage,
			aoe = true,
			skill = self,
		}
		--拉倒身边
		local mvr = ac.mover.line
		{
			source = hero,
			mover = u,
			angle = u:get_point() / p,
			speed = speed,
			distance = u:get_point() * p - 100,
			skill = self,
			block = true,
		}
	end
end