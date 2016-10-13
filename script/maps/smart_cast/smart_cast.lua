--本地命令
local japi = require 'jass.japi'
local message = require 'jass.message'
if not message then
	return
end

local keyboard = message.keyboard
local jass = require 'jass.common'
local unit = require 'types.unit'
local order_id = require 'war3.order_id'
local table = table
local ipairs = ipairs

local ORDER_STOP   = order_id['stop']
local ORDER_ATTACK = order_id['attack']
local ORDER_HOLD   = order_id['holdposition']
local ORDER_SMART  = order_id['smart']

local FLAG_QUEUE   = 2 ^ 0
local FLAG_INSTANT = 2 ^ 1
local FLAG_SINGLE  = 2 ^ 2
local FLAG_RESUME  = 2 ^ 5
local FLAG_FAIL	= 2 ^ 8

if not base.release then
	--message.order_enable_debug()
end

local function get_select()
	return unit.j_unit(message.selection())
end

--技能是否开启了智能施法
local function get_smart_cast_type(name)
	local hero = ac.player.self.hero
	if not hero then
		return 0
	end
	local skl = hero:find_skill(name, '英雄')
	if skl and hero.smart_cast_type and hero.smart_cast_type[skl.slotid] then
		return hero.smart_cast_type[skl.slotid]
	end
	return 0
end

--是否是目标选择界面
local function is_select_ui()
	--检查右下角是不是取消键
	local ability, order = message.button(3, 2)
	return order == 0xD000B
end

--是否是魔法书界面
local function is_book_ui()
	--检查右下角是不是返回键
	local ability, order = message.button(3, 2)
	return order == 0xD0007
end

--技能是否可以点击
local function can_cast(name)
	local hero = ac.player.self.hero
	if not hero then
		return false
	end
	--找到英雄的技能
	local skl = hero:find_skill(name)
	if not skl then
		return false
	end
	return skl:can_order()
end

-- 寻找目标
local function find_target(skill, x, y)
	--筛选出单位
	local target = ac.point(x, y)
	local g = ac.selector()
		: in_range(target, 200)
		: add_filter(base.target_filter(skill.owner, skill.target_data, true))
		: sort_nearest_type_hero(target)
		: get()
	return g[1]
end

-- 是否可以发动
local function on_can_order(skill, target)
	if not skill.on_can_order then
		return true
	end
	local suc, msg = skill:on_can_order(target)
	if suc then
		return true
	end
	if msg then
		skill.owner:get_owner():sendMsg('|cffffcc00' .. msg .. '|r', 3)
	end
	return false
end

local last_skill
local save_last_skill
local clean_last_skill

--使用技能
local function cast_spell(msg, hero, name, force)
	--找到英雄的技能
	local skl = hero:find_skill(name)
	if not skl then
		return false
	end
	-- 不是通魔则返回
	if skl:get_slk 'Order' ~= 'channel' then
		return false
	end
	-- 鼠标当前指向的位置
	local x, y = message.mouse()
	local order = skl:get_slk 'DataF1'
	local order_id = order_id[order]
	local flag = 0
	if skl.break_order == 0 then
		flag = flag + FLAG_RESUME
	end
	--print(order, ('%X'):format(order_id))
	if skl.target_type == ac.skill.TARGET_TYPE_POINT then
		if (x == 0 and y == 0) or (not force and get_smart_cast_type(name) ~= 1) then
			save_last_skill(msg, hero, name)
			return false
		end
		local target = ac.point(x, y)
		if not on_can_order(skl, target) then
			return true
		end
		clean_last_skill()
		if skl:is_in_range(target) then
			flag = flag + FLAG_INSTANT
		end
		message.order_point(order_id, x, y, flag)
		return true
	elseif skl.target_type == ac.skill.TARGET_TYPE_NONE then
		clean_last_skill()
		message.order_immediate(order_id, flag + FLAG_INSTANT)
		return true
	else
		if (x == 0 and y == 0) or (not force and get_smart_cast_type(name) ~= 1) then
			save_last_skill(msg, hero, name)
			return false
		end
		local target = find_target(skl, x, y)
		if target or skl.target_type == ac.skill.TARGET_TYPE_UNIT_OR_POINT then
			local target = target or ac.point(x, y)
			if not on_can_order(skl, target) then
				return true
			end
			clean_last_skill()
			if skl:is_in_range(target) then
				flag = flag + FLAG_INSTANT
			end
			message.order_target(order_id, x, y, target and target.handle or 0, flag)
			return true
		end
	end
	if get_smart_cast_type(name) == 1 then
		return true
	end
	save_last_skill(msg, hero, name)
	return false
end

--保存上个技能的状态
function save_last_skill(msg, hero, name)
	function last_skill(code)
		--print('last_skill', hero == get_select())
		if hero ~= get_select() then
			clean_last_skill()
			return false
		end
		--检查是不是处于目标选择界面
		if not is_select_ui() then
			clean_last_skill()
			return false
		end
		if code and (code ~= msg.code or get_smart_cast_type(name) ~= 2) then
			return false
		end
		if cast_spell(msg, hero, name, true) then
			return true
		end
		return false
	end
end

--清除上个技能
function clean_last_skill()
	if not last_skill then
		return false
	end
	last_skill = nil
	jass.ForceUICancel()
	return true
end

--是否选中了英雄
local function is_select_hero()
	local hero = unit.j_unit(message.selection())
	--是不是自己的英雄
	if hero and hero == ac.player.self.hero then
		return hero
	end
	return false
end

--是否选中了商店
local function is_select_shop()
	local shop = unit.j_unit(message.selection())
	--是不是自己的英雄
	if shop and shop == ac.player.self.shop then
		return true
	end
	return false
end

--是否选中了自己的单位
local function is_select_player_unit()
	local u = unit.j_unit(message.selection())
	--是不是自己的英雄
	if u and u:get_owner() == ac.player.self then
		return true
	end
	return false
end

--是否选中了可操作的单位
local function is_select_off_line_hero()
	local u = unit.j_unit(message.selection())
	if not u then
		return false
	end
	if not u:is_hero() then
		return false
	end
	if u == ac.player.self.hero then
		return false
	end
	local p = u:get_owner()
	return jass.GetPlayerAlliance(p.handle, ac.player.self.handle, 6) and u
end

--选择英雄
local function select_hero()
	local hero = is_select_hero()
	if hero then
		return hero
	end
	--否则将选择切回自己的英雄
	local hero = ac.player.self.hero
	if hero then
		--jass.SelectUnit(hero.handle, true)
		ac.player.self:selectUnit(hero)
		return is_select_hero()
	end					
	return false
end

--镜头锁定英雄
local function lock_hero(flag)
	if flag then
		local hero = ac.player.self.hero
		if hero then
			jass.SetCameraTargetController(hero.handle, 0, 0, false)
		end
	else
		local p = ac.player.self
		jass.SetCameraPosition(jass.GetCameraTargetPositionX(), jass.GetCameraTargetPositionY())
	end
end

--本地消息
function message.hook(msg)

	--键盘按下消息
	if msg.type == 'key_down' then
		local code = msg.code
		local state = msg.state
		
		--技能快捷键
		for name, key in ipairs{'Q', 'W', 'E', 'R'} do
			if code == keyboard[key] then
				if state == 0 and is_select_shop() then
					return true
				end

				local hero = is_select_off_line_hero() or select_hero()
				if not hero then
					return true
				end

				--判断组合键
				if state == 2 then
					local name = '学习技能' .. name
					--按下了ctrl键,学习技能
					if not can_cast(name) then
						return false
					end
					if cast_spell(msg, hero, name) then
						return false
					end
				end

				--判断是否是组合键
				if state == 0 then
					if is_book_ui() then
						return true
					end
					local skill = hero:find_skill(name, '英雄')
					if not skill then
						return false
					end
					local name = skill.name
					if not can_cast(name) then
						return false
					end
					
					if cast_spell(msg, hero, name) then
						return false
					end
				end

				return true
			end
		end

		--如果是组合键,则跳过
		if state ~= 0 then
			return true
		end

		--停止键
		if code == keyboard['S'] then
			if not is_select_player_unit() and not is_select_hero() and not is_select_off_line_hero() and not select_hero() then
				return true
			end

			message.order_immediate(ORDER_STOP, FLAG_INSTANT)
		end

		--攻击键
		if code == keyboard['A'] then
			if is_select_player_unit() then
				return true
			end
			
			if is_select_hero() then
				return true
			end

			if is_select_off_line_hero() then
				return true
			end

			if select_hero() then
				local x, y = message.mouse()
				if x == 0 and y == 0 then
					return false
				end
				message.order_target(ORDER_ATTACK, x, y, 0, FLAG_INSTANT)
				message.order_target(ORDER_ATTACK, x, y, 0, 0)
				return false
			end

			return true
		end

		--回城键
		if code == keyboard['B'] then
			local hero = is_select_off_line_hero() or select_hero()
			if not hero then
				return true
			end

			--本地发布技能指令
			if cast_spell(msg, hero, '回城') then
				return false
			end
			
			return true
		end

		--空格
		if code == 32 then
			select_hero()
			lock_hero(true)
			return false
		end

		--tab
		if code == 515 then
			if poi.multiboard then
				poi.multiboard:minimize(false)
			end
			return false
		end
	end

	--键盘放开消息
	if msg.type == 'key_up' then
		local code = msg.code
		
		--如果是组合键,则跳过
		local state = msg.state
		if state ~= 0 then
			return true
		end
		
		--空格
		if code == 32 then
			lock_hero(false)
			return false
		end

		--tab
		if code == 515 then
			if poi.multiboard then
				poi.multiboard:minimize(true)
			end
			return false
		end
		
		if last_skill then
			last_skill(code)
		end
	end
	
	--鼠标按下消息
	if msg.type == 'mouse_down' then
		local code = msg.code

		-- 鼠标左键按下
		if code == 1 then
			if last_skill then
				return not last_skill()
			end
			return true
		end

		-- 鼠标右键按下
		if code == 4 then
			if clean_last_skill() then
				return true
			end
			if is_select_off_line_hero() then
				return true
			end
			if is_select_shop() or not is_select_player_unit() then
				select_hero()
			end
			local x, y = message.mouse()
			message.order_target(ORDER_SMART, x, y, 0, FLAG_INSTANT)
			return true
		end
	end

	--鼠标技能消息
	if msg.type == 'mouse_ability' then
		local code = msg.code
		local order = msg.order
		local ability = msg.ability
		local name = base.id2string(ability)
		-- 鼠标左键按下
		if code == 1 then
			if ability == 0 then
				return true
			end

			if is_select_shop() then
				return true
			end

			if is_book_ui() then
				return true
			end
			local hero = get_select()
			for skill in hero:each_skill() do
				if skill.ability_id == name then
					name = skill.name
					break
				end
			end
			if not can_cast(name) then
				return false
			end
			
			if cast_spell(msg, get_select(), name) then
				return false
			end
		end
	end
	
	return true
end
