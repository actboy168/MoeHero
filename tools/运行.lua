require 'ydwe'
require 'sys'
if not ydwe then
    return
end
local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
local command = ([["%s" -launchwar3 -loadfile "%s"]]):format((ydwe / 'bin' / 'ydweconfig.exe'):string(), (rootpath / 'MoeHero.w3x'):string())
local p = sys.process()
if p:create(nil, command, nil) then
    p:close()
end
