local mt = ac.skill['龟派气功']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNwkq.blp]],

	--技能说明
	title = '龟派气功',
	
	tip = [[
经过最多%cast_channel_time%秒的蓄力发射一道冲击波，最多造成%damage%(+%damage_plus%)伤害并击晕%stun_time%秒，技能效果取决于蓄力时间。再次使用可以立刻释放。

|cffffff11需要持续施法|r
	]],

	--施法距离
	range = 1500,

	--施法时间
	cast_animation = 6,
	cast_channel_time = 1,
	cast_finish_time = 0.3,
	break_cast_channel = 1,

	--冷却
	cool = 10,

	--耗蓝
	cost = {100, 140},
	
	--伤害
	damage = {40, 200},
	
	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 2.2
	end,

	--最小伤害(%)
	damage_rate = 25,

	--击晕时间
	stun_time = 1,

	--目标类型
	target_type = mt.TARGET_TYPE_POINT,

	--射程
	distance = 1800,

	--弹道速度
	speed = 2000,
	
	--碰撞半径
	hit_area = 200,
}

mt.start_time = 0

function mt:on_cast_channel()
	local hero = self.owner
	self.start_time = hero:clock()
	self.ability01_effect = self.owner:add_effect('hand right',[[ModelDEKAN\Ability\DEKAN_Goku_Kamehameha_Channel.mdl]])
	hero:add_buff '龟派气功'
	{
		skill = self,
	}
end

function mt:on_cast_stop()
	local hero = self.owner
	local skill = self
	if self.ability01_effect then
		self.ability01_effect:remove()
	end
	hero:remove_buff '龟派气功'
	hero:set_animation(7)
	hero:set_animation_speed(5)
	hero:wait(100, function()
		hero:set_animation_speed(1)
		hero:add_animation 'stand'
	end)
	
	--蓄力时间
	local cast_channel_time = (hero:clock() - self.start_time) / 1000
	--最大伤害
	local max_damage = self.damage + self.damage_plus
	local stun_time = self.stun_time

	--求当前伤害
	local damage = max_damage
	local stun   = stun_time
	if cast_channel_time < self.cast_channel_time then
		local rate = (self.damage_rate + (100 - self.damage_rate) * cast_channel_time / self.cast_channel_time) / 100
		damage = damage * rate
		stun   = stun   * rate
	end

	--发射投射物
	local mvr = ac.mover.line
	{
		source = hero,
		target = self.target,
		model = [[modeldekan\ability\Dekan_Goku_kamehameha_missile.mdl]],
		distance = self.distance,
		speed = self.speed,
		damage = damage,
		hit_area = self.hit_area,
		skill = self,
		size = 2,
		high = 60,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
	}

	if not mvr then
		return
	end

	function mvr:on_hit(target)
		target:add_buff '晕眩'
		{
			source = hero,
			time = stun,
		}
		target:damage
		{
			source = hero,
			damage = damage,
			skill = skill,
			aoe = true,
			attack = true,
			missile = self.mover,
		}
	end
end

local mt = ac.skill['龟派气功-发射']

mt{
	art = [[BTNwkq.blp]],
	instant = 1,
}

function mt:on_cast_finish()
	local hero = self.owner
	hero:remove_buff '龟派气功'
end

local mt = ac.buff['龟派气功']

function mt:on_add()
	local hero = self.target
	hero:replace_skill('龟派气功', '龟派气功-发射')
end

function mt:on_remove()
	local hero = self.target
	hero:replace_skill('龟派气功-发射', '龟派气功')
	self.skill:finish()
end
