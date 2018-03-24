local w2l = require 'w3x2lni'

if w2l.config.mode ~= 'slk' then
    return
end

w2l:file_save('lua', 'lua/release.lua', '')
