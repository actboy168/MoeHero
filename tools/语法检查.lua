require 'luabind'
require 'filesystem'
local uni = require 'unicode'

local function for_directory(path, f)
	for p in path:list_directory() do
		if fs.is_directory(p) then
			for_directory(p, f)
		else
			f(p)
		end
	end
end

local succeed, failed = 0, 0
for_directory(fs.path(arg[1]), function(filename)
    if filename:extension():string():lower() ~= '.lua' then
        return
    end
    local r, e = loadfile(uni.u2a(filename:string()), 't')
    if not r then
        failed = failed + 1
        print(uni.a2u(e))
    else
        succeed = succeed + 1
    end
end)
print(string.format('成功 %d 个, 失败 %d 个', succeed, failed))
