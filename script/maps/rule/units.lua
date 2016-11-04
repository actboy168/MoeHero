local player = require 'ac.player'
local hero = require 'types.hero'

--补兵数
player.__index.farm_count = 0

--小兵死亡加钱
ac.game:event '单位-杀死单位' (function(trg, source, target)
	if target:is_type('建筑') then
		return
	end
	local from_p = source and source:get_owner()
	--找到附近的英雄
	local heros = hero.getAllHeros()
	local group = {}
	for u in pairs(heros) do
		if u:is_alive() and (from_p == u:get_owner() or u:is_in_range(target, 1200)) and target:is_enemy(u) then
			table.insert(group, u)
		end
	end

	if #group == 0 then
		return
	end
	
	local len = #group
	local exp, gold = target.reward_exp, target.reward_gold
	--根据人数提高金钱和经验总量
	if exp and len > 1 then
		exp = exp * (1+0.15*(len -1))
	end
	if gold and len > 1 then
		gold = gold * (1+0.15*(len -1)) 
	end
	--附近英雄平分金钱和经验
	for _, hero in ipairs(group) do
		if exp then
			hero:addXp(exp / len)
		end
		if gold then
			hero:addGold(gold / len, target)
		end
		local p = hero:get_owner()
		p.farm_count = p.farm_count + 1 / len
	end
end)

--建筑死亡爆炸
ac.game:event '单位-死亡' (function(trg, target, source)
	if not target:is_type('建筑') then
		return
	end

	target:set_class '马甲'
	target:add_buff '淡化'
	{
		time = 1,
	}

	local team = target:get_owner():get_team()
	local killer_team
	if team == 1 then
		killer_team = 2
	elseif team == 2 then
		killer_team = 1
	end
	if not killer_team then
		return
	end
	local p = player.com[killer_team]
	player.self:sendMsg(('%s%s|r |cffff1111摧毁了一座建筑物|r'):format(p:getColorWord(), p:get_name()))
	--敌方全队加钱加经验
	if not killer_team then
		return
	end

	for i = 1, 5 do
		local p = player.force[killer_team][i]
		local hero = p.hero
		if hero then
			hero:addXp(500)
			hero:addGold(250)
		end
	end
end)
