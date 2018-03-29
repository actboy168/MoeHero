local jass = require 'jass.common'
local heror = require 'types.hero'
local unit = require 'types.unit'
local rewin = require 'maps.rule.rewin'
local self = {};


function self.main()
	--注册英雄
	ac.game:event '玩家-注册英雄' (function(self, player, hero)
		--添加技能
		hero:add_all_hero_skills()
		
		--添加技能升级按钮
		hero:add_skill('技能升级', '隐藏')
		--添加一个技能点
		hero:addSkillPoint(1)

		--添加英雄属性面板
		hero:add_skill('英雄属性面板', '隐藏')

		--改玩家名字
		hero:get_owner():setName(('%s(%s)'):format(hero:get_owner():get_name(), hero:get_name()))
		
		--英雄死亡后复活
		hero:event '单位-死亡' (function()
			local lv = hero:get_level()
			local player = hero:get_owner()
			local time = math.floor(5 + lv * lv * 0.077)
			local lb = jass.CreateLeaderboard()
			rewin.re_ct(player,hero,time)
			player:sendMsg(('你将在 |cffffff00%d|r 秒后复活'):format(time))		
		end)
	end)

	--注册英雄升级
	ac.game:event '单位-英雄升级' (function(trg, hero)
		local hero_data = heror.hero_list[hero:get_name()].data

		--添加属性
		for k, v in pairs(hero_data.upgrade) do
			hero:add(k, v)
		end
		hero:add('冷却缩减', 1.5)

		if hero:is_hero() then
			--添加技能点
			hero:addSkillPoint(1)
		end
	end)
end

unit.__index.get_ad = function(self)
    return self:get '攻击'
end

pcall(self.main)

return self
