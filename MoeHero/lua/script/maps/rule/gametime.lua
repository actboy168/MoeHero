local jass = require 'jass.common'
local player = require 'ac.player'
local unit = require 'types.unit'

local self = {}
-- 设置空格键朝向
function self.spaceturn(p,x,y)
	if p == player.self then
		jass.SetCameraQuickPosition(x,y)
	end
end
-- 设置玩家木材，当前人口(时间)
function self.stime(p)
	if player.getusedfood(p)>=59 then
		player.addlumber(p,1)
		jass.SetPlayerState(p.handle,jass.PLAYER_STATE_RESOURCE_FOOD_USED,0)
	else
		player.addusedfood(p,1)
	end		
end

-- 计时器
function self.gt()
	ac.loop(1000, function()
		for i = 1, 10 do
			self.stime(player[i])
		end
	end)
end

return self
