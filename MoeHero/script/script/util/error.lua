
local runtime = require 'jass.runtime'
local jass = require 'jass.common'

local log = log

local msgs = {}

--错误汇报
function base.error_handle(msg)
	print("---------------------------------------")
	if not msgs[msg] or ac.clock() - msgs[msg] >= 10000 then
		msgs[msg] = ac.clock()
		jass.DisplayTimedTextToPlayer(jass.GetLocalPlayer(), 0, 0, 60, msg)
	end
	log.error(msg)
	print("---------------------------------------")
end
