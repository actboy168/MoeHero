require 'filesystem'
require 'registry'

local function main()
    local command = (registry.current_user() / [[SOFTWARE\Classes\YDWEMap\shell\run_war3\command]])['']
    local f, l = command:find('"[^"]*"')
    return fs.path(command:sub(f+1, l-1)):remove_filename()
end
local suc, r = pcall(main)
if not suc or not r then
    print('需要YDWE关联w3x文件')
    return
end
return r
