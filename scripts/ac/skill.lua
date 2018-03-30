local jass = require 'jass.common'
local japi = require 'jass.japi'
local hero = require 'types.hero'
local unit = require 'types.unit'
local slk = require 'jass.slk'
local runtime = require 'jass.runtime'

local setmetatable = setmetatable
local rawset = rawset
local rawget = rawget
local type = type
local xpcall = xpcall
local select = select
local table_concat = table.concat
local math_floor = math.floor
local math_ceil = math.ceil
local error_handle = runtime.error_handle
local table_insert = table.insert
local table_remove = table.remove
local math_tointeger = math.tointeger

-- 充能动画帧数
local CHARGE_FRAME = 8

local skill = {}
setmetatable(skill, skill)

--结构
local mt = {}
skill.__index = mt

local default_data = {
	-- 技能等级需要的人物等级
	requirement = {1, 3, 5, 7, 9},
}

--类型
mt.type = 'skill'

--技能名
mt.name = ''

--最大等级
mt.max_level = 5

--等级（等级为0时表示技能无效）
mt.level = 1

--英雄
mt.unit = nil

--技能位置(1~4)
mt.slotid = nil

--是被动技能
mt.passive = false

--技能id
mt.ability_id = nil

--耗蓝
mt.cost = 0

--每秒耗蓝
mt.cost_channel = 0

--冷却
mt.cool = 0

--冷却
mt.mana = 0

--施法距离
mt.range = 0

--技能图标
mt.art = nil

--技能说明
mt.tip = nil

--技能数据
mt.data = nil

--施法开始
mt.cast_start_time = 0

--施法引导
mt.cast_channel_time = 0

--施法出手
mt.cast_shot_time = 0

--施法完成
mt.cast_finish_time = 0

--打断移动
mt.break_move = 1

--某个阶段是否可以被打断
mt.break_cast_start = 0
mt.break_cast_channel = 0
mt.break_cast_shot = 0
mt.break_cast_finish = 1

--不恢复指令
mt.break_order = 0

--瞬发技能
mt.instant = 0

--强制施法(无视技能限制)
mt.force_cast = 0

--施法时间条
mt.casting_tag = nil

--禁用计数
mt.disable_count = 0

--冷却模式 0:默认 1:充能
mt.cooldown_mode = 0

--最大使用次数
mt.charge_max_stack = 0

--当前剩余使用次数
mt.spell_stack = 0

--显示数字
mt.show_stack = 0

--显示冷却
mt.show_cd = 1

--显示充能冷却
mt.show_charge = 0

--当层数大于等于这个值时才可以使用充能技能(负数层数会整合显示为一个冷却)
mt.cost_stack = 1

--充能时间
mt.charge_cool = 0

--触发系数
mt.proc = 0

--技能不受冷却缩减影响
mt.ignore_cool_save = false

--自动刷新文本
mt.auto_fresh_tip = true

-- 是否是施法表
mt.is_cast_flag = false

--暂停计数
mt.pause_count = 0

--无视暂停
mt.force = false

--类型
mt.slot_type = '隐藏'

--获得技能句柄(jass)
function mt:get_handle()
	if not self:is_visible() then
		return 0
	end
	if self.owner.removed then
		return 0
	end
	return japi.EXGetUnitAbility(self.owner.handle, base.string2id(self.ability_id))
end

-- 图标可见
function mt:is_visible()
	return not self.removed and self.ability_id and not self:is_hide() and self.is_enable_ability and not self.owner:is_illusion()
end

--获得技能名字
function mt:get_name()
	return self.name
end

--获得类型
function mt:get_type()
	return self.slot_type
end

--获得格子
function mt:get_slotid()
	return self.slotid
end

--读取技能数据
local function read_value(self, skill, key)
	local value = self[key]
	local dvalue = self.data[key]
	local tp = type(value)
	local dtp = type(dvalue)
	if value == nil then
		value = dvalue
		tp = dtp
	elseif not (tp == 'function' or tp == 'table') and (dtp == 'function' or dtp == 'table') then
		value = dvalue
		tp = dtp
	end
	if tp == 'function' then
		value = value(skill, self.owner)
		tp = type(value)
	end
	if tp == 'table' and not value.type then
		if value[self.level] == nil then
			value = value[1]
		else
			value = value[self.level]
		end
	end
	return value
end

--初始化技能
local function init_skill(self)
	if self.has_inited then
		return
	end
	self.has_inited = true
	local data = self.data
	if not data then
		data = {}
		self.data = data
	end
	for k, v in pairs(default_data) do
		if not data[k] then
			if type(v) == 'table' and not v.type then
				data[k] = {}
				for k2, v2 in pairs(v) do
					data[k][k2] = v2
				end
			else
				data[k] = v
			end
		end
	end
	if data.cooldown_mode == 1 then
		if not data.show_stack then
			data.show_stack = 1
		end
		if not data.show_charge then
			data.show_charge = 1
		end
	end
	local max_level = self.data.max_level or self.max_level
	for k, v in pairs(data) do
		--预处理data中的等差数列
		if type(v) == 'table' and not v.type and #v ~= max_level and #v > 1 then
			local n = v[1]
			local m = v[#v]
			if type(m) == 'number' then
				local o = (m - n) / (max_level - 1)
				for i = 1, max_level do
					v[i] = n + o * (i - 1)
				end
			else
				print('等差数列不是数字', k, n, m)
				print(debug.traceback())
			end
		end
	end
	for k, v in pairs(data) do
		self[k] = v
	end
end

--获取物编数据
--	数据项名称
--	[如果未找到,返回的默认值]
function mt:get_slk(name, default)
	local ability_id = self.ability_id
	if not ability_id then
		return
	end
	local ability_data = slk.ability[ability_id]
	if not ability_data then
		print('技能数据未找到', ability_id)
		return default
	end
	local data = ability_data[name]
	if data == nil then
		return default
	end
	if type(default) == 'number' then
		return tonumber(data) or default
	end
	return data
end

--根据图标路径获得对应的dis路径
--	路径
local dclared_icons = {}
local function get_dis_art(art)
	local file_name = art:match [[[^\]+$]]
	if not file_name then
		return ''
	end
	if not dclared_icons[file_name] then
		dclared_icons[file_name] = art
		japi.EXDclareButtonIcon(art)
	elseif dclared_icons[file_name] ~= art then
		log.error('同一个暗图标对应了多个明图标', art, dclared_icons[file_name])
	end
	return [[ReplaceableTextures\CommandButtonsDisabled\DIS]] .. file_name
end

--根据图图标径获得对应的charge路径
--	路径
local charge_icons = {}
local function get_charge_art(art, rate)
	local file_name = art:match [[[^\]+$]]
	if not file_name then
		return ''
	end
	file_name = rate .. [[r_]] .. file_name
	if not charge_icons[file_name] then
		charge_icons[file_name] = [[blend\]] .. file_name
		japi.EXBlendButtonIcon([[blend\cool_]] .. rate .. [[.blp]], art, charge_icons[file_name])
	end
	return charge_icons[file_name]
end

--根据图图标径获得对应的stack路径
--	路径
local stack_icons = {}
local function get_stack_art(art, stack)
	local file_name = art:match [[[^\]+$]]
	if not file_name then
		return ''
	end
	file_name = stack .. [[s_]] .. file_name
	if not stack_icons[file_name] then
		stack_icons[file_name] = [[blend\]] .. file_name
		japi.EXBlendButtonIcon([[blend\stack_]] .. stack .. [[.blp]], art, stack_icons[file_name])
	end
	return stack_icons[file_name]
end

--自定义图标混合
function mt:add_blend(file, type, priority)
	if not self._blends then
		self:set('_blends', {})
	end
	local blends = self._blends
	local blend = {file = file, type = type, priority = priority}
	local skill = self
	function blend:remove()
		if self.removed then
			return
		end
		self.removed = true
		for i, dest in ipairs(blends) do
			if blend == dest then
				table.remove(blends, i)
				if i == 1 then
					skill:fresh_art()
					skill.owner:show_fresh()
				end
				return
			end
		end
	end
	for i, dest in ipairs(blends) do
		if priority > dest.priority then
			table.insert(blends, i, blend)
			if i == 1 then
				self:fresh_art()
				self.owner:show_fresh()
			end
			return blend
		end
	end
	table.insert(blends, blend)
	self:fresh_art()
	self.owner:show_fresh()
	return blend
end

local blend_icons = {}
local function get_blend_art(art, blends, type)
	local file
	for _, blend in ipairs(blends) do
		if blend.type == type then
			file = blend.file
			break
		end
	end
	if not file then
		return art
	end
	local file_name = art:match [[[^\]+$]]
	if not file_name then
		return ''
	end
	local file_name = [[blend\blend_]] .. type .. file .. [[b_]] .. file_name
	if not blend_icons[file_name] then
		japi.EXBlendButtonIcon([[blend\]] .. type .. [[\]] .. file .. [[.blp]], art, file_name)
	end
	return file_name
end

--	[使用指定图标]
--	[是否使用暗图标]
function mt:get_art(art, dis)
	local art = art or self.art or ''
	if dis then
		art = get_dis_art(art)
	elseif dis == nil and (not self:is_enable() or self:get_level() == 0 or (self:is_silent() and not self.passive)) then
		art = get_dis_art(art)
	else
		if self._blends then
			art = get_blend_art(art, self._blends, 'frame')
		end

		if self._show_buff then
			-- 计算充能比例
			local max_charge_cd = self._show_buff.time
			local charge_cd = self._show_buff:get_remaining()
			local rate
			if max_charge_cd > 0 then
				rate = math_floor((1 - charge_cd / max_charge_cd) * CHARGE_FRAME + 0.9)
			else
				rate = CHARGE_FRAME
			end

			if rate <= 0 then
				rate = nil
			elseif rate > CHARGE_FRAME then
				rate = CHARGE_FRAME
			end
			if rate then
				art = get_charge_art(art, rate)
			end
		elseif self.show_charge == 1 then
			-- 计算充能比例
			local max_charge_cd = self:get_max_charge_cd()
			local charge_cd = self:get_charge_cd()
			local rate
			if max_charge_cd > 0 then
				rate = math_floor((1 - charge_cd / max_charge_cd) * CHARGE_FRAME + 0.9)
			else
				rate = CHARGE_FRAME
			end

			if self.spell_stack <= 0 or rate <= 0 then
				rate = nil
			elseif rate > CHARGE_FRAME then
				rate = CHARGE_FRAME
			end
			if rate then
				art = get_charge_art(art, rate)
			end
		end

		if self.show_stack == 1 then
			-- 计算充能层数
			local stack = self.spell_stack
			if stack > 9 then
				stack = '9+'
			elseif stack < 0 then
				stack = 0
			end
			art = get_stack_art(art, stack)
		end
		
	end
	return art
end

--设置技能图标
function mt:set_art(art)
	if not self.owner or not jass.GetPlayerAlliance(self.owner:get_owner().handle, ac.player.self.handle, 6) then
		return
	end
	if not self:is_visible() then
		return
	end
	japi.EXSetAbilityString(base.string2id(self.ability_id), 1, 0xCC, art)
end

--刷新技能图标
function mt:fresh_art()
	self:set_art(self:get_art())
end

-- 格式化数字
local function format_number(v)
	if type(v) ~= 'number' then
		return v
	end
	return math_tointeger(v) or ('%.1f'):format(v)
end

-- 格式化数组
 -- 数据
 -- 数组
 -- 高亮等级
local function format_table(self, data, hero, level, need_level)
	if need_level or level == 0 then
		local t = {}
		for i = 1, #data do
			local v = format_number(data[i])
			if i == level then
				t[i] = '|cffffcc00' .. v
				if i < #data then
					t[i] = t[i] .. '|cff888888'
				end
			elseif i == 1 then
				t[i] = '|cff888888' .. v
			else
				t[i] = v
			end
		end
		return table_concat(t, '/') .. '|r'
	else
		return '|cffffcc00' .. data[level] .. '|r'
	end
end

-- 格式化函数
 -- 技能数据
 -- 函数
local function format_function(self, func, hero, level, need_level)
	local t = {}
	local max_level = self.max_level
	local current_level
	local data = setmetatable({}, { __index = function(data, key)
		local v = self.data[key]
		local vt = type(v)
		if vt == 'table' and not v.type then
			return v[current_level]
		elseif vt == 'function' then
			return v(data, hero)
		else
			return format_number(self[key])
		end
	end})
	local flag = false
	if need_level or level == 0 then
		for i = 1, max_level do
			current_level = i
			t[i] = func(data, hero)
			if i > 1 and t[i] ~= t[1] then
				flag = true
			end
		end
	else
		current_level = level
		t[level] = func(data, hero)
	end
	if flag then
		return format_table(self, t, hero, level, need_level)
	else
		return t[level] or t[1]
	end
end

-- 格式化字符串
 -- 技能数据
 -- 字符串
 -- 单位
 -- [技能等级]
 -- [需要扩展等级数据]
local function format_string(self, str, hero, level, need_level)
	return str:gsub('%%([%w_]*)%%', function(name)
		local v = self[name]
		local dv = self.data[name]
		-- 如果表里的这项是函数或表,则总是以表里的为准
		local dvt = type(dv)
		if not v or dvt == 'function' or dvt == 'table' then
			v = dv
		end
		local vt = type(v)
		local color_flag
		if vt == 'function' then
			v = format_function(self, v, hero, level, need_level)
			vt = type(v)
			color_flag = true
		end
		if vt == 'table' then
			return format_table(self, v, hero, level, need_level)
		end
		if vt == 'number' then
			v = format_number(v)
			color_flag = true
		elseif vt == 'string' then
			v = format_string(self, v, hero, level, need_level)
			color_flag = false
		else
			v = tostring(v)
		end
		if color_flag then
			return '|cffffcc00' .. v .. '|r'
		else
			return v
		end
	end)
end

function mt:get_simple_tip(hero, level, need_level)
	if self.tip_relation then
		local skill = hero:find_skill(self.tip_relation, nil, true) or ac.skill[self.tip_relation]
		if skill then
			return skill:get_simple_tip(hero, level, need_level)
		end
	end
	if not level then
		level = self.level
	end
	local tip = self.data.tip or self.tip
	if type(tip) == 'function' then
		tip = format_function(self, tip, hero, level, need_level)
	end
	if tip then
		tip = format_string(self, tip, hero, level, need_level)
	end
	return tip
end

function mt:get_tip(hero, level, need_level)
	if not level then
		level = self.level
	end
	local tip = self:get_simple_tip(hero, level, need_level)
	tip = (tip or '')
		.. self:get_target_type_tip(hero)
		.. self:get_range_tip(hero, level, need_level)
		.. self:get_cd_tip(hero, level, need_level)
	return tip
end

function mt:get_simple_title(hero)
	if self.title_relation then
		local skill = hero:find_skill(self.title_relation, nil, true) or ac.skill[self.title_relation]
		if skill then
			return skill:get_simple_title(hero)
		end
	end
	local title = self.data.title or self.title or self.name
	if type(title) == 'function' then
		title = format_function(self, title, hero, self.level)
	end
	if title then
		title = format_string(self, title, hero, self.level)
	end
	return title
end

function mt:get_title(hero)
	local title = self:get_simple_title(hero)
	title = (title or '') .. self:get_hotkey_tip(hero) .. self:get_level_tip(hero)
	return title
end

function mt:get_learn_tip(hero, level)
	local level = level or self.level
	return self:get_tip(hero, level + 1, true)
end

function mt:get_learn_title(hero, level)
	local level = level or self.level
	local title = self:get_simple_title(hero)
	title = (title or '') .. self:get_learn_hotkey_tip(hero) .. self:get_learn_level_tip(hero, level)
	return title
end

--刷新技能说明
--	[使用指定说明]
function mt:set_tip(tip)
	if not self.owner or not jass.GetPlayerAlliance(self.owner:get_owner().handle, ac.player.self.handle, 6) then
		return
	end
	if not self:is_visible() then
		return
	end
	if japi.EXSetAbilityString then
		japi.EXSetAbilityString(base.string2id(self.ability_id), 1, 0xDA, tip)
	else
		japi.EXSetAbilityDataString(self:get_handle(), 1, 0xDA, tip)
	end
end

function mt:fresh_tip()
	self:set_tip(self:get_tip(self.owner))
end

--刷新标题
--	[使用指定标题]
function mt:set_title(title)
	if not self.owner or not jass.GetPlayerAlliance(self.owner:get_owner().handle, ac.player.self.handle, 6) then
		return
	end
	if not self:is_visible() then
		return
	end
	if not title then
		title = self:get_title()
	end
	if japi.EXSetAbilityString then
		japi.EXSetAbilityString(base.string2id(self.ability_id), 1, 0xD7, title)
	else
		japi.EXSetAbilityDataString(self:get_handle(), 1, 0xD7, title)
	end
end

function mt:fresh_title()
	self:set_title(self:get_title(self.owner))
end

--获取等级文本
function mt:get_level_tip(hero)
	if self.level == 0 or self.max_level <= 1 then
		return ''
	end
	return ' - [第|cffffff00 ' .. self.level .. ' |r级]'
end

function mt:get_hotkey_tip(hero)
	local hk = self.hot_key or self:get_hotkey(hero)
	if hk and not self.passive and hk:find '%w' then
		return '(|cffffff00' .. hk .. '|r)'
	end
	return ''
end

function mt:get_learn_level_tip(hero, level)
	local level = level or self.level
	if self.max_level <= 1 then
		return ''
	end
	return ' - [第|cffffff00 ' .. (level + 1) .. ' |r级]'
end

function mt:get_learn_hotkey_tip(hero)
	local hk = self.hot_key or self:get_hotkey(hero)
	if hk and not self.passive and hk:find '%w' then
		return '(|cffffff00Ctrl+' .. hk .. '|r)'
	end
	return ''
end

--获取技能的热键
function mt:get_hotkey()
	return self:get_slk('Hotkey', '')
end

--设置技能的热键
--	热键
function mt:set_hotkey(key)
	japi.EXSetAbilityDataInteger(self:get_handle(), 1, 200, key and key:byte() or 0)
end

--获取技能命令
function mt:get_order()
	local ability_id = self.ability_id
	if not ability_id then
		return nil
	end
	local ability_data = slk.ability[ability_id]
	if not ability_data then
		return nil
	end
	local order = ability_data['Order']
	if order ~= 'channel' then
		if order == '' then
			return nil
		end
		return order
	end
	local order = ability_data['DataF1']
	if order == '' then
		return nil
	end
	return order
end

--获取冷却说明
function mt:get_cd_tip(hero, level, need_level)
	if self.passive or self.simple_tip then
		return ''
	end
	local word
	if self.cooldown_mode == 0 then
		word = '冷却时间'
	else
		word = '充能时间'
	end
	local cool = format_function(self, self.get_max_cd, hero, level, need_level)
	if type(cool) == 'table' then
		cool = format_table(self, cool, hero, level, need_level)
	end
	if cool == 0 then
		return ''
	end
	return '\n|cff3399ff' .. word .. '|r: ' .. format_number(cool)
end

--获取目标类型说明
function mt:get_target_type_tip()
	if self.passive or self.simple_tip then
		return ''
	end
	local tt = self.target_type
	if tt == self.TARGET_TYPE_NONE then
		return '\n|cff3399ff目标类型|r: 无'
	elseif tt == self.TARGET_TYPE_POINT then
		return '\n|cff3399ff目标类型|r: 地面'
	elseif tt == self.TARGET_TYPE_UNIT then
		return '\n|cff3399ff目标类型|r: 单位'
	elseif tt == self.TARGET_TYPE_UNIT_OR_POINT then
		return '\n|cff3399ff目标类型|r: 单位或地面'
	end
	return ''
end

--获取施法距离说明
function mt:get_range_tip(hero, level, need_level)
	if self.passive or self.simple_tip or self.target_type == self.TARGET_TYPE_NONE then
		return ''
	end
	local function get_range(self)
		local range = self.range
		if range >= 5000 then
			return '全地图'
		else
			return range
		end
	end
	local range = format_function(self, get_range, hero, level, need_level)
	if type(range) == 'table' then
		range = format_table(self, range, hero, level, need_level)
	end
	return '\n|cff3399ff施法距离|r: ' .. format_number(range)
end

--刷新施法距离
--	[使用指定施法距离]
function mt:set_range(range)
	japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x6B, range or self.range)
end

--刷新影响范围
--	[使用指定范围]
function mt:set_area(area)
	japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x6A, area or self.area)
end

--刷新技能耗蓝
--	[使用指定耗蓝]
function mt:set_cost(cost)
	--不再使用魔兽的扣蓝
	if not self:is_enable() or self.level == 0 then
		return
	end
	cost = cost or self.cost
	--print(self.name, cost)
	japi.EXSetAbilityDataInteger(self:get_handle(), 1, 0x68, self:get_cost(cost))
end

--获取技能耗蓝
function mt:get_cost()
	if self.level == 0 or self.ignore_cost then
		return 0
	end
	return self.owner:get_cost(self.cost)
end

--刷新目标允许
--	[使用指定目标类型]
--	[使用指定目标允许]
--	[使用指定目标选取范围]
function mt:set_target(target_type, target_data, area)
	if not self:is_enable() then
		target_type = skill.TARGET_TYPE_NONE
	end
	--转换单位目标为单位或点目标
	local target_type = target_type or self.target_type
	japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x6D, target_type)
	japi.EXSetAbilityDataInteger(self:get_handle(), 1, 0x64, skill.convertTargets(target_data or self.target_data))
	japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x6E, 
		((area or self.area) and 0x02 or 0x00) +
		(self.hide_count == 0 and 0x01 or 0x00)
	)
	--改一下技能等级以刷新目标允许
	if self:is_visible() then
		self.owner:setAbilityLevel(self.ability_id, 2)
		self.owner:setAbilityLevel(self.ability_id, 1)
	end
end

function mt:pause_cool()
	if self.pause_count == 1 and self:is_cooling() then
		if self.cast_cd_timer then
			self.cast_cd_timer:pause()
		end
		if self.charge_cd_timer then
			self.charge_cd_timer:pause()
		end
		self:set('pause_timer', ac.loop(1000, function(t)
			if self.pause_count > 0 then
				local cool, max_cool = self:get_show_cd()
				if cool > 0 then
					if self:is_visible() and not self.no_ability then
						self:remove_ability()
						self:add_ability()
					end
					local time = cool / max_cool * 300
					japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x69, 300)
					japi.EXSetAbilityState(self:get_handle(), 0x01, time)
				end
			else
				t:remove()
			end
		end))
		self.pause_timer:on_timer()
	end
end

--暂停
function mt:pause(flag)
	if self.force then
		return
	end
	if flag == nil then
		flag = true
	end
	if flag then
		self:set('pause_count', self.pause_count + 1)
		self:pause_cool()
	else
		self:set('pause_count', self.pause_count - 1)
		if self.pause_count == 0 then
			if self.cast_cd_timer then
				self.cast_cd_timer:resume()
			end
			if self.charge_cd_timer then
				self.charge_cd_timer:resume()
			end
			self:set_show_cd()
		end
	end
end

--显示buff时间
function mt:show_buff(buff)
	if self._show_buff then
		self._show_buff._show_skill = nil
	end
	self:set('_show_buff', buff)
	if self._show_buff_timer then
		self._show_buff_timer:remove()
	end
	if not buff then
		self:set('_show_buff_timer', nil)
		self:fresh_art()
		self.owner:show_fresh()
		return
	end
	buff._show_skill = self
	self:set('_show_buff_timer', ac.loop(buff.time * 1000 / CHARGE_FRAME / 2, function(t)
		if buff.removed then
			self:set('_show_buff', nil)
			self:set('_show_buff_timer', nil)
			t:remove()
		end
		self:fresh_art()
		self.owner:show_fresh()
	end))
end

--获取充能
function mt:get_stack()
	return self.spell_stack
end

--增加充能
function mt:add_stack(n)
	self:set_stack(self.spell_stack + n)
end

--设置充能
function mt:set_stack(n)
	self:set('spell_stack', n)
	if self.cooldown_mode == 1 then
		if self.spell_stack < self.charge_max_stack then
			if self:get_charge_cd() == 0 then
				self:set_charge_cd(self:get_max_charge_cd())
			end
		else
			if self:get_charge_cd() > 0 then
				self:set_charge_cd(0)
			end
		end
	end
	if self.show_stack == 1 then
		self:fresh_art()
	end
	self:set_show_cd()
	self.owner:show_fresh()
end

--获取显示冷却
mt.last_min_stack = 0
function mt:get_show_cd()
	local cool = self:get_cast_cd()
	local max_cool = self:get_max_cast_cd()
	if self.cooldown_mode == 1 and self.spell_stack < self.cost_stack then
		local charge_cool = self:get_charge_cd()
		local max_charge_cool = self:get_max_charge_cd()
		if self.spell_stack < self.cost_stack then
			charge_cool = charge_cool + (self.cost_stack - 1 - self.spell_stack) * max_charge_cool
			max_charge_cool = max_charge_cool + (self.cost_stack - 1 - self.last_min_stack) * max_charge_cool
		end
		if cool < charge_cool then
			return charge_cool, max_charge_cool
		end
	end
	return cool, max_cool
end

--显示冷却时间
function mt:set_show_cd()
	if not self:is_visible() then
		return
	end
	if self.cooldown_mode == 1 then
		if self.spell_stack < self.last_min_stack then
			self:set('last_min_stack', self.spell_stack)
		elseif self.spell_stack >= self.cost_stack then
			self:set('last_min_stack', self.cost_stack)
		end
	end
	local cool, max_cool = self:get_show_cd()
	if cool ~= 0 and not self.no_ability then
		--print('强行重置技能冷却', self.name)
		self:remove_ability()
		self:add_ability()
	end
	if self.show_cd == 1 then
		japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x69, max_cool)
		japi.EXSetAbilityState(self:get_handle(), 0x01, cool)
		japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x69, 0)
	end
end

--设置技能剩余充能
mt.charge_cd_timer = nil

--设置技能冷却
--	冷却时间
function mt:set_charge_cd(cool)
	if cool == self:get_charge_cd() then
		return
	end
	if ac.wtf then
		cool = 0
	end
	
	local function remove_timer()
		if self.charge_cd_timer then
			self.charge_cd_timer:remove()
			self:set('charge_cd_timer', nil)
		end
		if self.charge_cd_rate_timer then
			self.charge_cd_rate_timer:remove()
			self:set('charge_cd_rate_timer', nil)
		end
	end
	
	local function cooled()
		--检查使用次数
		remove_timer()
		if self.spell_stack < self.charge_max_stack then
			self:add_stack(1)
		end
	end

	remove_timer()
	if cool > 0 then
		self:set('charge_cd_timer', ac.wait(cool * 1000, cooled))
		self:set('charge_cd_rate_timer', ac.loop(cool * 1000 / CHARGE_FRAME / 2, function()
			self:fresh_art()
			self.owner:show_fresh()
		end))
	else
		cooled()
	end
	self:set_show_cd()
	self:pause_cool()
end

--设置技能剩余冷却状态
mt.cast_cd_timer = nil

--设置技能冷却
--	冷却时间
function mt:set_cast_cd(cool)
	if cool == self:get_cast_cd() then
		return
	end
	if ac.wtf then
		cool = 0
	end
	
	local function cooled()
		self:_call_event 'on_cooldown'
	end
	
	if self.cast_cd_timer then
		self.cast_cd_timer:remove()
		self:set('cast_cd_timer', nil)
	end
	if cool > 0 then
		self:set('cast_cd_timer', ac.wait(cool * 1000, cooled))
	else
		cooled()
	end
	self:set_show_cd()
	self:pause_cool()
end

function mt:set_cd(cool)
	if self.cooldown_mode == 0 then
		self:set_cast_cd(cool)
		return
	end
	if self.cooldown_mode == 1 then
		self:set_charge_cd(cool)
		return
	end
end

function mt:active_charger_cd()
	self:set_charge_cd(self:get_max_charge_cd())
end

function mt:active_cast_cd()
	self:set_cast_cd(self:get_max_cast_cd())
end

function mt:active_cd()
	self:set_cd(self:get_max_cd())
end

--获取技能冷却
function mt:get_cast_cd()
	if not self.cast_cd_timer then
		return 0
	end
	return self.cast_cd_timer:get_remaining() / 1000
end

--获取充能剩余时间
function mt:get_charge_cd()
	if not self.charge_cd_timer then
		return 0
	end
	return self.charge_cd_timer:get_remaining() / 1000
end

function mt:get_cd()
	if self.cooldown_mode == 0 then
		return self:get_cast_cd()
	end
	if self.cooldown_mode == 1 then
		return self:get_charge_cd()
	end
	return 0
end

function mt:fresh_cool()
	local cast_cd = self:get_cast_cd()
	local max_cast_cd = self:get_max_cast_cd()
	local charge_cd = self:get_charge_cd()
	local max_charge_cd = self:get_max_charge_cd()
	return function()
		if cast_cd > 0 and max_cast_cd > 0 then
			self:set_cast_cd(cast_cd / max_cast_cd * self:get_max_cast_cd())
		else
			self:set_cast_cd(0)
		end
		if charge_cd > 0 and max_charge_cd > 0 then
			self:set_charge_cd(charge_cd / max_charge_cd * self:get_max_charge_cd())
		else
			self:set_charge_cd(0)
		end
	end
end

--技能是否正在冷却
function mt:is_cooling()
	return self:get_cast_cd() > 0 or self:get_charge_cd() > 0
end

--获取技能最大冷却
function mt:get_max_cast_cd()
	if not self.owner or self.ignore_cool_save then
		return self.cool
	end
	return self.owner:getSkillCool(self.cool)
end

--获取充能最大冷却
function mt:get_max_charge_cd()
	if not self.owner or self.ignore_cool_save then
		return self.charge_cool
	end
	return self.owner:getSkillCool(self.charge_cool)
end

function mt:get_max_cd()
	if self.cooldown_mode == 0 then
		return self:get_max_cast_cd()
	end
	if self.cooldown_mode == 1 then
		return self:get_max_charge_cd()
	end
	return 0
end

--启动技能冷却(施法流程)
function mt:start_cd_by_cast()
	local max_cd = self:get_max_cast_cd()
	self:set_cast_cd(max_cd)
	if self.cooldown_mode == 1 then
		local charge_cd = self:get_charge_cd()
		if charge_cd <= 0 then
			local max_charge_cd = self:get_max_charge_cd()
			self:set_charge_cd(max_charge_cd, max_charge_cd)
		end
		self:add_stack(-1)
		if self.spell_stack < self.cost_stack and self:get_charge_cd() > max_cd then
			self:set_show_cd(self:get_charge_cd(), self:get_max_charge_cd())
			return
		end
	end
end

--令技能消耗对应的法力值(计算节能施法)
function mt:cost_mana(mana)
	local hero = self.owner
	if self.ignore_cost then
		return true
	end
	if hero:cost_mana(mana or self.cost) then
		return true
	end

	return false
end

--隐藏技能
mt.hide_count = 0

--隐藏技能
function mt:hide()
	local handle = self:get_handle()
	self:set('hide_count', self.hide_count + 1)
	if self.hide_count == 1 then
		japi.EXSetAbilityDataReal(handle, 1, 0x6E, 
			(self.area and 0x02 or 0x00) + 
			(self.hide_count == 0 and 0x01 or 0x00)
		)
	end
end

--显示技能
function mt:show()
	self:set('hide_count', self.hide_count - 1)
	if self.hide_count == 0 then
		japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x6E, 
			(self.area and 0x02 or 0x00) +
			(self.hide_count == 0 and 0x01 or 0x00)
		)
	end
end

--是否隐藏
function mt:is_hide()
	return self.hide_count > 0
end

--获得技能模板(war3中的技能id)
function mt:get_ability_id()
	local slotid = self.slotid
	if slotid then
		local p = self.owner:get_owner()
		return p:get_ability_id(slotid)
	end
end

--禁用技能
mt.disable_count = 0

--禁用技能
function mt:disable()
	self:set('disable_count', self.disable_count + 1)
	if self.disable_count == 1 then
		--print('禁用技能', self.name)
		self:fresh()
		self:_call_event('on_disable', true)
	end
end

--允许技能
function mt:enable()
	self:set('disable_count', self.disable_count - 1)
	--print(self.disable_count)
	if self.disable_count == 0 then
		--print('允许技能', self.name)
		self:fresh()
		self:_call_event('on_enable', true)
	end
end

--技能是否有效
function mt:is_enable()
	return self.disable_count <= 0
end

--是否沉默
function mt:is_silent()
	if not self.owner:has_restriction '禁魔' then
		return false
	end
	if self:get_type() == '英雄' or self:get_type() == '通用' then
		return true
	end
	return false
end

--允许技能(War3)
mt.is_enable_ability = true

function mt:enable_ability()
	self:set('is_enable_ability', true)
	--print('self.enable_ability = true', self:get_name())
	self.owner:get_owner():enable_ability(self.ability_id)
	self:fresh()
	return false
end

--禁用技能(War3)
function mt:disable_ability()
	self:set('is_enable_ability', false)
	--print('self.enable_ability = false', self:get_name())
	self.owner:get_owner():disable_ability(self.ability_id)
	return false
end

--技能是否允许(War3)
function mt:is_ability_enable()
	return self.is_enable_ability
end

local event_name = {
	['on_add']          = '技能-获得',
	['on_remove']       = '技能-失去',
	['on_cast_start']   = '技能-施法开始',
	['on_cast_break']   = '技能-施法打断',
	['on_cast_channel'] = '技能-施法引导',
	['on_cast_shot']    = '技能-施法出手',
	['on_cast_finish']  = '技能-施法完成',
	['on_cast_stop']    = '技能-施法停止',
}

--触发技能事件
--	事件名
--	无视禁用状态
function mt:_call_event(name, force)
	if not force then
		if self.removed then
			return false
		end
		if not self:is_enable() then
			return false
		end
	end
	if event_name[name] then
		-- todo: 有返回值的事件
		self.owner:event_notify(event_name[name], self.owner, self)
	end
	if not self[name] then
		return false
	end
	return select(2, xpcall(self[name], error_handle, self))
end

--切换阶段
--	目标阶段
function mt:_change_step(step)
	if not self:is_cast() then
		for _, cast in self.owner:each_cast(self.name) do
			if cast:is(self) then
				cast:_change_step(step)
			end
		end
		return
	end
	if self._need_waiting_step then
		if not self._waiting_step then
			self._waiting_step = {}
		end
		table_insert(self._waiting_step, step)
		return
	end
	self._need_waiting_step = true
	self['_cast_' .. step](self)
	self._need_waiting_step = false
	if self._waiting_step and #self._waiting_step > 0 then
		local step = table_remove(self._waiting_step, 1)
		self:_change_step(step)
	end
end

--提升技能等级
--	[指定提升的等级,默认为1]
--	[升级方式]
function mt:upgrade(lv, skill)
	local fresh_cool = self:fresh_cool()
	lv = lv or 1
	for i = 1, lv do
		if self.level == self.max_level then
			break
		end
		if not self._upgrade_skill then
			self:set('_upgrade_skill', {})
		end
		self:set('level', self.level + 1)
		self._upgrade_skill[self.level] = skill
		if self.level == 1 then
			self:fresh()
			self:_call_event 'on_add'
			if self.owner:is_pause_skill() then
				self:pause()
			end
		else
			self:fresh()
		end
		self:_call_event 'on_upgrade'
	end
	self:fresh_tip()
	fresh_cool()
end

--设置技能等级
--	等级
function mt:set_level(lv)
	self:upgrade(lv - self.level)
end

--获取等级
function mt:get_level()
	return self.level
end

local cast_mt = {
	__index = function(skill, key)
		local value = read_value(skill.parent_skill, skill, key)
		skill[key] = value
		return value
	end,
}

-- 更新技能等级信息
function mt:update_data()
	local self = self.parent_skill or self
	local data = self.data
	if not data then
		return
	end
	local skill = setmetatable({}, cast_mt)
	skill.parent_skill = self
	for k in pairs(data) do
		skill[k] = read_value(self, skill, k)
		self[k] = skill[k]
	end
end

-- 创建施法表
function mt:create_cast(data)
	local self = self.parent_skill or self
	local skill = data or {}
	skill.is_cast_flag = true
	skill.parent_skill = self
	setmetatable(skill, cast_mt)
	for k in pairs(self.data) do
		skill[k] = read_value(self, skill, k)
	end
	return setmetatable(skill, self)
end

-- 是否是施法表
function mt:is_cast()
	return self.is_cast_flag
end

-- 是否是同一个技能对象
function mt:is(skill)
	return (self.parent_skill or self) == (skill.parent_skill or skill)
end

--进行标记
--	标记索引
function mt:set(key, value)
	if self.parent_skill then
		self.parent_skill[key] = value
	else
		self[key] = value
	end
end

--获取标记
--	标记索引
function mt:get(key)
	if self.parent_skill then
		return self.parent_skill[key]
	else
		return self[key]
	end
end

--设置选项
--	选项索引
--	选项值
function mt:set_option(key, value)
	if key == 'show_cd' then
		self:set(key, value)
		self:set_show_cd()
		return
	end
	if key == 'passive' or key == 'ignore_cost' then
		local nkey = '_option_count_' .. key
		if value then
			self:set(nkey, (self[nkey] or 0) + 1)
			if self[nkey] == 1 then
				self:set(key, true)
			end
		else
			self:set(nkey, (self[nkey] or 0) - 1)
			if self[nkey] == 0 then
				self:set(key, false)
			end
		end
		self:fresh()
		return
	end
	self:set(key, value)
	if key == 'tip_relation' then
		self:fresh_tip()
		return
	end
	if key == 'title_relation' then
		self:fresh_title()
		return
	end
	if key == 'target_type' then
		self:set_target()
		self:set('_out_range_target', nil)
		return
	end
end

--找到单位目标
function mt:find_target(target)
	if not target then
		return
	end
	if target.type == 'unit' then
		return target
	end
	--筛选出单位
	local g = ac.selector()
		: in_range(target, 200)
		: add_filter(base.target_filter(self.owner, self.target_data, true))
		: sort_nearest_type_hero(target)
		: get()
	if not g[1] then
		self.owner:get_owner():play_sound([[Sound\Interface\Error.wav]])
		self.owner:get_owner():sendMsg('|cffffff11没有找到目标|r', 10)
	end
	return g[1]
end

--设置技能动画
function mt:set_animation(name)
	self.cast_animation = name
end

function unit.__index:show_fresh()
	self:add_ability 'A888'
	self:remove_ability 'A888'
end

--刷新物编技能
function mt:fresh()
	self:update_data()

	if not self:is_visible() then
		return
	end
	self:fresh_art()
	self:set_target()
	self:set_range()
	self:set_area()
	self:set_cost()
	self:fresh_tip()
	self:fresh_title()
	self:set_show_cd()
end

--英雄添加技能
--	技能名
--	技能类型
--	[技能位置]
--	[初始数据]
--	@技能对象
function unit.__index:add_skill(name, type, slotid, data)
	if not ac.skill[name] then
		log.error('技能不存在', name)
		return false
	end

	if not self.skills then
		self.skills = {}
	end

	if not self.skills[type] then
		self.skills[type] = {}
	end

	if not slotid then
		for i = 1, #self.skills[type] + 1 do
			if self.skills[type][i] == nil then
				slotid = i
				break
			end
		end
	end
	
	if self.skills[type][slotid] then
		log.error('该位置已有技能:', type, slotid, self.skills[type][slotid].name)
		return false
	end
	
	--print('添加技能:' .. name)
	if not data then
		data = {}
	end
	for k, v in pairs(ac.skill[name]) do
		if data[k] == nil then
			data[k] = v
		end
	end
	local skill = setmetatable(data, skill)
	
	skill.__index = skill

	self.skills[type][slotid] = skill
	skill.slot_type = type
	skill.slotid = slotid
	skill.owner = self

	skill.ability_id = skill.ability_id or self:get_owner():get_ability_id(type, slotid)

	if skill.cooldown_mode == 1 then
		skill.spell_stack = skill.charge_max_stack
	end
	if skill.passive then
		skill:set_option('passive', true)
	end

	skill:update_data()
	
	--每秒刷新技能
	if skill.auto_fresh_tip then
		ac.loop(1000, function(t)
			if skill.removed then
				t:remove()
				return
			end
			skill:fresh_tip()
		end)
	end

	if type == '物品' then
		ac.item.bind_item(skill)
	else
		if skill.ability_id then
			skill:add_ability()
			self:makePermanent(skill.ability_id)
			local order = skill:get_order()
			if order then
				if not self._order_skills then
					self._order_skills = {}
				end
				if self._order_skills[order] then
					log.error('技能指令冲突', order, self:get_name(), self._order_skills[order].name, skill.name, self._order_skills[order].ability_id, skill.ability_id)
				end
				self._order_skills[order] = skill
			end
		end
	end

	local lv = skill.level
	skill.level = 0
	skill:upgrade(lv)
	skill:fresh()

	return skill
end

-- 移除技能
function mt:remove()
	self = self.parent_skill or self
	if self.removed then
		return false
	end
	local hero = self.owner
	if not hero then
		return false
	end
	if not hero.skills then
		return false
	end

	self.removed = true
	
	local name = self.name

	if self._is_casting then
		self:stop()
	end
	if hero.skills[self:get_type()][self.slotid] ~= self then
		log.error('技能位置不符', self.name, self:get_type(), self.slotid, hero.skills[self:get_type()][self.slotid].name)
	else
		hero.skills[self:get_type()][self.slotid] = nil
	end

	if self.opened then
		self:_call_event('on_close', true)
	end

	if self:get_level() > 0 and self:is_enable() then
		self:_call_event('on_remove', true)
	end

	local order = self:get_order()
	if order and hero._order_skills then
		hero._order_skills[order] = nil
	end

	if self.cast_cd_timer then
		self.cast_cd_timer:remove()
		self.cast_cd_timer = nil
	end

	if self:get_type() == '物品' then
		ac.item.remove(self)
	else
		self:remove_ability()
	end
	
	return true
end

function mt:add_ability()
	if self.ability_id and not self.no_ability then
		self.owner:add_ability(self.ability_id)
	end
end

function mt:remove_ability()
	if self.ability_id and not self.no_ability then
		self.owner:remove_ability(self.ability_id)
	end
end

--英雄移除技能
--	技能名
--	@是否成功
function unit.__index:remove_skill(name)
	local skill = self:find_skill(name)
	if skill then
		return skill:remove()
	end
	return false
end

--从单位身上找技能
--	技能名称
--	[技能类型]
--	[是否包含未学习的英雄技能]
--	@技能对象
function unit.__index:find_skill(name, type, ignore_level)
	if not self.skills then
		return nil
	end
	if not type then
		for type in pairs(self.skills) do
			local skill = self:find_skill(name, type, ignore_level)
			if skill then
				return skill
			end
		end
		return nil
	end
	if not self.skills[type] then
		return nil
	end
	for i, skill in pairs(self.skills[type]) do
		if name == i or name == skill.name then
			if ignore_level or skill:get_level() > 0 then 
				return skill
			end
		end
	end
	return nil
end

--遍历单位身上的技能
--	[技能类型]
--	[是否包含未学习的英雄技能]
--	@list
function unit.__index:each_skill(type, ignore_level)
	if not self.skills then
		return function () end
	end
	local result = {}
	if type then
		if not self.skills[type] then
			return function () end
		end
		for _, v in pairs(self.skills[type]) do
			if ignore_level or v:get_level() > 0 then
				table_insert(result, v)
			end
		end
	else
		for _, type_skills in pairs(self.skills) do
			for _, v in pairs(type_skills) do
				if ignore_level or v:get_level() > 0 then
					table_insert(result, v)
				end
			end
		end
	end
	local n = 0
	return function (t, v)
		n = n + 1
		return t[n]
	end, result
end

--添加全部技能
function hero.__index:add_all_hero_skills()
	local t = {}
	for i = 1, #self.skill_datas do
		local skl = self.skill_datas[i]
        if i > 4 then
            t[i] = self:find_skill(i, '隐藏', true) or self:add_skill(skl.name, '隐藏', i, {level = 0})
        else
            t[i] = self:find_skill(i, '英雄', true) or self:add_skill(skl.name, '英雄', i, {level = 0})
        end
	end
	for i = 1, #t do
		local level = self.skill_datas[i].level
		t[i]:set_level(level)
	end
end

--打断施法
--	[效果来源]
function unit.__index:cast_stop()
	if self:event_dispatch('单位-施法被打断', self) then
		return
	end
	local wait
	for _, skill in self:each_cast() do
		if not wait then
			wait = {}
		end
		table_insert(wait, skill)
	end
	if wait then
		for _, skill in ipairs(wait) do
			skill:stop()
		end
	end
end

--强制发动技能
--	技能名
--	[技能等级]
--	[技能目标]
function unit.__index:cast_spell(name, level, target)
	local skl = self:find_skill(name, nil, true)
	if not skl then
		skl = self:add_skill(name, '隐藏')
	end
	if level then
		skl:set_level(level)
	end
	if skl:get_level() == 0 then
		--print('不能发动等级0的技能', name)
		return
	end
	if skl:is_cooling() then
		--print('正在冷却', name, skl:get_cast_cd())
		return
	end
	if skl:get_cost() > self:get '魔法' then
		--print('能量不足', name)
		return
	end
	--print('脚本发动技能', name)
	return skl:_cast_start {target = target, force_cast = 1, instant = 1}
end

--替换技能
--	被替换掉的技能名
--	替换上来的技能名
--	[是否继承冷却]
function unit.__index:replace_skill(name, new_name, cool)
	--print('替换技能', name, new_name)
	local skl1 = self:find_skill(name, nil, true)
	local skl2 = self:find_skill(new_name, nil, true)
	if not skl1 then
		return false, '没有找到技能'
	end
	if not skl2 then
		skl2 = self:add_skill(new_name, '隐藏')
	end

	skl1:remove_ability()
	skl2:remove_ability()
	if not self._order_skills then
		self._order_skills = {}
	end
	for order, skill in pairs(self._order_skills) do
		if skill == skl1 then
			self._order_skills[order] = nil
		elseif skill == skl2 then
			self._order_skills[order] = nil
		end
	end
	
	skl1.ability_id, skl2.ability_id = skl2.ability_id, skl1.ability_id
	skl1.slot_type, skl2.slot_type = skl2.slot_type, skl1.slot_type
	skl1.slotid, skl2.slotid = skl2.slotid, skl1.slotid
	
	self.skills[skl1.slot_type][skl1.slotid] = skl1
	self.skills[skl2.slot_type][skl2.slotid] = skl2

	skl2:set_level(skl1:get_level())
	skl2:update_data()

	skl1:add_ability()
	skl2:add_ability()
	
	local order = skl1:get_order()
	if order then
		self._order_skills[order] = skl1
	end
	local order = skl2:get_order()
	if order then
		self._order_skills[order] = skl2
	end
	
	if cool then
		skl2.spell_stack = skl1.spell_stack
		skl2:set_cast_cd(skl1:get_cast_cd())
		skl2:set_charge_cd(skl1:get_charge_cd())
	end

	skl1:fresh()
	skl2:fresh()

	if skl1:is_ability_enable() then
		skl1:enable_ability()
	else
		skl1:disable_ability()
	end
	if skl2:is_ability_enable() then
		skl2:enable_ability()
	else
		skl2:disable_ability()
	end

	--刷新学习技能
	if skl1:get_type() == '英雄' then
		local lskl = self:find_skill(skl1.slotid, '学习')
		if lskl then
			lskl:_call_event 'on_add'
		end
	end
	if skl2:get_type() == '英雄' then
		local lskl = self:find_skill(skl2.slotid, '学习')
		if lskl then
			lskl:_call_event 'on_add'
		end
	end
	return true
end

-- 获取正在施放的技能
function unit.__index:each_cast(name)
	local skills = self._casting_list
	local t = {}
	if skills then
		for _, skill in ipairs(skills) do
			if not name or name == skill.name then
				--print(skill.name)
				table_insert(t, skill)
			end
		end
	end
	return ipairs(t)
end

-- 寻找正在施放的技能
function unit.__index:find_cast(name)
	local skills = self._casting_list
	if skills then
		for _, skill in ipairs(skills) do
			if not name or name == skill.name then
				return skill
			end
		end
	end
	return nil
end

-- 命令使用技能
function unit.__index:cast(name, target, data)
	local skill = self:find_skill(name)
	if not skill then
		return false
	end
	return skill:cast(target, data)
end

-- 命令强制使用技能
function unit.__index:force_cast(name, target, data)
	local skill = self:find_skill(name)
	if not skill then
		return false
	end
	data = data or {}
	data.force_cast = 1
	return skill:cast(target, data)
end

--是否可以发布指令
function mt:can_order(target)
	if self.removed then
		return false
	end
	if self.passive then
		return false
	end
	if self:get_level() == 0 then
		return false
	end
	if self:get_cast_cd() > 0 then
		return false
	end
	if not self:is_ability_enable() then
		return false
	end
	if not self:is_enable() then
		return false
	end
	if self:is_silent() then
		return false
	end
	if self.cooldown_mode == 1 and self.spell_stack < self.cost_stack then
		return false
	end
	if self:get_cost() > self.owner:get '魔法' then
		return false
	end
	if target and self.target_type == self.TARGET_TYPE_UNIT and target:has_restriction '魔免' then
		return false
	end
	return true
end

--是否可以使用
function mt:can_cast(target)
	if not self:can_order(target) then
		return false
	end
	if self.owner:has_restriction '时停' then
		return false
	end
	return true
end

--是否在施法范围内
function mt:is_in_range(target)
	if not target then
		return true
	end
	if target.type == 'unit' then
		if not target:is_in_range(self.owner, self.range) then
			return false
		end
	elseif target.type == 'point' then
		if target * self.owner:get_point() > self.range then
			return false
		end
	end
	return true
end

-- 客户端使用技能
function mt:cast_by_client(target, data)
	local hero = self.owner
	if not self:is_visible() then
		return false
	end
	if not target then
		if self.target_type ~= self.TARGET_TYPE_NONE then
			return false
		end
	elseif target.type == 'unit' then
		if self.target_type ~= self.TARGET_TYPE_UNIT and self.target_type ~= self.TARGET_TYPE_UNIT_OR_POINT then
			return false
		end
	elseif target.type == 'point' then
		if self.target_type ~= self.TARGET_TYPE_POINT and self.target_type ~= self.TARGET_TYPE_UNIT_OR_POINT then
			return false
		end
	else
		return false
	end
	if self.force_cast == 0 and hero:has_restriction '晕眩' then
		self._recover_skill = {self, target}
		return false
	end
	if self.instant == 0 and hero:find_cast() then
		for _, skill in hero:each_cast() do
			if skill.instant == 0 then
				local step = skill._current_step
				if step and skill['break_' .. step] == 0 then
					hero._recover_skill = {self, target}
					return false
				end
			end
		end
	end
	self._recover_skill = nil
	return self:cast(target, data)
end

-- 使用技能
function mt:cast(target, data)
	local self = self:create_cast(data)
	self.target = target
	if self.force_cast == 1 or (data and data.force_cast == 1) then
		return self:cast_force(target, self)
	end
	if not self:is_in_range(target) then
		return false
	end
	if self.owner:has_restriction '晕眩' then
		return false
	end
	if not self:can_cast(target) then
		return false
	end
	if self.on_can_cast then
		local suc, msg = self:_call_event 'on_can_cast'
		if not suc then
			if msg then
				self.owner:get_owner():sendMsg('|cffffcc00' .. msg .. '|r', 3)
			end
			return false
		end
	end
	-- 瞬发技能不允许多重施法
	if self.instant == 1 then
		local skills = self.owner._casting_list
		if skills then
			for _, skill in ipairs(skills) do
				if skill:is(self) then
					return false
				end
			end
		end
	end
	return self:cast_force(target, self)
end

-- 强制施法(不检查状态)
function mt:cast_force(target, data)
	local hero = self.owner
	local self = self:create_cast(data)
	self.target = target
	if self.instant == 0 then
		local skills = hero._casting_list
		if skills then
			local wait
			for _, skill in ipairs(skills) do
				if skill.instant == 0 then
					local step = skill._current_step
					if step and skill['break_' .. step] == 1 then
						if not wait then
							wait = {}
						end
						table_insert(wait, skill)
					else
						return false
					end
				end
			end
			if wait then
				for _, skill in ipairs(wait) do
					skill:stop()
				end
			end
		end
	end
	if not hero._casting_list then
		hero._casting_list = {}
	end
	table_insert(hero._casting_list, self)
	self._is_casting = true
	local need_animation = #hero._casting_list == 1 or self.instant == 0
	
	if self.break_move == 1 and self.cast_start_time + self.cast_channel_time + self.cast_shot_time + self.cast_finish_time > 0 then
		hero:add_restriction '硬直'
		self._cast_hard = true
		if need_animation and target and hero:get_point() * target:get_point() > 0 then
			hero:set_facing(hero:get_point() / target:get_point())
		end
	end
	
	self:_change_step 'start'
	ac.wait(0, function()
		hero:set('魔法', hero:get '魔法')
		if need_animation then
			if self.cast_animation_speed then
				hero:set_animation_speed(self.cast_animation_speed)
			end
			if self.cast_animation then
				hero:set_animation(self.cast_animation)
			end
		end
	end)
	return true
end

-- 施法开始
function mt:_cast_start()
	local hero = self.owner
	self._has_cast_start = true
	self._current_step = 'cast_start'
	--print('技能-施法开始', self.name)
	self:_call_event 'on_cast_start'
	if self.cast_start_time > 0 then
		hero:wait(math_floor(self.cast_start_time * 1000), function()
			self:_change_step 'channel'
		end)
	else
		self:_change_step 'channel'
	end
end

-- 施法打断
function mt:_cast_break()
	if not self._is_casting or self._has_cast_channel then
		return
	end
	--print('技能-施法打断', self.name)
	self:_call_event 'on_cast_break'
end

-- 施法引导
function mt:_cast_channel()
	if not self._is_casting or self._has_cast_channel then
		return
	end
	local hero = self.owner
	self:cost_mana()
	self:start_cd_by_cast()
	self._has_cast_start = true
	self._has_cast_channel = true
	self._current_step = 'cast_channel'
	self:_call_event 'on_cast_channel'
	if self.cost_channel > 0 then
		self._cost_channel_timer = hero:loop(100, function()
			if not hero:cost_mana(self.cost_channel / 10) then
				self:stop()
			end
		end)
	end
	if self.cast_channel_time > 0 then
		hero:wait(math_floor(self.cast_channel_time * 1000), function()
			self:_change_step 'shot'
		end)
	else
		self:_change_step 'shot'
	end
end

-- 施法出手
function mt:_cast_shot()
	if not self._is_casting or self._has_cast_shot or not self._has_cast_channel then
		return
	end
	local hero = self.owner
	self._has_cast_shot = true
	self._current_step = 'cast_shot'
	if self._cost_channel_timer then
		--print('_cast_shot 移除扣蓝')
		self._cost_channel_timer:remove()
		self._cost_channel_timer = nil
	end
	--print('技能-施法出手', self.name)
	self:_call_event 'on_cast_shot'
	if self.cast_shot_time > 0 then
		hero:wait(math_floor(self.cast_shot_time * 1000), function()
			self:_change_step 'finish'
		end)
	else
		self:_change_step 'finish'
	end
end

-- 施法完成
function mt:_cast_finish()
	if not self._is_casting or self._has_cast_finish or not self._has_cast_channel then
		return
	end
	local hero = self.owner
	self._has_cast_shot = true
	self._has_cast_finish = true
	self._current_step = 'cast_finish'
	--print('技能-施法完成', self.name)
	self:_call_event 'on_cast_finish'
	self:_change_step 'stop'
	if self.cast_finish_time == 0 then
		self:_change_step 'end'
		return
	end
	if self.break_cast_finish == 1 and self.want_break then
		self:_change_step 'end'
		return
	end
	hero:wait(math_floor(self.cast_finish_time * 1000), function()
		self:_change_step 'end'
	end)
end

-- 施法停止
function mt:_cast_stop()
	if not self._is_casting or self._has_cast_stop or not self._has_cast_channel then
		return
	end
	local hero = self.owner
	self._has_cast_start = true
	self._has_cast_channel = true
	self._has_cast_stop = true
	if self._cost_channel_timer then
		--print('cast_stop 移除扣蓝')
		self._cost_channel_timer:remove()
		self._cost_channel_timer = nil
	end
	--print('技能-施法停止', self.name)
	self:_call_event 'on_cast_stop'
	if not self._has_cast_finish then
		self:_change_step 'end'
	end
end

-- 施法结束
function mt:_cast_end()
	if self._has_cast_end then
		return
	end
	self._has_cast_end = true
	local hero = self.owner
	for i, v in ipairs(hero._casting_list) do
		if v == self then
			table_remove(hero._casting_list, i)
		end
	end
	self._is_casting = false
	if self._cast_hard then
		hero:remove_restriction '硬直'
	end
	if #hero._casting_list == 0 then
		hero:set_animation_speed(1)
		if self._has_cast_finish then
			hero:add_animation 'stand'
		else
			hero:set_animation 'stand'
		end
	end
end

-- 停止技能
function mt:stop()
	self:_change_step 'break'
	self:_change_step 'stop'
	self:_change_step 'end'
end

-- 施法完成
function mt:finish()
	self:_change_step 'shot'
end

local function init()
	-- 英雄或商店使用技能
	ac.game:event '单位-发布指令' (function(self, hero, order, target, player_order)
		if order == '' then
			return
		end
		if order == 'stop' or order == 'smart' or order == 'attack' then
			if player_order then
				hero._ignore_order_list = nil
			end
			for _, skill in hero:each_cast() do
				skill.want_break = true
				local step = skill._current_step
				if step and skill['break_' .. step] == 1 then
					if step == '_cast_finish' or order == 'stop' then
						skill:stop()
					end
				end
			end
			return
		end
		if not hero._order_skills then
			return
		end
		local skill = hero._order_skills[order]
		if skill then
			if not hero._ignore_order_list then
				hero._ignore_order_list = {}
			end
			local list = hero._ignore_order_list
			if hero:has_restriction '硬直' then
				table.insert(list, order)
			else
				local len = #list
				for i = 1, len do
					if order == list[i] then
						list[i] = list[len]
						list[len] = nil
						return false
					end
				end
			end
			
			if skill.target_type == skill.TARGET_TYPE_UNIT and target.type == 'point' then
				-- 对视野外的建筑物发布了单位目标指令
				return
			end
			if not skill:is_in_range(target) then
				skill:set('_out_range_target', target)
				return
			end
			skill:cast_by_client(target)
		end
	end)

	local j_trg = war3.CreateTrigger(function()
		local hero = unit.j_unit(jass.GetTriggerUnit())
		local ability_id = base.id2string(jass.GetSpellAbilityId())
		local skill
		for skl in hero:each_skill() do
			if skl.ability_id == ability_id then
				skill = skl
				break
			end
		end
		if not skill then
			return
		end
		local out_target = skill._out_range_target
		if not out_target then
			return
		end
		skill:set('_out_range_target', nil)
		local target = ac.unit(jass.GetSpellTargetUnit()) or ac.point(jass.GetSpellTargetX(), jass.GetSpellTargetY())
		if out_target.type ~= target.type then
			return
		end
		if out_target.type == 'unit' then
			if out_target ~= target then
				return
			end
		else
			if out_target * target ~= 0 then
				return
			end
		end
		skill:cast_by_client(target)
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, ac.player[i].handle, jass.EVENT_PLAYER_UNIT_SPELL_CHANNEL, nil)
	end

	--每秒刷新技能说明
	ac.game:event '玩家-注册英雄' (function(trg, player, hero)
		ac.timer(1000, 0, function()
			hero:show_fresh()
		end)
	end)

	ac.skill = setmetatable({}, {__index = function(self, name)
		self[name] = {}
		setmetatable(self[name], skill)
		self[name].name = name
		init_skill(self[name])
		return self[name]
	end})
end

init()

--保存技能数据
function skill:__call(data)
	self.data = data
	for k, v in pairs(data) do
		self[k] = v
	end
	self.has_inited = false
	init_skill(self)
	return self
end

return skill
