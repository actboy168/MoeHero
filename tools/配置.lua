local ydwe = require 'tools.ydwe'
local process = require 'process'
if not ydwe then
    return
end
print('YDWE:', ydwe:string())
local p = process()
if p:create(nil, ydwe / 'bin' / 'ydweconfig.exe', nil) then
    p:close()
end
