local creeps = {}

function creeps.init()
	--刷野
	require 'maps.creeps.creeps_create'

	--野怪AI
	require 'maps.creeps.AI'

	--监听游戏开始事件,刷野
	ac.game:event '游戏-开始' (function()
		creeps.start()
	end)
end

return creeps
