

local self = {}

function self.main()

	--禁止A队友
	ac.game:event '单位-攻击开始' (function(self, data)
		if data.target:is_ally(data.source) then
			data.source:issue_order 'stop'
			return true		--终结事件流程
		end
	end)

	--按下S后停止自动攻击
	ac.game:event '玩家-注册英雄' (function(_, _, hero)
		hero:event '单位-发布指令' (function(self, hero, order, target, player_order)
			if player_order then
				if order == 'stop' then
					hero:add_ability 'A00V'
				elseif order ~= '' then
					hero:remove_ability 'A00V'
				end
			end
		end)
	end)
	
	
	return self
end

return self.main()
