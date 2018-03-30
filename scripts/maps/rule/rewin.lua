
	local jass = require 'jass.common'
	local hero = require 'types.hero'

	local self = {}
	local all_lb = {}
	local gameover

	ac.game:event '游戏-结束' (function()
		gameover = true
	end)

	for i = 1,10 do
		all_lb[i] = jass.CreateLeaderboard()
		all_lb[i+10] = 0
	end
	--使用排行榜

	--设置指定玩家的复活计时
	function self.Setlbtime(player,t)
		local id = jass.GetPlayerId(player.handle)+1
		local lb = all_lb[id]
		all_lb[id+10] = t
	end

	
	function self.re_ct(player,hero,retime,...)
		local id = jass.GetPlayerId(player.handle)+1
		local lb = all_lb[id]
		jass.LeaderboardSetStyle(lb, false, true, true, false)
		if player.handle==jass.GetLocalPlayer() then
			jass.PlayerSetLeaderboard(player.handle,lb)
			jass.LeaderboardDisplay(lb,true)
		end
		jass.LeaderboardAddItem(lb,'|cffffcc00复活时间:',0,player.handle)
		jass.LeaderboardSetSizeByItemCount(lb,jass.LeaderboardGetItemCount(lb)-1)
		jass.LeaderboardSetItemValue(lb,0,retime)
		all_lb[id+10] = retime
		ac.loop(1000,function(t)
			if gameover then
				t:remove()
			end
			if hero:is_alive() then
				all_lb[id+10] = 0
			else
				all_lb[id+10] = all_lb[id+10] - 1
			end
			jass.LeaderboardSetItemValue(lb,0,all_lb[id+10])
			if all_lb[id+10]<1 then
				if not hero:is_alive() then
					hero:revive(hero:getBornPoint())
				end
				jass.LeaderboardRemovePlayerItem(lb,player.handle)
				jass.LeaderboardDisplay(lb,false)
				t:remove()
			end
		end)
	end

	--获取指定玩家的剩余复活时间
	function self.getReviveTime(p)
		local id = p:get()
		return all_lb[id + 10]
	end

	return self