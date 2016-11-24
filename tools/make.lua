(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\?.lua'
end)()

require 'filesystem'
require 'utility'
local uni      = require 'ffi.unicode'
local w3x2txt  = require 'w3x2txt'

local map_name = 'MoeHero.w3x'

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
    w3x2txt:init()
    local mode = arg[1]
    local map_dir = input_path / 'map'
    local script_dir = input_path / 'script'
    local resource_dir = input_path / 'resource'
    local static_dir = input_path / 'static'
    local map_file = w3x2txt:create_map()
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
    w3x2txt:init()
    local map_dir = input_path:parent_path() / 'map'
    local resource_dir = input_path:parent_path() / 'resource'
	local map_file = w3x2txt:create_map()
	map_file:add_input(input_path)
    function map_file:on_save(name)
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
            return name, resource_dir
        end
		return name, map_dir
    end
	map_file:save(map_dir)
end

local function main()
    local input_path = fs.path(uni.a2u(arg[2]))
	if fs.is_directory(input_path) then
        pack(input_path)
    else
        unpack(input_path)
	end
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
