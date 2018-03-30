local item = require 'types.item'

item.default_state =
{
	['武器'] = 
	{
		['attack']	= {10, 20, 30, 30},
		['gold']	= {500, 1000, 1500, 1500},
	},
	['防具'] = 
	{
		['defence']	= {10, 20, 30, 30},
		['life']	= {100, 200, 300, 300},
		['gold']	= {500, 1000, 1500, 1500},
	},
	['鞋子'] =
	{
		['shoes_count']	= {1, 1, 1, 1},
		['move_speed']	= {0, 10, 10, 20},
		['gold']		= {500, 500, 500, 500},
	},
	['打野鞋'] =
	{
		['shoes_count']	= {1, 1, 1, 1},
		['gold']		= {500, 500, 500, 500},
	}
}

local function require_item(file)
	require(file)
	local name = file:match '.+%.(.*)$'
	if not name then
		print('解析失败', file)
		return
	end
	local skill = rawget(ac.skill, name)
	if not skill then
		print('物品技能没找到', file)
		return
	end
	local item_type = skill.item_type .. skill.level
	item.add_list(item_type, name)
end

require_item 'maps.map_item.武器.铁剑'
require_item 'maps.map_item.武器.钢剑'
require_item 'maps.map_item.武器.精制钢剑'
require_item 'maps.map_item.武器.奥能迸发'
require_item 'maps.map_item.武器.奥术精华'
require_item 'maps.map_item.武器.潮汐纹章'
require_item 'maps.map_item.武器.多重弩刃'
require_item 'maps.map_item.武器.风羽长剑'
require_item 'maps.map_item.武器.困者之灾'
require_item 'maps.map_item.武器.连击之刺'
require_item 'maps.map_item.武器.裂钩刀刃'
require_item 'maps.map_item.武器.凝霜冰杖'
require_item 'maps.map_item.武器.圣炎光弩'
require_item 'maps.map_item.武器.世荆花杖'
require_item 'maps.map_item.武器.桐一文字'
require_item 'maps.map_item.武器.星云苍斧'
require_item 'maps.map_item.武器.陨铁大剑'
require_item 'maps.map_item.武器.战跃海锚'
require_item 'maps.map_item.武器.便携式连装炮酱'
require_item 'maps.map_item.武器.收割之镰'
require_item 'maps.map_item.武器.魔力之星'

require_item 'maps.map_item.防具.布甲'
require_item 'maps.map_item.防具.皮甲'
require_item 'maps.map_item.防具.精制皮甲'
require_item 'maps.map_item.防具.霸主魔盔'
require_item 'maps.map_item.防具.次元遗物'
require_item 'maps.map_item.防具.封印之锁'
require_item 'maps.map_item.防具.盖亚护手'
require_item 'maps.map_item.防具.光剑影光'
require_item 'maps.map_item.防具.黄昏腰带'
require_item 'maps.map_item.防具.卡巴拉生命之种'
require_item 'maps.map_item.防具.烈焰之握'
require_item 'maps.map_item.防具.能量收集器'
require_item 'maps.map_item.防具.青龙鳞盔'
require_item 'maps.map_item.防具.深渊刺盾'
require_item 'maps.map_item.防具.守护者铠甲'
require_item 'maps.map_item.防具.死神契约'
require_item 'maps.map_item.防具.天使之佑'
require_item 'maps.map_item.防具.修罗化身'
require_item 'maps.map_item.防具.溢能发射器'

require_item 'maps.map_item.鞋子.奈课'
require_item 'maps.map_item.鞋子.阿迪王'
require_item 'maps.map_item.鞋子.奥术风暴'
require_item 'maps.map_item.鞋子.充能漩涡'
require_item 'maps.map_item.鞋子.次元穿梭'
require_item 'maps.map_item.鞋子.高速神言'
require_item 'maps.map_item.鞋子.灵象异动'
require_item 'maps.map_item.鞋子.死神天降'

require 'maps.map_item.鞋子.鞋-脱战加速'
