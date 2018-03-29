
local map = require 'maps.map'

require 'maps.army.init_army'
require 'maps.army.create_army'
require 'maps.army.way_point'

local self = {}

function self.init()
	--注册路径点
	map.initWayPoint()
	--启动刷兵
	map.createArmy()
end

return self