
--分割字符串
string.split = function(str, tos)
    local x = 1
    local strl = str:len()
    local tosl = tos:len()
    local strs = {}
    for y = 1, strl do
        if str:sub(y, y + tosl - 1) == tos then
            table.insert(strs, str:sub(x, y - 1))
            x = y + tosl
        end
    end
    if strl >= x then
        table.insert(strs, str:sub(x, strl))
    end
    return strs
end
