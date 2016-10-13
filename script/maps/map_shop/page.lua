
local shop = require 'types.shop'

local page = shop.createPage '主页'
[[
	$武器1		$打野鞋1		~		~
	$防具1		~		~		~
	$鞋子1		~		~		~
]]

page.tip = '返回主页'
page.art = [[ReplaceableTextures\CommandButtons\BTNUnLoad.blp]]

local page = shop.createPage '武器1'
[[
	!武器21		!武器22		!武器23		<93
	!武器24		!武器25		!武器26		#主页
	!武器27		!武器28		!武器29		>93
]]

local page = shop.createPage '武器2'
[[
	!武器31		!武器32		!武器33		<93
	!武器34		!武器35		!武器36		#主页
	!武器37		!武器38		!武器39		>93
]]

local page = shop.createPage '武器3'
[[
	*武器41		*武器42		*武器43		-93	
	*武器44		*武器45		*武器46		#主页
	*武器47		*武器48		*武器49		+93	
]]

local page = shop.createPage '防具1'
[[
	!防具21		!防具22		!防具23		<93
	!防具24		!防具25		!防具26		#主页
	!防具27		!防具28		!防具29		>93
]]

local page = shop.createPage '防具2'
[[
	!防具31		!防具32		!防具33		<93
	!防具34		!防具35		!防具36		#主页
	!防具37		!防具38		!防具39		>93
]]

local page = shop.createPage '防具3'
[[
	*防具41		*防具42		*防具43		-93	
	*防具44		*防具45		*防具46		#主页
	*防具47		*防具48		*防具49		+93	
]]

local page = shop.createPage '鞋子1'
[[
	!鞋子21		!鞋子22		!鞋子23		<93	
	!鞋子24		!鞋子25		!鞋子26		#主页
	!鞋子27		!鞋子28		!鞋子29		>93	
]]

local page = shop.createPage '鞋子2'
[[
	*鞋子41		*鞋子42		*鞋子43		-93	
	*鞋子44		*鞋子45		*鞋子46		#主页
	*鞋子47		*鞋子48		*鞋子49		+93	
]]
