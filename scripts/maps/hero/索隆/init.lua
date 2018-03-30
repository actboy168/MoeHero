require 'maps.hero.索隆.龙卷风'
require 'maps.hero.索隆.二刀流居合罗生门'
require 'maps.hero.索隆.鬼泣九刀流'
require 'maps.hero.索隆.阿修罗穿威'

return ac.hero.create '索隆'
{
	--物编中的id
	id = 'H00Y',

	production = '海贼王',

	model_source = 'U9模型区',

	hero_designer = '德堪',

	hero_scripter = '德堪',

	show_animation = 'attack',

	--技能数量
	skill_count = 4,

	skill_names = '龙卷风 二刀流居合罗生门 鬼泣九刀流 阿修罗穿威',

	attribute = {
		['生命上限'] = 1040,
		['魔法上限'] = 750,
		['生命恢复'] = 3.5,
		['魔法恢复'] = 1.5,
		['魔法脱战恢复'] = 0,
		['攻击']    = 32,
		['护甲']    = 14,
		['移动速度'] = 320,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 130,
		['魔法上限'] = 30,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.15,
		['攻击']    = 3.1,
		['护甲']    = 1.2,
	},

	weapon = {
	},

	--触发系数
	proc = 1,

	difficulty = 3,

	--选取半径
	selected_radius = 32,
}
