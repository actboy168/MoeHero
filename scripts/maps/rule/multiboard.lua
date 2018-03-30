
local multiboard = require 'types.multiboard'
local player = require 'ac.player'
local rewin = require 'maps.rule.rewin'
local hot_fix = require 'types.hot_fix'

if type(hot_fix) ~= 'table' then
	log.error('hot_fix加载失败', hot_fix)
	hot_fix = {}
end

local self = {}

local mb

--x坐标内容
local mb_player	= 1
local mb_level	= 2
local mb_kill	= 3
local mb_assist	= 4
local mb_farm	= 5
local mb_gold	= 6
local mb_items = {}
for i = 1, 6 do
	mb_items[i] = i + 6
end

--y坐标内容
local mb_title	= 1
local mb_players	= {}
local player_count

--玩家对应的y坐标
local function init()
	player_count = mb_title
	--电脑1
	player_count = player_count + 1
	mb_players[player.com[1]] = player_count
	--队伍1
	for i = 1, 5 do
		local p = player.force[1][i]
		if p:is_player() then
			player_count = player_count + 1
			mb_players[p] = player_count
		end
	end

	--电脑2
	player_count = player_count + 1
	mb_players[player.com[2]] = player_count
	--队伍2
	for i = 1, 5 do
		local p = player.force[2][i]
		if p:is_player() then
			player_count = player_count + 1
			mb_players[p] = player_count
		end
	end
end

init()

--y坐标内容继续
local y = player_count
--宝箱奖励显示
local mb_box = {y + 2, y + 3, y + 4, y + 5}

--设置玩家的某一项文本
local function setPlayerText(k, p, text)
	local y = mb_players[p]
	if y then
		mb:setText(k, y, text)
	end
end

--设置玩家某一项的图标
local function setPlayerIcon(k, p, ico)
	local y = mb_players[p]
	if y then
		mb:setIcon(k, y, ico)
	end
end

--设置玩家某一项的stype
local function setPlayerStyle(k, p, show_text, show_icon)
	local y = mb_players[p]
	if y then
		mb:setStyle(k, y, show_text, show_icon)
	end
end

--设置玩家的某一项宽度
local function setPlayerWidth(k, p, text)
	local y = mb_players[p]
	if y then
		mb:setWidth(k, y, text)
	end
end

--刷新全部玩家栏
local function freshPlayer()
	local width = 0.15
	--玩家标题
	mb:setText(mb_player,	mb_title, '')
	mb:setWidth(mb_player,	mb_title, width)
	--设置玩家名字
	for i = 1, 12 do
		local p = player[i]
		local color
		if i > 10 or p:is_player() then
			color = p:getColorWord()
		else
			color = '|cff444444'
		end
		local revive = rewin.getReviveTime(p)
		if not revive or revive <= 0 then
			revive = ''
		else
			revive = (' |cffff1111(%d)|r'):format(math.floor(revive))
		end
		setPlayerText(mb_player, p, color .. p:get_name() .. '|r' .. revive)
		setPlayerWidth(mb_player, p, width)
		if i <= 10 then
			setPlayerStyle(mb_player, p, true, true)
		end
		if p.hero then
			setPlayerIcon(mb_player, p, p.hero:get_slk 'Art')
		else
			setPlayerIcon(mb_player, p, [[ReplaceableTextures\CommandButtons\BTNSelectHeroOn.blp]])
		end
	end
end

--刷新全部等级
local function freshLevel()
	local width = 0.03
	local title = '|cff11ffff等级|r'
	local text = '|cff11ffff% 4d|r'
	--等级标题
	mb:setText(mb_level,	mb_title, title)
	mb:setWidth(mb_level,	mb_title, width)
	--设置玩家等级
	for i = 1, 10 do
		local p = player[i]
		setPlayerWidth(mb_level, p, width)
		if p.hero and p.hero:is_visible(player.self) then
			setPlayerText(mb_level, p, text:format(p.hero:get_level()))
		end
	end
end

--刷新全部杀敌
local function freshKill()
	local width = 0.03
	local title = '|cffff1111萌杀|r'
	local text = '|cffff1111% 4d|r'
	--设置标题
	mb:setText(mb_kill,		mb_title, title)
	mb:setWidth(mb_kill,	mb_title, width)
	--统计双方杀敌数
	local kill_1, kill_2 = 0, 0
	for i = 1, 5 do
		local p = player.force[1][i]
		setPlayerWidth(mb_kill, p, width)
		setPlayerText(mb_kill, p, text:format(p.kill_count))
		kill_1 = kill_1 + p.kill_count
	end
	for i = 1, 5 do
		local p = player.force[2][i]
		setPlayerWidth(mb_kill, p, width)
		setPlayerText(mb_kill, p, text:format(p.kill_count))
		kill_2 = kill_2 + p.kill_count
	end
	--设置杀敌总数
	local p = player.com[1]
	setPlayerWidth(mb_kill, p, width)
	setPlayerText(mb_kill, p, text:format(kill_1))
	local p = player.com[2]
	setPlayerWidth(mb_kill, p, width)
	setPlayerText(mb_kill, p, text:format(kill_2))
end

--刷新全部助攻
local function freshAssist()
	local width = 0.03
	local title = '|cff3399ff助攻|r'
	local text = '|cff3399ff% 4d|r'
	--设置标题
	mb:setText(mb_assist,	mb_title, title)
	mb:setWidth(mb_assist,	mb_title, width)
	--统计双方杀敌数
	local assist_1, assist_2 = 0, 0
	for i = 1, 5 do
		local p = player.force[1][i]
		setPlayerWidth(mb_assist, p, width)
		setPlayerText(mb_assist, p, text:format(p.assist_count))
		assist_1 = assist_1 + p.assist_count
	end
	for i = 1, 5 do
		local p = player.force[2][i]
		setPlayerWidth(mb_assist, p, width)
		setPlayerText(mb_assist, p, text:format(p.assist_count))
		assist_2 = assist_2 + p.assist_count
	end
	--设置杀敌总数
	local p = player.com[1]
	setPlayerWidth(mb_assist, p, width)
	setPlayerText(mb_assist, p, text:format(assist_1))
	local p = player.com[2]
	setPlayerWidth(mb_assist, p, width)
	setPlayerText(mb_assist, p, text:format(assist_2))
end

--刷新全部补兵
local function freshFarm()
	local width = 0.03
	local title = '|cff11ff11补兵|r'
	local text = '|cff11ff11% 4.f|r'
	mb:setText(mb_farm,	mb_title, title)
	mb:setWidth(mb_farm, mb_title, width)
	for i = 1, 10 do
		local p = player[i]
		if p.hero and p.hero:is_visible(player.self) then
			setPlayerText(mb_farm, p, text:format(p.farm_count))
		end
	end
end

--刷新全部现金
local function freshGold()
	local width = 0.05
	local title = '|cffffff11现金|r'
	local text = '|cffffff11% 4.f|r'
	mb:setText(mb_gold, mb_title, title)
	mb:setWidth(mb_gold, mb_title, width)
	for i = 1, 10 do
		local p = player[i]
		setPlayerWidth(mb_gold, p, width)
		if p:is_ally(player.self) then
			setPlayerText(mb_gold, p, text:format(p:getGold()))
		else
			setPlayerText(mb_gold, p, '')
		end
	end
end

local empty_item_art = [[ReplaceableTextures\CommandButtonsDisabled\DISBTNDustOfAppearance.blp]]

--刷新指定玩家物品
local function freshItem(p)
	if p then
		local hero = p.hero
		if not hero then
			return
		end
		if hero:is_visible(player.self) then
			for x = 1, 6 do
				local it = hero:find_skill(x, '物品')
				local art = empty_item_art
				if it then
					art = it:get_art()
				end
				setPlayerIcon(mb_items[x], p, art)
			end
		else
			p.wait_to_fresh_item = true
		end
	else
		for i = 1, 10 do
			local p = player[i]
			if p.wait_to_fresh_item and p.hero:is_visible(player.self) then
				p.wait_to_fresh_item = false
				freshItem(p)
			end
		end
	end
end

--刷新所有物品
local function initItem()
	local width = 0.01
	for x = 1, 6 do
		mb:setWidth(mb_items[x], mb_title, width)
		for i = 1, 10 do
			local p = player[i]
			setPlayerWidth(mb_items[x], p, width)
			setPlayerStyle(mb_items[x], p, false, true)
			setPlayerIcon(mb_items[x], p, empty_item_art)
		end
	end
	for i = 1, 10 do
		freshItem(player[i])
	end
end

--刷新标题
local title = '|cffff1111萌杀 % 2d|r  |cff3399ff助攻 % 2d|r  |cff888888扑街 % 2d|r  |cff11ff11补兵 % 2.f|r  |cff888888%02d:%02d:%02d|r   |cff888888热补丁[%d]|r'
local function freshTitle()
	local p = player.self
	local t = os.date('*t')
	mb:setTitle(title:format(
		p.kill_count,
		p.assist_count,
		p.dead_count,
		p.farm_count,
		t.hour,
		t.min,
		t.sec,
		hot_fix.ver or 0
	))
end

--宝箱奖励
local function freshBox()
	local width = 0.2
	--local tip = '%s%s %s:|r    %s%s|r'
	local tip = '%s%s %s|r'
	local hero = player.self.hero
	for i = 1, 4 do
		local name = '宝箱奖励' .. i
		local bff = ac.buff[name]
		mb:setWidth(1, mb_box[i], width)
		local word = '√'
		local color1 = '|cffff8811'
		local color2 = '|cffffff11'
		if bff then
			if not hero or not hero:find_buff(name) then
				word = '□'
				color1 = '|cff888888'
				color2 = '|cff888888'
			else
				bff = hero:find_buff(name)
			end
			local bff_tip = bff:get_tip():gsub('%%', '%%%%')
			--local text = tip:format(color1, word, name, color2, bff_tip):gsub('%%%%', '%%')
			local text = tip:format(color2, word, bff_tip):gsub('%%%%', '%%')
			--print('宝箱奖励', word)
			mb:setText(1, mb_box[i], text)
		end
	end
end

--创建多面板
local objs = {}

local function getMultiboard()
	if not mb then
		mb = multiboard.create(12, player_count + 5)
		poi.multiboard = mb
		
		mb:setAllStyle(true, false)

		freshPlayer()
		freshLevel()
		freshKill()
		freshAssist()
		freshFarm()
		freshGold()
		freshTitle()
		initItem()
		freshBox()

		--每0.5秒刷新
		--刷新补兵数
		ac.wait(0, function()
			local obj = ac.loop(500, freshFarm)
			table.insert(objs, obj)
		end)
		--刷新现金和物品
		ac.wait(100, function()
			local obj = ac.loop(500, function()
				freshGold()
				freshItem()
			end)
			table.insert(objs, obj)
		end)
		--刷新玩家名
		ac.wait(200, function()
			local obj = ac.loop(500, freshPlayer)
			table.insert(objs, obj)
		end)
		--刷新多面板标题
		ac.wait(300, function()
			local obj = ac.loop(500, freshTitle)
			table.insert(objs, obj)
		end)
		--刷新英雄等级
		ac.wait(400, function()
			local obj = ac.loop(500, freshLevel)
			table.insert(objs, obj)
		end)

		--击杀英雄时刷新面板
		local obj = ac.game:event '玩家-击杀英雄' (function()
			freshKill()
			freshAssist()
			--freshTitle()
		end)
		table.insert(objs, obj)

		--操作物品时刷新面板
		local function f(_, hero)
			local p = hero:get_owner()
			freshItem(p)
		end
		local obj = ac.game:event '技能-获得' (function (_, hero, skill)
			if skill:get_type() == '物品' then
				f(_, hero)
			end
		end)
		table.insert(objs, obj)
		local obj = ac.game:event '技能-失去' (function (_, hero, skill)
			if skill:get_type() == '物品' then
				f(_, hero)
			end
		end)
		table.insert(objs, obj)
		local obj = ac.game:event '单位-移动物品' (f)
		table.insert(objs, obj)

		--显示宝箱奖励
		local obj = ac.game:event '游戏-宝箱奖励' (function()
			freshBox()
		end)
		table.insert(objs, obj)
		self.minimize(true)
	end
	return mb
end

function self.minimize(flag)
	if not mb then
		return
	end
	mb:minimize(flag)
end

--玩家选择英雄后显示多面板
ac.game:event '玩家-注册英雄' (function(trg, player, hero)
	local mt = getMultiboard()
	if player:is_self() then
		mt:show()
	end
end)

--游戏结束时停止多面板
ac.game:event '游戏-结束' (function()
	for _, obj in ipairs(objs) do
		obj:remove()
	end
end)

--event '脚本重载' (function(trg)
--	if mb then
--		mb:remove()
--		mb = nil
--		trg:remove()
--		for _, obj in ipairs(objs) do
--			obj:remove()
--		end
--	else
--		mb = getMultiboard()
--		if player.self.hero then
--			mb:show()
--		end
--	end
--end)

return self
