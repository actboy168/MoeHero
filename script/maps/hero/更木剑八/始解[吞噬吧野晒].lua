



local mt = ac.skill['始解[吞噬吧野晒]']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNjbr.blp]],

	--技能说明
	title = '始解[吞噬吧野晒]',
	
	tip = [[
发出一道巨大的斩击造成%damage%(+%damage_plus%)伤害并击晕%stun_time%秒，附近的敌方单位受到波及，造成%damage_rate%%的伤害。
击中的敌人会在%slow_time%秒内降低%move_speed_rate%%移动速度和%attack_speed%攻击速度。
斩魄刀变为巨大，暴击率提高%crit_chance%%，攻击力提高%buff_attack%%，攻击间隔延长%buff_attack_speed_rate%%，持续%time%秒。
	]],

	--施法前摇
	cast_start_time = 0.6,
	
	--施法后摇
	cast_finish_time = 0.6,

	--施法动作
	cast_animation = 5,

	--冷却
	cool = 75,

	--耗蓝
	cost = {150, 175, 200},
	
	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--施法距离
	range = 600,

	--伤害距离
	distance = 600,

	--弹道速度
	speed = 2000,

	--伤害宽度
	damage_width1 = 150,

	--伤害
	damage = {200, 325, 450},

	damage_plus = function(self, hero)
		return hero:get_ad() * 2.2
	end,

	--晕眩时间
	stun_time = 0.75,

	--波及宽度
	damage_width2 = 400,

	--波及伤害(%)
	damage_rate = 50,

	--减速时间
	slow_time = 0.75,

	--移速降低(%)
	move_speed_rate = 50,

	--攻速降低
	attack_speed = 50,

	--暴击几率(%)
	crit_chance = 20,

	--自身攻速降低(%)
	buff_attack_speed_rate = 60,

	--自身攻击增加(%)
	buff_attack = {100, 110, 120},

	--持续时间
	time = 10,

	--变身单位类型
	unit_type_id = 'H00K',

}

function mt:on_cast_start()
	local hero = self.owner
	
	--加个Buff,变身!
	hero:add_buff '卍解[吞噬吧野晒]'
	{
		time = self.time,
		move_speed_rate		= self.move_speed_rate,
		attack_speed		= self.attack_speed,
		crit_chance			= self.crit_chance,
		attack_speed_rate	= self.buff_attack_speed_rate,
		attack				= self.buff_attack,
		unit_type_id		= self.unit_type_id,
	}
end

function mt:on_cast_break()
	local hero = self.owner

	hero:remove_buff '卍解[吞噬吧野晒]'
end

function mt:on_cast_channel()
	local skill				= self
	local hero				= self.owner

	--发射一道剑气
	
	local target			= self.target
	local angle				= hero:get_point() / target
	local damage_area1		= self.damage_area1
	local damage1			= self.damage + self.damage_plus
	local stun_time			= self.stun_time
	local damage2			= damage1 * self.damage_rate / 100
	local slow_time			= self.slow_time
	local move_speed_rate	= self.move_speed_rate
	local attack_speed		= self.attack_speed

	local mvr = ac.mover.line
	{
		source = hero,
		model = [[redchongji_large.mdl]],
		angle = angle,
		distance = self.distance,
		speed = self.speed,
		skill = self,
		hit_area = self.damage_area2,
		hit_type = ac.mover.HIT_TYPE_ENEMY
	}

	if not mvr then
		return
	end

	local units = {}
	
	--造成伤害和晕眩
	for _, u in ac.selector()
		: in_line(hero, angle, self.distance, self.damage_width1)
		: is_enemy(hero)
		: ipairs()
	do
		units[u] = true

		--晕眩
		u:add_buff '晕眩'
		{
			time = stun_time,
		}

		--伤害
		u:damage
		{
			source = hero,
			damage = damage1,
			skill = skill,
			aoe = true,
			attack = true,
			--missile = mover
		}
	end

	--造成伤害和晕眩
	for _, u in ac.selector()
		: in_line(hero, angle, self.distance, self.damage_width2)
		: add_filter(function(u)
			return not units[u]
		end)
		: is_enemy(hero)
		: ipairs()
	do	
		--减速
		u:add_buff '减速'
		{
			time = slow_time,
			move_speed_rate = move_speed_rate,
		}
		u:add_buff '减攻速'
		{
			time = slow_time,
			attack_speed = attack_speed,
		}

		--伤害
		u:damage
		{
			source = hero,
			damage = damage2,
			skill = skill,
			aoe = true,
			attack = true,
			--missile = mover
		}
	end
end

local mt = ac.buff['卍解[吞噬吧野晒]']

mt.keep = true

function mt:on_add()
	local hero = self.target
	self.origin_id = hero:get_type_id()
	hero:transform(self.unit_type_id)
	hero:add('暴击', self.crit_chance)
	hero:add('攻击间隔%', self.attack_speed_rate)
	hero:add('攻击%', self.attack)
end

function mt:on_remove()
	local hero = self.target
	hero:transform(self.origin_id)
	hero:add('暴击', -self.crit_chance)
	hero:add('攻击间隔%', - self.attack_speed_rate)
	hero:add('攻击%', - self.attack)
end
