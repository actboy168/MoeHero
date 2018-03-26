local w2l = require 'w3x2lni'

if w2l.config.mode ~= 'lni' then
    return
end

w2l:file_remove('lua', 'lua/currentpath.lua')
w2l:file_remove('lua', 'lua/release.lua')

local file_save = w2l.file_save
function w2l:file_save(type, name, buf)
    if type == 'lua' then
        if name:sub(1, 7) == 'script\\' then
            return
        end
    end
    file_save(self, type, name, buf)
end
