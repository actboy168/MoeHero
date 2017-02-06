(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\w3x2lni\\script\\?.lua'
    package.cpath = package.cpath .. ';' .. exepath .. '..\\w3x2lni\\bin\\?.dll'
end)()

require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w2l = require 'w3x2lni'
local archive = require 'archive'
local save_map = require 'save_map'
w2l:initialize(fs.path(package.cpath:match(';([^;]+)\\bin\\%?%.dll$')))

function message(...)
    local strs = table.pack(...)
    for i = 1, strs.n do
        strs[i] = uni.u2a(tostring(strs[i]))
    end
    if strs[1] == '-progress' then
        return
    end
    print(table.unpack(strs))
end

local function pack_config()
    -- 转换后的目标格式(lni, obj, slk)
    config.target_format = 'obj'
    -- 是否分析slk文件
    read_slk = false
    -- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
    find_id_times = 0
    -- 移除与模板完全相同的数据
    remove_same = true
    -- 移除超出等级的数据
    remove_exceeds_level = true
    -- 移除只在WE使用的文件
    remove_we_only = false
    -- 移除没有引用的对象
    remove_unuse_object = false
    -- mdx压缩
    mdx_squf = false
    -- 转换为地图还是目录(mpq, dir)
    target_storage = 'mpq'
end

local function pack_proxy()
    local archives = {}

    local mt = {}

    function mt:add_input(path)
        fs.create_directory(path)
        archives[#archives+1] = archive(path)
    end
    
    return mt
end

local function pack_w3u(t)
    local ignore = {
        [".mdx"] = true,
        [".mdl"] = true,
        ["model\\dummy.mdl"] = true,
    }
    for id, u in pairs(t) do
        if u.file and not ignore[u.file:lower()] then
            u.file = [[units\human\Footman\Footman.mdx]]
        end
        if u.Art then
            u.Art = [[ReplaceableTextures\CommandButtons\BTNFootman.blp]]
        end
    end
    return t
end

local function pack(input_path)
    local mode = arg[1]

    local input_ar = pack_proxy()
    local output_ar = archive(input_path / 'MoeHero.w3x', 'w')
    if not input_ar or not output_ar then
        return
    end

    pack_config()

    input_ar:add_input(input_path / 'map')
    input_ar:add_input(input_path / 'static')
    if mode == 'release' then
        input_ar:add_input(input_path / 'script')
    end
    if fs.exists(input_path / 'resource') then
        input_ar:add_input(input_path / 'resource')
    end

    local slk = {}
    w2l:frontend(input_ar, slk)
    w2l:backend(input_ar, slk)
    save_map(w2l, output_ar, slk.w3i, input_ar)
    output_ar:close()
    input_ar:close()
    
    if not fs.exists(resource_dir) then
        function map_file:on_lni(name, t)
            if name == 'war3map.w3u' then
                return pack_w3u(t)
            end
            return t
        end 
    end
   --function map_file:on_save(name, file, dir)
   --    if name == 'war3map.j' then
   --        file = file .. '\r\n\r\n//' .. os.time()
   --    end
   --    if dir == script_dir then
   --        name = 'script\\' .. name
   --    end
	--	return name, file
   --end
end

local function unpack_config()
    local config = w2l.config
    -- 转换后的目标格式(lni, obj, slk)
    config.target_format = 'lni'
    -- 是否分析slk文件
    config.read_slk = false
    -- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
    config.find_id_times = 0
    -- 移除与模板完全相同的数据
    config.remove_same = false
    -- 移除超出等级的数据
    config.remove_exceeds_level = true
    -- 移除只在WE使用的文件
    config.remove_we_only = false
    -- 移除没有引用的对象
    config.remove_unuse_object = false
    -- mdx压缩
    config.mdx_squf = false
    -- 转换为地图还是目录(mpq, dir)
    config.target_storage = 'dir'
end

local function unpack_proxy(...)
    local archives = {}
    for i, path in ipairs {...} do
        fs.create_directory(path)
        archives[i] = archive(path, 'w')
        if not archives[i] then
            return nil
        end
    end

    local mt = {}

    function mt:set(name, buf)
        if name == 'war3map.imp' then
            return
        end
        if name == 'war3map.j' then
            return
        end
        if name:match '^script[/\\]' then
            return
        end
        local extension = name:match '^.*(%..-)$'
        if extension == '.blp' or 
            extension == '.mdx' or
            extension == '.mp3' or
            extension == '.mdl' or
            extension == '.tga'
        then
            archives[2]:set(name, buf)
            return
        end
        archives[1]:set(name, buf)
    end

    function mt:save(...)
        for _, archive in ipairs(archives) do
            if not archive:save(...) then
                return false
            end
        end
        return true
    end

    function mt:get_type()
        return 'dir'
    end

    function mt:close()
        for _, archive in ipairs(archives) do
            archive:close()
        end
    end

    return mt
end

local function unpack(input_path)
    local map_dir = input_path:parent_path() / 'map'
    local resource_dir = input_path:parent_path() / 'resource'

    local input_ar = archive(input_path)
    local output_ar = unpack_proxy(map_dir, resource_dir)
    if not input_ar or not output_ar then
        return
    end

    unpack_config()

    local slk = {}
    w2l:frontend(input_ar, slk)
    w2l:backend(input_ar, slk)

    save_map(w2l, output_ar, slk.w3i, input_ar)
    output_ar:close()
    input_ar:close()
end

local input_path = fs.path(uni.a2u(arg[2]))
if fs.is_directory(input_path) then
    pack(input_path)
else
    unpack(input_path)
end
message('[完毕]: 用时 ' .. os.clock() .. ' 秒')
