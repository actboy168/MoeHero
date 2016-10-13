
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local math = math

local lightning = {}
setmetatable(lightning, lightning)

local mt = {}
lightning.__index = mt

--类型
mt.type = 'lightning'

--句柄
mt.handle = 0

--开始点
mt.start = nil

--当前终结点
mt.present = nil

--终结点 (只能是点)
mt.target = nil

--z轴偏移
mt.oz1 = 0
mt.oz2 = 0

--使用相对z轴
mt.offset_z = true

--颜色
mt.red = 100
mt.green = 100
mt.blue = 100
mt.alpha = 100

--是否可见
mt.is_visible = true

--总是可见
mt.keep_visible = false

--淡出
mt.speed = 0
mt.isremove = 1

--移动速度
mt.movetimesspeed = 1
mt.movetimesAcceleration = 0.1
mt.movetimes = 0

--设置颜色
function mt:setColor(red, green, blue)
	if self.handle == 0 then
		return
	end
	
	self.red, self.green, self.blue = red, green, blue
	if self.is_visible then
		jass.SetLightningColor(self.handle, math.min(self.red / 100,1), math.min(self.green / 100,1), math.min(self.blue / 100,1), math.min(self.alpha / 100,1))
	end
end

function mt:setAlpha(alpha)
	if self.handle == 0 then
		return
	end
	
	self.alpha = math.max(alpha,0)

	if self.is_visible then
		jass.SetLightningColor(self.handle, math.min(self.red / 100,1), math.min(self.green / 100,1), math.min(self.blue / 100,1), math.min(self.alpha / 100,1))
	end

	--透明度为0时不移动
	if self.alpha <= 0 then
		lightning.group[self] = nil
	else
		lightning.group[self] = true
	end
end

function mt:getAlpha()
	return self.alpha
end

--设置z轴偏移量
function mt:setOffZ(oz1, oz2)
	self.oz1 = oz1
	self.oz2 = oz2
	self:move()
end

--设置移动参数
function mt:setMoveTimes(movetimes,movetimesAcceleration)
	self.movetimesspeed = 1
	self.movetimesAcceleration = 0.1
	if movetimes then
		self.movetimes = movetimes
	end
	if movetimesAcceleration then
		self.movetimesAcceleration = movetimesAcceleration
	end
end

--检查可见度
function mt:check_visible()
	local visible = self.keep_visible or ac.player.self:is_visible(self.start), ac.player.self:is_visible(self.target)
	if self.is_visible then
		if not visible then
			self.is_visible = false
			jass.SetLightningColor(self.handle, 0, 0, 0, 0)
		end
	else
		if visible then
			self.is_visible = true
			jass.SetLightningColor(self.handle, math.min(self.red / 100,1), math.min(self.green / 100,1), math.min(self.blue / 100,1), math.min(self.alpha / 100,1))
		end
	end
end

--移动
function mt:move(start, target, oz1, oz2)
	if self.handle == 0 then
		return
	end
	
	if start then
		self.start = start
	end
	if target then
		self.target = target
	end
	if oz1 then
		self.oz1 = oz1
	end
	if oz2 then
		self.oz2 = oz2
	end

	--如果闪电移动速度大于 0 （在设置移动速度的同时别忘记移动）
	if not self.present or self:getAlpha() <= 0 then
		self.present = self.target:get_point()
	end
	if self.movetimes > 1 then
		local d = self.present * self.target:get_point()
		self.movespeed = d / (self.movetimes * 1.0) 
		
		self.present = self.present - { self.present / self.target:get_point(), self.movespeed }
		--print('speed = ',self.movespeed)

		self.movetimes = self.movetimes - self.movetimesspeed
		self.movetimesspeed = self.movetimesspeed + self.movetimesAcceleration
	else
		self.present = self.target:get_point()
	end
	
	local x1, y1, z1 = self.start:get_point():get(self.offset_z)
	local x2, y2, z2 = self.present:get_point():get(self.offset_z)

	jass.MoveLightningEx(self.handle, false, x1, y1, z1 + self.oz1, x2, y2, z2 + self.oz2)

	self:check_visible()

end

--颜色变化
function mt:color()
	if self.speed ~= 0 then
		if self.alpha >= 100 then
			--淡入
			if self.speed > 0 then
				self.speed = 0
			end
			self:setAlpha(self.alpha + self.speed * 0.5)
		else
			self:setAlpha(self.alpha + self.speed)
		end
		
		--print(self.alpha)
		if self.alpha <= 0 and self.isremove == 1 then
			self:remove()
		end
	end
end

-- DEKAN
--speed > 0 淡入 （未验证）
--speed < 0 淡出
function mt:fade(speed,dont_remove) --默认淡出后直接删除，若isremove有值则淡出后不删除 , 速度为每0.02秒减少的alpha值
	self.isremove = 1
	if dont_remove or speed > 0 then
		self.isremove = 0
	else
	end
	self.speed = speed
end

--移除闪电
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true

	jass.DestroyLightning(self.handle)
	dbg.handle_unref(self.handle)
	self.handle = nil

	lightning.group[self] = nil
end


--创建一个闪电
function ac.lightning(name, start, target, oz1, oz2)
	local ln = setmetatable({}, lightning)

	ln.start = start
	ln.target = target
	ln.oz1 = oz1
	ln.oz2 = oz2
	local x1, y1, z1 = start:get_point(true):get()
	local x2, y2, z2 = target:get_point(true):get()
	ln.handle = jass.AddLightningEx(name, false, x1, y1, z1 + ln.oz1, x2, y2, z2 + ln.oz2)
	dbg.handle_ref(ln.handle)
	dbg.gchash(ln, ln.handle)
	ln.gchash = ln.handle
	lightning.group[ln] = true
	ln:check_visible()

	return ln
end

function lightning.init()
	lightning.group = {}
end

function lightning.update()
	for ln in pairs(lightning.group) do
		ln:move()
		ln:color()
	end
end

return lightning
