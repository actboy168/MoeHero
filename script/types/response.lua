
local jass = require 'jass.common'
local game = require 'types.game'
local player = require 'ac.player'
local sound = require 'types.sound'

local response = {}

--已加载的声音
response.what = {}
response.move = {}
response.attack = {}
response.dead = {}

--加载声音
function response.load_sound(type, hero)
	local file = hero.file
	if not file then
		return
	end
	if response[type][file] then
		return
	end
	local sounds = {}
	local temp

	--文件路径
	local dir = ([[response\%s\%s\]]):format(file, type)
	--尝试加载
	for i = 1, 99 do
		local file_name = dir .. i .. '.mp3'
		local snd = jass.CreateSound(file_name, false, false, false, 10, 10, '')
		local dur = sound.get_duration(file_name)
		if dur == 0 then
			if jass.GetSoundDuration(snd) == 0 then
				jass.KillSoundWhenDone(snd)
				break
			end
			jass.KillSoundWhenDone(snd)
			if not temp then
				temp = {}
			end
			table.insert(temp, ([=[sound.init([[%s]], %d)]=]):format(file_name, jass.GetSoundDuration(snd)))
		end
		jass.SetSoundVolume(snd, 0)
		jass.StartSound(snd)
		jass.KillSoundWhenDone(snd)
		
		sounds[i] = file_name
	end
	if temp then
		log.info('没有注册的音效\n' .. table.concat(temp, '\n'))
	end

	hero['sound_' .. type] = 0
	response[type][file] = sounds
	return sounds
end

--播放声音
function response.play_sound(type, hero, ignore_cd)
	local file = hero.file
	if not file then
		return
	end

	--查找回应列表
	local sounds = response[type][file]
	if not sounds then
		return
	end

	local max_count = #sounds
	if max_count == 0 then
		return
	end
	
	local time = ac.clock() / 1000

	--是否无视cd
	if ignore_cd then
		hero.response_idle_time = -99999
	end

	--上句回应是否说完
	if hero.response_idle_time + math.max(1, 12 - 2 * max_count) > time then
		return
	end

	--播放回应
	local key = 'sound_' .. type
	if not hero[key] then
		return
	end
	local count = hero[key] % max_count + 1
	hero[key] = count
	local file_name = sounds[count]
	local snd
	if ignore_cd then
		snd = hero:get_owner():play_sound(file_name)
	else
		snd = hero:get_owner():play_sound(file_name, '失败')
	end

	--回应间隔
	local dur = sound.get_duration(file_name)
	hero.response_idle_time = time + dur / 1000
end

--监听注册英雄
ac.game:event '玩家-注册英雄' (function(trg, player, hero)
	response.load_sound('what', hero)
	response.load_sound('move', hero)
	response.load_sound('attack', hero)
	response.load_sound('dead', hero)
	player:event '玩家-选择单位' (function ()
		response.play_sound('what', hero)
	end)
	hero:event '单位-发布指令' (function(_, _, order, target)
		if order == 'smart' and target then
			if target.type == 'unit' and target:is_enemy(hero) then
				response.play_sound('attack', hero)
			else
				response.play_sound('move', hero)
			end
		elseif order == 'attack' then
			response.play_sound('attack', hero)
		end
	end)
	hero:event '单位-死亡' (function ()
		response.play_sound('dead', hero, true)
	end)
end)

return response
