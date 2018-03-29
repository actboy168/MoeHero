rawset(_G, 'poi', {})

require 'maps.tower.防御塔-强化'

local map = {}

map.map_name = 'LOL'

ac.game:event '游戏-开始' (function()
	--刷兵
	local army = require 'maps.army'
	army.init()

	--启用计时
	local gamet = require 'maps.rule.gametime'
	gamet.gt() 
end)

function map.init()
	--加载地图规则
	require 'maps.rule.init'

	--注册不可通行区域
	map.pathRegionInit()

	--注册瀑布机制
	local spring = require 'maps.spring'
	spring.init()

	--注册野怪
	local creeps = require 'maps.creeps'
	creeps.init()

	--注册防御塔
	require 'maps.tower.init'

	--注册英雄
	require 'maps.hero.init'

	--注册物品
	require 'maps.map_item._init'

	--注册商店
	require 'maps.map_shop.init'

	--注册智能施法
	require 'maps.smart_cast.init'

	--等待选人结束
	require 'maps.choose_hero.init'
end

return map
