
local player = require 'ac.player'

--初始1000块钱
for i = 1, 10 do
	player[i]:addGold(1000)
end

--每秒8块钱
local t
local gold = 8
local player_count = {5, 5}

ac.game:event '游戏-开始' (function()
	t = ac.timer(1000 / 5, 0, function()
		for team = 1, 2 do
			local tp = player.force[team]
			local g = gold / player_count[team]
			for i = 1, 5 do
				local p = tp[i]
				if p:is_player() then
					p:addGold(g)
				end
			end
		end
	end)
end)

ac.game:event '游戏-结束' (function()
	t:remove()
end)

ac.game:event '玩家-离开' (function(trg, p)
	local team = p:get_team()
	local count = 0

	--卖掉身上的装备
	local hero = p.hero
	if hero then
		for i = 1, 6 do
			local it = hero:find_skill(i, '物品')
			if it then
				it:sell()
			end
		end
	end
	
	--分钱,改工资
	local g = p:getGold()
	p:addGold(- g)
	player_count[team] = player_count[team] - 1
	if player_count[team] > 0 then
		for i = 1, 5 do
			local fp = player.force[team][i]
			if fp:is_player() and p ~= fp then
				fp:addGold(g / player_count[team])
			end
		end
	end
end)
