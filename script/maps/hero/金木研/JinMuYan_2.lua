local mt = ac.skill['JinMuYan_2']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNjmyw.blp]],

	--技能说明
	title = '横扫甩击',
	
	tip = [[
对敌方单位造成%damage%(+%damage_plus%)伤害并击退%distance%距离
如果命中唯一目标可以再次按下该技能冲向该目标并造成一次额外的攻击
	]],

	--耗蓝
	cost = 85,

	--冷却
	cool = 10,

	--动画
	cast_animation = 'Spell five',

	--动画速度
	cast_animation_speed = 3,

	--施法前摇
	cast_start_time = 0.5,

	--施法后摇
	cast_finish_time = 0.2,

	--影响范围
	area = 250,

	--伤害
	damage = {80, 240},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,

	--击退距离
	distance = 200,

	--击退速度
	speed = 1000,

	--距离判定
	distance_limit = 500,

	--额外技能时间
	time = 2,
}

function mt:on_cast_channel()
	local hero = self.owner
	local p = hero:get_point()
	local damage = self.damage + self.damage_plus
	local speed = self.speed
	local distance = self.distance
	local g = ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: get()
	for _, u in ipairs(g) do
		--伤害
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
		}
		--击退
		u:add_buff '击退'
		{
			source = hero,
			angle = p / u:get_point(),
			speed = speed,
			distance = distance,
			skill = self,
		}
	end
	if #g == 1 then
		hero:add_buff 'JinMuYan_2_Buff'
		{
			time = self.time,
			dest = g[1],
			distance = self.distance_limit,
		}
	end
end

function mt:on_remove()
	local hero = self.owner
	hero:remove_buff 'JinMuYan_2_Buff'
end

