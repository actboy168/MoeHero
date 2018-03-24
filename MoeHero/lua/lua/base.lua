local runtime	= require 'jass.runtime'
local console	= require 'jass.console'

base = {}

--判断是否是发布版本
base.release = pcall(require, 'lua\\release')

--版本号
base.version = '4.18'

--打开控制台
if not base.release then
	console.enable = true
end

--重载print,自动转换编码
print = console.write

--将句柄等级设置为0(地图中所有的句柄均使用table封装)
runtime.handle_level = 0

--关闭等待
runtime.sleep = false

function base.error_handle(msg)
	print("---------------------------------------")
	print(tostring(msg) .. "\n")
	print(debug.traceback())
	print("---------------------------------------")
end

--错误汇报
function runtime.error_handle(msg)
	base.error_handle(msg)
end

--测试版本和发布版本的脚本路径
local localpath
if base.release then
	localpath = [[Poi\]] .. base.version .. [[\]]
else
	local suc, r = pcall(require, [[lua\currentpath]])
	if suc then localpath = r end
end

package.path = ''

function base.add_lua_path(dir)
	if dir ~= '' then dir = dir ..[[\]] end
	local r = [[script\]] .. dir .. '?.lua'
	if localpath then
		r = localpath .. dir .. '?.lua' .. ';' .. r
	end
	if package.path == '' then
		package.path = r
	else
		package.path = package.path .. ';' .. r
	end
end

--添加require搜寻路径
base.add_lua_path ''

--初始化本地脚本
require 'main'
