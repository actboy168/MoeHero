require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local process = require "process"

local std_print = print
local function print(...)
    local t = table.pack(...)
    for i = 1, t.n do
        t[i] = uni.u2a(tostring(t[i]))
    end
    std_print(table.concat(t, '\t'))
end

local input_path = fs.path(uni.a2u(arg[2]))
local function unpack_command()
    local commands = {
        ('"%s"'):format(input_path:string()),
        '-lni',
        ('"-config=%s"'):format(fs.current_path() / 'unpack_config.ini'),
    }
    return table.concat(commands, ' ')
end

local function unpack(path)
    local application = fs.current_path() / 'w3x2lni' / 'bin' / 'w2l-worker.exe'
    local entry = fs.current_path() / 'w3x2lni' / 'script' / 'map.lua'
    local currentdir = fs.current_path() / 'w3x2lni' / 'script'
    local command_line = ('"%s" -e "package.cpath=[[%s]]" "%s" %s'):format(application:string(), package.cpath, entry:string(), unpack_command())
	local p = process()
	p:hide_window()
	local stdout, stderr = p:std_output(), p:std_error()
	if not p:create(application, command_line, currentdir) then
		print(string.format("Executed %s failed", command_line))
		return -1, nil, nil
	end
	print(string.format("Executed %s.", command_line))
    local out = stdout:read 'a'
    local err = stderr:read 'a'
    local exit_code = p:wait()
    p:close()
end

if fs.is_directory(input_path) then
    pack(input_path)
else
    unpack(input_path)
end
message('[完毕]: 用时 ' .. os.clock() .. ' 秒')
