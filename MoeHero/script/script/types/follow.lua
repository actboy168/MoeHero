local runtime = require 'jass.runtime'
local jass = require 'jass.common'
local xpcall = xpcall
local setmetatable = setmetatable
local error_handle = runtime.error_handle
local dbg = require 'jass.debug'

local FRAME = 0.03

local follow = {}
ac.follow = follow
setmetatable(follow, follow)
local mt = {}
follow.__index = mt
-- 类型
mt.type = 'follow'
-- 关联技能
mt.skill = nil
-- 运动单位
mt.mover = nil
-- 跟随目标
mt.target = nil
-- 偏转角度
mt.angle = 0
mt.distance = 0
-- 朝向
mt.face = 0
-- 根据目标朝向偏移角度
mt.angle_follow = false
-- 根据目标朝向偏移朝向
mt.face_follow = false
-- 每秒偏转的角度
mt.angle_speed = nil
-- 每秒偏转的朝向
mt.face_speed = nil
-- 计数
mt.move_count = 0
mt.on_move_skip = 1
mt.high = 0
mt.height_f = 0
mt.height_l = 0

local gchash = 0

function follow:__call(self)
	if self.mover and self.mover.type == 'unit' and self.mover:has_restriction '禁锢' then
		return
	end
	gchash = gchash + 1
	dbg.gchash(self, gchash)
	self.gchash = gchash
	setmetatable(self, follow)
	if not self.source then
		self.source = self.mover
	end
	if self.mover then
		self.high = self.high + self.mover:get_high()
	end
	self.height_f = self.target:get_high()
	local face = self.face
	if self.face_follow then
		face = face + self.target:get_facing()
	end
	if not self.mover then
		local start = self.target:get_point() - {self.angle, self.distance}
		if self.id then
			self.mover = ac.player[16]:create_dummy(self.id, start, face)
		else
			self.mover = ac.player[16]:create_dummy(follow.UNIT_ID, start, face)
		end
		self.missile = true
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
	
	follow.add(self)

	-- 移除所有运动
	if self.mover.movers then
		for mover in pairs(self.mover.movers) do
			self.mover.movers[mover] = nil
		end
	end
	if self.mover._follow_data then
		self.mover._follow_data:remove()
	end
	self.mover._follow_data = self
	
	return self
end

function mt:next()
	--检查存活
	if not self.mover:is_alive() then
		self:remove()
		return
	end
	if self.target:has_restriction '时停' then
		return
	end
	if self.angle_speed then
		self.angle = self.angle + self.angle_speed * FRAME
	end
	if self.face_speed then
		self.face = self.face + self.face_speed * FRAME
	end
	local angle = self.angle
	local face = self.target:get_facing()
	if self.angle_follow then
		angle = angle + face
	end
	if self.face_follow then
		self.mover:set_facing(self.face + face)
	end
	--跟随运动
	self.next_point = self.target:get_point() - {angle, self.distance}
	--高度
	local height_n = self.target:get_high() - self.height_f
	self.mover:add_high(height_n)
	self.height_f = self.height_f + height_n
	self.height_l = self.height_l + height_n
	if not self.mover:set_position(self.next_point, true, true) then
		return
	end

	self.move_count = self.move_count + 1
	if self.on_move and self.move_count % self.on_move_skip == 0 then
		self:on_move(self.mover, self.move_count)
	end
end

function mt:remove()
	if self.removed then
		return
	end
	self.removed = true

	self.mover._follow_data = nil

	--还原高度
	if not self.missile then
		self.mover:add_high( - self.height_l)
	end
	
	if self.on_remove then
		self:on_remove(self.mover)
	end
	
	if follow.follow_group[self] then
		follow.follow_group[self] = nil
		follow.count = follow.count - 1
	end

	if self.missile then
		self.mover:kill()
		self.mover:removeAllEffects()
	end

	if not self.missile and self.effect then
		self.effect:remove()
	end

	follow.removed_follow[self] = self
end

follow.count = 0

--添加进循环
function follow.add(follow_data)
	follow.follow_group[follow_data] = true
	follow.count = follow.count + 1
end

function follow.init()
	--投射物的单位id
	follow.UNIT_ID = 'e00P'
	
	--无限循环
	follow.follow_group = {}
	follow.removed_follow = setmetatable({}, { __mode = 'kv' })
end

local move_index
local function follow_move()
	if move_index then
		follow.follow_group[move_index] = nil
		follow.count = follow.count - 1
	end
	local tbl = {}
	for follow_data in pairs(follow.follow_group) do
		tbl[#tbl + 1] = follow_data
	end
	for i = 1, #tbl do
		move_index = tbl[i]
		follow.next(tbl[i])
	end
	move_index = nil
end

function follow.move()
	xpcall(follow_move, error_handle)
end

return follow
