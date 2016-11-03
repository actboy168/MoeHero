local math = math

local mt = ac.skill['追踪御礼']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNlmq.blp]],

	--技能说明
	title = '追踪御礼',
	
	tip = [[
投掷%count%枚御礼，造成%damage%(+%damage_plus%)伤害。被多次击中时造成%damage_rate%%伤害
	]],

	--施法距离
	range = 600,
	
	--耗蓝
	cost = {60, 80},

	--冷却
	cool = 6.5,

	--动画
	cast_animation = 2,

	--施法前摇
	cast_start_time = 0.2,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--范围
	area = 350,

	--弹幕数量
	count = 5,

	--目标数量
	target_count = 5,

	--伤害
	damage = {40, 200},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.2
	end,

	--重复伤害
	damage_rate = 15,

	--弹道速度
	speed = 1000,

	--角度差
	angle = 17.5,

	--最大飞行距离
	distance = 900,

	--有追踪目标时的直线飞行距离
	distance_phase = 300,

	--自由碰撞时的碰撞半径
	hit_area = 100,

	--追踪运动时的转身速度限制(与角度差反比距离的比例(%))
	turn_speed_rate = 2000,
}

local function cast_spell_q(hero, target, skill, damage, do_damage)
	local angle = hero:get_point() / target
	local turn_speed_rate = skill.turn_speed_rate
	local n = 0
	while true do
		local start = n
		if n > skill.count then
			break
		end
		for _, u in ac.selector()
			: in_range(target, skill.area)
			: is_enemy(hero)
			: sort_nearest_hero(target)
			: ipairs()
		do
			n = n + 1
			if n > skill.count then
				break
			end
			local angle = angle + (skill.count / 2 - skill.count - 0.5 + n) * skill.angle
			local distance = skill.distance_phase
			local mvr = ac.mover.line
			{
				source = hero,
				model = [[fu.mdl]],
				speed = skill.speed,
				angle = angle,
				distance = distance,
				high = 110,
				skill = skill,
				damage = damage,
				hit_area = skill.hit_area,
				hit_type = ac.mover.HIT_TYPE_ENEMY,
			}
			if mvr then
				function mvr:on_hit(dest)
					if u == dest then
						do_damage(dest, self.mover)
						return true
					end
				end
				function mvr:on_finish()
					local angle = ac.math_angle(self.angle, self.mover:get_point() / u:get_point())
					local distance = self.mover:get_point() * u:get_point()
					local mvr = ac.mover.target
					{
						source = hero,
						mover = self.mover,
						speed = self.speed,
						target = u,
						turn_speed = angle * turn_speed_rate / distance,
						angle = self.angle,
						max_distance = 5000,
						on_move_skip = 3,
						skill = self.skill,
						damage = damage,
						missile = true,
					}

					if not mvr then
						return
					end

					function mvr:on_finish()
						do_damage(self.target, self.mover)
					end

					function mvr:on_move()
						local angle = ac.math_angle(self.angle, self.mover:get_point() / self.target:get_point())
						local distance = self.mover:get_point() * self.target:get_point()
						self.turn_speed = angle * turn_speed_rate / distance
						self:update()
					end
					self:remove(true)
					return true
				end
			end
		end
		if start == n then
			n = n + 1
			if n > skill.count then
				break
			end
			local angle = angle + (skill.count / 2 - skill.count - 0.5 + n) * skill.angle
			local mvr = ac.mover.line
			{
				source = hero,
				model = [[fu.mdl]],
				speed = skill.speed,
				angle = angle,
				distance = skill.distance,
				high = 110,
				skill = skill,
				damage = damage,
				hit_area = skill.hit_area,
				hit_type = ac.mover.HIT_TYPE_ENEMY,
			}
			if mvr then
				function mvr:on_hit(target)
					do_damage(target, self.mover)
				end
			end
		end
	end
end

function mt:on_cast_channel()
	local hero = self.owner
	local damage = self.damage + self.damage_plus
	local damage_rate = self.damage_rate / 100
	local unit_mark = {}
	cast_spell_q(self.owner, self.target, self, damage, function (dest, missile)
		if not unit_mark[dest] then
			unit_mark[dest] = true
			dest:damage
			{
				source = hero,
				damage = damage,
				skill = self,
				missile = missile,
				attack = true,
			}
		else
			dest:damage
			{
				source = hero,
				damage = damage * damage_rate,
				skill = self,
				missile = missile,
				attack = true,
			}
		end
	end)
end

return cast_spell_q
