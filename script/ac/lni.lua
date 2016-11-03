local lni = require 'ac.lni-loader'
local storm = require 'jass.storm'

ac.lni = {}

local localpath
local suc, r = pcall(require, [[lua\currentpath]])
if suc then localpath = r end

if localpath then
	lni:set_marco('MapPath', localpath)
else
	lni:set_marco('MapPath', 'script\\')
end
lni:set_marco('TableSearcher', '$MapPath$table\\')
for _, path in ipairs(ac.split(package.path, ';')) do
	local buf = storm.load(path:gsub('%?%.lua', 'table\\.iniconfig'))
	if buf then
		lni:set_marco('MapPath', path:gsub('%?%.lua', ''))
		break
	end
end

function ac.lni_loader(name)
	ac.lni[name] = lni:packager(name, storm.load)
end
