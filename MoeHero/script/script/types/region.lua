
local jass = require 'jass.common'
local rect = require 'types.rect'
local unit = require 'types.unit'
local dbg = require 'jass.debug'

local region = {}
setmetatable(region, region)

--不规则区域结构
local mt = {}
region.__index = mt
ac.region = region

--类型
mt.type = 'region'

--句柄
mt.handle = 0

--创建不规则区域
function region.create(...)
	local rgn = setmetatable({}, region)
	rgn.handle = jass.CreateRegion()
	dbg.handle_ref(rgn.handle)
	for _, rct in ipairs{...} do
		rgn = rgn + rct
	end

	return rgn
end

--移除不规则区域
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	jass.RemoveRegion(self.handle)
	if self.event_enter then
		war3.DestroyTrigger(self.event_enter)
	end
	if self.event_leave then
		war3.DestroyTrigger(self.event_leave)
	end
	dbg.handle_unref(self.handle)
	self.handle = nil
end

--进入区域事件
mt.event_enter = nil

--离开区域事件
mt.event_leave = nil

local ac_game = ac.game

--注册区域事件
--	event_type是字符串,包含e时注册进入事件,包含l时注册离开事件
function mt:event(name)
	if name == '区域-进入' and not self.event_enter then
		self.event_enter = war3.CreateTrigger()
		jass.TriggerRegisterEnterRegion(self.event_enter, self.handle, nil)
		jass.TriggerAddCondition(self.event_enter, jass.Condition(function()
			local unit = unit.j_unit(jass.GetTriggerUnit())
			if unit then
				ac.event_notify(self, name, unit, self)
				ac.game:event_notify(name, unit, self)
			end
		end))
	end
	
	if name == '区域-离开' and not self.event_leave then
		self.event_leave = war3.CreateTrigger(function()
			local unit = unit.j_unit(jass.GetTriggerUnit())
			if unit then
				ac.event_notify(self, name, unit, self)
				ac.game:event_notify(name, unit, self)
			end
		end)
		jass.TriggerRegisterLeaveRegion(self.event_leave, self.handle, nil)
	end

	return ac.event_register(self, name)
end

--在不规则区域中添加/移除区域
--	region = region + other
function region:__add(other)
	if other.type == 'rect' then
		--添加矩形区域
		jass.RegionAddRect(self.handle, rect.j_temp(other))
	elseif other.type == 'point' then
		--添加单元点
		jass.RegionAddCell(self.handle, other:get())
	elseif other.type == 'circle' then
		--添加圆形
		local x, y, r = other:get()
		local p0 = other:get_point()
		for x = x - r, x + r + 32, 32 do
			for y = y - r, y + r + 32, 32 do
				local p = ac.point(x, y)
				if p * p0 <= r + 16 then
					jass.RegionAddCell(self.handle, x, y)
				end
			end
		end
	else
		jass.RegionAddCell(self.handle, other:get_point():get())
	end

	return self
end

--	region = region - other
function region:__sub(other)
	if other.type == 'rect' then
		--添加矩形区域
		jass.RegionClearRect(self.handle, rect.j_temp(other))
	elseif other.type == 'point' then
		--移除单元点
		jass.RegionClearCell(self.handle, other:get())
	elseif other.type == 'circle' then
		--移除圆形
		local x, y, r = other:get()
		local p0 = other:get_point()
		for x = x - r, x + r + 32, 32 do
			for y = y - r, y + r + 32, 32 do
				local p = ac.point(x, y)
				if p * p0 <= r + 16 then
					jass.RegionClearCell(self.handle, x, y)
				end
			end
		end
	else
		jass.RegionClearCell(self.handle, other:get_point():get())
	end

	return self
end

--点是否在不规则区域内
--	result = region < point
function region:__lt(dest)
	local x, y = dest:get_point():get()
	return jass.IsPointInRegion(self.handle, x, y)
end

function region:__call(...)
	return self.create(...)
end

return region