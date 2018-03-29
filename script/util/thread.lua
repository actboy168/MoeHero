
local runtime = require 'jass.runtime'
local jass = require 'jass.common'

local thread = {}
local msgs = {}

--错误汇报(带线程)
function thread.error_handle(msg, th)
	print("---------------------------------------")
	if not msgs[msg] then
		msgs[msg] = true
		jass.DisplayTimedTextToPlayer(jass.GetLocalPlayer(), 0, 0, 60, msg)
	end
	local trace = debug.traceback(th, msg)
	print(trace)
	log.error(trace)
	print("---------------------------------------")
end


--以线程模式运行函数
function thread.call(f, ...)
	local co = coroutine.create(f)
	local info = {coroutine.resume(co, ...)}
	if info[1] then
		return table.unpack(info, 2)
	else
		thread.error_handle(info[2], co)
	end
end

--等待时间
function thread.sleep(time_out)
	local co = coroutine.running()
	ac.wait(time_out * 1000, function ()
		local info = {coroutine.resume(co)}
		if not info[1] then
			thread.error_handle(info[2], co)
		end
	end)
	coroutine.yield()
end

--等待回调
function thread.wait(f)
	if not f then
		log.error('没有传入等待回调')
	end
	
	local co = coroutine.running()
	local function fo()
		local info = {coroutine.resume(co)}
		if not info[1] then
			thread.error_handle(info[2], co)
		end
	end
	f(fo)
	coroutine.yield()
end

return thread