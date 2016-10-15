require 'luabind'
require 'filesystem'
require 'registry'
require 'sys'

local function main()
    local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
    local command = (registry.current_user() / [[SOFTWARE\Classes\YDWEMap\shell\run_war3\command]])['']
        : gsub('%%1', (rootpath / 'MoeHero.w3x'):string())
    local p = sys.process()
    if p:create(nil, command, nil) then
    	p:close()
    end
end

if not pcall(main) then
    print('需要YDWE关联w3x文件')
end
