local mt = ac.skill['剑技-升天阵']
{
	--初始等级
	level = 0,
	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNAmiellaSwordW.blp]],
	--技能说明
	title = '剑技-升天阵',
	tip = [[
|cff00ccff剑技-升天阵|r:
将小范围内的敌人挑飞，造成%sword_damage_base%(+%sword_damage_plus%)伤害。
|cff8888883Hit之后，落地时会对附近的敌人造成等额的伤害。|r

|cff00ccff炮技-轰爆|r:
对目标区域进行强烈的轰炸，敌人会被击退（远离爆炸中心）并造成%gun_damage_base%(+%gun_damage_plus%)伤害。
|cff8888883Hit之后，额外晕眩%gun_stun_time%秒。|r
	]],

	cool = 1,
	cost = 80,
	range = 9999,
	cast_start_time = 0.4,
	cast_shot_time = 0.3,
	cast_finish_time = 0.4,
	target_type = ac.skill.TARGET_TYPE_POINT,

	--剑技
	sword_range = {200, 300},
	sword_damage_base = {80, 160},
	sword_damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	sword_damage = function(self, hero)
		return self.sword_damage_base + self.sword_damage_plus
	end,

	--炮技
	gun_range = {300, 500},
	gun_distance = {800, 1000},
	gun_stun_time = 0.5,
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
		self.on_cast_stop = self.sword_on_cast_stop
		self.cast_shot_time = 0.4
		self:set_animation(7)
	else
		self.mode = 'gun'
		self.on_cast_shot = self.gun_on_cast_shot
		self.on_cast_stop = self.gun_on_cast_stop
		self.cast_shot_time = 0.2
		self:set_animation(6)
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
	local dummy = hero:create_dummy('e00J', hero:get_point() - {self.cast_angle, 100}, self.cast_angle + 40)
	dummy:set_size(3)
	dummy:set_high(200)
	dummy:kill()
	
	for _, u in ac.selector()
		: in_range(hero:get_point() - {self.cast_angle, 120}, self.sword_range)
		: is_enemy(hero)
		: ipairs()
	do
		local buff = u:add_buff '击退'
		{
			source = hero,
			angle = self.cast_angle,
			speed = 100,
			distance = 400,
			accel = 2000,
			high = 400,
		}
		local dmg = u:damage
		{
			source = hero,
			damage = self.sword_damage,
			skill = self,
			aoe = true,
			attack = true,
		}
		if dmg and dmg.success and buff and dmg.amiella_hit then
			local skill = self
			function buff:event_remove()
				for _, u2 in ac.selector()
					: in_range(u:get_point(), skill.sword_range)
					: is_enemy(hero)
					: ipairs()
				do
					if u2 ~= u then
						u2:damage
						{
							source = hero,
							damage = self.skill.sword_damage,
							skill = skill,
							aoe = true,
							attack = true,
						}
					end
				end
			end
		end
	end
end

function mt:gun_on_cast_shot()
	local hero = self.owner
	local distance = math.min(hero:get_point() * self.target, self.gun_distance)
	local angle = hero:get_point() / self.target
	self.target = hero:get_point() - {angle, distance}
	local mvr = ac.mover.line
	{
		source = hero,
		distance = distance - 200,
		start = hero:get_point() - {angle, 200} - {angle - 90, 20},
		model = [[Abilities\Weapons\Mortar\MortarMissile.mdl]],
		speed = 800,
		turn_speed = 360,
		angle = hero:get_point() / self.target,
		skill = self.skill,
		missile = true,
		skill = self,
		high = 170,
		target_high = 0,
		height = 50 + (distance - 200) / 6,
		size = self.gun_range / 200,
	}
	if not mvr then
		return
	end
	function mvr:on_remove()
		for _, u in ac.selector()
			: in_range(self.mover, self.skill.gun_range)
			: is_enemy(hero)
			: ipairs()
		do
			local buff = u:add_buff '击退'
			{
				source = hero,
				angle = self.mover:get_point() / u:get_point(),
				speed = 1000,
				distance = math.max(0, self.skill.gun_range - self.mover:get_point() * u:get_point()),
				accel = -1000,
			}
			local dmg = u:damage
			{
				source = hero,
				damage = self.skill.gun_damage,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
			if dmg and dmg.success and buff and dmg.amiella_hit then
				local skill = self.skill
				function buff:event_remove()
					u:add_buff '晕眩'
					{
						source = hero,
						time = skill.gun_stun_time,
					}
				end
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
	damage.amiella_hit = true
end

function mt:gun_on_hit(hit, damage)
	if hit < 3 then
		return
	end
	damage.amiella_hit = true
end
