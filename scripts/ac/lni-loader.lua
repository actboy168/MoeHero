local lni = require 'lni'

local mt = {}
local marco = {}
local function split(str, p) local rt = {} str:gsub('[^'..p..']+', function (w) table.insert(rt, w) end) return rt end

function mt:searcher(name, callback)
	local searcher = marco[name .. 'Searcher']
	if searcher == '' then
		callback('')
		return
	end
	for _, path in ipairs(split(searcher, ';')) do
		local fullpath = path: gsub('%$(.-)%$', function(v) return marco[v] or '' end)
		callback(fullpath)
	end
end
function mt:packager(name, loadfile)
	local result = {}
	local ok = {}
	local function package(path, default, enum)
		ok[path] = true
		local content = loadfile(path.. name .. '.ini')
		if content then
			result, default, enum = lni(content, path .. name .. '.ini', {result, default, enum})
		end
		local config = loadfile(path .. '.iniconfig')
		if config then
			for _, dir in ipairs(split(config, '\n')) do
				local name = dir:gsub('^%s', ''):gsub('%s$', '')
				if name ~= '' then
					local name = path .. name .. '\\'
					if not ok[name] then
						package(name, default, enum)
					end
				end
			end
		end
	end
	self:searcher('Table', package)
	return result
end
function mt:set_marco(key, value)
	marco[key] = value
end
function mt:get_searcher(name)
	local result = nil
	self:searcher(name, function(path)
		if result then
			result = result .. ';' .. path
		else
			result = path
		end
	end)
	return result
end
return mt
