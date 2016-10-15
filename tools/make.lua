(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\src\\?.lua'
end)()

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'

local map_name = 'MoeHero.w3x'

local function main()
    w3x2txt:init()
    local mode = arg[1]
    local input_path = fs.path(uni.a2u(arg[2]))
	if not fs.is_directory(input_path) then
        local map_dir = input_path:parent_path() / 'map'
        local script_dir = input_path:parent_path() / 'script'
        local resource_dir = input_path:parent_path() / 'resource'
		local map_file = w3x2txt:create_map()
		map_file:add_input(input_path)
		map_file:save(_, function(name)
            if name == 'war3map.imp' then
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
		end)
    else
        local map_dir = input_path / 'map'
        local script_dir = input_path / 'script'
        local resource_dir = input_path / 'resource'
        local map_file = w3x2txt:create_map()
		map_file:add_input(map_dir)
		map_file:add_input(resource_dir)
        if mode == 'release' then
		    map_file:add_input(script_dir)
        end
		map_file:save(input_path / map_name, function(name, file, dir)
            if dir == script_dir then
                name = 'script\\' .. name
            end
			return name, file
		end)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
