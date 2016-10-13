
local jass = require 'jass.common'
local player = require 'ac.player'
local unit = require 'types.unit'
local point = require 'ac.point'
local table = table

local sound = {}

local mt = {}
sound.__index = mt

--音效池
local pool = {}
sound.pool = pool

--将音效放入音效池
--	路径名
--	音效
function sound.pool_add(name, sound)
	local list = pool[name]
	if not list then
		list = {}
		pool[name] = list
	end
	table.insert(list, sound)
end

--从音效池取出音效
--	路径名
--	@音效
function sound.pool_get(name)
	local list = pool[name]
	if not list then
		return
	end
	local sound = list[#list]
	table.remove(list)
	log.info('音效池', name)
	return sound
end

--音效长度注册
sound.dur_list = {}

function sound.init(file_name, dur)
	sound.dur_list[file_name] = dur
end

function sound.get_duration(name)
	return sound.dur_list[name] or 0
end

function sound.set_duration(snd, name)
	local dur = sound.get_duration(name)
	if dur == 0 then
		dur = 10000
		sound.init(name, dur)
		log.warn('没有注册的音效:' .. name)
		log.info(([=[sound.init([[%s]], %d)]=]):format(name, jass.GetSoundDuration(snd)))
	end
	jass.SetSoundDuration(snd, dur)
end

--创建音效
--	音效路径
function sound.create(name)
	local snd = jass.CreateSound(name, false, false, false, 10, 10, '')
	log.info('音效创建', name, jass.GetSoundDuration(snd))
	jass.SetSoundChannel(snd, 0)
	jass.SetSoundVolume(snd, 127)
	jass.SetSoundPitch(snd, 1)
	jass.SetSoundDistances(snd, 1250, 1800)
	jass.SetSoundDistanceCutoff(snd, 3000)
	jass.SetSoundConeAngles(snd, 0, 0, 127)
	jass.SetSoundConeOrientation(snd, 0, 0, 0)
	sound.set_duration(snd, name)
	
	--jass.StartSound(snd)
	--jass.StopSound(snd, false, false)
	--print('snd', name)
	return snd
end

--额外参数
function sound:__call(data)
	if self.player and self.player ~= ac.player.self then
		return
	end
	-- 音量[0-1]
	if data.volume then
		jass.SetSoundVolume(self.handle, data.volume * 127)
	end
	-- 播放速度[0-1]
	if data.pitch then
		jass.SetSoundPitch(self.handle, data.pitch)
	end
	return self
end

--玩家播放音效
--	路径
--	[占用规则]
function player.__index:play_sound(name, on_cover)
	if self._current_sound then
		if on_cover == '失败' then
			-- 当前通道被占用时播放失败
			return
		elseif on_cover == '等待' then
			-- 当前通道被占用时等待队列空闲再播放
			if not self._sound_queue then
				self._sound_queue = {}
			end
			table.insert(self._sound_queue, name)
			return
		else
			-- 当前通道被占用时结束当前音效播放新音效
			local snd = self._current_sound.handle
			jass.SetSoundVolume(snd, 0)
			jass.StopSound(snd, false, false)
			self._current_sound.timer:remove()
		end
	end
	local snd = sound.pool_get(name) or sound.create(name)
	jass.StartSound(snd)
	if self ~= player.self then
		jass.SetSoundVolume(snd, 0)
	end

	local data = setmetatable({handle = snd, player = self, name = name,}, sound)
	self._current_sound = data
	local dur = sound.get_duration(name)
	data.timer = ac.wait(dur, function()
		sound.pool_add(name, snd)
		self._current_sound = nil
		if self._sound_queue and #self._sound_queue > 0 then
			local name = table.remove(self._sound_queue)
			self:play_sound(name)
		end
	end)
	return data
end

--以点为目标播放音效
function point.__index:play_sound(name)
	local snd = sound.pool_get(name) or sound.create(name)
	jass.SetSoundPosition(snd, self:get_point():get())
	jass.StartSound(snd)
	return setmetatable({handle = snd}, sound)
end

--以单位为目标播放音效
function ac.unit.__index:play_sound(name)
	local snd = sound.pool_get(name) or sound.create(name)
	jass.AttachSoundToUnit(snd, self.handle)
	jass.StartSound(snd)
	return setmetatable({handle = snd}, sound)
end

--获得武器音效名
--	目标单位
--	[使用哪一个音效,一共有3个,如果不指定则随机]
--	[武器类型]
function unit.__index:get_weapon_sound(target, weapon_type, n)
	local weapon_type = weapon_type or self:get_slk 'weapType1'
	local armor = target:get_slk 'armor'
	return [[Sound\Units\Combat\]] .. weapon_type .. armor .. (n or math.random(1, 3)) .. '.wav'
end

return sound
