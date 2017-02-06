local mt = ac.skill['剑技-幻影突刺']
{
	--初始等级
	level = 0,
	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNAmiellaSwordE.blp]],
	--技能说明
	title = '剑技-幻影突刺',
	tip = [[
|cff00ccff剑技-幻影突刺|r:
俯身冲刺，对目标扇形区域造成%sword_damage_base%(+%sword_damage_plus%)伤害。
|cff8888883Hit之后，返还%sword_cost_rate%%消耗的体力，这个效果只能生效一次。|r

|cff00ccff炮技-天光流隙|r:
对前方直线上的敌人造成%gun_damage_base%(+%gun_damage_plus%)伤害。
|cff8888883Hit之后，伤害提高%gun_damage_rate%%。|r
	]],

	cool = 1,
	cost = {120, 80},
	range = 9999,
	cast_start_time = 0,
	cast_channel_time = 10,
	cast_shot_time = 0.4,
	cast_finish_time = 0.4,
	target_type = ac.skill.TARGET_TYPE_POINT,
	break_order = 1,

	--剑技
	sword_range = 400,
	sword_speed = 3000,
	sword_distance = {500, 700},
	sword_cost_rate = 50,
	sword_damage_base = {80, 160},
	sword_damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	sword_damage = function(self, hero)
		return self.sword_damage_base + self.sword_damage_plus
	end,
	
	--炮技
	gun_speed = 1000,
	gun_distance = 50,
	gun_accel = -5000,
	gun_damage_rate = 30,
	gun_hit_width = {100, 140},
	gun_hit_height = {700, 900},
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
	if hero:get_point() * self.target >= 350 then
		self.mode = 'sword'
		self.on_cast_channel = self.sword_on_cast_channel
		self.on_cast_shot = self.sword_on_cast_shot
		self.on_cast_stop = nil
		self:set_animation(3)
	else
		self.mode = 'gun'
		self.on_cast_channel = self.gun_on_cast_channel
		self.on_cast_shot = self.gun_on_cast_shot
		self.on_cast_stop = self.gun_on_cast_stop
		self:set_animation(4)
	end
end

function mt:on_cast_break()
	local hero = self.owner
	hero:set_animation('stand')
end

function mt:sword_on_cast_channel()
	local hero = self.owner
	local target = self.target
	self.cast_angle = hero:get_point() / target
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		speed = self.sword_speed,
		angle = self.cast_angle,
		distance = math.min(self.sword_distance, hero:get_point() * target),
		skill = self,
	}
	if not mvr then
		self:stop()
		return
	end
	function mvr:on_move()
		hero:get_point():add_effect([[model\amiella\sword_e_effect.mdx]]):remove()
	end
	function mvr:on_remove()
		self.skill:finish()
	end
	local u = hero:create_dummy(hero:get_type_id(), hero:get_point(), self.cast_angle)
	u:set_owner(ac.player(16))
	u:set_animation(3)
	u:set_animation_speed(0.6)
	u:setAlpha(60)
	u:set_class '马甲'
	local mvr = ac.mover.line
	{
		source = hero,
		mover = u,
		speed = self.sword_speed * 0.6,
		angle = self.cast_angle,
		distance = mvr.distance,
		skill = self,
	}
	if not mvr then
		u:remove()
		return
	end
	function mvr:on_remove()
		self.mover:remove()
	end
end

function mt:sword_on_cast_shot()
	local hero = self.owner
	local target = self.target
	ac.effect(hero:get_point() - {self.cast_angle, 50}, [[model\amiella\sword_q_effect.mdx]], self.cast_angle, 3):remove()
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

function mt:gun_on_cast_channel()
	local hero = self.owner
	local target = self.target
	self.cast_angle = hero:get_point() / target
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		speed = self.gun_speed,
		min_speed = 100,
		accel = self.gun_accel,
		angle = 180 + self.cast_angle,
		distance = self.gun_distance,
		skill = self,
		block = true,
	}
	if not mvr then
		self:stop()
		return
	end
	function mvr:on_remove()
		self.skill:finish()
	end
end

local missile = {
	[[model\amiella\gun_e_missile_a.mdx]],
	[[model\amiella\gun_e_missile_b.mdx]],
}

function mt:gun_on_cast_shot()
	local hero = self.owner
	for i = 1, 2 do
		local mvr = ac.mover.line
		{
			source = hero,
			distance = self.gun_hit_height,
			start = hero:get_point() - {self.cast_angle, 200} - {self.cast_angle - 90, 80 * i - 90},
			model = missile[i],
			speed = 2800,
			angle = self.cast_angle,
			missile = true,
			skill = self,
			high = 110,
			hit_area = self.gun_hit_width,
		}
		if mvr then
			function mvr:on_hit(target)
				target:damage
				{
					source = hero,
					damage = self.skill.gun_damage,
					skill = self.skill,
					aoe = true,
					attack = true,
				}
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
	if self.has_hit then
		return
	end
	self.has_hit = true
	local hero = self.owner
	hero:add_resource('体力', self:get_cost() * self.sword_cost_rate / 100)
end

function mt:gun_on_hit(hit, damage)
	if hit < 3 then
		return
	end
	damage:mul(self.gun_damage_rate / 100)
end
