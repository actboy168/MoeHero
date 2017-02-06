local mt = ac.skill['剑技-胧月']
{
	--初始等级
	level = 0,
	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNAmiellaSwordQ.blp]],
	--技能说明
	title = '剑技-胧月',
	tip = [[
|cff00ccff剑技-胧月|r:
对前方扇形区域造成%sword_damage_base%(+%sword_damage_plus%)伤害。
|cff8888883Hit之后，减少敌人%sword_move_speed%%移动速度，持续%sword_time%秒。|r

|cff00ccff炮技-连爆|r:
对目标区域的敌人发射%gun_count%枚追踪的炮弹，命中后会产生小规模的爆炸，造成%gun_damage_base%(+%gun_damage_plus%)伤害。
|cff8888883Hit之后，掉落一个血球，恢复%gun_life_rate%%生命值。|r
	]],

	cool = 1,
	cost = {70, 30},
	range = 9999,
	cast_start_time = 0.3,
	cast_shot_time = 0.4,
	cast_finish_time = 0.4,
	target_type = ac.skill.TARGET_TYPE_POINT,

	--剑技
	sword_range = 400,
	sword_move_speed = 40,
	sword_time = 2,
	sword_damage_base = {80, 160},
	sword_damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	sword_damage = function(self, hero)
		return self.sword_damage_base + self.sword_damage_plus
	end,

	--炮技
	gun_range = 200,
	gun_count = {3, 7},
	gun_distance = 600,
	gun_life_rate = 4,
	gun_damage_base = {60, 140},
	gun_damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
	gun_damage = function(self, hero)
		return self.gun_damage_base + self.gun_damage_plus
	end,
}

function mt:on_cast_start()
	local hero = self.owner
	if hero:get_point() * self.target < 350 then
		self.mode = 'sword'
		self.on_cast_shot = self.sword_on_cast_shot
		self.on_cast_stop = nil
		self:set_animation(5)
	else
		self.mode = 'gun'
		self.on_cast_shot = self.gun_on_cast_shot
		self.on_cast_stop = self.gun_on_cast_stop
		self:set_animation(4)
	end
end

function mt:on_cast_break()
	local hero = self.owner
	hero:set_animation('stand')
end

function mt:sword_on_cast_shot()
	local hero = self.owner
	local target = self.target
	self.cast_angle = hero:get_point() / target
	local dummy = hero:create_dummy('e00K', hero:get_point() - {self.cast_angle, 50}, self.cast_angle)
	dummy:set_size(3)
	dummy:kill()
	for _, u in ac.selector()
		: in_sector(hero, self.sword_range, self.cast_angle, 120)
		: is_enemy(hero)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = self.sword_damage,
			skill = self,
			aoe = true,
			attack = true,
		}
	end
end

function mt:gun_on_cast_shot()
	local hero = self.owner
	local distance = math.min(hero:get_point() * self.target, self.gun_distance)
	local angle = hero:get_point() / self.target
	self.target = hero:get_point() - {angle, distance}
	local mark = {}
	local function do_damage(poi)
		for _, u in ac.selector()
			: in_range(poi, self.gun_range)
			: is_enemy(hero)
			: ipairs()
		do
			if not mark[u] then
				mark[u] = true
				u:damage
				{
					source = hero,
					damage = self.gun_damage,
					skill = self,
					aoe = true,
					attack = true,
				}
			end
		end
	end
	local n = 0
	for _, u in ac.selector()
		: in_range(self.target, 400)
		: is_enemy(hero)
		: sort_nearest_hero(self.target)
		: ipairs()
	do
		n = n + 1
		if n > self.gun_count then
			return
		end
		local mvr = ac.mover.target
		{
			source = hero,
			target = u,
			start = hero:get_point() - {angle, 120} - {angle - 90, 20},
			model = [[Abilities\Spells\Other\TinkerRocket\TinkerRocketMissile.mdl]],
			speed = 2000,
			turn_speed = 720,
			angle = angle,
			missile = true,
			skill = self,
			high = 110,
			size = 1.2,
		}
		if mvr then
			function mvr:on_remove()
				do_damage(self.mover:get_point())
			end
		end
	end
	for i = n, self.gun_count do
		local target = self.target - {math.random(0, 359), math.random(100, 300)}
		local mvr = ac.mover.line
		{
			source = hero,
			distance = hero:get_point() * target - 120,
			start = hero:get_point() - {angle, 120} - {angle - 90, 20},
			model = [[Abilities\Spells\Other\TinkerRocket\TinkerRocketMissile.mdl]],
			speed = 2000,
			turn_speed = 360,
			angle = hero:get_point() / target,
			missile = true,
			skill = self,
			high = 110,
			target_high = 0,
			size = 1.2,
		}
		if mvr then
			function mvr:on_remove()
				do_damage(self.mover:get_point())
			end
		end
	end
end

function mt:gun_on_cast_stop()
	local hero = self.owner
	hero:set_animation('stand')
end

function mt:sword_on_hit(hit, damage)
	if hit < 3 then
		return
	end
	local hero = self.owner
	damage.target:add_buff '减速'
	{
		source = hero,
		move_speed_rate = self.sword_move_speed,
		time = self.sword_time,
	}
end

function mt:gun_on_hit(hit, damage)
	if hit < 3 then
		return
	end
	local hero = self.owner
	local life_rate = self.gun_life_rate
	local mvr = ac.mover.target
	{
		source = hero,
		target = hero,
		start = damage.target:get_point(),
		model = [[ball_green_weak.mdl]],
		speed = 1000,
		missile = true,
		skill = self,
		high = 60,
		size = 0.5,
	}
	if mvr then
		function mvr:on_finish()
			hero:add('生命', hero:get '生命上限' * life_rate / 100)
		end
	end
end
