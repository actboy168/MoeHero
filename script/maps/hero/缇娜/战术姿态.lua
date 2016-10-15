local mt = ac.skill['战术姿态']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNTinaE.blp]],
	title = '战术姿态',
	tip = [[
缇娜进入|cff00ccff战术姿态|r并开始装填子弹，每%reload%装填一颗子弹。
子弹装填满或再次使用此技能后回到|cff00ccff强袭姿态|r。
	]],
	cool = {20, 8},
	instant = 1,
	-- 装填周期
	reload = {1.8, 1.4},
}

function mt:on_cast_finish()
	local hero = self.owner
	hero:set_resource('子弹', 0)
	local buff = hero:add_buff '战术姿态'
	{
		skill = self,
		pulse = self.reload,
	}
	if buff then
		self.buff = buff
	end
end

function mt:on_remove()
	if self.buff then
		self.buff:remove()
	end
end


local mt = ac.buff['战术姿态']

function mt:on_add()
	local hero = self.target
	self.eff = hero:add_effect('overhead', [[Units\NightElf\Owl\Owl.mdl]])
	hero:replace_skill('战术姿态', '强袭姿态')
	hero:replace_skill('震撼弹', '风暴之舞')
	hero:replace_skill('爆裂弹', '雷霆奔袭')
end

function mt:on_remove()
	local hero = self.target
	self.eff:remove()
	hero:replace_skill('强袭姿态', '战术姿态')
	hero:replace_skill('风暴之舞', '震撼弹')
	hero:replace_skill('雷霆奔袭', '爆裂弹')
	hero:remove_skill '风暴之舞'
	hero:remove_skill '雷霆奔袭'
end

function mt:on_pulse()
	local hero = self.target
	hero:add_resource('子弹', 1)
	hero:get_owner():play_sound [[response\缇娜\skill\E.mp3]]
	if hero:get_resource '子弹' >= hero:get_resource '子弹上限' then
		self:remove()
	end
end


local mt = ac.skill['强袭姿态']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNTinaEE.blp]],
	title = '强袭姿态',
	tip = [[
立刻回到强袭姿态并结束装填。
	]],
	instant = 1,
}

function mt:on_cast_finish()
	local hero = self.owner
	hero:remove_buff '战术姿态'
end


local mt = ac.skill['风暴之舞']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNTinaEQ.blp]],
	title = '风暴之舞',
	tip = [[
缇娜扔出一颗手雷将附近的敌人击晕%stun%秒并后退%distance%距离。
	]],
	cast_channel_time = 10,
	cast_animation = 'spell four',
	cast_animation_speed = 0.5,
	-- 位移距离
	distance = 500,
	-- 位移速度
	speed = 2000,
	-- 位移加速度
	accel = 5000,
	-- 最小速度
	min_speed = 300,
	-- 晕眩范围
	area = 300,
	-- 晕眩时间
	stun = 1,
}

function mt:on_cast_channel()
	self:disable()
	local hero = self.owner
	local mover = ac.mover.line
	{
		source = hero,
		mover = hero,
		skill = self,
		angle = hero:get_facing() + 180,
		distance = self.distance,
		speed = self.speed,
		accel = - self.accel,
		min_speed = self.min_speed,
		block = true,
	}

	if not mover then
		self:stop()
		return
	end

	function mover:on_remove()
		self.skill:finish()
	end

	local mover = ac.mover.line
	{
		source = hero,
		model = [[Abilities\Weapons\ProcMissile\ProcMissile.mdl]],
		size = 3,
		skill = self,
		angle = 0,
		distance = 1,
		speed = 1,
		height = 400,
		high = 0,
		target_high = 0,
	}

	if not mover then
		return
	end

	local area = self.area
	local stun = self.stun

	function mover:on_finish()
		self.mover:get_point():add_effect [[model\tina\newdirtexnofire.mdl]] :remove()
		for _, u in ac.selector()
			: in_range(self.mover, area)
			: is_enemy(hero)
			: ipairs()
		do
			u:add_buff '晕眩'
			{
				source = hero,
				skill = self.skill,
				time = stun,
			}
		end
	end
end


local mt = ac.skill['雷霆奔袭']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNTinaEW.blp]],
	title = '雷霆奔袭',
	tip = [[
缇娜飞速跑向目标位置。
若缇娜跑向了一个没有敌方英雄的位置或没有使用过这个技能，缇娜将在回到强袭姿态后提高%move_rate%%的移动速度，持续%move_time%秒。
	]],
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 999999,
	cast_channel_time = 10,
	cast_animation = 12,
	-- 位移距离
	distance = 800,
	-- 位移速度
	speed = 1500,
	-- 判定范围
	area = 800,
	-- 移动速度奖励(%)
	move_rate = 30,
	-- 移速持续时间
	move_time = 3,
}

function mt:on_cast_channel()
	self:disable()
	local hero = self.owner
	local target = self.target
	local area = self.area
	local mover = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = hero:get_point() / target,
		distance = self.distance,
		skill = self,
		speed = self.speed,
	}

	if not mover then
		self:stop()
		return
	end

	function mover:on_remove()
		self.skill:finish()
	end

	function mover:on_finish()
		local g = ac.selector()
			: in_range(hero, area)
			: is_enemy(hero)
			: of_hero()
			: get()
		if #g == 0 then
			self.skill:set('flag', true)
		end
	end
end

function mt:on_remove()
	local hero = self.owner
	if self:is_enable() or self.flag then
		hero:add_buff '雷霆奔袭'
		{
			skill = self,
			move_rate = self.move_rate,
			time = self.move_time,
		}
	end
end


local mt = ac.buff['雷霆奔袭']

function mt:on_add()
	self.target:add('移动速度%', self.move_rate)
	self.eff = self.target:add_effect('origin', [[Abilities\Spells\NightElf\FaerieDragonInvis\FaerieDragon_Invis.mdl]])
end

function mt:on_remove()
	self.target:add('移动速度%', - self.move_rate)
	self.eff:remove()
end
