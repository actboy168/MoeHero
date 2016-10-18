require 'ydwe'
require 'sys'
if not ydwe then
    return
end
print('YDWE:', ydwe:string())
local p = sys.process()
if p:create(nil, ydwe / 'bin' / 'ydweconfig.exe', nil) then
    p:close()
end
