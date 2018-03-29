
local map = require 'maps.map'
local runtime = require 'jass.runtime'
local hero = require 'types.hero'
local japi = require 'jass.japi'


hero.hero_list = {
	{'小悟空', '小悟空'},
	{'御坂美琴', '御坂美琴'},
	{'黑雪姬', '黑雪姬'},
	{'鹿目圆香', '鹿目圆香'},
	{'更木剑八', '更木剑八'},
	{'桐人', '桐人'},
	{'夏娜', '夏娜'},
	{'博丽灵梦', '博丽灵梦'},
	{'魔理沙', '魔理沙'},
	{'十六夜咲夜', '十六夜咲夜'},
	{'丹特丽安', '丹特丽安'},
	{'立华奏', '立华奏'},
	{'金木研', '金木研'},
	{'时崎狂三', '时崎狂三'},
	--{'四糸乃', '四糸乃'},
	{'五河琴里', '五河琴里'},
	{'夜刀神十香', '夜刀神十香'},
	{'爱丽莎', '爱丽莎'},
	{'亚丝娜', '亚丝娜'},
	{'夜夜', '夜夜'},
	{'楪祈', '楪祈'},
	{'赤瞳', '赤瞳'},
	{'漩涡鸣人', '漩涡鸣人'},
	{'阿尔托莉亚', '阿尔托莉亚'},
	{'惠惠', '惠惠'},
	--{'玉置亚子', '玉置亚子'},
	--{'岛风', '岛风'},
	{'缇娜', '缇娜'},
	{'索隆', '索隆'},
}

--加载英雄的数据
function map.load_heroes()
	for _, hero_data in ipairs(hero.hero_list) do
		local name, file = hero_data[1], hero_data[2]
		hero.hero_list[name] = hero_data
		local hero_data = select(2, xpcall(require, runtime.error_handle ,('maps.hero.%s.init'):format(file)))
		hero.hero_list[name].data = hero_data
		hero_data.name = name
		hero_data.file = file

		if japi.EXSetUnitArrayString then
			japi.EXSetUnitArrayString(base.string2id(hero_data.id), 10, 0, hero_data.production)
			japi.EXSetUnitInteger(base.string2id(hero_data.id), 10, 1)
			japi.EXSetUnitArrayString(base.string2id(hero_data.id), 61, 0, hero_data.name)
			japi.EXSetUnitInteger(base.string2id(hero_data.id), 61, 1)
		else
		end
	end

	--英雄总数
	hero.hero_count = #hero.hero_list
end

map.load_heroes()
