
local shop = require 'types.shop'
local skill = require 'ac.skill'
local item = require 'types.item'
local affix = require 'types.affix'
local math = math

local self = {}

--普通页面默认图标
local default_arts = {
	['默认'] = [[shop\default.blp]],
	['武器'] = [[shop\attack.blp]],
	['防具'] = [[shop\defence.blp]],
	['鞋子'] = [[shop\speed.blp]],
}

local level_color = {
	'ffffffff',
	'ff3399ff',
	'ffffff33',
	'ffff8f2f',
}

--获取物品词缀
--	物品名
--	[原物品]
--	[额外词缀]
local function merge_affixs(dest, other_affixs)
	local affixs = {}
	--添加原物品词缀
	if dest then
		for _, affix in ipairs(dest:get_affixs()) do
			table.insert(affixs, affix)
		end
	end
	--添加额外词缀
	if other_affixs then
		for _, affix in ipairs(other_affixs) do
			table.insert(affixs, affix)
		end
	end
	return affixs
end

local function each_affix(affixs, callback)
	local affix_types = affix.types
	for _, affix in ipairs(affixs) do
		for k, v in pairs(affix) do
			if affix_types[k] and v ~= 0 then
				callback(k, v)
			end
		end
	end
end

-- 获取物品数据
local item_info = {}
local function get_item_info(name)
	if not name then
		return nil
	end
	if item_info[name] then
		return item_info[name]
	end
	local info = {}
	item_info[name] = info
	local skill = ac.skill[name]
	if not skill then
		return nil
	end
	for k, v in pairs(skill) do
		info[k] = v
	end
	setmetatable(info, ac.item)
	return info
end

local function get_item_info_by_list(name)
	local list = item.get_list(name)
	local item_name = list[1]
	if not item_name then
		log.error('没有找到物品:', name)
		return
	end
	local item = get_item_info(item_name)
	if not item then
		log.error('没有找到物品:', item_name, name)
		return
	end
	return item
end

local function can_buy(item, hero)
	if not hero then
		return false, '你没有英雄'
	end
	if item.unique and hero:find_skill(item.name, '物品') then
		return false, '你只能拥有一个[' .. item.name .. ']'
	end
	local error_tip = item.canBuy and item:canBuy(hero)
	if error_tip then
		return false, error_tip
	end
	return true
end

--购买物品
local function buyItem(hero, name)
	local player = hero:get_owner()
	local shop = player.shop
	if hero:is_alive() and hero:get_point() * shop:get_point() > 1500 then
		player:sendMsg '|cffffff00你的英雄距离商店太远了|r'
		return false
	end
	
	local item_count = 0
	for _ in hero:each_skill '物品' do
		item_count = item_count + 1
	end
	if item_count >= 6 then
		player:sendMsg '|cffffff00物品栏已满'
		return false
	end

	local item = get_item_info(name)
	local my_gold = player:getGold()
	local gold = item:get_gold() or 0
	if gold > my_gold then
		player:sendMsg('|cffffff00金钱不够,还差 ' .. (gold - my_gold))
		return false
	end

	--扣钱
	player:addGold( - gold)

	--创建物品给英雄
	local skl = hero:add_skill(name, '物品')
	if skl then
		skl.create_time = ac.clock()
		skl:set_affixs(item:get_affixs())
		ac.item.on_add(skl)
		skl:fresh_tip()
	end
	return skl
end

--升级物品
local function upgradeItem(hero, name, dest, other_affixs)
	local player = hero:get_owner()
	local shop = player.shop
	if hero:is_alive() and hero:get_point() * shop:get_point() > 1500 then
		player:sendMsg '|cffffff00你的英雄距离商店太远了|r'
		return false
	end

	local item = get_item_info(name)
	local gold = item:get_gold(other_affixs) or 0
	for _, affix in ipairs(dest:get_affixs()) do
		if affix.gold then
			gold = gold + affix.gold
		end
	end
	--计算词缀
	local my_gold = player:getGold()
	local gold = gold - (dest:get_gold() or 0)
	if gold > my_gold then
		player:sendMsg('|cffffff00金钱不够,还差 ' .. (gold - my_gold))
		return false
	end

	--扣钱
	player:addGold( - gold)
	--删除原来的物品
	dest:remove()
	ac.item.on_remove(dest)

	--创建物品给英雄
	local skl = hero:add_skill(name, '物品', dest:get_slotid())
	if skl then
		skl.create_time = dest.create_time
		skl:set_affixs(merge_affixs(dest, other_affixs))
		ac.item.on_add(skl)
		skl:fresh_tip()
	end
	return skl
end

function self.init_skills()
	for x = 1, 4 do
		for y = 1, 3 do
			local mt = ac.skill[('商店技能%d%d'):format(x, y)]
			{
				--技能ID
				ability_id = shop:get_ability_id(x, y),

				simple_tip = true,

				auto_fresh_tip = false,

				level = 1,

				max_level = 1,
			}
			
			--隐藏技能
			function mt:hide(...)
				if self.owner:get_owner() == ac.player.self then
					skill.hide(self, ...)
				end
			end

			--显示技能
			function mt:show(...)
				if self.owner:get_owner() == ac.player.self then
					skill.show(self, ...)
				end
			end

			function mt:set_show(item, dest, other_affixs)
				local hero = self.owner:get_owner().hero
				local my_gold = self.owner:get_owner():getGold()
				local affix_types = affix.types
				local tips = {}
				local gold = item.gold
				for k, v in pairs(item:get_base_affix()) do
					if k == 'gold' then
						gold = gold + v
					elseif v ~= 0 then
						local fmt = affix_types[k]
						if fmt then
							table.insert(tips, '|cffffffff' .. fmt:format(v) .. '|r')
						end
					end
				end
				if dest then
					each_affix(dest:get_affixs(), function(k, v)
						if k == 'gold' then
							gold = gold + v
						else
							table.insert(tips, '|cffffffff' .. affix_types[k]:format(v) .. '|r')
						end
					end)
				end
				if other_affixs then
					each_affix(other_affixs, function(k, v)
						if k == 'gold' then
							gold = gold + v
						else
							table.insert(tips, '|cffccccff' .. affix_types[k]:format(v) .. '|r')
						end
					end)
				end

				if dest then
					gold = gold - (dest:get_gold() or 0)
				end
				if gold > 0 then
					table.insert(tips, 1, affix_types['gold']:format(gold))
				end
				if item.tip then
					table.insert(tips, '')
					table.insert(tips, '|cffff8f2f' .. item:get_simple_tip(hero, 1):gsub('|r', '|cffff8f2f') .. '|r')
				end
				
				--升级列表
				if item.level == 4 then
					table.insert(tips, '|cffff1111这是终极装备!|r')
				end
				local is_can_buy, error_tip = can_buy(item, hero)
				if is_can_buy then
					if dest then
						table.insert(tips, '')
						table.insert(tips, '|cffffff00点击升级|r')
					else
						table.insert(tips, '')
						table.insert(tips, '|cffffff00点击购买|r')
					end
				else
					table.insert(tips, '')
					table.insert(tips, '|cffff1111' .. error_tip .. '|r')
				end
				self:set_title('|c' .. level_color[item.level] .. item.name .. '|r')
				self:set_tip(table.concat(tips, '|n'))
				self:set_art(item:get_art(nil, not is_can_buy))
			end

			--设置这一栏的物品
			function mt:setItem(name, type, page)
				local shop = self.owner
				local hero = shop:get_owner().hero
				self.current_name = name
				self.current_type = type
				self.current_item = nil

				if self:is_hide() then
					self:show()
				end

				-- 空
				self:set_title '空'
				self:set_tip ''
				self:set_art(default_arts[name:sub(1, -3)] or default_arts['默认'])

				-- 购买物品
				if type == '$' then
					local item = get_item_info_by_list(name)
					if not item then
						return
					end
					self:set_show(item)
					self.current_item = item
					return
				end
				
				--页面
				if type == '#' then
					local page = shop:getPage(name)
					self:set_title(page.name)
					self:set_tip(page.tip)
					self:set_art(page.art)
					return
				end

				--词缀列表
				if type == '!' then
					--当前位置是否有可升级的物品
					local item_type = name:sub(1, -2)
					local i = tonumber(name:sub(-1, -1))
					local list = ac.item.get_list(item_type)
					local item = get_item_info_by_list(item_type)
					if not item then
						return
					end

					--可升级的词缀
					local list = affix.get_list(item_type)
					local pos = i + shop.current_list_pos
					local affix = list[pos]
					if not affix then
						return
					end
					self.current_item = item
					self:set_show(item, shop.current_item, {affix})
					return
				end

				--附魔列表
				if type == '*' then
					--当前位置是否有可升级的物品
					local item_type = name:sub(1, -2)
					local i = tonumber(name:sub(-1, -1))
					local list = ac.item.get_list(item_type)
					local pos = i + shop.current_list_pos
					
					--显示物品
					local item = get_item_info(list[pos])
					if not item then
						return
					end
					self.current_item = item
					self:set_show(item, shop.current_item, nil)
					return
				end

				--向上翻词缀页
				if type == '<' or type == '-' then
					--是否选中了物品
					local dest = shop.current_item
					if not dest then
						return
					end
					local list
					if type == '<' then
						list = affix.get_list(dest.item_type .. (dest.level + 1))
					else
						list = item.get_list(dest.item_type .. (dest.level + 1))
					end
					local max = tonumber(name:sub(1, 1))
					local count = tonumber(name:sub(2, 2))
					self:set_title '向上翻'
					self:set_art(self:get_art([[ReplaceableTextures\CommandButtons\BTNReplay-SpeedUp.blp]], shop.current_list_pos <= 0))
					shop.up_list = list
					shop.up_max = max
					shop.up_page = count
					return
				end

				--向下翻词缀页
				if type == '>' or type == '+' then
					--是否选中了物品
					local dest = shop.current_item
					if not dest then
						return
					end
					local list
					if type == '>' then
						list = affix.get_list(dest.item_type .. (dest.level + 1))
					else
						list = item.get_list(dest.item_type .. (dest.level + 1))
					end
					local max = tonumber(name:sub(1, 1))
					local count = tonumber(name:sub(2, 2))
					self:set_title '向下翻'
					self:set_art(self:get_art([[ReplaceableTextures\CommandButtons\BTNReplay-SpeedDown.blp]], shop.current_list_pos >= #list - max))
					shop.down_list = list
					shop.down_max = max
					shop.down_page = count
					return
				end
			end

			function mt:on_cast_shot()
				local name = self.current_name
				local type = self.current_type
				local item = self.current_item
				local shop = self.owner
				local player = shop:get_owner()
				local hero = player.hero

				if type == '~' then
					return false
				end

				--购买物品
				if type == '$' then
					local is_can_buy, error_tip = can_buy(item, hero)
					if not is_can_buy then
						player:sendMsg('|cffff1111' .. error_tip .. '|r')
						return false
					end
					local new_it = buyItem(hero, item.name)
					if not new_it then
						return false
					end
					--如果购买成功,则打开子页面
					shop:open_list_page(new_it)
					return true
				end
				
				--打开页面
				if type == '#' then
					shop:setCurrentPage(name)
					return true
				end

				--点击词缀列表升级物品
				if type == '!' or type == '*' then
					if not item then
						return
					end
					local is_can_buy, error_tip = can_buy(item, hero)
					if not is_can_buy then
						player:sendMsg('|cffff1111' .. error_tip .. '|r')
						return false
					end
					local item_type = name:sub(1, -2)
					local i = tonumber(name:sub(-1, -1))
					local list = ac.item.get_list(item_type)

					--可升级的词缀
					local list = affix.get_list(item_type)
					local pos = i + shop.current_list_pos
					local affix = list[pos]
					local new_it = upgradeItem(hero, item.name, shop.current_item, {affix})
					if not new_it then
						return false
					end
					shop:open_list_page(new_it)
					return true
				end

				--向上翻页
				if type == '<' or type == '-' then
					return shop:page_up()
				end

				--向下翻页
				if type == '>' or type == '+' then
					return shop:page_down()
				end
			end
		end
	end

	return self
end

return self.init_skills()
