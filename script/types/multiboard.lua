local jass = require 'jass.common'

local multiboard = {}
setmetatable(multiboard, multiboard)

--结构
local mt = {}
multiboard.__index = mt

--类型
mt.type = 'multiboard'

--句柄
mt.handle = 0

--列数
mt.x = 0

--行数
mt.y = 0

--修改列数
function mt:setX(x)
	jass.MultiboardSetColumnCount(self.handle, x)
	self.x = x
end

--修改行数
function mt:setY(y)
	jass.MultiboardSetRowCount(self.handle, y)
	self.y = y
end

--修改标题文字
function mt:setTitle(title)
	jass.MultiboardSetTitleText(self.handle, title)
end

--显示多面板
function mt:show()
	jass.MultiboardDisplay(self.handle, true)
end

--隐藏多面板
function mt:hide()
	jass.MultiboardDisplay(self.handle, false)
end

--最小化多面板
function mt:minimize(flag)
	jass.MultiboardMinimize(self.handle, flag)
end

--获得项目
function mt:getItem(x, y)
	local t = self[x]
	if t then
		return t[y]
	end
	return 0
end

--设置项目图标
function mt:setIcon(x, y, src)
	jass.MultiboardSetItemIcon(self:getItem(x, y), src)
end

--设置某个Item的文字
function mt:setText(x, y, txt)
	jass.MultiboardSetItemValue(self:getItem(x, y), txt)
end

--设置某个Item的图标和文字是否显示
function mt:setStyle(x, y, show_txt, show_icon)
	jass.MultiboardSetItemStyle(self:getItem(x, y), show_txt, show_icon)
end

--设置某个Item的宽度
function mt:setWidth(x, y, w)
	jass.MultiboardSetItemWidth(self:getItem(x, y), w)
end

--设置所有item的style
function mt:setAllStyle(show_txt, show_icon)
	jass.MultiboardSetItemsStyle(self.handle ,show_txt, show_icon)
end

--设置Item的宽度
function mt:setAllWidth(w)
	jass.MultiboardSetItemsWidth(self.handle, w)
	self:hide()
	self:show()
end

--删除多面板
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	jass.DestroyMultiboard(self.handle)
end

--创建一个多面板
function multiboard.create(x, y)
	local mb =	setmetatable({}, multiboard)
	mb.handle = jass.CreateMultiboard()
	mb:setX(x or 0)
	mb:setY(y or 0)
	mb:show()

	--保存多面板项目
	for x = 1, x do
		mb[x] = {}
		for y = 1, y do
			mb[x][y] = jass.MultiboardGetItem(mb.handle, y - 1, x - 1)
		end
	end
	
	return mb
end

return multiboard