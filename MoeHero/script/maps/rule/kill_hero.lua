local player = require 'ac.player'
local jass = require 'jass.common'
local game = require 'types.game'
local math = math

local self = {}

--记录击杀次数
player.__index.kill_count = 0
--记录死亡次数
player.__index.dead_count = 0
--记录助攻次数
player.__index.assist_count = 0
--超神称号等级
player.__index.kill_holyshit = 0
--超鬼称号等级
player.__index.dead_holyshit = 0
--连杀称号等级
player.__index.kill_doublekill = 0
--连杀称号时间记录
player.__index.kill_doublekill_time = 0

--击杀英雄给的经验
self.xp = {
	200,
	210,
	230,
	260,
	300,
	350,
	410,
	480,
	560,
	650,
	750,
	860,
	980,
	1110,
	1250,
	1400,
	1560,
	1730,
	1910,
	2100,
	2300,
	2510,
	2720,
	2930,
	3170,
}

--击杀英雄的金钱奖励(暂时)
self.gold = {
	300,
	325,
	350,
	375,
	400,
	425,
	450,
	475,
	500,
	525,
	550,
	575,
	600,
	625,
	650,
	675,
	700,
	725,
	750,
	775,
	800,
	825,
	850,
	875,
	900,
}

--超神称号
self.holyshit_title = {
	'nothing',
	'nothing',
	'正在 |cff33ff33大展萌力|r',
	'已经 |cffaa22aa萌力爆表|r',
	'已经 |cff00ffff萌倒众人|r',
	'已经 |cffffff00无可匹敌|r',
	'已经 |cff808000至上最萌|r',
	'已经 |cffff00ff接近萌王啦(～o￣3￣)～o|r',
	'已经 |cffff3300晋升萌王！！！|r',
	'已经 |cffff9900超越萌王！！！！拜托谁去让她停下来吧！！！！|r',
}
self.holyshit_shutdown = {
	'nothing',
	'nothing',
	'|cff33ff33大展萌力|r',
	'|cffaa22aa萌力爆表|r',
	'|cff00ffff萌倒众人|r',
	'|cffffff00无可匹敌|r',
	'|cff808000至上最萌|r',
	'|cffff00ff接近萌王|r',
	'|cffff3300晋升萌王|r',
	'|cffff9900超越萌王|r',
}
self.holyshit_sound = {
	'nothing',
	'nothing',
	[[modeldekan\sound\DEKAN_3KillingSpree.mp3]],
	[[modeldekan\sound\DEKAN_4Dominating.mp3]],
	[[modeldekan\sound\DEKAN_5MegaKill.mp3]],
	[[modeldekan\sound\DEKAN_6Unstoppable.mp3]],
	[[modeldekan\sound\DEKAN_7WhickedSick.mp3]],
	[[modeldekan\sound\DEKAN_8MonsterKill.mp3]],
	[[modeldekan\sound\DEKAN_9GodLike.mp3]],
	[[modeldekan\sound\DEKAN_10HolyShit.mp3]],
}
self.doublekill_title = {
	'nothing',
	'|cff3333ff气势正劲，连续击穿双人！|r',
	'|cffaa0000乘胜追击，红色萌杀三倍！|r',
	[[|cff00ffff一鼓作气，四天王也不过如此！|r]],
	'|cff00ffff全灭众敌，你已经死了！！|r',
}
self.doublekill_sound = {
	[[modeldekan\sound\DEKAN__1Firstblood.mp3]],
	[[modeldekan\sound\DEKAN__2DoubleKill.mp3]],
	[[modeldekan\sound\DEKAN__3TripleKill.mp3]],
	[[modeldekan\sound\DEKAN__4UltraKill.mp3]],
	[[modeldekan\sound\DEKAN__5Rampage.mp3]],
}


self.isFirstBlood = true

--击杀英雄给经验给钱
ac.game:event '玩家-注册英雄' (function(_, _, hero)
hero:event '单位-死亡' (function(_, target, source)
	local lv = target:get_level()
	if not lv then
		return
	end

	--计算经验
	local xp = self.xp[lv]
	local gold = self.gold[lv]
	local hero_tables = {}

	--周围所有己方英雄获得平分的经验
	local hero_tables = ac.selector()
		: in_range(target, 1200)
		: is_not(target)
		: of_hero()
		: of_not_illusion()
		: get()
	if not source or not source:get_owner():is_player() then
		if #hero_tables > 0 then
			source = hero_tables[math.random(1, #hero_tables)]
		else
			source = nil
		end
	end
	local p_from = source and source:get_owner()
	local p_to = target and target:get_owner()
	local count = #hero_tables
	if count == 0 then
		for i = 1, 10 do
			local eu = player[i].hero
			if eu and target:is_enemy(eu) then
				table.insert(hero_tables, eu)
			end
		end
	end
	count = #hero_tables
	--连杀影响收入
	if p_to.dead_holyshit > 0 then
		xp = xp / (1 + 0.1 * p_to.dead_holyshit)
		gold = gold / (1 + 0.1 * p_to.dead_holyshit)
	end
	if p_to.kill_holyshit > 0 then
		xp = xp * (1 + 0.1 * p_to.kill_holyshit)
		gold = gold * (1 + 0.1 * p_to.kill_holyshit)
	end
	--人数影响收入
	if count ~= 2 then
		xp = xp * (1 + 0.1 * (count - 2))
		gold = gold * (1 + 0.1 * (count - 2))
	end
	--最后修正
	xp = xp * 0.9
	gold = gold * 0.9
	for i = 1, count do
		--等级差影响收入
		local self_xp = xp / count
		local self_gold = gold / count
		local self_lv = hero_tables[i]:get_level()
		if lv > self_lv then
			self_xp = self_xp * ( 1+0.15*( lv - self_lv ))
			self_gold = self_gold * ( 1+0.15*( lv - self_lv ))
		end
		if lv < self_lv then
			self_xp = self_xp * (1/( 1+0.15*( self_lv - lv )))
			self_gold = self_gold * (1/( 1+0.15*( self_lv - lv )))
		end
		hero_tables[i]:addXp(math.floor(self_xp))
		hero_tables[i]:addGold(math.floor(self_gold), target)
	end

	--统计助攻列表
	local assist_string = ''
	local assist_table = {}
	local assist_strings = {}
	for _, eu in ac.selector()
		: in_range(target, 1200)
		: is_enemy(target)
		: of_hero()
		: of_not_illusion()
		: ipairs()
	do
		local p = eu:get_owner()
		if p_from ~= p then
			p.assist_count = p.assist_count + 1
			table.insert(assist_table, p)
			table.insert(assist_strings, p:getColorWord() .. p.hero:get_name() .. '|r')
		end
	end
	if #assist_table ~= 0 then
		assist_string = ' 助攻 ' .. table.concat(assist_strings, [[、]])
	end

	p_to.dead_count = p_to.dead_count + 1

	--显示击杀
	local GOLD_FIRSTBLOOD = 200 --第一滴血奖励金钱
	if p_from then
		if p_from ~= p_to then
			p_from.kill_count = p_from.kill_count + 1
			--超神称号 - 终结
			if p_to.kill_holyshit >= 3 then
				player.self:sendMsg(('%s%s|r 终结了 %s%s|r 的 %s%s'):format(
					p_from:getColorWord(),
					p_from.hero:get_name(),
					p_to:getColorWord(),
					p_to.hero:get_name(),
					self.holyshit_shutdown[math.min(p_to.kill_holyshit,10)],
					assist_string
				))
			else
				--非终结时显示正常击杀（萌死）
				player.self:sendMsg(('%s%s|r 萌死了 %s%s|r!%s'):format(
					p_from:getColorWord(),
					p_from.hero:get_name(),
					p_to:getColorWord(),
					p_to.hero:get_name(),
					assist_string
				))
			end
			--第一滴血
			if self.isFirstBlood then
				player.self:sendMsg(('%s%s|r 拿下了|cffff3300第一滴血|r（|cffffcc00+%s|r）!'):format(
					p_from:getColorWord(),
					p_from.hero:get_name(),
					GOLD_FIRSTBLOOD
				))
				self.isFirstBlood = false
				p_from:addGold(GOLD_FIRSTBLOOD)
				--player.self:play_sound(self.doublekill_sound[1])
			end
			--超神称号 - 获得
			p_to.kill_holyshit = 0
			p_to.dead_holyshit = p_to.dead_holyshit + 1
			p_from.dead_holyshit = 0
			p_from.kill_holyshit = p_from.kill_holyshit + 1
			if p_from.kill_holyshit >= 3 then
				player.self:sendMsg(('%s%s|r %s'):format
				(
					p_from:getColorWord(),
					p_from.hero:get_name(),
					self.holyshit_title[math.min(p_from.kill_holyshit,10)]
				))
			end
			--连杀称号
			local gametime = ac.clock() / 1000
			if gametime - p_from.kill_doublekill_time > 22 then
				p_from.kill_doublekill = 0
			end
			p_from.kill_doublekill_time = gametime
			p_from.kill_doublekill = p_from.kill_doublekill + 1
			if p_from.kill_doublekill >= 2 then
				local temp_lv = p_from.kill_doublekill
				ac.wait(1600, function()
					player.self:sendMsg(('%s%s|r %s'):format
					(
						p_from:getColorWord(),
						p_from.hero:get_name(),
						self.doublekill_title[math.min(temp_lv,5)]
					))
					--player.self:play_sound(self.doublekill_sound[math.min(temp_lv,5)])
				end)
			end
		else
			--自杀或死因不明
			player.self:sendMsg(('%s%s|r 被自己萌死了!'):format(
				p_to:getColorWord(),
				p_to.hero:get_name()
			))
		end
	else
		if p_from == player[13] then
			--被中立生物所击杀
			player.self:sendMsg(('%s%s|r 被中立生物萌死了!'):format(
				p_to:getColorWord(),
				p_to.hero:get_name()
			))
		else
			--被阵营玩家所击杀
			--超神称号 - 终结
			if p_to.kill_holyshit >= 3 then
				player.self:sendMsg(('小兵 终结了 %s%s|r 的 %s'):format(
					p_to:getColorWord(),
					p_to.hero:get_name(),
					self.holyshit_shutdown[math.min(p_to.kill_holyshit,10)]
				))
			else
				--非终结时显示正常击杀（萌死）
				player.self:sendMsg(('%s%s|r 被小兵萌死了!'):format(
					p_to:getColorWord(),
					p_to.hero:get_name()
				))
			end
			p_to.kill_holyshit = 0
			p_from = ac.player.com[p_to:get_team() % 2 + 1]
		end
	end

	p_from:event_notify('玩家-击杀英雄', p_from, p_to, assist_table)
end)
end)

return self
