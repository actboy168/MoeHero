
local unit = require 'types.unit'
local jass = require 'jass.common'
local mover = require 'types.mover'
local dbg = require 'jass.debug'

local path_block = {}
setmetatable(path_block, path_block)

--碰撞体的单位ID
path_block.UNIT_ID = 'e001'

local mt = {}
path_block.__index = mt
--类型
mt.type = 'path_block'

--阻挡位置
mt.point = nil

--关联的unit
mt.unit = nil

--阻挡地面
mt.groud = false

--阻挡空中
mt.fly = false

--阻挡弹道
mt.missile = true

--阻挡半径
mt.area = 32

--弹道进入阻挡的回调
mt.on_entry = nil

--弹道离开阻挡的回调
mt.on_leave = nil

--在阻挡器内的弹幕
mt.movers = nil

--令阻挡跟随单位运动
mt.following_unit = nil

--是否计算运动的碰撞
mt.hit_area = true

--移除阻挡
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	local tbl = {}
	for mover_data in pairs(self.movers) do
		tbl[#tbl + 1] = mover_data
	end
	for i = 1, #tbl do
		self:remove_mover(tbl[i])
	end
	path_block.all_path_blocks[self] = nil
end

--设置阻挡位置
function mt:set_position(p)
	self.point = p
end

function mt:follow_unit(u)
	self.following_unit = u
end

function mt:check_entry(mover)
	if mover.source.handle then
		local p = mover.mover:get_point()
		local hit_area = self.hit_area and mover.hit_area or 0
		if self.point * p <= self.area + hit_area then
			if self.movers[mover] then
				return
			end
			if self.on_entry and self:on_entry(mover) then
				return true
			else
				self.movers[mover] = true
			end
		end
	end 
end

function mt:check_leave(mover)
	local hit_area = self.hit_area and mover.hit_area or 0
	if self.point * mover.mover:get_point() > self.area + hit_area then
		if self.on_leave then self:on_leave(mover) end
		self.movers[mover] = nil
	end
end

function mt:remove_mover(mover)
	if self.movers[mover] then
		if self.on_leave then self:on_leave(mover) end
		self.movers[mover] = nil
	end
end

--创建动态阻挡
local gchash = 0
function unit.__index:create_block(data)
	setmetatable(data, path_block)
	gchash = gchash + 1
	dbg.gchash(data, gchash)
	data.gchash = gchash
	data.source = self
	data.point = data.point or self:get_point()
	data.team = data.team or self:get_team()
	data.movers = {}
	path_block.all_path_blocks[data] = true
	return data
end

--更新所有的阻挡
function path_block.update()
	for pb in pairs(path_block.all_path_blocks) do
		if pb.following_unit then
			pb:set_position(pb.following_unit:get_point())
		end
		local tbl = {}
		for mover_data in pairs(pb.movers) do
			tbl[#tbl + 1] = mover_data
		end
		for i = 1, #tbl do
			pb:check_leave(tbl[i])
		end
		local tbl = {}
		for mover_data in pairs(mover.mover_group) do
			tbl[#tbl + 1] = mover_data
		end
		for i = 1, #tbl do
			if pb:check_entry(tbl[i]) then
				tbl[i]:remove()
			end
		end
		
	end
end

function mover.__index:remove_path_block()
	local pbs = {}
	for pb in pairs(path_block.all_path_blocks) do
		pbs[#pbs + 1] = pb
	end
	for i = 1, #pbs do
		pbs[i]:remove_mover(self)
	end
end

function path_block.init()
	path_block.all_path_blocks = {}
end

return path_block
