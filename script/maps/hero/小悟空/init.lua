require 'maps.hero.小悟空.龟派气功'
require 'maps.hero.小悟空.如意棒'
require 'maps.hero.小悟空.筋斗云'
require 'maps.hero.小悟空.狂暴'

return ac.hero.create '小悟空'
{
	--物编中的id
	id = 'H00C',

	production = '龙珠',

	model_source = '魔霸工作室(动作:月真)',

	hero_designer = 'ZN',

	hero_scripter = '最萌小汐',

	show_animation = { 'attack slam', 'spell channel' },

	--技能数量
	skill_count = 4,

	skill_names = '龟派气功 如意棒 筋斗云 狂暴',

	attribute = {
		['生命上限'] = 1000,
		['魔法上限'] = 600,
		['生命恢复'] = 3.5,
		['魔法恢复'] = 1.1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 33,
		['护甲']    = 13,
		['移动速度'] = 310,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 125,
		['魔法上限'] = 30,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.3,
		['护甲']    = 1.3,
	},

	weapon = {
	},

	difficulty = 1,

	--选取半径
	selected_radius = 32,
}
