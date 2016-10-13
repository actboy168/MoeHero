
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local runtime = require 'jass.runtime'
local math = math
local game = require 'types.game'
local runtime = require 'jass.runtime'
local xpcall = xpcall
local select = select
local setmetatable = setmetatable

local error_handle = runtime.error_handle

ac.mover = {}

local mover = {}
setmetatable(mover, mover)

--常量
mover.HIT_TYPE_NONE		= ''
mover.HIT_TYPE_ENEMY	= '敌人'
mover.HIT_TYPE_ALLY		= '友方'
mover.HIT_TYPE_ALL		= '别人'

ac.mover.HIT_TYPE_NONE		= ''
ac.mover.HIT_TYPE_ENEMY		= '敌人'
ac.mover.HIT_TYPE_ALLY		= '友方'
ac.mover.HIT_TYPE_ALL		= '别人'

--帧数
mover.FRAME = game.FRAME
local gchash = 0

--结构
mover.__index = {
	--类型
	type = 'mover',

	--模型路径
	model = nil,

	--模型特效
	effect = nil,

	--是自动创建的投射物
	missile = false,

	--关联技能
	skill = nil,

	--Buff附带的伤害
	damage = 0,

	--朝向偏移
	off_angle = 0,

	--移动中的单位
	mover = nil,

	--目标
	target = nil,

	--触发碰撞
	block = nil,

	--无视边界
	super = nil,

	--速度
	speed = 0,

	--加速度
	accel = 0,

	--最大速度
	max_speed = nil,

	--最小速度
	min_speed = nil,

	--运动速率
	time_scale = 1,

	--已经移动的距离
	moved = 0,

	--最大移动距离
	max_distance = 99999,

	--角度
	angle = nil,

	--朝向
	face = nil,

	--需要显示仰角
	need_elevation = true,
	
	--运动计数
	move_count = 0,

	--周期回调间隔
	on_move_skip = 1,

	--初始高度
	high = nil,

	--目标高度
	target_high = nil,

	--每个运动周期回调函数
	on_move = nil,

	--运动完成时回调
	on_hit = nil,

	--运动结束时回调
	on_remove = nil,

	--运动碰撞地形时回调
	on_block = nil,

	--最大高度(抛物线)
	height = nil,

	--已经变化了的高度(抛物线)
	height_c = 0,

	--已经变化了的高度(线性)
	height_l = 0,
	
	--移动进度
	moved_progress = 0,

	--碰撞类型
	hit_type = '敌人',

	--碰撞半径
	hit_area = nil,

	--是否重复碰撞
	hit_same = false,

	--是否碰撞目标
	hit_target = false,

	--当前正在碰撞的单位
	hit_unit = nil,

	--false的话就强制不还原高度，否则（true）只有非missile会还原高度 dekan
	do_reset_high = true,

	--暂停
	paused = 0,

	remove_path_block = function (self)
	end,

	--移除运动方程
	remove = function(self, skip_remove)
		
		if self.removed then
			return
		end
		self.removed = true

		--在阻挡器内移除
		self:remove_path_block()
		if self.mover.movers then
			self.mover.movers[self] = nil
		end

		--还原高度
		if not self.missile and self.do_reset_high then
			self.mover:add_high(- self.height_c - self.height_l)
		end
		
		if self.missile and self.model then
			self.mover:set_animation(0)
		end
		
		if self.on_remove then
			self:on_remove(self.mover)
		end
		
		if mover.mover_group[self] then
			mover.mover_group[self] = nil
			mover.count = mover.count - 1
		end

		if self.missile and not skip_remove then
			self.mover:kill()
			self.mover:removeAllEffects()
		end

		if not self.missile and self.effect then
			self.effect:remove()
		end

		mover.removed_mover[self] = self
	end,

	--运动更新
	next = function(self)
		--检查存活
		if not self.mover:is_alive() then
			self:remove()
			return
		end

		--运动方程更新
		self:next()

		if self.removed then
			return
		end

		local point = self.mover:get_point()

		self.speed = self.speed + self.accel * mover.FRAME * self.time_scale
		if self.min_speed and self.speed < self.min_speed then
			self.speed = self.min_speed
		elseif self.max_speed and self.speed > self.max_speed then
			self.speed = self.max_speed
		end

		local speed = self.speed * mover.FRAME * self.time_scale
		local height = 0
		--位移
		if not self.mover:set_position(self.next_point, not self.block, self.super) then
			if self.on_block then
				if self:on_block() then
					self:remove()
					return
				end
			elseif self.missile then
				self:remove()
				return
			end
			--求出x,y轴分速度
			local x0, y0 = point:get()
			local x1, y1 = self.next_point:get()
			--找空位
			local p1 = ac.point(x1, y0)
			local p2 = ac.point(x0, y1)
			if not p1:is_block() then
				self.mover:set_position(p1)
			elseif not p2:is_block() then
				self.mover:set_position(p2)
			end
		end

		--计算当前高度(相对值)
		self.moved = self.moved + speed
		if self.moved > self.max_distance then
			self:remove()
			return
		end

		--剩余移动进度
		local progress
		if speed >= self.distance then
			progress = 1
		else
			progress = speed / self.distance
		end
		
		--线性
		local target_high = self.target_high
		if self.target then
			target_high = target_high + self.target:get_high()
		end
		local height_n = (target_high - self.high) * progress
		--print('height_n', target_high, self.high, progress)
		self.high = self.high + height_n
		height = height + height_n
		self.height_l = self.height_l + height_n
		
		--抛物线
		if self.height then
			--全局移动进度
			local progress = (1 - self.moved_progress) * progress
			self.moved_progress = self.moved_progress + progress
			
			local height_n = 4 * self.height * self.moved_progress * (1 - self.moved_progress)
			height = height + height_n - self.height_c
			self.height_c = height_n
		end

		self.mover:add_high(height)

		if self.missile and speed ~= 0 and self.model and self.need_elevation then
			local r = math.atan(height, speed)
			local r = math.floor((r % 360) / 3.6)
			if r ~= self._last_animation then
				self.mover:set_animation(r)
				self._last_animation = r
			end
		end

		local function check_hit(u)
			if not self.hit_target then
				if u == self.target then
					return
				end
			end
			if not self.hit_same then
				if not self.hited_units then
					self.hited_units = {}
				end
				
				if self.hited_units[u] then
					return
				end

				self.hited_units[u] = true
			end
			if self:isMissile() and u:event_dispatch('单位-即将被投射物击中', u, self) then
				self:remove()
			else
				if self.on_hit and self:on_hit(u) then
					self:remove()
				end
			end
		end

		if self.hit_area and self.on_hit then
			if self.hit_area > speed then
				for _, u in self.selector
					: in_range(self.mover, self.hit_area)
					: ipairs()
				do
					check_hit(u)
					if self.removed then
						return
					end
				end
			else
				for _, u in self.selector
					: in_line(point, self.angle, speed + self.hit_area, self.hit_area)
					: ipairs()
				do
					check_hit(u)
					if self.removed then
						return
					end
				end
			end
		end

		self.move_count = self.move_count + 1
		if self.on_move and self.move_count % self.on_move_skip == 0 then
			self:on_move(self.mover, self.move_count)
		end
	end,

	--初始化
	init = function(self)
		gchash = gchash + 1
		dbg.gchash(self, gchash)
		self.gchash = gchash
		if not self.source then
			self.source = self.mover
		end
		if not self.start then
			self.start = self.mover or self.source
		end
		if not self.high then
			self.high = self.start[3] or 0
		end

		if self.mover then
			self.high = self.high + self.mover:get_high()
		else
			self.high = self.high + self.start:get_high()
		end
		self.selector = ac.selector():is_not(self.source)

		if self.hit_type == '敌人' then
			self.selector:is_enemy(self.source)
		elseif self.hit_type == '友方' then
			self.selector:is_ally(self.source)
		end
		
		return self:create()
	end,

	--发射
	launch = function(self)
		
		if self.mover and self.mover.type == 'unit' and (self.mover:has_restriction '禁锢' or self.mover._follow_data) then
			return
		end

		--初始化一下数据
		self:init()

		if not self.mover then
			if self.id then
				self.mover = ac.player[16]:create_dummy(self.id, self.start, self.face or self.angle or 0)
			else
				self.mover = ac.player[16]:create_dummy(mover.UNIT_ID, self.start, self.face or self.angle or 0)
			end
			self.missile = true
			if self.super == nil then
				self.super = true
			end
			jass.SetUnitBlendTime(self.mover.handle, 0)
		end

		self.mover:set_high(self.high)

		if self.skill == nil then
			print '============================'
			print(debug.traceback '运动没有关联技能!')
		end

		if self.model then
			self.effect = self.mover:add_effect('origin', self.model)
		end

		--设置缩放
		if self.size then
			self.mover:set_size(self.size)
		end
		
		mover.add(self)

		if not self.mover.movers then
			self.mover.movers = {}
		end
		self.mover.movers[self] = true
		if self.mover:is_pause_mover() then
			self:pause()
		end
		
		return self
	end,

	--更新数据(假API)
	update = function()
	end,

	--是否是投射物
	isMissile = function(self)
		return self.missile
	end,

	--获得运动已经移动的距离
	get_moved = function(self)
		return self.moved
	end,

	--是否是技能弹道
	is_skill = function(self)
		return self.skill
	end,
	pause = function(self, flag)
		if flag then
			self.paused = self.paused + 1
		else
			self.paused = self.paused - 1
		end
	end,
}
function ac.mover.line(data)
	setmetatable(data, mover.line)
	return data:launch()
end

function ac.mover.target(data)
	setmetatable(data, mover.target)
	return data:launch()
end

--运动完成
function mover.on_finish(self)
	local on_finish = self.on_finish
	self.on_finish = nil
	if on_finish and on_finish(self, self.mover) then
		return
	end

	self:remove()
	return true
end

mover.count = 0

--添加进循环
function mover.add(mover_data)
	mover.mover_group[mover_data] = true
	mover.count = mover.count + 1
	--print('运动方程计数:', mover.count)
end

function mover.init()
	--投射物的单位id
	mover.UNIT_ID = 'e001'
	
	require 'types.mover.target'
	require 'types.mover.line'
	
	--无限循环
	mover.mover_group = {}
	mover.removed_mover = setmetatable({}, { __mode = 'kv' })
end

local move_index
local function mover_move()
	if move_index then
		mover.mover_group[move_index] = nil
		mover.count = mover.count - 1
	end
	local tbl = {}
	for mover_data in pairs(mover.mover_group) do
		tbl[#tbl + 1] = mover_data
	end
	for i = 1, #tbl do
		move_index = tbl[i]
		if tbl[i].paused <= 0 then
			mover.next(tbl[i])
		end
	end
	move_index = nil
end

function mover.move()
	xpcall(mover_move, error_handle)
end

local hit_index
local function mover_hit()
	if hit_index then
		mover.mover_group[hit_index] = nil
		mover.count = mover.count - 1
	end
	local tbl = {}
	for mover_data in pairs(mover.mover_group) do
		tbl[#tbl + 1] = mover_data
	end
	for i = 1, #tbl do
		hit_index = tbl[i]
		if tbl[i].paused <= 0 then
			tbl[i]:checkHit()
		end
	end
	hit_index = nil
end

function mover.hit()
	xpcall(mover_hit, error_handle)
end

return mover