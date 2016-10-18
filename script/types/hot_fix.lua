
local storm = require 'jass.storm'
local jass = require 'jass.common'
local player = require 'ac.player'
local table = table
local rsa = require 'util.rsa'

local hot_fix = {}

local ver_name = base.version
local dir_hot_fix = '我的英雄不可能那么萌\\热补丁\\' .. ver_name .. '\\'

local logs = {}

local function save_logs(log)
	table.insert(logs, log)
end

local function start_logs(p)
	local i = 0
	ac.loop(2000, function(t)
		i = i + 1
		local text = logs[i]
		if not text then
			return true
		end
		p:sendMsg(text)
	end)
end

local function show_logs()
	ac.game:event '玩家-注册英雄' (function(trg, player)
		start_logs(player)
	end)
	for i = 1, 10 do
		local p = player[i]
		if p.hero then
			start_logs(p)
		end
	end
end

--找最大值以及位置
local function maxn(...)
	local ns = {...}
	local mn, mi
	for i, n in ipairs(ns) do
		if not mn or n > mn then
			mn = n
			mi = i
		end
	end
	return mn, mi
end

-- 	新的热补丁流程如下
--	每个玩家验证自己的热补丁签名
-- 	每个玩家查询自己的热补丁版本号并同步
-- 	找到版本号最大的那个玩家,将整个热补丁文件与签名文件进行同步
-- 	所有玩家将本地热补丁与签名文件更新为该文件
-- 	所有玩家一起加载热补丁中的代码

function hot_fix.main(god_p)
	log.info('开始读取本地热补丁')
	hot_fix.file_name = 'hot_fix.lua'
	hot_fix.sign_name = 'hot_fix.sign'
	hot_fix.my_ver = 0
	hot_fix.my_map = ''
	hot_fix.my_content = ''
	hot_fix.my_sign = ''

	--读取热补丁内容
	local content = storm.load(dir_hot_fix .. hot_fix.file_name) or ''
	local sign
	
	if god_p and god_p == player.self then
		--计算热补丁签名
		sign = rsa:get_sign(content)
	else
		--读取签名文件
		sign = storm.load(dir_hot_fix .. hot_fix.sign_name) or ''
		--验证签名是否匹配
		if content ~= '' and not rsa:check_sign(content, sign) then
			content = ''
			log.warn('签名验证未通过')
		end
	end

	hot_fix.my_content = content
	hot_fix.my_sign = sign
	
	if hot_fix.my_content ~= '' and hot_fix.my_sign ~= '' then
		--读取热补丁地图版本号
		hot_fix.my_map = hot_fix.my_content:match '--map%=(%C+)'
		if hot_fix.my_map == ver_name then
			--读取热补丁版本号
			hot_fix.my_ver = hot_fix.my_content:match '--ver%=(%d+)'
			hot_fix.my_ver = tonumber(hot_fix.my_ver) or 0
		end
	end
	print('hot_fix_ver=' .. hot_fix.my_ver)

	--将热补丁版本号同步
	hot_fix.vers = {}

	local load_hot_fix
	local count = 0
	
	for i = 1, 10 do
		local p = god_p or player[i]
		if p:is_player() then
			p:sync(
				{ver = hot_fix.my_ver},
				function(data)
					count = count + 1
					if data then
						p.hot_fix_ver = data.ver
						hot_fix.vers[i] = data.ver
						print(('hot_fix_ver[%s]=%s'):format(i, data.ver))
					else
						print('热补丁版本号同步失败', i)
					end
					if count >= player.countAlive() then
						load_hot_fix()
					end
				end
			)
		else
			p.hot_fix_ver = 0
		end
		hot_fix.vers[i] = 0
	end

	local has_loaded = false

	--等待3秒后执行
	function load_hot_fix()
		if has_loaded then
			return
		end
		has_loaded = true
		--找到版本号最大的玩家
		local ver, n = maxn(table.unpack(hot_fix.vers))

		--所有玩家都没有热补丁
		if not ver or ver == 0 then
			log.info('无热补丁')
			return
		end

		hot_fix.ver = ver
		hot_fix.player = player[n]
		log.info(('[%s]同步热补丁,版本号为[%s]'):format(hot_fix.player:getBaseName(), hot_fix.ver))
		
		--版本号最大的玩家同步热补丁
		if not hot_fix.player:is_player() then
			log.info(('[%s]离开游戏,同步失败'):format(hot_fix.player:getBaseName()))
			return
		end

		--先同步签名文件
		hot_fix.player:syncText(
			{
				sign	= hot_fix.my_sign,
			},
			function(data)
				if not data then
					log.warn('签名文件同步失败')
					return
				end
				local sign = data.sign

				--再同步热补丁
				hot_fix.player:syncText(
					{
						content = hot_fix.my_content,
					},
					function(data)
						if not data then
							log.warn('热补丁文件同步失败')
							return
						end
						local content 	= data.content

						--验证签名是否匹配
						if not rsa:check_sign(content, sign) then
							log.warn('热补丁签名不匹配')
							return
						end

						--同学们,加载起热补丁啦
						hot_fix.my_content = content
						local func, res = load(hot_fix.my_content)
						if func then
							--运行热补丁函数
							local suc, res = pcall(func, save_logs)
							
							if suc then
								show_logs()
								--在本地生成该热补丁
								storm.save(dir_hot_fix .. hot_fix.file_name, content)
								log.info('生成热补丁,长度为' .. #content)

								--在本地生成该签名
								storm.save(dir_hot_fix .. hot_fix.sign_name, sign)
								log.info('生成签名文件,长度为' .. #sign)

								player.self:sendMsg(('来自[%s]的热补丁加载完成,版本为[%s]'):format(hot_fix.player:getBaseName(), hot_fix.ver))
							else
								log.error('热补丁运行错误')
								log.error(res)
							end					
						else
							log.error('热补丁语法错误')
							log.error(res)
						end
						
					end
				)
			end
		)
	end
end

ac.wait(0, function()
	hot_fix.main()
end)

return hot_fix
