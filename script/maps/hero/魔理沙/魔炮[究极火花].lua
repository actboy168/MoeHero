local mt = ac.skill['魔炮[究极火花]']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNmarisaR.blp]],

	--技能说明
	title = '魔炮[究极火花]',
	
	tip = [[
魔理沙使出浑身之力放出魔之光线，每秒对前方直线区域造成%damage%(+%damage_plus%)伤害。再次使用可以提前结束，并根据引导的时间返还冷却和魔法。

|cffffff11需要引导|r
	]],

	--冷却
	charge_cool = {90, 70, 50},

	--耗蓝
	cost = {160, 200, 240},

	--施法距离
	range = 800,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--施法动作相关
	cast_start_time = 0.2,
	cast_channel_time = {4, 5, 6},
	break_cast_channel = 1,

	--伤害
	damage = {180, 240, 300},

	damage_plus = function(self, hero)
		return hero:get_ad() * 3.0
	end,

	damage_distance = 900,
	damage_width = 200,
	cooldown_mode = 1,
	charge_max_stack = 1,
	show_stack = 0,
	show_charge = 0,
}

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local damage = (self.damage + self.damage_plus) / 10
	hero:add_buff '魔炮[究极火花]'
	{
		skill = self,
		angle = angle,
		damage_distance = self.damage_distance,
		damage_width = self.damage_width,
		damage = damage,
	}
	self.current_channel_tick = hero:clock()
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:remove_buff '魔炮[究极火花]'
	local per = 0.15 + (hero:clock() - self.current_channel_tick) / self.cast_channel_time / 1000
	if per < 1 then
		self:set_cd(self:get_cd() * per)
		hero:add('魔法', self.cost * (1 - per))
	end
end

local mt = ac.skill['魔炮[究极火花]-关闭']

mt{
	art = [[replaceabletextures\commandbuttons\BTNmarisaR.blp]],
	instant = 1,
}

function mt:on_cast_finish()
	local hero = self.owner
	hero:remove_buff '魔炮[究极火花]'
end

local mt = ac.buff['魔炮[究极火花]']

mt.pulse = 0.1

function mt:on_add()
	local hero = self.target
	hero:replace_skill('魔炮[究极火花]', '魔炮[究极火花]-关闭')
	hero:set_animation 'stand channel'
	self.eff = hero:create_dummy('e00G', hero:get_point(), self.angle)
	self.eff:set_high(120)
	self.trg1 = hero:event '单位-时停开始' (function ()
		self.eff:add_restriction '时停'
	end)
	self.trg2 = hero:event '单位-时停结束' (function ()
		self.eff:remove_restriction '时停'
	end)
end

function mt:on_pulse()
	local hero = self.target
	for _, u in ac.selector()
		: in_line(hero, self.angle, self.damage_distance, self.damage_width)
		: is_enemy(hero)
		: ipairs()
	do
		if u:is_type('建筑') then
			u:damage
			{
				source = hero,
				damage = self.damage * 0.2,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
		else
			u:damage
			{
				source = hero,
				damage = self.damage,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
		end
	end
end

function mt:on_remove()
	local hero = self.target
	if self.eff then
		self.eff:remove()
	end
	self.trg1:remove()
	self.trg2:remove()
	hero:replace_skill('魔炮[究极火花]-关闭', '魔炮[究极火花]')
	hero:add_animation 'stand'
	self.skill:finish()
end
