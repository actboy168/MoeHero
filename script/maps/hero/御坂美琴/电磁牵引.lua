local math = math

local mt = ac.skill['电磁牵引']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNpjq.blp]],

	--技能说明
	title = '电磁牵引',
	
	tip = [[
吸附一个地形或者单位，你靠近或者向目标移动时速度增加%move_speed%点，持续%mark_time%秒。
沿着地形高速移动时，你可以保持这个状态。

|cffffff11可充能%charge_max_stack%次|r
	]],

	--施法距离
	range = {500, 700},

	--冷却
	cool = 1,
	charge_cool = {10, 8},

	--耗蓝
	cost = 50,

	--目标类型
	target_type = mt.TARGET_TYPE_POINT,

	--弹道速度
	speed = 3000,

	--弹道距离
	distance = {600, 800},

	--判定半径
	radius = 100,

	--标记Buff时间
	mark_time = 3,

	--加速
	move_speed = {280, 600},

	--面向单位的角度判定
	move_angle = 120,

	--吸附地形时需要保持的距离
	move_distance = 175,

	--使用次数
	cooldown_mode = 1,
	charge_max_stack = 3,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local skl = self
	local mvr = ac.mover.line
	{
		source = hero,
		speed = self.speed,
		model = [[Abilities\Weapons\FarseerMissile\FarseerMissile.mdl]],
		high = 50,
		skill = self,
		block = true,
		angle = hero:get_point() / target:get_point(),
		distance = self.distance,
		hit_area = self.radius,
		hit_type = ac.mover.HIT_TYPE_ALL,
	}
	if not mvr then
		return
	end
	local ln = ac.lightning('CLSB', hero, mvr.mover, 75, 75)
	function mvr:on_hit(target)
		skl:add_unit_buff(target)
		return true
	end
	function mvr:on_block()
		skl:add_block_buff(self.mover:get_point())
		return true
	end
	function mvr:on_remove()
		if ln then
			ln:remove()
		end
	end
end

function mt:add_unit_buff(u)
	local hero = self.owner
	u:add_buff '电磁牵引-单位特效'
	{
		source = hero,
		time = self.mark_time,
		skill = self,
	}
	hero:add_buff '电磁牵引-标记'
	{
		source = hero,
		time = self.mark_time,
		move_speed = self.move_speed,
		move_time = self.move_time,
		move_angle = self.move_angle / 2,
		target_unit = u,
		move_distance = self.move_distance,
		skill = self,
	}
end

function mt:add_block_buff(poi)
	local hero = self.owner
	hero:add_buff '电磁牵引-标记'
	{
		source = hero,
		time = self.mark_time,
		move_speed = self.move_speed,
		move_time = self.move_time,
		move_distance = self.move_distance,
		move_angle = self.move_angle / 2,
		path_point = poi,
		skill = self,
	}
end

local mt = ac.buff['电磁牵引-加速']

function mt:on_add()
	local hero = self.target
	self.blend = self.skill:add_blend('2', 'frame', 2)
	hero:add('移动速度', self.move_speed)
end

function mt:on_remove()
	local hero = self.target
	self.blend:remove()
	hero:add('移动速度', -self.move_speed)
end

function mt:on_cover(new)
	self:set_remaining(new.time)
	return false
end


local mt = ac.buff['电磁牵引-单位特效']

mt.cover_type = 1

function mt:on_add()
	self.eff = self.target:add_effect('origin', [[Abilities\Spells\Orc\Purge\PurgeBuffTarget.mdl]])
end

function mt:on_remove()
	self.eff:remove()
end

local mt = ac.buff['电磁牵引-标记']

mt.cover_type = 1
mt.pulse = 0.1

function mt:on_add()
	if self.path_point then
		self.eff = self.path_point:add_effect([[Abilities\Spells\Orc\Purge\PurgeBuffTarget.mdl]])
	end
	local target = self.target_unit or self.path_point
	self.blend = self.skill:add_blend('1', 'frame', 1)
	self.ln = ac.lightning('CLSB', self.source, target, 75, 75)
	self:on_pulse()
end

function mt:on_remove()
	self.blend:remove()
	if self.eff then
		self.eff:remove()
	end
	if self.bff then
		self.bff:remove()
	end
	self.ln:remove()
end

function mt:on_pulse()
	local hero = self.source
	local target = self.target_unit or self.path_point
	if self.target_unit and not self.target_unit:is_alive() then
		self:remove()
		return
	end
	if ac.math_angle(hero:get_facing(), hero:get_point() / target:get_point()) < self.move_angle then
		self.bff = hero:add_buff '电磁牵引-加速'
		{
			move_speed = self.move_speed,
			time = 0.25,
			skill = self.skill,
		}
		self.ln:setAlpha(100)
		return
	end
	--判断是否在目标附近
	if self.target_unit then
		if hero:get_point() * self.target_unit:get_point() <= self.move_distance then
			self.bff = hero:add_buff '电磁牵引-加速'
			{
				move_speed = self.move_speed,
				time = 0.25,
				skill = self.skill,
			}
			self.ln:setAlpha(100)
			return
		end
	end
	--判断附近是否有地形
	if self.path_point then
		local path_point = hero:get_point():find_path(self.move_distance, hero:get_facing())
		if path_point then
			if self.ln.target * path_point >= 100 then
				self:set_remaining(self.skill.mark_time)
			end
			self.ln:move(hero, path_point)
			self.bff = hero:add_buff '电磁牵引-加速'
			{
				move_speed = self.move_speed,
				time = 0.25,
				skill = self.skill,
			}
			self.ln:setAlpha(100)
			return
		end
	end
	
	if self.bff then
		self.bff:remove()
		self.bff = nil
	end
	self.ln:setAlpha(20)
end
