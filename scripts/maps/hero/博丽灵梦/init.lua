require 'maps.hero.博丽灵梦.追踪御礼'
require 'maps.hero.博丽灵梦.四方神域礼'
require 'maps.hero.博丽灵梦.刹那亚空穴'
require 'maps.hero.博丽灵梦.灵符[梦想封印]'
require 'maps.hero.博丽灵梦.直排御礼'

return ac.hero.create '博丽灵梦'
{
	--物编中的id
	id = 'H00N',

	production = '东方Project',

	model_source = '全明星战役',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐 actboy168',

	show_animation = { 'stand channel', 'spell', 'attack' },

	--技能数量
	skill_count = 4,

	skill_names = '追踪御礼 四方神域礼 刹那亚空穴 灵符[梦想封印] 直排御礼',

	attribute = {
		['生命上限'] = 840,
		['魔法上限'] = 750,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.4,
		['魔法脱战恢复'] = 0,
		['攻击']    = 31,
		['护甲']    = 12,
		['移动速度'] = 320,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 105,
		['魔法上限'] = 45,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.15,
		['攻击']    = 3.2,
		['护甲']    = 1.2,
	},

	weapon = {
		['弹道模型'] = [[fu.mdl]],
		['弹道速度'] = 900,
		['弹道弧度'] = 0,
		['弹道出手'] = {15, 0, 66},
	},

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,
}
