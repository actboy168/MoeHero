
local shop = require 'types.shop'
local table = table

shop.page = {}
local mt = {}

--页面默认值
shop.page.__index = mt

mt.type = 'shop_page'

mt.name = nil

--获取页面上某个格子的值
function mt:getValue(y, x)
	return self[x] and self[x][y]
end

function mt:get_name(x, y)
	local value = self:getValue(x, y)
	if value then
		return value:sub(2)
	end
end

function mt:getType(x, y)
	local value = self:getValue(x, y)
	if value then
		return value:sub(1, 1)
	end
end

--创建页面
function shop.createPage(name)
	return function(list)
		local page = shop.readList(list)
		shop.all_pages[name] = page

		page.name = name

		setmetatable(page, shop.page)

		return page
	end
end

--解析页面
function shop.readList(list)
	local page = {}

	--解析每一行
	for line in list:gmatch '[^\r\n]+' do
		local line_data = {}
		for name in line:gmatch '%C+' do
			table.insert(line_data, name)
		end
		if #line_data ~= 0 then
			table.insert(page, line_data)
		end
	end

	return page

end

--获取页面
--	页面名称
function shop.__index:getPage(name)
	return self.all_pages and self.all_pages[name] or shop.all_pages[name]
end

--设置页面
--	页面名称
--	@设置具体页面内容
	--	页面内容表
function shop.__index:setPage(name)
	return function(page)
		if not self.all_pages then
			self.all_pages = {}
		end

		self.all_pages[name] = page
	end
end

function shop.initPage()
	shop.all_pages = {}
	
	return shop
end

return shop.initPage()