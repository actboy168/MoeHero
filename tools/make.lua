require 'filesystem'
local uni = require 'ffi.unicode'
local process = require "process"


function io.load(file_path)
    local f, e = io.open(file_path:string(), "rb")
    if f then
        if f:read(3) ~= '\xEF\xBB\xBF' then
            f:seek('set')
        end
        local content = f:read 'a'
        f:close()
        return content
    else
        return false, e
    end
end

function io.save(file_path, content)
    local f, e = io.open(file_path:string(), "wb")
    if f then
        f:write(content)
        f:close()
        return true
    else
        return false, e
    end
end

local std_print = print
local function print(...)
    local t = table.pack(...)
    for i = 1, t.n do
        t[i] = uni.u2a(tostring(t[i]))
    end
    std_print(table.concat(t, '\t'))
end

local function message(msg)
    if msg:sub(1, 9) == '-progress' or
       msg:sub(1, 7) == '-report' or
       msg:sub(1, 4) == '-tip'
    then
        return
    end
    print('w3x2lni:', msg)
end

local function call_w2l(commands)
    local application = fs.current_path() / 'w3x2lni' / 'bin' / 'w2l-worker.exe'
    local entry = fs.current_path() / 'w3x2lni' / 'script' / 'map.lua'
    local currentdir = fs.current_path() / 'w3x2lni' / 'script'
    local command_line = ('"%s" "%s" %s'):format(application:string(), entry:string(), commands)
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
end

local mode = arg[1]
local input_path = fs.path(uni.a2u(arg[2]))
local function lni_command()
    local commands = {
        ('"%s"'):format(input_path:string()),
        ('"%s"'):format((input_path:parent_path() / 'MoeHero'):string()),
        '-lni',
        ('"-config=%s"'):format(fs.current_path() / 'config.ini'),
    }
    return table.concat(commands, ' ')
end

local function obj_command()
    local commands = {
        ('"%s"'):format(input_path:string()),
        ('"%s"'):format((input_path:parent_path() / 'MoeHero.w3x'):string()),
        '-obj',
        ('"-config=%s"'):format(fs.current_path() / 'config.ini'),
    }
    return table.concat(commands, ' ')
end

local function slk_command()
    local commands = {
        ('"%s"'):format(input_path:string()),
        ('"%s"'):format((input_path:parent_path() / 'MoeHero.w3x'):string()),
        '-slk',
        ('"-config=%s"'):format(fs.current_path() / 'config.ini'),
    }
    return table.concat(commands, ' ')
end

local function lni(path)
    local map_path = fs.current_path():parent_path() / 'MoeHero'
    local jass = io.load(map_path / 'jass' / 'war3map.j')
	call_w2l(lni_command())
    io.save(map_path / 'jass' / 'war3map.j', jass)
end

local function obj(path)
    local map_path = fs.current_path():parent_path() / 'MoeHero'
    local resource_path = map_path:parent_path() / 'resource'
    io.save(map_path / 'lua' / 'lua' / 'currentpath.lua', ([=[return [[%s\script\]]]=]):format(fs.current_path():parent_path():string()))
    if fs.exists(resource_path) then
        fs.rename(resource_path, map_path / 'resource')
    end
    call_w2l(obj_command())
    fs.remove(map_path / 'lua' / 'lua' / 'currentpath.lua')
    if fs.exists(map_path / 'resource') then
        fs.rename(map_path / 'resource', resource_path)
    end
end

local function slk(path)
    local map_path = fs.current_path():parent_path() / 'MoeHero'
    local resource_path = map_path:parent_path() / 'resource'
    local script_path = map_path:parent_path() / 'script'
    if fs.exists(resource_path) then
        fs.rename(resource_path, map_path / 'resource')
    end
    if fs.exists(script_path) then
        fs.rename(script_path, map_path / 'lua' / 'script')
    end
    call_w2l(slk_command())
    if fs.exists(map_path / 'resource') then
        fs.rename(map_path / 'resource', resource_path)
    end
    if fs.exists(map_path / 'lua' / 'script') then
        fs.rename(map_path / 'lua' / 'script', script_path)
    end
end

if fs.is_directory(input_path) then
    if mode == 'debug' then
        obj(input_path)
    else
        slk(input_path)
    end
else
    lni(input_path)
end
print('[完毕]: 用时 ' .. os.clock() .. ' 秒')
