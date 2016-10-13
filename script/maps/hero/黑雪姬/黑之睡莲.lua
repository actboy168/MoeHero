local mt = ac.skill['黑之睡莲']
{
	--初始等级
	level = 0,
	--技能图标
	art = [[btnkrykw.blp]],
	--技能说明
	title = '黑之睡莲',
	tip = [[
|cff00ccff主动|r:
立即回收假想体，并为|cff11ccff死亡穿刺|r增加一层充能。

|cff00ccff被动|r:
每次回收假想体时，获得一个护盾，吸收%life_base%(+%life_plus%)伤害，并且让你造成的伤害提高%damage_rate%%，移动速度提高%move_speed_rate%%，持续%buff_time%秒。
	]],

	--冷却
	cool = {24, 16},
	--耗蓝
	cost = 20,
	--瞬发
	instant = 1,
	--护盾
	life_base = {40, 200},
	life_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	--护盾时间
	buff_time = {5, 7},
	damage_rate = {18, 30},
	move_speed_rate = 30,
}

function mt:on_cast_finish()
	local hero = self.owner
	local skill = hero:find_skill '假想体'
	if not skill then
		return
	end
	local dummy = skill.dummy
	if not dummy then
		return
	end
	if skill.is_follow then
		self:get_back()
		return
	end
	local dummy = skill:create_dummy(hero)
	if not dummy then
		return
	end
	skill:idle(false)
	dummy:set_animation(4)
	local mover = ac.mover.target
	{
		source = hero,
		mover = dummy,
		target = hero,
		speed = 2000,
		skill = self,
		super = true,
		hit_range = 150,
	}

	if not mover then
		return
	end

	function mover:on_remove()
		skill:idle(true)
		skill:follow()
		self.skill:get_back()
	end
end

function mt:get_back()
	local hero = self.owner
	local skill = hero:find_skill '死亡穿刺'
	if skill and skill:get_stack() < skill.charge_max_stack then
		skill:add_stack(1)
	end
end

function mt:on_back()
	local hero = self.owner
	self = self:create_cast()
	hero:add_buff '黑之睡莲'
	{
		life = self.life_base + self.life_plus,
		time = self.buff_time,
		skill = self,
		damage_rate = self.damage_rate,
		move_speed_rate = self.move_speed_rate,
	}
end


local mt = ac.shield_buff['黑之睡莲']

function mt:on_add()
	local hero = self.target
	hero:addDamageRate(self.damage_rate)
	hero:add('移动速度%', self.move_speed_rate)
end

function mt:on_remove()
	local hero = self.target
	hero:addDamageRate(-self.damage_rate)
	hero:add('移动速度%', -self.move_speed_rate)
end
