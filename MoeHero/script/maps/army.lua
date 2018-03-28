
local map = require 'map'

require 'army.init_army'
require 'army.create_army'
require 'army.way_point'

local self = {}

function self.init()
	--注册路径点
	map.initWayPoint()
	--启动刷兵
	map.createArmy()
end

return self