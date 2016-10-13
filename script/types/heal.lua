
local unit = require 'types.unit'

local heal = {}
setmetatable(heal, heal)

--伤害结构
local mt = {}
heal.__index = mt

--类型
mt.type = 'heal'

--来源
mt.source = nil

--目标
mt.target = nil

--原因
mt.reason = '未知'

--治疗
mt.heal = 0

--关联技能
mt.skill = nil

--创建漂浮文字
local function text(heal)
	if heal.target ~= ac.player.self.hero then
		return
	end
	local tag = heal.target.heal_texttag
	if tag and ac.clock() - tag.time < 2000 then
		tag.heal = tag.heal + heal.heal
		tag:setText(('%.f'):format(tag.heal), 8 + (tag.heal ^ 0.5) / 5)
	else
		local x, y = heal.target:get_point():get()
		local z = heal.target:get_point():getZ()
		local tag = ac.texttag
		{
			string = ('+%.f'):format(heal.heal),
			size = 8 + (heal.heal ^ 0.5) / 5,
			position = ac.point(x - 60, y, z - 30),
			speed = 86,
			angle = -45,
			red = 20,
			green = 100,
			blue = 20,
			heal = heal.heal,
			time = ac.clock(),
		}
		heal.target.heal_texttag = tag
	end
end

--创建治疗
function heal:__call(heal)
	if not heal.target or heal.heal == 0 then
		return
	end

	if heal.skill == nil then
		log.warnning('治疗没有关联技能')
		log.warnning(debug.traceback())
	end
	
	setmetatable(heal, self)

	if heal.target:event_dispatch('受到治疗开始', heal) then
		return heal
	end

	if heal.heal < 0 then
		heal.heal = 0
	end
	
	--进行治疗
	heal.target:add('生命', heal.heal)

	--创建漂浮文字
	text(heal)

	heal.target:event_notify('受到治疗效果', heal)

	return heal
end

--进行治疗
function unit.__index:heal(data)
	data.target = self
	return heal(data)
end

return heal