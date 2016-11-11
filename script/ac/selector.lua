
local jass = require 'jass.common'
local math = math
local table = table
local table_insert = table.insert
local table_sort = table.sort
local setmetatable = setmetatable
local ipairs = ipairs
local math_angle = ac.math_angle
local math_abs = math.abs
local math_random = math.random

local MAX_COLLISION = 200
local dummy_group = jass.CreateGroup()
local GroupEnumUnitsInRange = jass.GroupEnumUnitsInRange
local FirstOfGroup = jass.FirstOfGroup
local GroupRemoveUnit = jass.GroupRemoveUnit
local ac_unit = ac.unit

local mt = {}
local api = {}
mt.__index = api

api.type = 'selector'

api.filter_in = 0

api.center = {}
function api.center:get_point()
	return ac.point(0, 0)
end

api.r = 99999

--筛选条件
api.filters = nil

--允许选择无敌单位
api.is_allow_god = false
api.is_allow_dead = false

--自定义条件
function api:add_filter(f)
	table_insert(self.filters, f)
	return self
end

--圆形范围
--	圆心
--	半径
function api:in_range(p, r)
	self.filter_in = 0
	self.center = p
	self.r = r
	return self
end

--扇形范围
--	圆心
--	半径
--	角度
--	区间
function api:in_sector(p, r, angle, section)
	self.filter_in = 1
	self.center = p
	self.r = r
	self.angle = angle
	self.section = section
	return self
end

--直线范围
--	起点
--	角度
--	长度
--	宽度
function api:in_line(p, angle, len, width)
	self.filter_in = 2
	self.center = p
	self.angle = angle
	self.len = len
	self.width = width
	return self
end

--不是指定单位
--	单位
function api:is_not(u)
	return self:add_filter(function(dest)
		return dest ~= u
	end)
end

--是敌人
--	参考单位/玩家
function api:is_enemy(u)
	return self:add_filter(function(dest)
		return dest:is_enemy(u)
	end)
end

--是友军
--	参考单位/玩家
function api:is_ally(u)
	return self:add_filter(function(dest)
		return dest:is_ally(u)
	end)
end

--必须是英雄
function api:of_hero()
	return self:add_filter(function(dest)
		return dest:is_type('英雄')
	end)
end

--必须不是英雄
function api:of_not_hero()
	return self:add_filter(function(dest)
		return not dest:is_type('英雄')
	end)
end

--必须是建筑
function api:of_building()
	return self:add_filter(function(dest)
		return dest:is_type('建筑')
	end)
end

--必须不是建筑
function api:of_not_building()
	return self:add_filter(function(dest)
		return not dest:is_type('建筑')
	end)
end

--必须是可见的
function api:of_visible(u)
	return self:add_filter(function(dest)
		return dest:is_visible(u)
	end)
end

function api:of_illusion()
	return self:add_filter(function(dest)
		return dest:is_illusion()
	end)
end

function api:of_not_illusion()
	return self:add_filter(function(dest)
		return not dest:is_illusion()
	end)
end

--可以是无敌单位
function api:allow_god()
	self.is_allow_god = true
	return self
end

--可以是死亡单位
function api:allow_dead()
	self.is_allow_dead = true
	return self
end

--对选取到的单位进行过滤
function api:do_filter(u)
	if not self.is_allow_god and u:has_restriction '无敌' then
		return false
	end
	if not self.is_allow_dead and not u:is_alive() then
		return false
	end
	for i = 1, #self.filters do
		local filter = self.filters[i]
		if not filter(u) then
			return false
		end
	end
	return true
end

--对选取到的单位进行排序
function api:set_sorter(f)
	self.sorter = f
	return self
end

--排序权重：1、英雄 2、和poi的距离
function api:sort_nearest_hero(poi)
	local poi = poi:get_point()
	return self:set_sorter(function (u1, u2)
		if u1:is_hero() and not u2:is_hero() then
			return true
		end
		if not u1:is_hero() and u2:is_hero() then
			return false
		end
		return u1:get_point() * poi < u2:get_point() * poi
	end)
end

function api:sort_nearest_type_hero(poi)
	local poi = poi:get_point()
	return self:set_sorter(function (u1, u2)
		if u1:is_type('英雄') and not u2:is_type('英雄') then
			return true
		end
		if not u1:is_type('英雄') and u2:is_type('英雄') then
			return false
		end
		return u1:get_point() * poi < u2:get_point() * poi
	end)
end

--进行选取
function api:select(select_unit)
	if self.filter_in == 0 then
		--	圆形选取
		local p = self.center:get_point()
		local x, y = p()
		local r = self.r
		GroupEnumUnitsInRange(dummy_group, x, y, r + MAX_COLLISION, nil)
		local u
		while true do
			u = FirstOfGroup(dummy_group)
			if u == 0 then
				break
			end
			GroupRemoveUnit(dummy_group, u)
			local u = ac_unit(u)
			if u and u:is_in_range(p, r) and self:do_filter(u) then
				select_unit(u)
			end
		end
	elseif self.filter_in == 1 then
		--	扇形选取
		local p = self.center:get_point()
		local x, y = p()
		local r = self.r
		local angle = self.angle
		local section = self.section / 2
		GroupEnumUnitsInRange(dummy_group, x, y, r + MAX_COLLISION, nil)
		local u
		while true do
			u = FirstOfGroup(dummy_group)
			if u == 0 then
				break
			end
			GroupRemoveUnit(dummy_group, u)
			local u = ac_unit(u)
			if u and u:is_in_range(p, r) and math_angle(angle, p / u:get_point()) <= section and self:do_filter(u) then
				select_unit(u)
			end
		end
	elseif self.filter_in == 2 then
		--	直线选取
		local start = self.center:get_point()
		local target = start - {self.angle, self.len}
		local x1, y1 = start()
		local x2, y2 = target()

		local a, b = y1 - y2, x2 - x1
		local c = - a * x1 - b * y1
		local l = (a * a + b * b) ^ 0.5
		local w = self.width / 2
		local r = self.len / 2

		local x, y = (x1 + x2) / 2, (y1 + y2) / 2
		local p = ac.point(x, y)
		GroupEnumUnitsInRange(dummy_group, x, y, r + MAX_COLLISION, nil)
		local u
		while true do
			u = FirstOfGroup(dummy_group)
			if u == 0 then
				break
			end
			GroupRemoveUnit(dummy_group, u)
			local u = ac_unit(u)
			if u and u:is_in_range(p, r) then
				local x, y = u:get_point()()
				local d = math_abs(a * x + b * y + c) / l
				if d <= w + u:get_selected_radius() and self:do_filter(u) then
					select_unit(u)
				end
			end
		end
	end
end

function api:get()
	local units = {}
	self:select(function (u) table_insert(units, u) end)
	if self.sorter then
		table_sort(units, self.sorter)
	end
	return units
end

--选取并遍历
function api:ipairs()
	return ipairs(self:get())
end

--选取并选出随机单位
function api:random()
	local g = self:get()
	if #g > 0 then
		return g[math_random(1, #g)]
	end
end

function ac.selector()
	return setmetatable({filters = {}}, mt)
end
