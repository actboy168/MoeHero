
local response = require 'maps.response'
local hero = require 'types.hero'
local jass = require 'jass.common'

local list = {''}

local function load_sound(file_name)
	local sound = jass.CreateSound(file_name, false, false, false, 10, 10, '')
	local dur = jass.GetSoundDuration(sound)
	--log.info('load_sound', file_name)
	if dur == 0 then
		return false
	end
	table.insert(list, ([=[sound.init([[%s]], %d)]=]):format(file_name, dur))
	return true
end

--静态音效
local sounds = [[
response\御坂美琴\skill\R.mp3
response\立华奏\skill\R.mp3
response\阿尔托莉亚\skill\R.mp3
response\鹿目圆香\skill\R.mp3
Sound\Interface\Warning.wav
Sound\Interface\Error.wav
]]

for file_name in sounds:gmatch '%C+' do
	load_sound(file_name)
end

--英雄回应
local function load_hero_sound(type, file)
	--文件路径
	local dir = ([[response\%s\%s\]]):format(file, type)
	--尝试加载
	for i = 1, 99 do
		local file_name = dir .. i .. '.mp3'
		if not load_sound(file_name) then
			break
		end
	end
end

for i = 1, #hero.hero_list do
	load_hero_sound('what', hero.hero_list[i][1])
	load_hero_sound('move', hero.hero_list[i][1])
	load_hero_sound('attack', hero.hero_list[i][1])
	load_hero_sound('dead', hero.hero_list[i][1])
end

--武器音效
--武器类型
local weapons = {'Axe', 'Ethereal', 'Metal', 'Rock', 'Wood'}
--护甲类型
local armors = {'Wood', '', 'Flesh', 'Metal', 'Stone'}
--力度
local powers = {'Medium', 'Heavy', 'Light'}
--方式
local modes = {'Chop', 'Hit', 'Bash', 'Slice'}

local dir = [[Sound\Units\Combat\]]
for _, weapon in ipairs(weapons) do
	for _, armor in ipairs(armors) do
		for _, power in ipairs(powers) do
			for _, mode in ipairs(modes) do
				for i = 1, 3 do
					local file_name = dir .. weapon .. power .. mode .. armor .. i .. '.wav'
					load_sound(file_name)
				end
			end
		end
	end
end

log.info(table.concat(list, '\n'))