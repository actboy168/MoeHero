local game = {}

game.FRAME = 0.03

local observer = {}

function game.register_observer(name, ob)
	log.info('注册观察者', name)
	table.insert(observer, ob)
end

function game.init()
	ac.loop(game.FRAME * 1000, function()
		for _, ob in ipairs(observer) do
			ob()
		end
	end)
end

return game
