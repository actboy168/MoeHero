local ydwe = require 'tools.ydwe'
local subprocess = require 'bee.subprocess'
if not ydwe then
    return
end
print('YDWE:', ydwe:string())
local p = subprocess.spawn {
    ydwe / 'bin' / 'ydweconfig.exe'
}
if p then
    p:close()
end
