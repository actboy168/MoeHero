local mt = {}

function mt:on_complete_data(w2l)
    if w2l.config.mode ~= 'lni' then
        return
    end
    
    w2l:file_remove('lua', 'lua/currentpath.lua')
end

return mt
