require 'ydwe'
require 'sys'
if not ydwe then
    return
end
local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
local command = (registry.current_user() / [[SOFTWARE\Classes\YDWEMap\shell\run_war3\command]])['']
local p = sys.process()
if p:create(nil, command:gsub("%%1", (rootpath / 'MoeHero.w3x'):string()), nil) then
    p:close()
end
