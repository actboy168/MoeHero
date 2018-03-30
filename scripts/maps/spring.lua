local player = require 'ac.player'

local spring = {}

--开始瀑布流程
function spring.start()
	--瀑布冲击
	spring.createWave()

	--踏浪而行
	spring.springStart()

	ac.wait(60000, function()
		--关闭踏浪而行
		spring.springStop()
	end)
end

local function spring_add(t)
	for k, v in pairs(t) do
		spring[k] = v
	end
end

function spring.init()
	spring_add(require 'maps.spring.river')
	spring_add(require 'maps.spring.wave')
	spring_add(require 'maps.spring.box')

	require 'maps.spring.buff'

	--每7分钟开始一次地图事件
	ac.game:event '游戏-开始' (function(trg)
		trg:remove()
		
		ac.loop(5 * 60 * 1000, function()
			spring.start()
		end)
	end)
end

return spring
