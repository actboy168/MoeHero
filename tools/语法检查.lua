local fs = require 'bee.filesystem'

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

local fw = require 'filewatch'
local ffi = require 'ffi'
ffi.cdef[[
    void Sleep(unsigned long dwMilliseconds);
]]

local last = ''
local watch = assert(fw.add(script:string(), 'fdts'))
local guard = assert(fw.add(root:string(), 'd'))

local function notifychage()
    local res, succeed, failed = compilation(script)
    if last ~= res then
        last = res
        print('[Watch] File change detected.')
        if last ~= '' then
            print(last)
        end
        print('[Watch] Complete.')
    end
end

notifychage()

while true do
    local change = false
    while true do
        local id, type, path = fw.select()
        if id then
            if id == watch then
                change = true
            elseif id == guard and path == name then
                if watch and (type == 'delete' or type == 'rename from') then
                    fw.remove(watch)
                    watch = nil
                    change = false
                elseif not watch and (type == 'create' or type == 'rename to') then
                    watch = assert(fw.add(script:string(), 'fdts'))
                    change = false
                end
            end
        else
            break
        end
    end
    if change then
        change = false
        notifychage()
    end
    ffi.C.Sleep(200)
end
