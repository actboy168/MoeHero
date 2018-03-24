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

local function message(msg)
    if msg:sub(1, 9) == '-progress' then
        return
    end
    print('w3x2lni:', msg)
end

local mode = arg[1]
local input_path = fs.path(uni.a2u(arg[2]))
local function unpack_command()
    local commands = {
        ('"%s"'):format(input_path:string()),
        ('"%s"'):format((input_path:parent_path() / 'MoeHero'):string()),
        '-lni',
        ('"-config=%s"'):format(fs.current_path() / 'unpack_config.ini'),
    }
    return table.concat(commands, ' ')
end

local function save_files()
    local map_path = fs.current_path():parent_path() / 'MoeHero'
    local jass = io.load(map_path / 'jass' / 'war3map.j')
    return function ()
        io.save(map_path / 'jass' / 'war3map.j', jass)
    end
end

local function unpack(path)
    local application = fs.current_path() / 'w3x2lni' / 'bin' / 'w2l-worker.exe'
    local entry = fs.current_path() / 'w3x2lni' / 'script' / 'map.lua'
    local currentdir = fs.current_path() / 'w3x2lni' / 'script'
    local command_line = ('"%s" "%s" %s'):format(application:string(), entry:string(), unpack_command())
    local save_point = save_files()
	local p = process()
	p:hide_window()
	local stdout, stderr = p:std_output(), p:std_error()
	if not p:create(application, command_line, currentdir) then
		error('运行失败：\n'..command_line)
    end
    while true do
        local out = stdout:read 'l'
        if out then
            message(out)
        else
            break
        end
    end
    local err = stderr:read 'a'
    local exit_code = p:wait()
    p:close()
    if err ~= '' then
        print(err)
    end
    save_point()
end

if fs.is_directory(input_path) then
    pack(input_path)
else
    unpack(input_path)
end
print('[完毕]: 用时 ' .. os.clock() .. ' 秒')
