require 'ydwe'
require 'sys'
if not ydwe then
    return
end

local function get_debugger()
    local path = fs.path(os.getenv('USERPROFILE')) / '.vscode' / 'extensions'
    for extpath in path:list_directory() do
        if extpath:filename():string():sub(1, 20) == 'actboy168.lua-debug-' then
            local dbgpath = extpath / 'debugger.dll'
            if fs.exists(dbgpath) then
                return dbgpath
            end
            return
        end
    end
end

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
local command = (registry.current_user() / [[SOFTWARE\Classes\YDWEMap\shell\run_war3\command]])['']
command = command:gsub("%%1", (rootpath / 'MoeHero.w3x'):string())
local dbg = get_debugger()
if dbg then
    command = command .. ' -debugger "' .. dbg:string() .. '"'
end
print(command)
local p = sys.process()
if p:create(nil, command, nil) then
    p:close()
end

