
local jass = require 'jass.common'
local japi = require 'jass.japi'
local slk = require 'jass.slk'
local dbg = require 'jass.debug'
local player = require 'ac.player'
local rect = require 'types.rect'
local effect = require 'types.effect'
local move = require 'types.move'
local game = require 'types.game'
local order2id = require 'war3.order_id'
local damage = require 'types.damage'
local math = math
local ignore_flag = false
local table_insert = table.insert
local table_remove = table.remove

local last_summoned_unit

local unit = {}
setmetatable(unit, unit)
ac.unit = unit

function unit:__tostring()
    local player = self:get_owner()
    return ('%s|%s|%s'):format('unit', self:get_name(), player.base_name)
end

--结构
local mt = {}
unit.__index = mt

--类型
mt.type = 'unit'

--单位类型
mt.unit_type = 'unit'

--句柄
mt.handle = 0

--所有者
mt.owner = nil

--存活
mt._is_alive = true

--技能点
mt.skill_points = 0

--技能
mt.skills = nil

--造成伤害的倍率(%)
mt.damage_rate = 100

--受到伤害的倍率(%)
mt.damaged_rate = 100

--家当
mt.gold = 0

--选取半径
mt.selected_radius = 16

--单位计时器
mt._timers = nil

--已暂停时间
mt.paused_clock = 0

--上一次暂停开始的时间
mt.last_pause_clock = 0

--系数
mt.proc = 1

--获得所有者
function mt:get_owner()
	return self.owner
end

--注册单位事件
function mt:event(name)
	return ac.event_register(self, name)
end

local ac_game = ac.game

--发起事件
function mt:event_dispatch(name, ...)
	local res = ac.event_dispatch(self, name, ...)
	if res ~= nil then
		return res
	end
	local player = self:get_owner()
	if player then
		local res = ac.event_dispatch(player, name, ...)
		if res ~= nil then
			return res
		end
	end
	local res = ac.event_dispatch(ac_game, name, ...)
	if res ~= nil then
		return res
	end
	return nil
end

function mt:event_notify(name, ...)
	ac.event_notify(self, name, ...)
	local player = self:get_owner()
	if player then
		ac.event_notify(player, name, ...)
	end
	ac.event_notify(ac_game, name, ...)
end

--id
mt.id = ''

--获得单位id
function mt:get_type_id()
	return self.id
end

function mt:is_type(type)
	return self.unit_type == type
end

--是否是英雄
function mt:is_hero()
	return self.unit_type == '英雄' and not self._is_illusion
end

function mt:is_illusion()
	return self._is_illusion
end

--是否是马甲单位
function mt:is_dummy()
	return self._is_dummy
end

--获得名字
function mt:get_name()
    return self.name or self:get_slk 'Propernames' or self:get_slk 'Name'
end

--获取物编数据
--	数据项名称
--	[如果未找到,返回的默认值]
function mt:get_slk(name, default)
	local unit_data = slk.unit[self.id]
	if not unit_data then
		log.error('单位数据未找到', self.id)
		return default
	end
	local data = unit_data[name]
	if data == nil then
		return default
	end
	if type(default) == 'number' then
		return tonumber(data) or default
	end
	return data
end

--自定义数据
	mt.user_data = nil

	--保存数据
	--	索引
	--	值
	function mt:set_data(key, value)
	    if not self.user_data then
	        self.user_data = {}
	    end
		self.user_data[key] = value
	end

	--获取数据
	--	索引
	function mt:get_data(key)
	    if not self.user_data then
	        self.user_data = {}
	    end
		return self.user_data[key]
	end

--死亡	
	--杀死单位
	--	[致死伤害]
	function mt:kill(killer)
	    if not self:is_alive() then
		    return false
	    end
	    
		if not killer then
			killer = self
		end

		self._is_alive = false
		self:set('生命', 0)
		
		if not self:is_dummy() then
			jass.KillUnit(self.handle)
			killer:event_notify('单位-杀死单位', killer, self)
			self:event_notify('单位-死亡', self, killer)
		end

		--打断施法
		self:cast_stop()
		--删除Buff
		if self.buffs then
			local buffs = {}
			for bff in pairs(self.buffs) do
				if not bff.keep then
					buffs[#buffs + 1] = bff
				end
			end
			for i = 1, #buffs do
				buffs[i]:remove()
			end
		end
		if self:is_illusion() then
			self:remove()
		elseif not self:is_hero() then
			self:wait_to_remove()
		end
		return true
	end

	--删除单位
	function mt:remove()
		if self.removed then
			return
		end
		self.removed = true
		
		self._last_point = ac.point(jass.GetUnitX(self.handle), jass.GetUnitY(self.handle))
		self:event_notify('单位-移除', self)

		self:removeAllEffects()

		--移除单位的所有Buff
		if self.buffs then
			local buffs = {}
			for bff in pairs(self.buffs) do
				buffs[#buffs + 1] = bff
			end
			for i = 1, #buffs do
				buffs[i]:remove()
			end
		end
		
		--移除单位的所有技能
		for skill in self:each_skill() do
			skill:remove()
		end

		--移除单位身上的物品
		for i = 1, 6 do
			local it = self:find_skill(i, '物品')
			if it then
				it:remove()
			end
		end

		--移除单位身上的计时器
		if self._timers then
			for i, t in ipairs(self._timers) do
				t:remove()
			end
		end

		ignore_flag = true
		jass.RemoveUnit(self.handle)
		ignore_flag = false
		
		--从表中删除单位
		unit.all_units[self.handle] = nil

		unit.removed_units[self] = self
		dbg.handle_unref(self.handle)
	end

--是否存活
	--是否存活
	function mt:is_alive()
		return not self.removed and self._is_alive
	end

--队伍
	--获得单位的队伍
	function mt:get_team()
		return self:get_owner():get_team()
	end

	--是否是友方
	--	对象
	function mt:is_ally(dest)
		return self:get_team() == dest:get_team()
	end

	--是否是敌人
	--	对象
	function mt:is_enemy(dest)
		return self:get_team() ~= dest:get_team()
	end

--位置
	--上一个位置
	mt._last_point = nil

	--获取位置
	function mt:get_point()
		if self._dummy_point then
			return self._dummy_point
		end
		if self.removed then
			return self._last_point:copy()
		else
			return ac.point(jass.GetUnitX(self.handle), jass.GetUnitY(self.handle))
		end
	end

	--设置位置
	function mt:setPoint(point)
		if self:has_restriction '禁锢' then
			return false
		end
		local x, y = point:get()
		jass.SetUnitX(self.handle, x)
		jass.SetUnitY(self.handle, y)
		if self._dummy_point then
			self._dummy_point[1] = x
			self._dummy_point[2] = y
		end
		return true
	end

	--移动单位到指定位置(检查碰撞)
	--	移动目标
	--	[无视地形阻挡]
	--	[无视地图边界]
	function mt:set_position(where, path, super)
		if self:has_restriction '禁锢' then
			return false
		end
		if where:get_point():is_block(path, super) then
			return false
		end
		local x, y = where:get_point():get()
		local x1, y1, x2, y2 = rect.map:get()
		if x < x1 then
			x = x1
		elseif x > x2 then
			x = x2
		end
		if y < y1 then
			y = y1
		elseif y > y2 then
			y = y2
		end
		self:setPoint(ac.point(x, y))
		return true
	end

	--传送到指定位置
	--	[无视地形]
	function mt:blink(target, path, not_stop)
		local source = self:get_point()
		if self:set_position(target, path) then
			self:event_notify('单位-传送完成', self, source, target)
		end
		if not not_stop then self:issue_order 'stop' end
	end

	--获取出生点
	function mt:getBornPoint()
		return self.born_point
	end

--是否在指定位置附近(计算碰撞)
function mt:is_in_range(p, radius)
	return self:get_point() * p:get_point() - self:get_selected_radius() <= radius
end

--高度
	mt.high = 0
	
	--获取高度
	--	[是否是绝对高度(地面高度+飞行高度)]
	function mt:get_high(b)
		if b then
			return self:get_point():getZ() + self.high
		else
			return self.high
		end
	end

	--设置高度
	--	高度
	--	[是否是绝对高度]
	function mt:set_high(high, b, change_time)
		if b then
			self.high = high - self:get_point():getZ()
		else
			self.high = high
		end
		if not self:has_restriction '阿卡林' then
			jass.SetUnitFlyHeight(self.handle, self.high, change_time or 0)
		end
	end

	--增加高度
	--	高度
	--	[是否是绝对高度]
	function mt:add_high(high, b)
		self:set_high(self:get_high(b) + high)
	end

--朝向
	--获得朝向
	function mt:get_facing()
		if self._dummy_angle then
			return self._dummy_angle
		end
		return jass.GetUnitFacing(self.handle)
	end

	--设置朝向
	--	朝向
	--  瞬间转身
	function mt:set_facing(angle, instant)
    	if instant then
        	japi.EXSetUnitFacing(self.handle, angle)
    	else
		    jass.SetUnitFacing(self.handle, angle)
    	end
		if self._dummy_angle then
			self._dummy_angle = angle
		end
	end

--大小
	mt.size = 1
	mt.default_size = nil
	
	--设置大小
	--	大小
	function mt:set_size(size)
		self.size = size
		if not self.default_size then
			self.default_size = tonumber(self:get_slk 'modelScale') or 1
		end
		size = size * self.default_size
		jass.SetUnitScale(self.handle, size, size, size)
	end

	--获取大小
	function mt:get_size()
		return self.size
	end

	--增加大小
	--	大小
	function mt:addSize(size)
		size = size + self:get_size()
		self:set_size(size)
	end

--属性
	--近战
		mt.melee = nil
		--弹道
		mt.missile_art = nil
        --弹道速度
        mt.missile_speed = nil

		--是否是近战
		--	默认值
		function mt:isMelee(default)
			if default then
				local art = self.missile_art or (self.weapon and self.weapon['弹道模型']) or self:get_slk 'Missileart_1'
				return not art or art == '' or art == '.mdl' or art == '.mdx'
			else
                if self.melee == nil then
					self.melee = self:isMelee(true)
				end

				return self.melee
			end
		end

		--设置单位是否是近战
		--	近战
		function mt:setMelee(b)
			self.melee = b
		end

	--获取技能的冷却(经过冷却缩减和冷却加速计算)
	function mt:getSkillCool(cool)
		local cool = cool or 0
		--先计算冷却缩减
		cool = cool * (1 - self:get '冷却缩减' / 100)
		--再计算冷却加速
		local cs = self:get '攻击速度' / 2
		if cs > 0 then
			--每点加速视为技能频率加快1%
			cool = cool / (1 + cs / 100)
		elseif cs < 0 then
			--每点负加速视为技能间隔增加1%
			cool = cool * (1 - cs / 100)
		end
		return cool
	end

	--刷新所有技能的冷却
	function mt:fresh_cool()
		local t = {}
		for skl in self:each_skill() do
			local f = skl:fresh_cool()
			table.insert(t, f)
		end
		return function()
			for _, f in ipairs(t) do
				f()
			end
		end
	end
	
	function mt:fresh_cost()
		return function()
			for skl in self:each_skill() do
				skl:set_cost()
			end
		end
	end

--等级
	mt.level = 1

	--设置等级
	--	等级
    function mt:set_level(lv)
    	if lv > self.level then
        	jass.SetHeroLevel(self.handle, lv, self:is_hero())
    	end
    end

	--获取等级
    function mt:get_level()
		return self.level
	end

--技能(War3)
	--添加技能
	--	技能id
	--	技能等级
	function mt:add_ability(sid, lv)
		if not sid then
			return false
		end
		local id = base.string2id(sid)
		if not jass.UnitAddAbility(self.handle, id) then
			return false
		end
		if lv then
			jass.SetUnitAbilityLevel(self.handle, id, lv)
		end
		self:makePermanent(sid)
		return true
	end

	--移除技能
	--	技能id
	function mt:remove_ability(ability_id)
		if not ability_id then
			return false
		end
		local ability_id = base.string2id(ability_id)
		return jass.UnitRemoveAbility(self.handle, ability_id)
	end

	--允许技能
	--	技能id
	function mt:enable_ability(ability_id)
		self:get_owner():enable_ability(ability_id)
	end

	--禁用技能
	--	技能id
	function mt:disable_ability(ability_id)
		self:get_owner():disable_ability(ability_id)
	end

	--获取技能等级
	--	技能id
	function mt:getAbilityLevel(ability_id)
		local ability_id = base.string2id(ability_id)
		return jass.GetUnitAbilityLevel(self.handle, ability_id)
	end

	--设置技能等级
	--	技能id
	--	[技能等级]
	function mt:setAbilityLevel(ability_id, lv)
		local ability_id = base.string2id(ability_id)
		jass.SetUnitAbilityLevel(self.handle, ability_id, lv or 1)
	end

	--命令单位使用技能
	--	技能id
	--	[目标]
	function mt:castAbility(ability_id, target)
		local order = slk.ability[ability_id].Order
		if not target then
			return jass.IssueImmediateOrder(self.handle, order)
		elseif target.owner then
			return jass.IssueTargetOrder(self.handle, order, target.handle)
		else
			return jass.IssuePointOrder(self.handle, order, target:get_point():get())
		end
	end

	--设置技能永久性
	--	技能id
	function mt:makePermanent(ability_id)
		if not ability_id then
			return
		end
		local ability_id = base.string2id(ability_id)
		jass.UnitMakeAbilityPermanent(self.handle, true, ability_id)
	end

--命令
	mt.script_order = false
	
	--发布命令
	--	命令
	--	[目标]
	function mt:issue_order(order, target)
		local res
		self.script_order = true
		if not target then
			res = jass.IssueImmediateOrder(self.handle, order)
		elseif target.owner then
			res = jass.IssueTargetOrder(self.handle, order, target.handle)
		else
			local x, y
			if target.type == 'point' then
				x, y = target:get()
			else
				x, y = target:get_point():get()
			end
			res = jass.IssuePointOrder(self.handle, order, x, y)
		end
		self.script_order = false
		return res
	end

	local id2order = setmetatable({}, {__index = function(self, k)
		log.info('OrderId2String', k)
		local order = jass.OrderId2String(k)
		if order then
			log.error(('%s = 0x%X,'):format(order, k))
			self[k] = order
		else
			self[k] = ''
		end
		return order
	end})
	for k, v in pairs(order2id) do
		id2order[v] = k
	end
	
	--获得命令
	--	@命令
	function mt:getOrder()
		local order = jass.GetUnitCurrentOrder(self.handle)
		return id2order[order], order
	end

	--获取单位的碰撞体积
	function mt:get_collision()
		return self:get_slk('collision', 0)
	end

	--获取单位的选取半径
	function mt:get_selected_radius()
		return self.selected_radius
	end

	function mt:clock()
		if self:has_restriction '时停' then
			return self.last_pause_clock - self.paused_clock
		else
			return ac.clock() - self.paused_clock
		end
	end

function mt:follow(data)
	data.target = self
	return ac.follow(data)
end

mt.pause_timer_count = 0

--暂停单位计时器
function mt:pause_timer(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_timer_count = self.pause_timer_count + 1
		if self.pause_timer_count == 1 and self._timers then
			for _, t in ipairs(self._timers) do
				t:pause()
			end
		end
	else
		if self.pause_timer_count == 0 then
			log.error '计数错误'
			return
		end
		self.pause_timer_count = self.pause_timer_count - 1
		if self.pause_timer_count == 0 and self._timers then
			for _, t in ipairs(self._timers) do
				t:resume()
			end
		end
	end
end

function mt:is_pause_timer()
	return self.pause_timer_count > 0
end

    --暂停buff
    mt.pause_buff_count = 0

    function mt:pause_buff(flag)
		if flag == nil then
			flag = true
		end
		if flag then
			self.pause_buff_count = self.pause_buff_count + 1
			if self.pause_buff_count == 1 then
				if self.buffs then
					for buff in pairs(self.buffs) do
						buff:pause(true)
					end
				end
			end
		else
			if self.pause_buff_count == 0 then
				log.error '计数错误'
				return
			end
			self.pause_buff_count = self.pause_buff_count - 1
			if self.pause_buff_count == 0 then
				if self.buffs then
					for buff in pairs(self.buffs) do
						buff:pause(false)
					end
				end
			end
		end
	end

	--判断是否暂停
	function mt:is_pause_buff()
		return self.pause_buff_count > 0
	end

	--暂停技能
    mt.pause_skill_count = 0

    function mt:pause_skill(flag)
		if flag == nil then
			flag = true
		end
		if flag then
			self.pause_skill_count = self.pause_skill_count + 1
			if self.pause_skill_count == 1 then
				for skill in self:each_skill() do
					skill:pause(true)
				end
			end
		else
			if self.pause_skill_count == 0 then
				log.error '计数错误'
				return
			end
			self.pause_skill_count = self.pause_skill_count - 1
			if self.pause_skill_count == 0 then
				for skill in self:each_skill() do
					skill:pause(false)
				end
			end
		end
	end

	--判断是否暂停
	function mt:is_pause_skill()
		return self.pause_skill_count > 0
	end

	--暂停运动
    mt.pause_mover_count = 0

    function mt:pause_mover(flag)
		if flag == nil then
			flag = true
		end
		if flag then
			self.pause_mover_count = self.pause_mover_count + 1
			if self.pause_mover_count == 1 and self.movers then
				for mover in pairs(self.movers) do
					mover:pause(true)
				end
			end
		else
			if self.pause_mover_count == 0 then
				log.error '计数错误'
				return
			end
			self.pause_mover_count = self.pause_mover_count - 1
			if self.pause_mover_count == 0 and self.movers then
				for mover in pairs(self.movers) do
					mover:pause(false)
				end
			end
		end
	end

	--判断是否暂停
	function mt:is_pause_mover()
		return self.pause_mover_count > 0
	end

--颜色
	mt.red = 100
	mt.green = 100
	mt.blue = 100
	mt.alpha = 100

	--设置单位颜色
	--	[红(%)]
	--	[绿(%)]
	--	[蓝(%)]
	function mt:setColor(red, green, blue)
		self.red, self.green, self.blue = red, green, blue
		jass.SetUnitVertexColor(
			self.handle,
			self.red * 2.55,
			self.green * 2.55,
			self.blue * 2.55,
			self.alpha * 2.55
		)
	end

	--设置单位透明度
	--	透明度(%)
	function mt:setAlpha(alpha)
		self.alpha = alpha
		jass.SetUnitVertexColor(
			self.handle,
			self.red * 2.55,
			self.green * 2.55,
			self.blue * 2.55,
			self.alpha * 2.55
		)
	end

	--获取单位透明度
	function mt:getAlpha()
		return self.alpha
	end

--动画
	--设置单位动画
	--	动画名或动画序号
	function mt:set_animation(ani)
		if not self:is_alive() then
			return
		end
		if type(ani) == 'string' then
			jass.SetUnitAnimation(self.handle, self.animation_properties .. ani)
		else
			jass.SetUnitAnimationByIndex(self.handle, ani)
		end
	end

	--将动画添加到队列
	--	动画序号
	function mt:add_animation(ani)
		if not self:is_alive() then
			return
		end
		jass.QueueUnitAnimation(self.handle, ani)
	end

	--设置动画播放速度
	--	速度
	function mt:set_animation_speed(speed)
		jass.SetUnitTimeScale(self.handle, speed)
	end

	mt.animation_properties = ''

	--添加动画附加名
	--	附加名
	function mt:add_animation_properties(name)
		jass.AddUnitAnimationProperties(self.handle, name, true)
		self.animation_properties = self.animation_properties .. name .. ' '
	end

	--移除动画附加名
	--	附加名
	function mt:remove_animation_properties(name)
		jass.AddUnitAnimationProperties(self.handle, name, false)
		self.animation_properties = self.animation_properties:gsub(name .. ' ', '')
	end

--视野
	--是否可见
	--	对象
	function mt:is_visible(dest)
		if dest.type ~= 'player' then
			dest = dest:get_owner()
		end
		return jass.IsUnitVisible(self.handle, dest.handle)
	end

	--设置索敌范围
	function mt:set_search_range(r)
		jass.SetUnitAcquireRange(self.handle, r)
	end

	--添加单位视野(依然不能超过1800)
	function mt:addSight(r)
		self:add_ability 'A007'
		local handle = japi.EXGetUnitAbility(self.handle, base.string2id 'A007')
		japi.EXSetAbilityDataReal(handle, 2, 108, - r)
		self:setAbilityLevel('A007', 2)
		self:remove_ability 'A007'
	end

--特效
	--创建特效
	--	附加点
	--	模型路径
	function mt:add_effect(part, model)
		local j_eff = jass.AddSpecialEffectTarget(model, self.handle, part)
		dbg.handle_ref(j_eff)
		local eff = setmetatable({handle = j_eff}, effect)

		eff.model = model
		eff.unit = self
		eff.socket = part

		--存在单位身上
		if not self._effect_list then
			self._effect_list = {}
		end
		table.insert(self._effect_list, eff)

		return eff
	end

	function mt:effect(data)
		return ac.unit_effect(self, data)
	end

	--移除所有特效
	function mt:removeAllEffects()
		if self._effect_list then
			for i, eff in ipairs(self._effect_list) do
				jass.DestroyEffect(eff.handle)
				dbg.handle_unref(eff.handle)
				eff.handle = nil
				eff.removed = true
			end
			self._effect_list = nil
		end
	end

--获得金钱
--	金钱数量
--	[显示位置]
--	[不抛出加钱事件]
function mt:addGold(gold, where, flag)
	self:get_owner():addGold(gold, where or self, flag)
end

--添加敌我识别
mt.enemy_tag = nil

function mt:add_enemy_tag()
	if self.enemy_tag then
		self.enemy_tag:remove()
	end
	--敌我识别特效
	local str
	if self:is_ally(player.self) then
		str = [[modeldekan\ui\DEKAN_Tag_Ally.mdl]]
	else
		str = [[modeldekan\ui\DEKAN_Tag_Enmy.mdl]]
	end
	self.enemy_tag = self:add_effect('origin', str)
end

-- 设置所有者
function mt:set_owner(p, color)
	jass.SetUnitOwner(self.handle, p.handle, not not color)
end

--创建马甲
--	位置
--	朝向
function mt:create_dummy(id, where, face)
	local u = self:get_owner():create_dummy(id or self:get_type_id(), where, face)
	return u
end

--创建镜像
--	位置
--	朝向
--	不复制物品
function mt:create_illusion(p, no_item)
	local life = self:get '生命'
	self:set('生命', self:get '生命上限')
	ignore_flag = true
	jass.IssueTargetOrderById(ac.dummy.handle, 852274, self.handle)
	ignore_flag = false
	self:set('生命', life)
	if not last_summoned_unit then
		return
	end
	local handle = last_summoned_unit
	if not handle then
		return
	end
	dbg.handle_ref(handle)
	last_summoned_unit = nil
	jass.SetUnitOwner(handle, self:get_owner().handle, false)
	local dummy = unit.init_illusion(handle, self:get_owner())
	jass.SetUnitBlendTime(handle, dummy:get_slk('blend', 0))
	dummy:set_position(p, true, true)
	setmetatable(dummy, getmetatable(self))
	dummy.unit_type = self.unit_type
	dummy._is_illusion = true
	dummy:set_class(self:get_class())
	dummy.hero_data = self.hero_data
	if dummy:getAbilityLevel 'Aloc' == 0 then
		dummy:event_notify('单位-创建', dummy)
	end

	for k, v in pairs(self.hero_data.attribute) do
		dummy:set(k, v)
	end
	
	--复制等级
	for i = 1 + 1, self:get_level() do
		dummy:event_dispatch('单位-英雄升级', dummy)
	end

	--复制技能
	for skl in self:each_skill() do
		if not skl.never_copy then
			local skl2 = dummy:add_skill(skl.name, skl:get_type(), skl:get_slotid())
			skl2:set_level(skl:get_level(), false)
		end
	end

	--敌我识别标记
	dummy:add_enemy_tag()
	--当前生命值与魔法值
	dummy:set('生命', life)
	dummy:set('魔法', self:get '魔法')
	
	return dummy
end

--增加伤害倍率
function mt:addDamageRate(r)
	self.damage_rate = self.damage_rate + r
	if self.freshDamageInfo then
		self:freshDamageInfo()
	end
end

--获取伤害倍率
function mt:getDamageRate()
	return self.damage_rate
end

--增加受伤倍率
function mt:addDamagedRate(r)
	self.damaged_rate = self.damaged_rate + r
	if self.freshDefenceInfo then
		self:freshDefenceInfo()
	end
end

--获取受伤倍率
function mt:getDamagedRate()
	return self.damaged_rate
end

mt.last_active_time = -99999
mt.active = true 
--设置战斗状态
function mt:setActive(dest)
	self.last_active_time = self:clock()
	if not self.active then
		self.active = true
		self:event_notify('单位-进入战斗', self, dest)
	end
end

function mt:updateActive()
	if self.active then 
		if not self:isActive() then
			self.active = false
			self:event_notify('单位-脱离战斗', self)
		end
	end
end

--单位是否处于战斗状态
function mt:isActive()
	return self:clock() - self.last_active_time < 3000
end

--获取在节能施法后的耗蓝
--	原来的耗蓝
function mt:get_cost(mana)
	if mana <= 0 then
		return mana
	end
	local resource = ac.resource[self.resource_type]
	return mana - mana * self:get '减耗' / 100 * resource.get_cost_save_rate
end

--消耗法力
--	法力
--	@是否消耗成功
function mt:cost_mana(mana)
	local mana = self:get '魔法' - self:get_cost(mana)
	if mana < 0 then
		return false
	end
	if not ac.wtf then
		self:set('魔法', mana)
	end
	return true
end

--更新数据
function mt:update()
	if self:has_restriction '时停' then
		return
	end
	local life_recover, life_recover_idle = self:get '生命恢复', self:get '生命脱战恢复'
	local mana_recover, mana_recover_idle = self:get '魔法恢复', self:get '魔法脱战恢复'
	if not self.active then
		life_recover = life_recover + life_recover_idle
		mana_recover = mana_recover + mana_recover_idle
	end
	if life_recover ~= 0 then
		self:add('生命', life_recover / unit.frame)
	end
	if mana_recover ~= 0 then
		self:add('魔法', mana_recover / unit.frame)
	end
end

--共享视野
function mt:shareVisible(p, flag)
	jass.UnitShareVision(self.handle, p.handle, flag ~= false and true or false)
end

--创建单位(以单位为参照)
--	单位id
--	[位置(默认为参照单位)]
--	朝向
function mt:create_unit(id, where, face)
	if not where then
		where = self:get_point()
	end
	return self:get_owner():create_unit(id, where, face or self:get_facing())
end

local function init_unit(handle, p)
	if unit.all_units[handle] then
		return unit.all_units[handle]
	end
	if handle == 0 then
		return nil
	end
	local u = setmetatable({}, unit)
	dbg.gchash(u, handle)
	u.gchash = handle
	--保存到全局单位表中
	u.handle = handle
	u.id = base.id2string(jass.GetUnitTypeId(handle))
	u.owner = p or player[1 + jass.GetPlayerId(jass.GetOwningPlayer(handle))]
	u.born_point = u:get_point()
	unit.all_units[handle] = u

	--令物体可以飞行
	u:add_ability 'Arav'
	u:remove_ability 'Arav'

	--忽略警戒点
	jass.RemoveGuardPosition(u.handle)
	jass.SetUnitCreepGuard(u.handle, true)

	--设置高度
	u:set_high(u:get_slk('moveHeight', 0))

	if u:getAbilityLevel 'Aloc' ~= 0 then
		u:set_class '马甲'
	end

	return u
end

function unit.init_illusion(handle, p)
	local u = init_unit(handle, p)
	
	return u
end

function unit.init_unit(handle, p)
	if unit.all_units[handle] then
		return unit.all_units[handle]
	end
	local u = init_unit(handle, p)
	if not u then
		return nil
	end
	local data = ac.lni.unit[u:get_name()]
	if data then
		u.unit_type = data.type
		if data.attribute then
			for k, v in pairs(data.attribute) do
				u:set(k, v)
			end
		end
		if data.restriction then
			for _, v in ipairs(data.restriction) do
				u:add_restriction(v)
			end
		end
	end
	if u:getAbilityLevel 'Aloc' == 0 then
		u:event_notify('单位-创建', u)
	end
	if data then
		if data.hero_skill then
			for _, skl in ipairs(data.hero_skill) do
				u:add_skill(skl, '英雄')
			end
		end
		if data.hide_skill then
			for _, skl in ipairs(data.hide_skill) do
				u:add_skill(skl, '隐藏')
			end
		end
	end
	
	return u
end

--创建单位(以玩家为参照)
--	单位id
--	位置
--	[朝向]
function player.__index:create_unit(id, where, face)
	local data = ac.lni.unit[id]
	if data then
		id = data.id
	end
	local j_id = base.string2id(id)
	local x, y
	if where.type == 'point' then
		x, y = where:get()
	else
		x, y = where:get_point():get()
	end

	ignore_flag = true
	local handle = jass.CreateUnit(self.handle, j_id, x, y, face or 0)
	dbg.handle_ref(handle)
	ignore_flag = false
	local u = unit.init_unit(handle, self)

	return u
end

function player.__index:create_dummy(id, where, face)
	local id = id or self:get_type_id()
	local data = ac.lni.unit[id]
	if data then
		id = data.id
	end
	local j_id = base.string2id(id)
	local x, y
	if where.type == 'point' then
		x, y = where:get()
	else
		x, y = where:get_point():get()
	end

	local team = self:get_team()
	local owner = self
	if ac.player.com and ac.player.com[team] then
		owner = ac.player.com[team]
	end
	ignore_flag = true
	local handle = jass.CreateUnit(owner.handle, j_id, x, y, face or 0)
	dbg.handle_ref(handle)
	ignore_flag = false
	local u = unit.init_unit(handle, self)
	u._is_dummy = true
	u._dummy_point = ac.point(x, y)
	u._dummy_angle = face or 0
	if u:getAbilityLevel 'Aloc' == 0 then
		u:event_notify('单位-创建', u)
	end

	return u
end

--转换handle为单位
function unit.j_unit(handle)
	if not handle or handle == 0 then
		return
	end
	local u = unit.all_units[handle]
	if not u then
		if not ignore_flag then
			log.warn('没有被脚本控制的单位!', handle, base.id2string(jass.GetUnitTypeId(handle)), jass.GetUnitName(handle))
		end
		u = unit.init_unit(handle)
	end
	return u
end

function unit:__call(handle)
	return self.j_unit(handle)
end

require('ac.unit')(unit.j_unit)

mt.launch_distance = nil
mt.launch_angle = nil
mt.launch_z = nil

function mt:get_launch_point()
	if not self.launch_z then
		local weapon_launch = self.weapon and self.weapon['弹道出手']
		local x = weapon_launch and weapon_launch[1] or self:get_slk('launchX', 0)
		local y = weapon_launch and weapon_launch[2] or self:get_slk('launchY', 0)
		self.launch_z = weapon_launch and weapon_launch[3] or self:get_slk('launchZ', 0)
		self.launch_distance = math.sqrt(x * x + y * y)
		self.launch_angle = math.atan(y, x)
	end
	local p = self:get_point()
	local size = self:get_size()
	local angle = self:get_facing()
	local point = p - {angle + self.launch_angle, size * self.launch_distance}
	point[3] = size * self.launch_z
	return point
end

function mt:wait_to_remove()
	--将待删除的单位保存在1级表中
	table.insert(unit.wait_to_remove_table1, self)
end

function mt:melee_attack_start(data)
	self:attackDamage(data)
end

function mt:range_attack_start(data)
	--发射一个弹道
	local target = data.target
	local size = self:get_size()
	local start = self:get_launch_point()
	local speed = self.missile_speed or (self.weapon and self.weapon['弹道速度']) or self:get_slk('Missilespeed_1', 0)
	local arc = self.weapon and self.weapon['弹道弧度'] or self:get_slk('Missilearc_1', 0)
	local mover_data = ac.mover.target
	{
		source = self,
		start = start,
		target = target,
		path = true,
		speed = speed,
		model = self.missile_art or (self.weapon and self.weapon['弹道模型']) or self:get_slk 'Missileart_1',
		height = self:get_point() * target:get_point() * arc,
		damage = data.damage,
		size = size,
		skill = false,
		need_elevation = self:is_type('英雄'),
	}

	--弹道击中目标时造成伤害
	function mover_data:on_finish()
		if self.target:is_alive() then
			data.missile = mover_data.mover
			self.source:attackDamage(data)
		end
	end

	if speed <= 0 then
		mover_data.mover:set_position(target:get_point(), true)
		mover_data.mover:set_high(mover_data.target_high)
		mover_data:on_finish()
		mover_data:remove()
	end
end

--造成伤害
function mt:damage(data)
	data.target = self
	setmetatable(data, damage)
	return data()
end

--发动一次物理伤害
function mt:attackDamage(data)
	data.attack = true
	data.common_attack = true
	data.skill = data.skill or false
	setmetatable(data, damage)
	return data()
end

--进行一次攻击
function mt:attack_start(target, skill, attack_damage)
	if target:has_restriction '物免' then
		return false
	end
	local dmg = attack_damage or self:get '攻击'
	local data = self.last_attack_damage
	if skill or attack_damage or not data then
		data = {
			source = self,
			target = target,
			attack = true,
			common_attack = true,
			damage = dmg,
			skill = skill or false,
		}
		setmetatable(data, damage)
	end
	self.last_attack_damage = nil

	if self:event_dispatch('单位-发动攻击', data) then
		return false
	end
	
	data.source:event_notify('单位-攻击出手', data)
	data.target:event_notify('单位-被攻击出手', data)

	--如果是近战攻击,则直接造成伤害
	if self:isMelee() then
		self:melee_attack_start(data)
	else
		self:range_attack_start(data)
	end
	return true
end

mt._class = nil
mt._class_timer = nil

function mt:get_class()
	return self._class
end

function mt:set_class(class)
	if self._class == class then
		return
	end
	if class == '幻象' then
		if self._class ~= '马甲' then
			self:add_ability 'Aloc'
			self:add_restriction '无敌'
		end
		self._class = '幻象'
		-- 显示血条
		jass.ShowUnit(self.handle, false)
		jass.ShowUnit(self.handle, true)
		self._class_timer = self:loop(10, function()
			jass.SelectUnit(self.handle, false)
		end)
	elseif class == '马甲' then
		if self._class == '幻象' then
			if self._class_timer then
				self._class_timer:remove()
			end
			self:remove_ability 'Aloc'
			self:add_ability 'Aloc'
		else
			self:add_ability 'Aloc'
			self:add_restriction '无敌'
		end
		self._class = '马甲'
	end
end

-- 行为限制
local function restriction_move(unit, flag)
	if flag then
		jass.SetUnitMoveSpeed(unit.handle, 0)
	else
		jass.SetUnitMoveSpeed(unit.handle, unit:get '移动速度')
	end
end

local function restriction_attack(unit, flag)
	if flag then
		unit:add_ability 'Abun'
	else
		unit:remove_ability 'Abun'
	end
end

local function restriction_attacked(unit, flag)
	if flag then
		jass.UnitAddType(unit.handle, jass.UNIT_TYPE_ANCIENT)
	else
		jass.UnitRemoveType(unit.handle, jass.UNIT_TYPE_ANCIENT)
	end
end

local function restriction_spell(self, flag)
	for skill in self:each_skill() do
		if skill:is_visible() and not skill.passive and (skill:get_type() == '英雄' or skill:get_type() == '通用') then
			skill:fresh_art()
		end
	end
	self:show_fresh()
end

local function restriction_spelled(unit, flag)
end

local function restriction_dead(unit, flag)
end

local function restriction_stealth(unit, flag)
	if flag then
		unit:add_ability 'A00E'
	else
		unit:remove_ability 'A00E'
	end
end

local function restriction_hide(unit, flag)
	jass.ShowUnit(unit.handle, not flag)
end

local function restriction_akari(unit, flag)
	if flag then
		jass.SetUnitFlyHeight(unit.handle, 999999, 0)
	else
		jass.SetUnitFlyHeight(unit.handle, unit.high, 0)
	end
end

local function restriction_fly(unit, flag)
    if flag then
        japi.EXSetUnitMoveType(unit.handle, 4)
    else
    	if unit:has_restriction '幽灵' then
        	japi.EXSetUnitMoveType(unit.handle, 16)
		else
        	japi.EXSetUnitMoveType(unit.handle, 2)
    	end
    end
end

local function restriction_collision(unit, flag)
    if unit:has_restriction '飞行' then
        return
    end
	if flag then
        japi.EXSetUnitMoveType(unit.handle, 16)
	else
        japi.EXSetUnitMoveType(unit.handle, 2)
	end
end

local function restriction_stun(self, flag)
	if flag then
		self:add_restriction '硬直'
	else
		self:remove_restriction '硬直'
	end
end

local function restriction_time_pause(self, flag)
	if flag then
		self.last_pause_clock = ac.clock()
		self:add_restriction '硬直'
		self:pause_buff(true)
		self:pause_skill(true)
		self:pause_mover(true)
		self:pause_timer(true)
		self:setAlpha(self:getAlpha() - 50)
		ac.wait(0, function()
			self:set_animation_speed(0)
		end)
		self:set_facing(self:get_facing())
		self:event_notify('单位-时停开始', self)
	else
		self.paused_clock = self.paused_clock + ac.clock() - self.last_pause_clock
		self:setAlpha(self:getAlpha() + 50)
		self:set_animation_speed(1)
		self:pause_timer(false)
		self:pause_mover(false)
		self:pause_skill(false)
		self:pause_buff(false)
		self:remove_restriction '硬直'
		self:event_notify('单位-时停结束', self)
	end
end

local function restriction_hard(self, flag)
	if flag then
		if not self._ignore_order_list then
			self._ignore_order_list = {}
		end
		local order = self._current_issue_order
		if order and self._order_skills and self._order_skills[order] then
			table.insert(self._ignore_order_list, order)
		end
		japi.EXPauseUnit(self.handle, true)
	else
		japi.EXPauseUnit(self.handle, false)
		if self._recover_skill then
			local skill = self._recover_skill
			self._recover_skill = nil
			skill[1]:cast_by_client(skill[2])
		end
	end
end

local function restriction_god(self, flag)
	if flag then
		self:add_restriction '物免'
		self:add_restriction '魔免'
	else
		self:remove_restriction '物免'
		self:remove_restriction '魔免'
	end
end

local function restriction_constraint()
end

local restriction_type = {
	['定身']	= restriction_move,
	['缴械']	= restriction_attack,
	['物免']	= restriction_attacked,
	['禁魔']	= restriction_spell,
	['魔免']	= restriction_spelled,
	['免死']	= restriction_dead,
	['隐身']	= restriction_stealth,
	['隐藏']	= restriction_hide,
	['阿卡林']	= restriction_akari,
	['飞行']	= restriction_fly,
	['幽灵']	= restriction_collision,
	['蝗虫']	= false,
	['晕眩']	= restriction_stun,
	['时停']	= restriction_time_pause,
	['硬直']	= restriction_hard,
	['无敌']	= restriction_god,
	['禁锢']	= restriction_constraint,
}

function mt:add_restriction(name)
	if not restriction_type[name] then
		log.error('错误的限制类型', name)
		return 0
	end
	local res = self['限制']
	if not res then
		res = {}
		self['限制'] = res
	end
	res[name] = (res[name] or 0) + 1
	if res[name] == 1 and restriction_type[name] then
		restriction_type[name](self, true)
	end
	return res[name]
end

function mt:remove_restriction(name)
	if not restriction_type[name] then
		log.error('错误的限制类型', name)
		return 0
	end
	local res = self['限制']
	if not res then
		res = {}
		self['限制'] = res
	end
	res[name] = (res[name] or 0) - 1
	if res[name] == 0 and restriction_type[name] then
		restriction_type[name](self, false)
	end
	if res[name] == -1 then
		log.error('计数错误', name)
	end
	return res[name]
end

function mt:has_restriction(name)
	if not restriction_type[name] then
		log.error('错误的限制类型', name)
		return false
	end
	local res = self['限制']
	if not res then
		res = {}
		self['限制'] = res
	end
	return res[name] and res[name] > 0
end

function mt:event(name)
	return ac.event_register(self, name)
end

mt.wait = ac.uwait
mt.loop = ac.uloop
mt.timer = ac.utimer

function unit.registerJassTriggers()
	--单位发布指定目标事件
	local j_trg = war3.CreateTrigger(function()
		local u = unit.j_unit(jass.GetTriggerUnit())
		if not u then
			return
		end
		local player_order = not u.script_order
		u.script_order = false
		local order = jass.GetIssuedOrderId()
		if not u._current_issue_order then
			u._current_issue_order = id2order[order]
		end
		u:event_notify('单位-发布指令', u, id2order[order], unit.j_unit(jass.GetOrderTargetUnit()), player_order, order)
		u._current_issue_order = nil
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, nil)
	end

	--单位发布点目标事件
	local j_trg = war3.CreateTrigger(function()
		local u = unit.j_unit(jass.GetTriggerUnit())
		if not u then
			return
		end
		local player_order = not u.script_order
		u.script_order = false
		local order = jass.GetIssuedOrderId()
		if not u._current_issue_order then
			u._current_issue_order = id2order[order]
		end
		u:event_notify('单位-发布指令', u, id2order[order], ac.point(jass.GetOrderPointX(), jass.GetOrderPointY()), player_order, order)
		u._current_issue_order = nil
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, nil)
	end

	--单位发布无目标事件
	local j_trg = war3.CreateTrigger(function()
		local u = unit.j_unit(jass.GetTriggerUnit())
		if not u then
			return
		end
		local player_order = not u.script_order
		u.script_order = false
		local order = jass.GetIssuedOrderId()
		if not u._current_issue_order then
			u._current_issue_order = id2order[order]
		end
		u:event_notify('单位-发布指令', u, id2order[order], nil, player_order, order)
		u._current_issue_order = nil
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_ISSUED_ORDER, nil)
	end

	--单位开始攻击事件
	local j_trg = war3.CreateTrigger(function()
		local source = unit.j_unit(jass.GetAttacker())
		local target = unit.j_unit(jass.GetTriggerUnit())
		local dmg = source:get '攻击'
		source.last_attack_damage = {
			source = source,
			target = target,
			attack = true,
			common_attack = true,
			damage = dmg,
			skill = false,
		}
		setmetatable(source.last_attack_damage, damage)
		source.last_attack_damage:on_attribute_attack()
		source:event_notify('单位-攻击开始', source.last_attack_damage)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_ATTACKED, nil)
	end

	--单位丢弃物品事件
	local j_trg = war3.CreateTrigger(function()
		local it = ac.item.j_item(jass.GetManipulatedItem())
		if not it then
			return
		end
		it.owner:event_notify('单位-丢弃物品', it.owner, it)
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_DROP_ITEM, nil)
	end

	--单位出售物品事件
	local j_trg = war3.CreateTrigger(function()
		local it = ac.item.j_item(jass.GetSoldItem())
		if not it then
			return
		end
		it:sell()
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_PAWN_ITEM, nil)
	end

	--单位使用物品事件
	local j_trg = war3.CreateTrigger(function()
		local it = ac.item.j_item(jass.GetManipulatedItem())
		if it then
			it.target = it.owner.last_spell_target
			it.owner:event_notify('单位-使用物品', it.owner, it)
		end
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_USE_ITEM, nil)
	end
end

--保存地图上的预设单位
function unit.saveDefaultUnits()
	ignore_flag = true
	local group = ac.selector():allow_god():get()
	ignore_flag = false
	for _, u in ipairs(group) do
		dbg.handle_ref(u.handle)
		if u.unit_type == 'unit' then
			-- 预设单位没有普通单位，如果有，说明是误摆放的单位，或者是预设建筑没有识别
			log.error('未知的单位', u.handle, u.id, u:get_name())
		end
	end
end

--初始化
function unit.init()
	--全局单位索引
	unit.all_units = {}
	unit.removed_units = setmetatable({}, { __mode = 'kv' })

	--注册单位的jass事件
	unit.registerJassTriggers()

	--更新数据
	unit.frame = 8

	ac.loop(1000 / unit.frame, function()
		for _, u in pairs(unit.all_units) do
			u:update()
		end
	end)

	--单位移除队列
	unit.wait_to_remove_table1 = {}
	unit.wait_to_remove_table2 = {}
	ac.loop(5000, function()
		--遍历2级表来移除单位
		for _, u in ipairs(unit.wait_to_remove_table2) do
			u:remove '死亡'
		end
		--将1级表升级为2级表
		unit.wait_to_remove_table2 = unit.wait_to_remove_table1
		--创建新的1级表
		unit.wait_to_remove_table1 = {}
	end)

	--捕捉攻击伤害
	local j_trg = war3.CreateTrigger(function()
		if jass.GetEventDamage() == 1 then
			--认为是物理伤害
			local source = unit.j_unit(jass.GetEventDamageSource())
			local target = unit.j_unit(jass.GetTriggerUnit())
			--todo: 传一个普通攻击的技能
			source:attack_start(target, nil)
		end
	end)
	--每个单位创建时加入捕捉
	ac.game:event '单位-创建' (function(self, u)
		jass.TriggerRegisterUnitEvent(j_trg, u.handle, jass.EVENT_UNIT_DAMAGED)
	end)

	-- 创建一个dummy,用于使用马甲技能
	ac.dummy = player[16]:create_unit('e003', ac.point(0, 0), 0)
	
	-- 创建幻象
	ac.dummy:add_ability 'A01W'
	local j_trg = war3.CreateTrigger(function()
		last_summoned_unit = jass.GetSummonedUnit()
	end)
	for i = 0, 15 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, jass.Player(i), jass.EVENT_PLAYER_UNIT_SUMMON, nil)
	end
end

return unit
