
local slk = require 'jass.slk'
local game = require 'types.game'
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local skill = require 'ac.skill'
local table = table
local japi = require 'jass.japi'
local runtime = require 'jass.runtime'
local affix = require 'types.affix'
local setmetatable = setmetatable
local xpcall = xpcall
local select = select
local error_handle = runtime.error_handle

local item = {}
local mt = {}
ac.item = item

item.__index = mt
setmetatable(mt, skill)

--类型
mt.type = 'item'

--物品分类
mt.item_type = '无'

--物品等级
mt.level = 1

--价格
mt.gold = 0

--附魔价格
mt.enchant_gold = nil

--物品所在的格子
mt.slotid = nil

--物品是否是附魔
mt.enchant = false

--物品是否唯一
mt.unique = false

--物品创建时间
mt.create_time = nil

--物品词缀表
mt.affix = nil

--类型
mt.slot_type = '物品'

local drop_flag = false

local dummy_id = base.string2id 'ches'
local item_slk = slk.item
local j_items = {}

--根据句柄获取物品
function item.j_item(handle)
	return j_items[handle]
end

local item_list = {}

--添加物品列表
function item.add_list(type_name, name)
	local list = item.get_list(type_name)
	table.insert(list, name)
	return list
end

--获取物品列表
function item.get_list(type_name)
	local list = item_list[type_name]
	if not list then
		list = {}
		item_list[type_name] = list
	end
	return list
end

--清空物品列表
function item.clear_list()
	item_list = {}
end

--获取物品基础词缀
function mt:get_base_affix()
	if self.base_affix then
		return self.base_affix
	end
	local affix = {}
	if not item.default_state then
		return affix
	end
	if not self.item_type then
		return affix
	end
	if not item.default_state[self.item_type] then
		return affix
	end
	
	for k, v in pairs(item.default_state[self.item_type]) do
		affix[k] = v[self.level]
	end
	self.base_affix = affix
	return affix
end

--获取词缀表
function mt:get_affixs()
	local affixs = self.affixs
	if not affixs then
		affixs = {}
		self.affixs = affixs
	end
	return affixs
end

function mt:set_affixs(affixs)
	self.affixs = affixs
end

--获取物品的物编id
function item.get_id(skill)
	if skill.default_item_id then
		return skill.default_item_id
	end
	local p = skill.owner:get_owner()
	return ('IT%d%d'):format(p:get() - 1, skill:get_slotid() - 1)
end

--获取物品的技能物编id
function mt:get_ability_id()
	if not self.item_id then
		return nil
	end
	return 'AT' .. self.item_id:sub(3, 4)
end

local function add_item_slot(skill, slotid)
	if skill.removed or not skill.item_id then
		return false
	end
	local u = skill.owner
	if not u:is_alive() then
		u:event '单位-复活' (function(trg)
			trg:remove()
			add_item_slot(skill, slotid)
		end)
		return false
	end
	local j_its = {}
	for i = 1, slotid - 1 do
		--创建占位物品
		if jass.UnitItemInSlot(u.handle, i - 1) == 0 then
			local j_it = jass.CreateItem(dummy_id, 0, 0)
			dbg.handle_ref(j_it)
			jass.UnitAddItem(u.handle, j_it)
			table.insert(j_its, j_it)
		end
	end
	local res = jass.UnitAddItem(u.handle, skill.item_handle)
	--移除占位物品
	for i = 1, #j_its do
		jass.RemoveItem(j_its[i])
		dbg.handle_unref(j_its[i])
	end
	if res then
		skill._in_slot = true
		return true
	else
		u:wait(100, function()
			add_item_slot(skill, slotid)
		end)
		return false
	end
end

--给技能绑定物品
function item.bind_item(skill)
	if skill.owner:is_illusion() then
		return skill
	end
	setmetatable(skill, item)
	if skill.owner:is_hero() or skill.owner.type == 'shop' then
		skill.item_id = item.get_id(skill)
		skill.item_handle = jass.CreateItem(base.string2id(skill.item_id), 0, 0)
		dbg.handle_ref(skill.item_handle)
		jass.SetItemVisible(skill.item_handle, false)
		skill:fresh_tip()
		skill:fresh_title()
		skill:fresh_art()
		j_items[skill.item_handle] = skill
	end

	skill.ability_id = skill:get_ability_id()

	add_item_slot(skill, skill:get_slotid())
	return skill
end

function mt:debug_on_remove()
	for k, v in pairs(self) do
		if type(v) == 'table' and type(v.remove) == 'function' and v.type ~= 'unit' and k ~= '__index' then
			if v.removed ~= true then
				log.error(self.name, k, '没有释放.')
			end
		end
	end
end

--删除物品
function item.remove(self)
	if not self.item_handle then
		return
	end
	self._in_slot = false
	self.item_id = nil
	jass.RemoveItem(self.item_handle)
	dbg.handle_unref(self.item_handle)
	j_items[self.item_handle] = nil
	self.item_handle = nil
end

--卖出物品给钱
function mt:sell()
	local u = self.owner
	local slotid = self:get_slotid()
	self:remove()
	local gold = self:get_gold() or 0
	--60秒内卖出可以原价卖出
	if ac.clock() - self.create_time <= 60000 then
		u:addGold(gold, nil, true)
	else
		--检查要给多少钱
		local sell_gold = self.sell_gold or gold * 0.5
		u:addGold(sell_gold, nil, true)
	end

	item.on_remove(self)

	if u:is_hero() then
		log.info(('[%s]卖出[%s],之前在第[%d]个格子中'):format(u:get_name(), self.name, slotid))
		for i = 1, 6 do
			local it = u:find_skill(i, '物品')
			if it then
				log.info(('物品栏[%s][%s][%s]'):format(i, it:get_name(), it.item_id))
			else
				log.info(('物品栏[%s][nil]'):format(i))
			end
		end
	end
end

function mt:add_ability()
end

function mt:remove_ability()
end

function mt:unpack_affix(other_affixs)
	local affix_types = affix.types
	local state = {}
	for _, affix in ipairs(self:get_affixs()) do
		for k, v in pairs(affix) do
			if affix_types[k] then
				state[k] = (state[k] or 0) + v
			end
		end
	end
	for k, v in pairs(self:get_base_affix()) do
		if affix_types[k] then
			state[k] = (state[k] or 0) + v
		end
	end
	if other_affixs then
		for _, affix in ipairs(other_affixs) do
			for k, v in pairs(affix) do
				if affix_types[k] then
					state[k] = (state[k] or 0) + v
				end
			end
		end
	end
	return state
end

function mt:get_gold(other_affixs)
	return (self:unpack_affix(other_affixs).gold or 0) + self.gold
end

--获取使用次数
function mt:get_stack()
	return jass.GetItemCharges(self.item_handle)
end

--设置使用次数
function mt:set_stack(count)
	jass.SetItemCharges(self.item_handle, count)
end

--增加使用次数
function mt:add_stack(count)
	jass.SetItemCharges(self.item_handle, jass.GetItemCharges(self.item_handle) + (count or 1))
end

function mt:is_visible()
	return not self.removed and self._in_slot and not self.owner:is_illusion()
end

function mt:pause_cool()
	if self.pause_count == 1 and self.cool_timer then
		self.cool_timer:pause()
		japi.EXSetAbilityState(self:get_handle(), 0x01, 0)
		japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x69, 300)
		if self.pause_timer then
			self.pause_timer:remove()
		end
		local time = self:get_cd() / self:get_max_cd() * 300
		self.pause_timer = ac.loop(1000, function(t)
			if self.pause_count > 0 then
				japi.EXSetAbilityState(self:get_handle(), 0x01, time)
			else
				t:remove()
			end
		end)
		ac.wait(0, function()
			self.pause_timer:on_timer()
		end)
		return true
	end
	return false
end

--暂停
function mt:pause(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_count = self.pause_count + 1
		self:pause_cool()
	else
		self.pause_count = self.pause_count - 1
		if self.pause_count == 0 and self.cool_timer then
			japi.EXSetAbilityState(self:get_handle(), 0x01, 0)
			self:set_show_cd()
		end
	end
end

function mt:fresh_item()
	if not self:is_visible() then
		return
	end
	if not self.owner:is_alive() then
		self._wait_fresh_item = true
		return
	end
	local u = self.owner
	local slotid = self.slotid
	drop_flag = true
	jass.SetItemPosition(self.item_handle, 0, 0)
	drop_flag = false
	local j_its = {}
	for i = 1, slotid - 1 do
		--创建占位物品
		if jass.UnitItemInSlot(u.handle, i - 1) == 0 then
			local j_it = jass.CreateItem(dummy_id, 0, 0)
			dbg.handle_ref(j_it)
			jass.UnitAddItem(u.handle, j_it)
			table.insert(j_its, j_it)
		end
	end
	jass.UnitAddItem(u.handle, self.item_handle)
	--移除占位物品
	for i = 1, #j_its do
		jass.RemoveItem(j_its[i])
		dbg.handle_unref(j_its[i])
	end
	self:set_show_cd()
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
	if self.show_cd == 1 then
		japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x69, max_cool)
		japi.EXSetAbilityState(self:get_handle(), 0x01, cool)
		japi.EXSetAbilityDataReal(self:get_handle(), 1, 0x69, 0)
	end
end


local level_color = {
	'ffffffff',
	'ff3399ff',
	'ffffff33',
	'ffff8f2f',
}

--获取说明
function mt:get_tip(hero)
	local gold = self.gold or 0
	local tips = {}
	--词缀部分
	local affix_types = affix.types
	for k, v in pairs(self:get_base_affix()) do
		if k == 'gold' then
			gold = gold + v
		elseif v ~= 0 then
			local fmt = affix_types[k]
			if fmt then
				table.insert(tips, '|cffffffff' .. fmt:format(v) .. '|r')
			end
		end
	end
	for _, affix in ipairs(self:get_affixs()) do
		for k, v in pairs(affix) do
			if k == 'gold' then
				gold = gold + v
			elseif v ~= 0 then
				local fmt = affix_types[k]
				if fmt then
					table.insert(tips, '|cffccccff' .. fmt:format(v) .. '|r')
				end
			end
		end
	end
	--说明部分
	if gold > 0 then
		table.insert(tips, 1, affix_types['gold']:format(gold))
	end
	if self.tip then
		table.insert(tips, '')
		table.insert(tips, '|cffff8f2f' .. self:get_simple_tip(hero, 1):gsub('|r', '|cffff8f2f') .. '|r')
	end
	return table.concat(tips, '\n')
end

function mt:get_title()
	return '|c' .. level_color[self.level] .. (self.title or self.name) .. '|r'
end

--设置物品名字
function mt:set_tip(tip)
	japi.EXSetItemDataString(base.string2id(self.item_id), 3, tip)
end

function mt:set_title(title)
	japi.EXSetItemDataString(base.string2id(self.item_id), 4, title)
end

--设置物品图标
function mt:set_art(art)
	japi.EXSetItemDataString(base.string2id(self.item_id), 1, art)
	self:fresh_item()
end

--禁止丢弃
function mt:disable_drop()
	jass.SetItemDroppable(self.item_handle, false)
end

--阻止物品丢弃
ac.game:event '单位-丢弃物品' (function(trg, hero, it)
	if it.removed then
		return
	end
	if drop_flag then
		return
	end
	if hero:is_hero() then
		--卖掉
		it:sell()
	elseif hero.type == 'shop' then
		return
	else
		--删掉
		it:remove()
	end
end)

--监听在物品栏中移动物品
ac.game:event '单位-发布指令' (function(trg, hero, order, target, player_order, order_id)
	local slotid = order_id - 852001
	if slotid >= 1 and slotid <= 6 then
		local j_it = jass.GetOrderTargetItem()
		local it = item.j_item(j_it)
		--原地移动物品(右键双击)
		if it.slotid == slotid then
			hero:event_notify('单位-右键双击物品', hero, it)
			return
		end
		local dest = hero:find_skill(slotid, '物品')
		local last_slot = it:get_slotid()
		hero.skills['物品'][slotid] = it
		hero.skills['物品'][last_slot] = dest
		it.slotid = slotid
		if dest then
			dest.slotid = last_slot
		end
		drop_flag = true
		item.remove(it)
		if dest then
			item.remove(dest)
		end
		drop_flag = false
		item.bind_item(it)
		hero:event_notify('单位-移动物品', hero, it)
		if dest then
			item.bind_item(dest)
			hero:event_notify('单位-移动物品', hero, dest)
		end
		hero:get_owner().shop:fresh()
		if hero:is_hero() then
			log.info(('[%s]移动物品'):format(hero:get_name()))
			for i = 1, 6 do
				local it = hero:find_skill(i, '物品')
				if it then
					log.info(('物品栏[%s][%s][%s]'):format(i, it:get_name(), it.item_id))
				else
					log.info(('物品栏[%s][nil]'):format(i))
				end
			end
		end
	end
end)

--获得物品加成属性
function item:on_add()
	local hero = self.owner

	--保存物品
	local name = self.name

	local state = setmetatable(self:unpack_affix(), { __index = function() return 0 end })

	hero:add('攻击', state.attack)
	hero:add('攻击%', state.attack_rate)
	hero:add('攻击速度', state.attack_speed)
	hero:add('暴击', state.crit)
	hero:add('吸血', state.life_steal)
	hero:add('破甲', state.pene)
	hero:add('穿透', state.pene_rate_ex)
	hero:add('溅射', state.splash)
	hero:add('生命上限', state.life)
	hero:add('生命上限%', state.life_rate)
	hero:add('生命恢复', state.life_recover)
	hero:add('生命脱战恢复', state.restore)
	hero:add('护甲', state.defence)
	hero:add('护甲%', state.defence_rate)
	hero:add('移动速度', state.move_speed)
	hero:add('减耗', state.cost_save)
	hero:add('冷却缩减', state.cool_save)
	hero:add('格挡', state.block)
	local resource = ac.resource[hero.resource_type]
	hero:add('魔法上限', state.mana * resource.add_max_rate)
	hero:add('魔法恢复', state.mana_recover * resource.add_recover_rate)
	hero:add('魔法脱战恢复', state.restore / 2 * resource.add_recover_rate)
	if state.shoes_count > 0 then
		self.shoe_buff = hero:add_buff '鞋-加速' { skill = self, }
	end
	hero:get_owner().shop:fresh()
end

--失去物品减少属性
function item:on_remove()
	local hero = self.owner
	local name = self.name

	local state = setmetatable(self:unpack_affix(), { __index = function() return 0 end })

	hero:add('攻击', - state.attack)
	hero:add('攻击%', - state.attack_rate)
	hero:add('攻击速度', - state.attack_speed)
	hero:add('暴击', - state.crit)
	hero:add('吸血', - state.life_steal)
	hero:add('破甲', - state.pene)
	hero:add('穿透', - state.pene_rate_ex)
	hero:add('溅射', - state.splash)
	hero:add('生命上限', - state.life)
	hero:add('生命上限%', - state.life_rate)
	hero:add('生命恢复', - state.life_recover)
	hero:add('生命脱战恢复', - state.restore)
	hero:add('护甲', - state.defence)
	hero:add('护甲%', - state.defence_rate)
	hero:add('移动速度', - state.move_speed)
	hero:add('减耗', - state.cost_save)
	hero:add('冷却缩减', - state.cool_save)
	hero:add('格挡', - state.block)
	local resource = ac.resource[hero.resource_type]
	hero:add('魔法上限', - state.mana * resource.add_max_rate)
	hero:add('魔法恢复', - state.mana_recover * resource.add_recover_rate)
	hero:add('魔法脱战恢复', - state.restore / 2 * resource.add_recover_rate)
	if state.shoes_count then
		if self.shoe_buff then
			self.shoe_buff:remove()
		end
	end
	hero:get_owner().shop:fresh()
end

--使用物品的回调
ac.game:event '单位-使用物品' (function(trg, hero, it)
	it:_call_event 'on_use'
end)

return item
