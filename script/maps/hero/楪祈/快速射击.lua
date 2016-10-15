local mt = ac.skill['快速射击']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNyqq.blp]],

	--技能说明
	title = '快速射击',
	
	tip = [[
对目标和其%area%范围的敌方单位造成%damage_base%(+%damage_plus%)伤害。

|cffffff11可充能%charge_max_stack%次|r
		]],

	--耗蓝
	cost = {50, 30},

	--冷却
	cooldown_mode = 1,
	charge_max_stack = 3,
	cool = 1,
	charge_cool = {6, 4},

	--施法动画
	cast_animation = 'attack two',

	--施法前摇
	cast_start_time = 0.067,

	--施法后摇
	cast_finish_time = 0.1,

	--施法距离
	range = 650,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--伤害
	damage_base = {100, 200},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,

	--作用范围
	area = 250,
}

function mt:on_cast_shot()
	local hero = self.owner
	local damage = self.damage
	local start = hero:get_point()
	if self.damage_rate then
		damage = damage * (1 + self.damage_rate / 100)
		start = start - { math.random(1, 360), math.random(50, 350) }
		local angle = start / self.target:get_point()
		local dummy = hero:create_dummy(nil, start, angle)
		dummy:add_restriction '硬直'
		dummy:set_class '马甲'
		dummy:set_animation('attack two')
		dummy:add_buff '淡化'
		{
			time = 0.4,
		}
	end
	for _, u in ac.selector()
		: in_range(self.target, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		local mvr = ac.mover.target
		{
			source = hero,
			start = start,
			target = u,
			speed = 3500,
			model = [[modeldekan\ability\DEKAN_Inori_Q_Missile.mdl]],
			skill = self,
			high = 75,
			height = 25,
		}
		if mvr then
			function mvr:on_finish()
				u:damage
				{
					source = hero,
					damage = damage,
					skill = self.skill,
					attack = true,
				}
			end
		end
	end
end
