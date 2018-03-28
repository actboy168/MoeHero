
local rect = require 'types.rect'
local unit = require 'types.unit'
local item = require 'types.item'
local affix = require 'types.affix'
local jass = require 'jass.common'
local setmetatable = setmetatable

local shop = {}
setmetatable(shop, shop)
local mt = {}

shop.__index = mt

--类型
mt.type = 'shop'

--页面记录
mt.page_stack = nil

--当前选中的物品
mt.current_item = nil

--当前列表位置
mt.current_list_pos = 0

--获得页面记录
--	@返回一个数组,记录所有的页面记录
function mt:getPageStack()
	if not self.page_stack then
		self.page_stack = {self:getPage '主页'}
	end

	return self.page_stack
end

--清空页面记录
function mt:clearPageStack()
	self.page_stack = nil
end

--获得当前页面
function mt:getCurrentPage()
	local stack = self:getPageStack()

	return stack[#stack]
end

--设置当前页面
--	页面名称[详细的页面表]
function mt:setCurrentPage(page)
	local stack = self:getPageStack()
	if type(page) == 'string' then
		shop.current_item = nil
		if page == '主页' then
			shop:clearPageStack()
		end
		page = self:getPage(page)
	end
	if page then
		table.insert(stack, page)

		self:fresh()
		return true
	end
	return false
end

--获得商店技能ID
function mt:get_ability_id(x, y)
	return ('AS%d%d'):format(x, y)
end

--获得商店技能
function mt:getSkill(x, y)
	return self:find_skill(('商店技能%d%d'):format(x, y), nil, true)
end

--刷新商店页面
function mt:fresh()
	local page = self:getCurrentPage()
	if self.current_item and self.current_item.removed then
		self.current_item = nil
		self:clearPageStack()
		self:setCurrentPage '主页'
		return
	end

	--刷新技能
	for x = 1, 4 do
		for y = 1, 3 do
			local skl = self:getSkill(x, y)
			local name = page:get_name(x, y)
			local ty = page:getType(x, y)
			if skl then
				skl:setItem(name, ty, page)
			end
		end
	end

	--刷新物品
	for it in self:each_skill '物品' do
		it:fresh()
		--把物品丢地上再捡起来
		jass.SetItemPosition(it.handle, 0, 0)
		jass.UnitAddItem(self.handle, it.handle)
	end
end

--继承unit类
setmetatable(shop.__index, unit)

function shop.create(player, unit_id, rect_name, ...)
	shop.rect_name = rect_name

	--为每个玩家创建一个商店
	local tid = player:get_team()
	local i = player:get()

	--创建商店类型
	local u = player:create_unit(unit_id, rect.j_rect(shop.rect_name .. tid), ...)
	
	setmetatable(u, shop)
	shop[i] = u
	player.shop = u
	
	u:set_high(10000)

	--添加选择英雄技能
	--u:add_ability 'A01G'
	u:add_ability 'Asid'
	u:add_ability 'Apit'
	--添加物品栏
	u:add_ability 'AInv'

	--为商店添加所有技能
	for x = 1, 4 do
		for y = 1, 3 do
			u:add_skill(('商店技能%d%d'):format(x, y), '隐藏')
		end
	end

	--为商店添加马甲物品
	for x = 1, 6 do
		u:add_skill('商店物品', '物品', x, {default_item_id = ('ID%d%d'):format(i - 1, x - 1)})
	end

	if player:is_self() then
		shop.self = u
		u:set_high(0)
	end
	
	--移除商店移动技能
	u:remove_ability 'Amov'
	--立刻刷新商店页面
	u:fresh()

	player:event_notify('玩家-注册商店', player, u)
	return u
end

--打开升级界面
function mt:open_list_page(it)
	if it then
		local next_type_name = it.item_type .. (it.level + 1)
		local next_page = it.item_type .. it.level
		self.current_item = it
		self.current_list_pos = 0
		if self:setCurrentPage(next_page) then
			return
		end
	end
	self.current_item = nil
	self.current_list_pos = 0
	self:setCurrentPage '主页'
end

-- 向上翻页
function mt:page_up()
	--是否选中了物品
	local dest = self.current_item
	if not dest then
		return false
	end
	local list = self.up_list
	if not list then
		return false
	end
	local max = self.up_max
	local count = #list
	local page = self.up_page
	local pos = self.current_list_pos
	if pos > 0 then
		self.current_list_pos = math.max(0, self.current_list_pos - page)
		self:fresh()
		return true
	end
	return false
end

-- 向下翻页
function mt:page_down()
	--是否选中了物品
	local dest = self.current_item
	if not dest then
		return false
	end
	local list = self.down_list
	if not list then
		return false
	end
	local max = self.down_max
	local count = #list
	local page = self.down_page
	local pos = self.current_list_pos
	if pos < count - max then
		self.current_list_pos = self.current_list_pos + page
		self:fresh()
		return true
	end
	return false
end

--选中英雄时取消商店的选择
ac.game:event '玩家-选择单位' (function(trg, player, hero)
	if not hero:is_hero() or player ~= hero:get_owner() then
		return
	end

	local p = hero:get_owner()
	local i = p:get()
	p:removeSelect(shop[i])
end)

function shop.init()

	require 'types.shop.skill'
	require 'types.shop.page'
	require 'types.shop.item'
end

return shop