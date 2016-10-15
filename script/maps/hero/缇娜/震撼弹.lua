local mt = ac.skill['震撼弹']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNTinaQ.blp]],
	title = '震撼弹',
	tip = [[
|cff00ccff强袭姿态|r：
缇娜发射一枚震撼弹，击退沿途的敌人并造成%damage_base1%(+%damage_plus1%)点伤害。震撼弹在最远处爆炸，造成%damage_base2%(+%damage_plus2%)点伤害。

|cff00ccff战术姿态|r：
缇娜扔出一颗手雷将附近的敌人击晕%sub_stun%秒并后退%sub_distance%距离。
	]],
	cool = 3,
	cost = 1,
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 900,
	cast_start_time = 0.3,
	cast_shot_time = 0.2,
	cast_animation = 'spell one',
	-- 判定半径
	hit_area = 100,
	-- 爆炸半径
	boom_area = 200,
	-- 弹道速度
	speed = 1500,
	-- 击退距离
	beat_distance = 300,
	-- 击退速度
	beat_speed = 1500,
	-- 弹道伤害
	damage_base1 = {40, 80},
	damage_plus1 = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	-- 爆炸伤害
	damage_base2 = {80, 160},
	damage_plus2 = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	-- 环绕弹道数量
	count = 5,
	-- 环绕半径
	radius = 50,
	-- 环绕速度
	ang_speed = 15,

	-- 手雷晕眩
	sub_stun = function()
		return ac.skill['风暴之舞'].data.stun
	end,
	-- 后退距离
	sub_distance = function()
		return ac.skill['风暴之舞'].data.distance
	end,
}

function mt:on_cast_shot()
	local hero = self.owner
	local beat_distance = self.beat_distance
	local beat_speed = self.beat_speed
	local angle = hero:get_point() / self.target
	local damage1 = self.damage_base1 + self.damage_plus1
	local damage2 = self.damage_base2 + self.damage_plus2
	local boom_area = self.boom_area
	local count = self.count
	local radius = self.radius
	local ang_speed = self.ang_speed
	hero:play_sound([[response\缇娜\skill\Q.mp3]])
	local mover = ac.mover.line
	{
		source = hero,
		model = [[model\tina\TN_Q_missile.mdl]],
		angle = angle,
		distance = self.range,
		speed = self.speed,
		skill = self,
		size = 0.5,
		high = 50,
		hit_area = self.hit_area,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
	}

	if not mover then
		return
	end
	
	function mover:on_hit(target)
		target:add_buff '击退'
		{
			source = hero,
			skill = self.skill,
			speed = beat_speed,
			distance = beat_distance,
			angle = angle,
		}
		target:damage
		{
			source = hero,
			skill = self.skill,
			damage = damage1,
			aoe = true,
		}
	end

	function mover:on_finish()
		for _, u in ac.selector()
			: in_range(self.mover, boom_area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				skill = self.skill,
				damage = damage2,
				aoe = true,
			}
		end	
	end

	local sub_movers = {}
	for i = 1, count do
		local ang = 360 / count * i
		local distance = radius * math.cos(ang)
		local high = radius * math.sin(ang) + 50
		local mover = mover.mover:follow
		{
			source = hero,
			model = [[model\tina\TN_Q_missile.mdl]],
			angle = angle,
			distance = distance,
			high = high,
			skill = self,
			size = 0.5,
			angle = 90,
			face_follow = true,
			angle_follow = true,
		}

		table.insert(sub_movers, mover)

		if mover then
			function mover:on_move()
				ang = ang + ang_speed
				self.mover:set_high(radius * math.sin(ang) + 50)
				self.distance = radius * math.cos(ang)
			end
		end
	end

	function mover:on_remove()
		for _, mover in ipairs(sub_movers) do
			mover:remove()
		end
	end	
end
