local mt = {}

mt.info = {
    name = '引用声明',
    version = 1.0,
    author = '最萌小汐',
    description = '对只在lua中使用的对象进行引用声明。',
}

local list = {}

for x = 1, 4 do
    for y = 1, 5 do
        list['AX'..x..y] = true
        list['AS'..x..y] = true
    end
end

for x = 0, 9 do
    for y = 0, 6 do
        list['A0'..x..y] = true
        list['AL'..x..y] = true
        list['AT'..x..y] = true
        list['AD'..x..y] = true
        list['IT'..x..y] = true
        list['ID'..x..y] = true
    end
end

for x = 1, 4 do
    list['AF0'..x] = true
end

for x = 0, 3 do
    list['A20'..x] = true
end

list['A028'] = true
list['A888'] = true
list['A889'] = true
list['A01H'] = true
list['A00V'] = true
list['A00E'] = true
list['AZ00'] = true
list['AB31'] = true
list['A01K'] = true
list['A01G'] = true
list['A01W'] = true
list['A007'] = true
list['AInv'] = true

local firsts = 'ehbnH'
local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
for x = 0, 1 do
    for y = 1, #chars do
        for z = 1, #firsts do
            list[firsts:sub(z,z)..'0'..x..chars:sub(y,y)] = true
        end
    end
end

function mt:on_mark()
    return list
end

return mt
