
local jass = require 'jass.common'
local rect = require 'types.rect'
local player = require 'ac.player'

--禁用战争迷雾
jass.FogEnable(false)
jass.FogMaskEnable(false)

--1秒后启用战争迷雾
ac.timer(1000, 1, function()
	jass.FogEnable(true)
end)

--在瀑布处创建一个视野单位
player[16]:create_unit('e009', rect.j_rect 'Vision')
