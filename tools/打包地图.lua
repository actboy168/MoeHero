require 'filesystem'
local process = require "process"

local mode = arg[1]
local root = fs.path(arg[2])

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
    local application = root / 'tools' / 'w3x2lni' / 'bin' / 'w2l-worker.exe'
    local entry = root / 'tools' / 'w3x2lni' / 'script' / 'map.lua'
    local currentdir = root / 'tools' / 'w3x2lni' / 'script'
    local command_line = ('"%s" "%s" %s'):format(application:string(), entry:string(), commands)
    local p = process()
	p:hide_window()
	local stdout, stderr = p:std_output(), p:std_error()
	if not p:create(application, command_line, currentdir) then
		error('运行失败：\n'..command_line)
    end
    local outs = {}
    while true do
        local out = stdout:read 'l'
        if out then
            outs[#outs+1] = out
            message(out)
        else
            break
        end
    end
    io.save(root / 'log.txt', table.concat(outs, '\n'))
    local err = stderr:read 'a'
    local exit_code = p:wait()
    p:close()
    if err ~= '' then
        print(err)
    end
end

local function lni_command()
    local commands = {
        ('"%s"'):format((root / 'MoeHero.w3x'):string()),
        ('"%s"'):format((root / 'MoeHero'):string()),
        '-lni',
        ('"-config=%s"'):format(root / 'tools' / 'config.ini'),
    }
    return table.concat(commands, ' ')
end

local function obj_command()
    local commands = {
        ('"%s"'):format((root / 'MoeHero'):string()),
        ('"%s"'):format((root / 'MoeHero.w3x'):string()),
        '-obj',
        ('"-config=%s"'):format(root / 'tools' / 'config.ini'),
    }
    return table.concat(commands, ' ')
end

local function slk_command()
    local commands = {
        ('"%s"'):format((root / 'MoeHero'):string()),
        ('"%s"'):format((root / 'MoeHero.w3x'):string()),
        '-slk',
        ('"-config=%s"'):format(root / 'tools' / 'config.ini'),
    }
    return table.concat(commands, ' ')
end

local function lni()
    local map_path = root / 'MoeHero'
    local jass = io.load(map_path / 'jass' / 'war3map.j')
	call_w2l(lni_command())
    io.save(map_path / 'jass' / 'war3map.j', jass)
end

local function obj()
    local map_path = root / 'MoeHero'
    io.save(map_path / 'script' / 'lua' / 'currentpath.lua', ([=[return [[%s\MoeHero\script\script\]]]=]):format(root:string()))
    call_w2l(obj_command())
    fs.remove(map_path / 'script' / 'lua' / 'currentpath.lua')
end

local function slk()
    call_w2l(slk_command())
end


if mode == 'obj' then
    obj()
elseif mode == 'lni' then
    lni()
elseif mode == 'slk' then
    slk()
else
    error(('错误的`mode`: %s'):format(mode))
end

print('[完毕]: 用时 ' .. os.clock() .. ' 秒')
