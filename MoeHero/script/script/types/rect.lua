
local jass = require 'jass.common'

local rect = {}
setmetatable(rect, rect)

--矩形区域结构
local mt = {}
--类型
mt.type = 'rect'

--4个数值
mt.minx = 0
mt.miny = 0
mt.maxx = 0
mt.maxy = 0

--获取4个值
function mt:get()
	return self.minx, self.miny, self.maxx, self.maxy
end

--获取点
function mt:get_point()
	return ac.point((self.minx + self.maxx) / 2, (self.miny + self.maxy) / 2)
end

rect.__index = mt

--创建矩形区域
---rect.create(最小x, 最小y, 最大x, 最大y)
function rect.create(minx, miny, maxx, maxy)
	return setmetatable({minx = minx, miny = miny, maxx = maxx, maxy = maxy}, rect)
end

--扩展矩形区域
function rect:__add(dest)
	local minx0, miny0, maxx0, maxy0 = self:get()
	local minx1, miny1, maxx1, maxy1 = table.unpack(dest)
	return rect.create(minx0 + minx1, miny0 + miny1, maxx0 + maxx1, maxy0 + maxy1)
end

--转化jass中的矩形区域
	rect.j_rects = {}
	
	function rect.j_rect(name)
		if not rect.j_rects[name] then
			local jRect = jass['gg_rct_' .. name]
			rect.j_rects[name] = rect.create(jass.GetRectMinX(jRect), jass.GetRectMinY(jRect), jass.GetRectMaxX(jRect), jass.GetRectMaxY(jRect))
		end
		return rect.j_rects[name]
	end

--转化jass中的矩形区域为点
	rect.j_points = {}
	
	function rect.j_point(name)
		if not rect.j_points[name] then
			local jRect = jass['gg_rct_' .. name]
			rect.j_points[name] = ac.point(jass.GetRectCenterX(jRect), jass.GetRectCenterY(jRect))
		end
		return rect.j_points[name]
	end

--获得一个临时的jass区域
	function rect.j_temp(rct)
		jass.SetRect(rect.dummy, rct:get())
		return rect.dummy
	end

--注册
function rect.init()
	rect.map = rect.create(
		jass.GetCameraBoundMinX() - jass.GetCameraMargin(jass.CAMERA_MARGIN_LEFT) + 32,
		jass.GetCameraBoundMinY() - jass.GetCameraMargin(jass.CAMERA_MARGIN_BOTTOM) + 32,
		jass.GetCameraBoundMaxX() + jass.GetCameraMargin(jass.CAMERA_MARGIN_RIGHT) - 32,
		jass.GetCameraBoundMaxY() + jass.GetCameraMargin(jass.CAMERA_MARGIN_TOP) - 32
	)

	rect.dummy = jass.Rect(0, 0, 0, 0)
end

return rect