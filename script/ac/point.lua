
local jass = require 'jass.common'
local math = math
local setmetatable = setmetatable
local table_insert = table.insert
local table_remove = table.remove
local ipairs = ipairs

local point = {}
setmetatable(point, point)

function point:__tostring()
    return ('{%.4f, %.4f, %.4f}'):format(self:get(true))
end

--结构
local mt = {}
point.__index = mt

--类型
mt.type = 'point'

--坐标
mt[1] = 0
mt[2] = 0
mt[3] = 0

--获取坐标
--	是否重新计算z轴坐标
function mt:get(getz)
	return self[1], self[2], getz and self:getZ() or self[3]
end

--计算地面的z轴坐标
function mt:getZ()
	jass.MoveLocation(point.dummy, self[1], self[2])
	return jass.GetLocationZ(point.dummy)
end

--获取点高度
function mt:get_high()
	return self[3]
end

--复制点
function mt:copy()
	return ac.point(self[1], self[2], self[3])
end

--转换点
function mt:get_point()
	return self
end

--移动点
function mt:move(dest)
	self[1], self[2], self[3] = dest:get()
end

--距离/角度
	--与单位的距离
	function mt:distance(u)
		local x1, y1 = self:get()
		local x2, y2 = u:get_point():get()
		local x = x1 - x2
		local y = y1 - y2
		return math.sqrt(x * x + y * y)
	end

	--与单位的角度
	function mt:angle(u)
		local x1, y1 = self:get()
		local x2, y2 = u:get_point():get()
		return math.atan(y2 - y1, x2 - x1)
	end

--获得一条直线上的一点
--	直线终点
--	直线长度
--	是否不超过终点
function mt:getLineDest(target, rng, flag)
	if flag and self * target < rng then
		return target
	end

	local angle = self / target
	return self - {angle, rng}
end

--获得地层高度
function mt:get_level()
	return jass.GetTerrainCliffLevel(self:get())
end

--动态阻挡(地面)
local block_ground = nil
--动态阻挡(空中)
local block_air = nil
--动态阻挡单元点列表
local block_points = {}

--添加阻挡
-- 边长x
-- 边长y
-- 是否阻挡空中
function mt:add_block(x, y, air)
	if not self.block_points then
		self.block_points = {}
		table_insert(block_points, self.block_points)
		block_points.new = true
	end
	if x == nil or x < 32 then
		x = 32
	end
	if y == nil or y < 32 then
		y = 32
	end
	local x0, y0 = self[1], self[2]
	for dx = - x / 2, x / 2, 32 do
		for dy = - y / 2, y / 2, 32 do
			local p = ac.point(x0 + dx, y0 + dy)
			p.block_air = air
			table_insert(self.block_points, p)
		end
	end
end

--移除阻挡
function mt:remove_block()
	if self.block_points then
		for i, points in ipairs(block_points) do
			if self.block_points == points then
				table_remove(block_points, i)
				block_points.new = true
				return
			end
		end
		self.block_points = nil
	end
end

--获取阻挡
local function get_block(path)
	if block_points.new then
		block_points.new = false
		if block_ground then
			block_ground:remove()
			block_ground = nil
		end
		if block_air then
			block_air:remove()
			block_air = nil
		end
		for _, points in ipairs(block_points) do
			for _, p in ipairs(points) do
				if p.block_air then
					if not block_air then
						block_air = ac.region()
					end
					block_air = block_air + p
				end
				if not block_ground then
					block_ground = ac.region()
				end
				block_ground = block_ground + p
			end
		end
	end
	if path then
		return block_air
	else
		return block_ground
	end
end

--阻挡
point.path_region = nil

--是否无法通行
--	是否无视地面阻挡(飞行)
--	是否无视地图边界
function mt:is_block(path, super)
	local x, y = self:get()
	if not path then
		if jass.IsTerrainPathable(x, y, 1) then
			return true
		end
		if point.path_region and point.path_region < self then
			return true
		end
	end
	if not super then
		if jass.IsTerrainPathable(x, y, 2) then
			return true
		end
		local block = get_block(path)
		if block and block < self then
			return true
		end
	end
	return false
end

--附近是否有阻挡
--	[采样范围]
--	[初始角度]
function mt:find_path(r, angle)
	local r = r or 0
	local angle = angle or 0
	local x0, y0 = self:get()
	if self:is_block() then
		return self
	end

	for r = 32, r, 32 do
		for angle = angle, angle + 315, 45 do
			local p = self - {angle, r}
			if p:is_block() then
				return p
			end
		end
	end
end

--在附近寻找一个可通行的点
--	[采样范围]
--	[初始角度]
--	[不包含当前位置]
function mt:findMoveablePoint(r, angle, other)
	local r = r or 512
	local angle = angle or 0
	local x0, y0 = self:get()
	if not other and not self:is_block() then
		return self
	end

	for r = math.min(r, 32), r, 32 do
		for angle = angle, angle + 315, 45 do
			local p = self - {angle, r}
			if not p:is_block() then
				return p
			end
		end
	end
end

function mt:effect(data)
	return ac.point_effect(self, data)
end

--移动点
	--按照直角坐标系移动(point + {x, y})
	--	@新点
	function point:__add(data)
		return ac.point(self[1] + data[1], self[2] + data[2], self[3] + (data[3] or 0))
	end

	--按照极坐标系移动(point - {angle, distance})
	--	@新点
	function point:__sub(data)
		local x, y = self:get()
		local angle, distance = data[1], data[2]
		return ac.point(x + distance * math.cos(angle), y + distance * math.sin(angle))
	end

--求2个点的距离/方向
	--求距离(point * point)
	function point:__mul(dest)
		local x1, y1 = self:get()
		local x2, y2 = dest:get()
		local x0, y0 = x1 - x2, y1 - y2
		return math.sqrt(x0 * x0 + y0 * y0)
	end

	--求方向(point / point)
	function point:__div(dest)
		local x1, y1 = self:get()
		local x2, y2 = dest:get()
		return math.atan(y2 - y1, x2 - x1)
	end

--获取点
point.__call = mt.get

--创建一个点
--	ac.point(x, y, z)
function ac.point(x, y, z)
	return setmetatable({x, y, z}, point)
end


point.dummy = jass.Location(0, 0)

return point
