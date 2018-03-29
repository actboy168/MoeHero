
local rect = require 'types.rect'
local player = require 'ac.player'
local map = require 'maps.map'
local spring = require 'maps.spring'

local self = {}

function self.initWave()
	local wave1, wave2 = {}, {}

	local function f(wave)
		return function(rcts)
			for _, s in ipairs(rcts) do
				local rct = rect.j_rect('falls' .. s)
				table.insert(wave, rct:get_point())
			end
		end
	end

	f(wave1)
	{
		'1',
		'2',
		'3_1',
		'4_1',
		'5_1',
		'6_1',
		'7',
		'8',
	}

	f(wave2)
	{
		'1',
		'2',
		'3_2',
		'4_2',
		'5_2',
		'6_2',
		'7',
		'8',
	}

	return wave1, wave2
	
end

function self.createWave()
	local units_mark = {}
	local river = require('maps.spring').river
	--删掉旧的宝箱
	if map.box then
		map.box:remove()
	end
	
	player.self:sendMsg '|cffff1111瀑布激流出现啦,下路即将出现宝箱|r'
	player.self:pingMinimap(rect.j_rect 'treasure', 30)

	local jarray = {2, 1}
	ac.timer(100, 2, function ()
		local j = jarray[1]
		table.remove(jarray, 1)
		local wave = self['wave' .. j]
		local mvr
		
		local wave_count = 0
		local function getNextPoint()
			wave_count = wave_count + 1
			if wave[wave_count] then
				return wave[wave_count]
			else
				if j == 1 then
					spring.createBox()
				end
				mvr.mover:remove()
			end
		end
		
		--创建一个弹幕
		mvr = ac.mover.target
		{
			source = getNextPoint(),
			target = getNextPoint(),
			speed = 1000,
			size = 2,
			model = [[]],
			on_move_skip = 2,
			skill = false,
		}

		if not mvr then
			return
		end

		function mvr:on_move(_, count)
			local mover = self.mover
			local face = mover:get_facing()
			local p = mover:get_point()
			if river < mover then
				for i = 1, 3 do
					local p = p - {face + 135, i * 50} - {face, 100 * j}
					p:add_effect([[Abilities\Spells\Other\CrushingWave\CrushingWaveDamage.mdl]]):remove()
				end
				for i = 0, 3 do
					local p = p - {face - 135, i * 50} - {face, 100 * j}
					p:add_effect([[Abilities\Spells\Other\CrushingWave\CrushingWaveDamage.mdl]]):remove()
				end
			else
				for x = 1, 3 do
					local max = 1 + x * 1
					for y = 1, max do
						local p = p - {360 / max * y + count * 30, 100 * x}
						p:add_effect([[Abilities\Spells\Other\CrushingWave\CrushingWaveDamage.mdl]]):remove()
					end
				end
			end

			--击退附近的单位
			if river < mover then
				for _, u in ac.selector()
					: in_range(mover, 300)
					: is_not(mover)
					: add_filter(function(u)
						return not units_mark[u]
					end)
					: ipairs()
				do
					units_mark[u] = true

					u:add_buff '击退'
					{
						source = mover,
						angle = mover:get_facing(),
						speed = self.speed,
						distance = 500,
					}
				end
			else
				for _, u in ac.selector()
					: in_range(mover, 500)
					: is_not(mover)
					: add_filter(function(u)
						return not units_mark[u]
					end)
					: ipairs()
				do
					units_mark[u] = true

					u:add_buff '击退'
					{
						source = mover,
						angle = mover:get_point() / u:get_point(),
						speed = self.speed,
						distance = 500,
					}
				end
			end
			
		end

		local function addOnFinish()
			function mvr:on_finish()
				local p = getNextPoint()
				if p then
					self.target = p
					addOnFinish()
					return true
				end
			end
		end

		addOnFinish()
	end)
end

function self.main()
	self.wave1, self.wave2 = self.initWave()

	return self
end

return self.main()
