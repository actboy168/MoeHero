
local jass = require 'jass.common'
local japi = require 'jass.japi'
local dbg = require 'jass.debug'
local point = require 'ac.point' -- todo
local math = math

local effect = {}
setmetatable(effect, effect)

--结构
local mt = {}
effect.__index = mt

--类型
mt.type = 'effect'

--句柄
mt.handle = 0

--模型
mt.model = ''

--单位(unit - 绑定在单位身上)
mt.unit = nil

--部位(字符串 - 绑在单位身上的哪个位置)
mt.socket = 'origin'

--点(创建在哪个点上)
mt.point = nil

local function point_effect_simple(self, point)
	self.point = point
	self.handle = jass.AddSpecialEffect(self.model, point:get())
	dbg.handle_ref(self.handle)
	return setmetatable(self, effect)
end

local function unit_effect_simple(self, unit)
	self.unit = unit
	self.handle = jass.AddSpecialEffectTarget(self.model, unit.handle, self.socket or 'origin')
	dbg.handle_ref(self.handle)
	return setmetatable(self, effect)
end

local function point_effect_ex(self, point)
	self.point = point
	japi.EXSetUnitString(base.string2id(effect.UNIT_ID), 13, self.model)
	self.dummy = ac.player[16]:create_dummy(effect.UNIT_ID, point, self.angle or 270)
	if self.size then
		self.dummy:set_size(self.size)
	end
	if self.height then
		self.dummy:set_high(self.height)
	end
	if self.speed then
		self.dummy:set_animation_speed(self.speed)
	end
	if self.alpha then
		self.dummy:setAlpha(self.alpha)
	end
	if self.animation then
		self._has_animation = true
		self.dummy:set_animation(self.animation)
	else
		self.dummy:set_animation 'birth'
	end
	
	function self:kill()
		if not self._has_animation then
			self.dummy:set_animation 'death'
		end
		self.dummy:kill()
		self.removed = true
	end

	function self:remove()
		self.dummy:remove()
		self.removed = true
	end
	
	return setmetatable(self, effect)
end

local function unit_effect_ex(self, unit)
	self.unit = unit
	point_effect_ex(self, unit:get_point())

	local mover = unit:follow
	{
		mover = self.dummy,
		skill = false,
	}

	return self
end

local function point_effect_elevation(self, point)
	self.point = point
	local angle, elevation
	if type(self.angle) == 'table' then
		angle, elevation = self.angle[1], self.angle[2]
	else
		angle = self.angle
	end
	self.dummy = ac.player[16]:create_dummy(effect.UNIT_ID1, point, angle or 270)
	if self.size then
		self.dummy:set_size(self.size)
	end
	if self.height then
		self.dummy:set_high(self.height)
	end
	if self.speed then
		self.dummy:set_animation_speed(self.speed)
	end
	if self.alpha then
		self.dummy:setAlpha(self.alpha)
	end
	if elevation then
		jass.SetUnitBlendTime(self.dummy.handle, 0)
		-- 与xy平面的夹角
		local r = math.floor((elevation % 360) / 3.6)
		self.dummy:set_animation(r)
	end
	self.effect = self.dummy:add_effect('origin', self.model)

	function self:kill()
		self.effect:remove()
		self.dummy:kill()
		self.removed = true
	end

	function self:remove()
		self.dummy:remove()
		self.removed = true
	end
	
	return self
end

local function unit_effect_elevation(self, unit)
	self.unit = unit
	point_effect_elevation(self, unit:get_point())

	unit:follow
	{
		mover = self.dummy,
		skill = false,
	}

	return self
end

--创建在地上
--	模型路径
function ac.point_effect(point, data)
	if data.speed or data.size or data.height or data.angle or data.alpha or data.animation then
		if data.angle and type(data.angle) == 'table' then
			return point_effect_elevation(data, point)
		else
			return point_effect_ex(data, point)
		end
	else
		return point_effect_simple(data, point)
	end
end

--绑在单位身上
function ac.unit_effect(unit, data)
	local effect
	if data.speed or data.size or data.height or data.angle or data.alpha or data.animation then
		if data.angle and type(data.angle) == 'table' then
			effect = unit_effect_elevation(data, unit)
		else
			effect = unit_effect_ex(data, unit)
		end
	else
		effect = unit_effect_simple(data, unit)
	end
	--存在单位身上
	if not unit._effect_list then
		unit._effect_list = {}
	end
	table.insert(unit._effect_list, effect)
	return effect
end

--创建在地上
--	模型路径
function point.__index:add_effect(model)
	local j_eff = jass.AddSpecialEffect(model, self:get())
	dbg.handle_ref(j_eff)
	local eff = setmetatable({handle = j_eff}, effect)
	eff.model = model
	eff.point = self
	return eff
end

--设置动画
function mt:set_animation(name)
	if self.dummy then
		self._has_animation = true
		self.dummy:set_animation(name)
	end
end

--设置缩放
function mt:set_size(size)
	if self.dummy then
		self.dummy:set_size(size)
	end
end

--设置速度
function mt:set_speed(speed)
	if self.dummy then
		self.dummy:set_animation_speed(speed)
	end
end

--设置高度
function mt:set_height(height)
	if self.dummy then
		self.dummy:set_high(height)
	end
end

--设置透明
function mt:set_alpha(alpha)
	if self.dummy then
		self.dummy:setAlpha(alpha)
	end
end

--移除
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	
	jass.DestroyEffect(self.handle)
	dbg.handle_unref(self.handle)
	self.handle = nil

	--从单位身上删除记录
	if self.unit then
		for i, v in ipairs(self.unit._effect_list) do
			if v == self then
				table.remove(self.unit._effect_list, i)
				break
			end
		end
	end
end

function mt:kill()
	return self:remove()
end

--创建一个马甲特效
function ac.effect(where, model, face, size, attachment)
	local angle
	if type(face) == 'table' then
		angle = face[2]
		face = face[1]
	end
	local u
	if angle and angle ~= 0 then
		u = ac.player[16]:create_dummy(effect.UNIT_ID1, where, face or 270)
	else
		u = ac.player[16]:create_dummy(effect.UNIT_ID2, where, face or 270)
	end
	local self = u:add_effect(attachment or 'chest', model) --附着点 attachment
	self.unit = u
	--支持缩放
	u:set_size(size or 1)
	if angle and angle ~= 0 then
		jass.SetUnitBlendTime(u.handle, 0)
		-- 与xy平面的夹角
		local r = math.floor((angle % 360) / 3.6)
		u:set_animation(r)
	end
	
	function self:remove()
		effect.remove(self)
		self.unit:kill()
	end
	
	return self
end

function effect.init()
	effect.UNIT_ID1 = 'e001'
	effect.UNIT_ID2 = 'e00P'
	effect.UNIT_ID = 'e00R'
end

return effect
