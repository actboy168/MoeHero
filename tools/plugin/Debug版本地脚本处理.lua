local mt = {}

function mt:on_complete_data(w2l)
    if w2l.config.mode ~= 'obj' then
        return
    end
    
    local file_save = w2l.file_save
    function w2l:file_save(type, name, buf)
        if type == 'script' and name:sub(1, 7) == 'script\\' then
            return
        end
        return file_save(self, type, name, buf)
    end
end

return mt
