
local jass = require 'jass.common'
local player = require 'ac.player'

local sync = {}

--缓存文件
sync.gc = jass.InitGameCache 'U'
sync.using	= {} --记录正在使用的
sync.str	= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
sync.len	= #sync.str
sync.strs	= {}
for i = 1, sync.len do
	sync.strs[i] = sync.str:sub(i, i)
end

--获取路径
function sync.getKey(i)
	local r = ''
	while i > 0 do
		local n	= (i - 1) % sync.len + 1
		i = math.floor(i / sync.len)
		r = sync.strs[n] .. r
	end
	return r
end

--同步整数
--	数据表(key为字符串,value必须是整数.要求所有玩家都知道正确的key(即不同步key))
--	同步完成后回调的函数
function player.__index:sync(data, func)
	--print(('Start Sync: %s\t%s'):format(self:get(), func))
	if self:isObserver() or not self:is_player() then
		print(('sync.lua warning:player %d is not an alive player'):format(self:get()))
		return
	end
	local i 	= 0
	local index = 0
	for n = 1, 36 do
		if not sync.using[n] then
			sync.using[n]	= data
			index	= n
			break
		end
	end
	if index == 0 then
		error('sync.lua error:Could not find idle index', 2)
		return
	end
	local first	= sync.str:sub(index, index)
	--print(('sync[%d]: first = %s'):format(self:get(), first))
	local keys	= {}
	for name, value in pairs(data) do
		i	= i + 1
		keys[i]	= name
		local key = sync.getKey(i)
		--print(('player[%d] sync start: %s = %s'):format(self:get(), name, value))
		if value ~= 0 then
			if self:is_self() then
				--将数据保存到缓存中
				jass.StoreInteger(sync.gc, first, key, value)
				--发起同步
				jass.SyncStoredInteger(sync.gc, first, key)
			end
		end
		--清空本地数据
		jass.StoreInteger(sync.gc, first, key, 0)
	end
	--发送一个结束标记
	if self:is_self() then
		jass.StoreInteger(sync.gc, first, '-', 1)
		jass.SyncStoredInteger(sync.gc, first, '-')
	end
	jass.StoreInteger(sync.gc, first, '-', 0)

	local times	= 0
	--开启计时器,等待同步完成
	ac.loop(100,
		function(t)
			--检查是否同步完成
			if jass.GetStoredInteger(sync.gc, first, '-') == 0 then
				--检查是否还在游戏中
				if not self:is_player() then
					sync.using[index]	= nil
					t:remove()
					if func then
						func(false)
					end
				end
				times	= times + 1
				if times > 1000 then
					sync.using[index]	= nil
					t:remove()
					print('数据同步超时!')
					log.error('数据同步超时!')
					if func then
						func(false)
					end
				end
				return
			end
			sync.using[index]	= nil
			t:remove()
			--同步完成,开始写回数据
			local data	= {}
			for i, name in ipairs(keys) do
				data[name]	= jass.GetStoredInteger(sync.gc, first, sync.getKey(i))
				--print(('player[%d] synced: %s = %s'):format(self:get(), name, data[name]))
			end
			--回调数据
			--print(('Ready Sync: %s\t%s'):format(self:get(), func))
			if func then
				func(data)
			end
		end
	)
end

--同步完全的数据
--	数据表(key为字符串, value为字符串.其他玩家可以不知道key)
--	同步完成时的回调函数
function player.__index:syncText(data, func)

	local texts = {}

	local ints	= {}
	--先发送文本数量与每个文本的长度

	for key, text in pairs(data) do
		key		= tostring(key)
		text	= tostring(text)
		table.insert(texts, key)
		table.insert(texts, text)
		table.insert(ints, #key)
		table.insert(ints, #text)
	end

	table.insert(ints, 1, #texts / 2)

	--拼成一个长文本
	local all_text = table.concat(texts)

	--全部拆成整数,每4个字节存在一个整数里
	for i = 1, math.ceil(#all_text / 4) do
		local text	= all_text:sub(i * 4 - 3, i * 4)
		local int	= base.string2id(text) - 2 ^ 31
		table.insert(ints, int)
	end

	--先同步长度
	self:sync(
		{count = #ints},
		function(data)
			if not data then
				func(false)
				return
			end
			if not self:is_self() then
				for i = 1, data.count do
					ints[i] = 0
				end
			end
			--同步所有的整数
			self:sync(
				ints,
				function(data)
					if not data then
						func(false)
						return
					end
					--文本数量
					local text_count = data[1]
					local key_lens	= {}
					local text_lens	= {}
					local all_len	= 0
					
					for i = 1, text_count do
						--key的长度
						key_lens[i]		= data[i * 2]
						--文本的长度
						text_lens[i]	= data[i * 2 + 1]
						--文本总长度
						all_len = all_len + key_lens[i] + text_lens[i]
					end

					--拼出长文本
					local texts = {}
					for i = text_count * 2 + 2, #data do
						table.insert(texts, base.id2string(data[i] + 2 ^ 31))
					end

					local all_text = table.concat(texts):sub(1, all_len)

					--取出文本
					local pos = 0
					local function read(len)
						local text = all_text:sub(pos + 1, pos + len)
						pos = pos + len
						return text
					end

					--循环取出每个key和text
					for i = 1, text_count do
						local key	= read(key_lens[i])
						local text	= read(text_lens[i])
						data[key]	= text
					end

					if func then
						func(data)
					end
				end
			)
		end
	)
	
end