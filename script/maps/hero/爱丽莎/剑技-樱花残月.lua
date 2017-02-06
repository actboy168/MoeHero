local mt = ac.skill['剑技-樱花残月']
{
	--初始等级
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNAmiellaSwordR.blp]],
	--技能说明
	title = '剑技-樱花残月',
	tip = [[
|cff00ccff剑技-樱花残月|r:
对前方区域连续打击，造成%sword_damage_base%(+%sword_damage_plus%)伤害。

|cffffff11施法时无敌。|r

|cff00ccff炮技-赤色彗星|r:
对前方扇形区域连续扫射，造成%gun_damage_base%(+%gun_damage_plus%)伤害。

|cff00ccff被动|r:
敌人被剑技、炮技交替命中时会累积连击数，每点连击会让本次伤害的破甲增加%pene_per_hit%，并附带额外的效果。
	]],

	cool = {70, 50},
	cost = 100,
	range = 9999,
	cast_start_time = 0.1,
	cast_channel_time = 1.46,
	target_type = ac.skill.TARGET_TYPE_POINT,

	--剑技
	sword_range = 450,
	sword_damage_base = {80, 160},
	sword_damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	sword_damage = function(self, hero)
		return self.sword_damage_base + self.sword_damage_plus
	end,

	--炮技
	gun_damage_base = {60, 140},
	gun_damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
	gun_damage = function(self, hero)
		return self.gun_damage_base + self.gun_damage_plus
	end,

	--被动
	pene_per_hit = {6, 10},
}

function mt:on_cast_start()
	local hero = self.owner
	if hero:get_point() * self.target < 350 then
		self.mode = 'sword'
		self.on_cast_channel = self.sword_on_cast_channel
		self.on_cast_stop = self.sword_on_cast_stop
		self.cast_start_time = 0.1
		self.cast_channel_time = 1.46
		self:set_animation('spell two')
		hero:set_animation_speed(1.6)
	else
		self.mode = 'gun'
		self.on_cast_channel = self.gun_on_cast_channel
		self.on_cast_stop = self.gun_on_cast_stop
		self.cast_start_time = 0.3
		self.cast_channel_time = 1.36
		self:set_animation(4)
	end
end

function mt:on_cast_break()
	local hero = self.owner
	hero:set_animation('stand')
	hero:set_animation_speed(1)
end

function mt:sword_on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	hero:add_restriction '无敌'
	self.eff = hero:add_effect('origin', [[model\amiella\sword_r_effect.mdx]])
	ac.effect(hero:get_point() - {angle, 50}, [[model\amiella\sword_q_effect.mdx]], angle, 3):remove()
	for _, u in ac.selector()
		: in_sector(hero:get_point(), self.sword_range, angle, 120)
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
	self.cast_timer = hero:wait(300, function()
		local dummy = hero:create_dummy('e00K', hero:get_point() - {angle, 100}, angle)
		dummy:set_size(3)
		dummy:kill()
		for _, u in ac.selector()
			: in_sector(hero:get_point() - {angle, 50}, self.sword_range, angle, 120)
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
		self.cast_timer = hero:wait(300, function()
			local dummy = hero:create_dummy('e00J', hero:get_point() - {angle, 150}, angle + 40)
			dummy:set_size(3)
			dummy:set_high(200)
			dummy:kill()
			for _, u in ac.selector()
				: in_range(hero:get_point() - {angle, 150}, self.sword_range * 0.75)
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
			self.cast_timer = hero:wait(500, function()
				local dummy = hero:create_dummy('e00M', hero:get_point() - {angle, 200}, angle + 40)
				dummy:set_size(3)
				dummy:set_high(240)
				dummy:kill()
				for _, u in ac.selector()
					: in_range(hero:get_point() - {angle, 150}, self.sword_range)
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
			end)
		end)
	end)
end

function mt:sword_on_cast_stop()
	local hero = self.owner
	hero:remove_restriction '无敌'
	self.eff:remove()
	self.cast_timer:remove()
	hero:set_animation('stand')
	hero:set_animation_speed(1)
end

function mt:gun_on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local facing = angle
	local min_facing = facing - 50
	local max_facing = facing + 50
	local delta = 5
	local mark = {}
	local count = 0
	self.timer = hero:loop(20, function()
		if facing > max_facing then
			delta = -math.abs(delta)
		elseif facing < min_facing then
			delta = math.abs(delta)
		end
		facing = facing + delta
		hero:set_facing(facing)
		local start = hero:get_point() - {facing, 120}
		count = count + 1
		if count % 5 == 1 then
			start:play_sound([[response\爱丽莎\skill\GunR.mp3]])
		end
		local mvr = ac.mover.line
		{
			source = hero,
			distance = 1000,
			start = start,
			model = [[model\amiella\gun_r_missile.mdx]],
			speed = 2000,
			angle = facing,
			missile = true,
			skill = self,
			high = 110,
			target_high = 0,
			size = 1.2,
			hit_area = 100,
		}
		if not mvr then
			return
		end
		function mvr:on_hit(u)
			if mark[u] == nil then
				mark[u] = 1
			elseif mark[u] < 4 then
				mark[u] = mark[u] + 1
			else
				return
			end
			u:damage
			{
				source = hero,
				damage = self.skill.gun_damage,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
			return true
		end
		function mvr:on_remove()
			ac.effect(self.mover:get_point(),[[model\amiella\gun_r_effect.mdx]],self.angle):remove()
		end
	end)
	self.timer:on_timer()
end

function mt:gun_on_cast_stop()
	local hero = self.owner
	self.timer:remove()
	hero:set_animation('stand')
end

function mt:sword_on_hit()
end

function mt:gun_on_hit()
end

function mt:on_add()
	local hero = self.owner
	self.hit_trg = hero:event '造成伤害前效果' (function (_, damage)
		if not damage.skill or damage.skill:get_type() ~= '英雄' then
			return
		end
		damage.target:add_buff '血技-不动明王阵'
		{
			source = hero,
			skill = self,
			mode = damage.skill.mode,
			damage = damage,
			time = 5,
		}
	end)
end

function mt:on_remove()
	self.hit_trg:remove()
end

local mt = ac.buff['血技-不动明王阵']

function mt:on_add()
	self:add_stack(1)
	self.skill_set = { [self.damage.skill] = true }
end

function mt:on_remove()
end

function mt:on_cover(new)
	if self.skill_set[new.damage.skill] then
		if new.damage.skill.slotid == 4 then
			self.mode = new.mode
			self:on_hit(new.damage)
			self:set_remaining(new.time)
		end
		return false
	end
	self.skill_set[new.damage.skill] = true
	if self.mode ~= new.mode then
		self.mode = new.mode
		self:on_hit(new.damage)
	else
		self:set_stack(1)
		self.mode = new.mode
	end
	self:set_remaining(new.time)
	return false
end

function mt:on_hit(damage)
	self:add_stack(1)
	local hit = self:get_stack()
	damage.skill[self.mode .. '_on_hit'](damage.skill, hit, damage)
	damage['破甲'] = damage['破甲'] + hit * self.skill.pene_per_hit
	ac.texttag
	{
		string = ('%dHit!'):format(hit),
		size = 12,
		position = self.target:get_point(),
		zoffset = -30,
		red = 100,
		green = self.mode == 'sword' and 0 or 100,
		blue = 0,
		player = self.source:get_owner(),
		show = ac.texttag.SHOW_SELF,
		life = 5,
		fade = 4,
		speed = 40,
		angle = 45,
	}
end
