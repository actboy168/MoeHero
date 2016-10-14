package.path = package.path .. ';' .. arg[1] .. '\\w3x2txt\\src\\?.lua'
package.cpath = package.cpath .. ';' .. arg[1] .. '\\w3x2txt\\build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'

local root_dir = fs.path(uni.a2u(arg[1]))
local w3x2txt_dir = root_dir / 'w3x2txt'
local map_name = 'MoeHero.w3x'

local function main()
    w3x2txt:init(w3x2txt_dir)
    local mode = arg[2]
    
    local map_dir = root_dir / 'map'
    local script_dir = root_dir / 'script'
    local resource_dir = root_dir / 'resource'

	if arg[3] then
        local path_path = fs.path(uni.a2u(arg[3]))
		local map_file = w3x2txt:create_map()
		map_file:add_input(path_path)
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
        local map_file = w3x2txt:create_map()
		map_file:add_input(map_dir)
		map_file:add_input(resource_dir)
        if mode == 'release' then
		    map_file:add_input(script_dir)
        end
		map_file:save(root_dir / map_name, function(name, file, dir)
            if dir == script_dir then
                name = 'script\\' .. name
            end
			return name, file
		end)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
