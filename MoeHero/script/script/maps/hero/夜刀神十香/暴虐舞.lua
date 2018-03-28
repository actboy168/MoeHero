


local mt = ac.skill['暴虐舞']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNtonkaW.blp]],

	--技能说明
	title = '暴虐舞',
	
	tip = [[
对周围%area%范围的敌人造成%damage%(+%damage_plus%)伤害。

|cff888888消耗40%怒气，每点怒气会提高0.6%伤害。如果消耗超过20怒气，伤害附带击退。|r
	]],

	--冷却
	cool = {22, 14},

	cost = 0,

	--动画
	cast_animation = 5,
	cast_start_time = 0.2,
	cast_shot_time = 0.7,
 
	--伤害
	damage = {60, 120},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,

	area = 400,

	--触发系数
	proc = 0.4,
}

function mt:on_cast_shot()
	local hero = self.owner
	local damage = self.damage + self.damage_plus
	local fury = hero:get_resource '怒气' * 0.4
	hero:add_resource('怒气', -fury)
	damage = damage * (1 + 0.006 * fury)
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		if fury > 20 then
			local distance = math.max(0, self.area - hero:get_point() * u:get_point())
			u:add_buff '击退'
			{
				source = hero,
				skill = self,
				angle = hero:get_point() / u:get_point(),
				speed = 2000,
				distance = distance * (fury / 20 - 1) / 3,
				accel = -5000,
			}
		end
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
			attack = true,
		}
	end
end
