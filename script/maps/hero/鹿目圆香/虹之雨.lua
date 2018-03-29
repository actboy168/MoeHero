
local mt = ac.skill['虹之雨']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNxyw.blp]],

	--技能说明
	title = '虹之雨',
	
	tip = [[
射出箭雨，造成%damage%(+%damage_plus%)点伤害,每击中一个单位会为自己恢复%mana_recover%点法力值。
	]],

	--施法距离
	range = 700,

	--冷却
	cool = 12,

	--耗蓝
	cost = {120, 140},

	--范围
	area = 300,

	--目标类型
	target_type = mt.TARGET_TYPE_POINT,

	--施法动画
	cast_animation = 5,

	--施法前摇
	cast_start_time = 0.6,

	--伤害范围
	damage_area = 300,

	--伤害
	damage = {110, 270},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,

	mana_recover = {3, 15},
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local skill = self

	--发射一枚箭矢
	local mvr = ac.mover.line
	{
		source = hero,
		start = hero:get_point() - {angle + 180, 50},
		id = 'e005',
		angle = angle,
		speed = 0,
		distance = 100,
		size = 1,
		high = hero:get_high() + 225,
		skill = false,
	}

	if mvr then
		function mvr:on_move()
			local dummy = self.mover
			local high = dummy:get_high() + 100

			dummy:set_high(high)

			if high > 2000 then
				mvr:remove()
				self:remove()
			end
		end
	end

	local damage = self.damage + self.damage_plus
	local area = self.damage_area

	hero:wait(500, function(t)
		hero:timer(100, 10, function(t)
			for i = 1, 8 do
				local angle = math.random(1, 360)
				local p = target - {angle, math.random(1, area)}

				--落下箭矢
				local mvr = ac.mover.line
				{
					source = hero,
					start = p,
					id = 'e005',
					angle = angle,
					speed = 0,
					distance = 100,
					high = 1500,
					size = 0.35,
					skill = false,
				}

				if mvr then
					function mvr:on_move()
						local dummy = self.mover
						local high = dummy:get_high() - 150

						dummy:set_high(high)

						if high <= 0 then
							p:add_effect([[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
							dummy:remove()
							self:remove()
						end
					end
				end
			end

			--造成伤害
			local n = 0
			for _, u in ac.selector()
				: in_range(target, area)
				: is_enemy(hero)
				: ipairs()
			do
				n = n + 1
				u:damage
				{
					source = hero,
					damage = damage / 10,
					skill = skill,
					aoe = true,
					attack = true,
				}
			end
			hero:add('魔法', n * skill.mana_recover)
		end)
	end)
end
