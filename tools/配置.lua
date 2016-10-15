require 'luabind'
require 'filesystem'
require 'registry'
require 'sys'

local function main()
    local command = (registry.current_user() / [[SOFTWARE\Classes\YDWEMap\shell\run_war3\command]])['']
    command = command:sub(command:find('"[^"]*"'))
    local p = sys.process()
    if p:create(nil, command, nil) then
    	p:close()
    end
end

if not pcall(main) then
    print('需要YDWE关联w3x文件')
end
