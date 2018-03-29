require 'filesystem'
local process = require "process"

local mode = arg[1]
local root = fs.path(arg[2])
local w2l = root / 'tools' / 'w3x2lni'
local title = ('W3x2%s%s'):format(mode:sub(1,1):upper(), mode:sub(2))

function io.save(filepath, content)
    local f, e = io.open(filepath:string(), "wb")
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
       msg:sub(1, 4) == '-tip' or
       msg:sub(1, 6) == '-title'
    then
        return
    end
    print(('| %s |    %s'):format(title, msg))
end

local function call_w2l(commands)
    local application = w2l / 'bin' / 'w2l-worker.exe'
    local entry = w2l / 'script' / 'map.lua'
    local currentdir = w2l / 'script'
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

local function make_command(mode)
    local dir = root
    local w3x = root / 'MoeHero.w3x'
    local input, output
    if mode == 'obj' then
        input, output = dir, w3x
    elseif mode == 'lni' then
        input, output = w3x, dir
    elseif mode == 'slk' then
        input, output = dir, w3x
    else
        error(('错误的`mode`: %s'):format(mode))
    end
    return table.concat({
        ('"%s"'):format(input:string()),
        ('"%s"'):format(output:string()),
        '-' .. mode,
        ('"-config=%s"'):format(root / 'tools' / 'config.ini'),
    }, ' ')
end

call_w2l(make_command(mode))

print('用时 ' .. os.clock() .. ' 秒')
