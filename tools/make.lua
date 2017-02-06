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

local map_name = 'MoeHero.w3x'

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

function progress()
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
    local map_dir = input_path / 'map'
    local script_dir = input_path / 'script'
    local resource_dir = input_path / 'resource'
    local static_dir = input_path / 'static'
    local map_file = w2l:create_map()
	map_file:add_input(map_dir)
	map_file:add_input(resource_dir)
    map_file:add_input(static_dir)
    if mode == 'release' then
	    map_file:add_input(script_dir)
    end
    if not fs.exists(resource_dir) then
        function map_file:on_lni(name, t)
            if name == 'war3map.w3u' then
                return pack_w3u(t)
            end
            return t
        end 
    end
    function map_file:on_save(name, file, dir)
        if name == 'war3map.j' then
            file = file .. '\r\n\r\n//' .. os.time()
        end
        if dir == script_dir then
            name = 'script\\' .. name
        end
		return name, file
    end
	map_file:save(input_path / map_name)
end

local function unpack(input_path)
    local map_dir = input_path:parent_path() / 'map'
    local resource_dir = input_path:parent_path() / 'resource'

    local input_ar = archive(input_path)
    if not input_ar then
        return
    end
    local output_ar = archive(resource_dir, 'w')
    if not output_ar then
        return
    end

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
    
    local slk = {}
    w2l:frontend(input_ar, slk)
    w2l:backend(input_ar, slk)

    input_ar:set('war3map.imp', false)
    input_ar:set('war3map.j', false)

    save_map(w2l, output_ar, slk.w3i, input_ar)
    output_ar:close()
    input_ar:close()

   --function map_file:on_save(name)
   --    if name == 'war3map.imp' then
   --        return
   --    end
   --    if name == 'war3map.j' then
   --        return
   --    end
   --    if name:match '^script[/\\]' then
   --        return
   --    end
   --    local extension = name:match '^.*(%..-)$'
   --    if extension == '.blp' or 
   --       extension == '.mdx' or
   --       extension == '.mp3' or
   --       extension == '.mdl' or
   --       extension == '.tga'
   --    then
   --        return name, resource_dir
   --    end
	--	return name, map_dir
   --end
end

local input_path = fs.path(uni.a2u(arg[2]))
if fs.is_directory(input_path) then
    pack(input_path)
else
    unpack(input_path)
end
message('[完毕]: 用时 ' .. os.clock() .. ' 秒')
