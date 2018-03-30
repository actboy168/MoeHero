require 'filesystem'

local function for_directory(path, f)
	for p in path:list_directory() do
		if fs.is_directory(p) then
			for_directory(p, f)
		else
			f(p)
		end
	end
end

local function compilation(path)
    local succeed, failed = 0, 0
    local res = ''
    for_directory(path, function(filename)
        if filename:extension():string():lower() ~= '.lua' then
            return
        end
        local r, e = loadfile(filename:string(), 't')
        if not r then
            failed = failed + 1
            res = res .. e
        else
            succeed = succeed + 1
        end
    end)
    return res, succeed, failed
end

local root = fs.path(arg[1])
local script = root / 'scripts'
local watch = arg[2] == '--watch'

if not watch then
    local res, succeed, failed = compilation(script)
    print(res)
    print(string.format('成功 %d 个, 失败 %d 个', succeed, failed))
    return
end

-- TODO: 使用`ReadDirectoryChangesW`之类的API实现
local ffi = require 'ffi'
ffi.cdef[[
    void Sleep(unsigned long dwMilliseconds);
]]

local last = ''
while true do
    local res, succeed, failed = compilation(script)
    if last ~= res then
        last = res
        print('[Watch] File change detected.')
        if last ~= '' then
            print(last)
        end
        print('[Watch] Complete.')
    end
    ffi.C.Sleep(1000)
end
