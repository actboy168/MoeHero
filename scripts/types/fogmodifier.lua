
local jass = require 'jass.common'
local debug = require 'jass.debug'
local rect = require 'types.rect'

local fogmodifier = {}
setmetatable(fogmodifier, fogmodifier)

local mt = {}
fogmodifier.__index = mt

--类型
mt.type = 'fogmodifier'

--句柄
mt.handle = 0

--创建可见度修正器
--	玩家
--	位置
--	[是否可见]
--	[是否共享]
--	[是否覆盖单位视野]
function fogmodifier.create(p, where, see, share, over)
	--默认可见
	see = see == false and 2 or 4

	--默认共享视野
	share = share ~= false and true or false

	--是否覆盖单位视野
	over = over and true or false
	
	local j_handle
	if where.type == 'rect' then
		j_handle = jass.CreateFogModifierRect(p.handle, see, rect.j_temp(where), share, over)
	elseif where.type == 'circle' then
		local x, y, r = where:get()
		j_handle = jass.CreateFogModifierRadius(p.handle, see, x, y, r, share, over)
	end
	debug.handle_ref(j_handle)
	jass.FogModifierStart(j_handle)
	return setmetatable({handle = j_handle}, fogmodifier)
end

--启用修正器
function mt:start()
	jass.FogModifierStart(self.handle)
	return self
end

--暂停修正器
function mt:stop()
	jass.FogModifierStop(self.handle)
	return self
end

--摧毁修正器
function mt:remove()
	jass.DestroyFogModifier(self.handle)
	debug.handle_unref(self.handle)
	self.handle = nil
end

return fogmodifier