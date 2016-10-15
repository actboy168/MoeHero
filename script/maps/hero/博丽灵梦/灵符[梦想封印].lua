



local mt = ac.skill['灵符[梦想封印]']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNlmr.blp]],

	--技能说明
	title = '灵符[梦想封印]',
	
	tip = [[
释放%count%颗光玉，造成%damage%(+%damage_plus%)伤害并击晕%stun_time%秒
光玉对碰撞到的单位造成%damage_rate_1%%伤害并击晕%stun_time%秒，但这也导致这枚光玉爆炸时减少%damage_rate_2%%范围伤害
	]],

	--冷却
	cool = {55, 50, 45},

	--耗蓝
	cost = {120, 160, 200},

	--瞬发
	instant = 1,

	--施法距离
	range = 800,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT_OR_POINT,

	--范围
	area = 400,

	--施法动作相关
	cast_finish_time = 0.5,

	cast_animation = 6,

	cast_animation_speed = 1.5,

	--光玉数量
	count = 18,

	--伤害
	damage = {10, 20, 30},

	damage_plus = function(self, hero)
		return hero:get_ad() * 0.24
	end,

	--击晕
	stun_time = 0.05,

	--穿透伤害(%)
	damage_rate_1 = 50,

	--穿透后的减少伤害(%)
	damage_rate_2 = 50,

	--一段飞行距离
	distance = 500,
	
	--一段飞行速度
	speed1 = 600,

	--二段飞行速度
	speed2 = 1500,

	--飞行时的碰撞半径
	hit_area = 100,

	--二段运动转身速度限制
	turn_speed = 360,

	--二段运动最大飞行距离
	max_distance = 5000,
}

function mt:on_cast_channel()
	local hero = self.owner
	local count = self.count
	local face = hero:get_facing()
	local damage = self.damage + self.damage_plus
	local speed1 = self.speed1
	local speed2 = self.speed2
	local hit_area = self.hit_area
	local target = self.target
	local turn_speed = self.turn_speed
	local max_distance = self.max_distance
	local damage_rate_1 = self.damage_rate_1 / 100
	local damage_rate_2 = self.damage_rate_2 / 100
	local stun_time = self.stun_time
	local area = self.area

	local createBall, startTrack

	--创建光玉
	local models = {}
	models[1] = [[ball_red.mdl]]
	models[2] = [[ball_blue.mdl]]
	models[3] = [[ball_green.mdl]]
	
	function createBall(i, start)
		local mvr = ac.mover.line
		{
			source = hero,
			start = start,
			model = models[i % 3 + 1],
			angle = i * (360.0 / count) + face,
			pt = start,
			distance = self.distance,
			speed = speed1,
			high = 125,
			size = 1.5,
			skill = self,
			damage = damage,
		}

		if not mvr then
			return
		end

		function mvr:on_move()
			self.angle = self.angle + 5
		end

		function mvr:on_finish()
			startTrack(mvr.mover, self.pt)
			self:remove(true)
			return true
		end

		
	end

	--二段运动
	function startTrack(who, pt)
		local mvr = ac.mover.target
		{
			source = hero,
			start = who,
			target = target,
			mover = who,
			missile = true,
			speed = speed2,
			angle = pt / who:get_point(),
			turn_speed = turn_speed,
			max_distance = max_distance,
			on_moved_skip = 6,
			damage = damage,

			skill = self,

			hit_area = hit_area
		}

		if not mvr then
			return
		end
		
		if target.type == 'point' then
			mvr.target = target - {math.random(1, 360), math.random(0, 300)}
		end

		--转身速度随时间递增
		function mvr:on_move()
			self.turn_speed = self.turn_speed * 1.05
			self:update()
		end

		--碰撞到单位的处理
		local has_hited = false
		local hited = {}
		function mvr:on_hit(dest)
			local damage = damage * damage_rate_1
			
			--伤害与晕眩
			dest:add_buff '晕眩'
			{
				time = stun_time,
			}
			
			dest:damage
			{
				source = self.source,
				damage = damage,
				skill = self.skill,
				missile = self.mover,
				aoe = true,
				attack = true,
			}

			if has_hited then
				return
			end
			if dest:is_in_range(self.target, area) then
				hited[dest] = true
				return
			end
			has_hited = true

			local damage = damage - damage * damage_rate_2
			self.damage = damage
		end

		--到终点爆炸
		function mvr:on_finish()
			self.target:get_point():add_effect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]]):remove()
			local damage = self.damage
			for _, u in ac.selector()
				: in_range(self.target, area)
				: is_enemy(self.source)
				: ipairs()
			do
				--伤害与晕眩
				u:add_buff '晕眩'
				{
					time = stun_time,
				}

				local damage = damage
				if hited[u] then
					damage = damage - damage * damage_rate_2
				end
				u:damage
				{
					source = self.source,
					damage = damage,
					skill = self.skill,
					missile = self.mover,
					aoe = true,
					attack = true,
				}
			end
		end

		
	end

	local start = hero:get_point()
	for i = 1, count do
		createBall(i, start)
	end
end
