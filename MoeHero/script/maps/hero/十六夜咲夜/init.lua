require 'maps.hero.十六夜咲夜.速符[闪光弹跳]'
require 'maps.hero.十六夜咲夜.银符[完美女仆]'
require 'maps.hero.十六夜咲夜.幻符[杀人玩偶]'
require 'maps.hero.十六夜咲夜.[小夜的世界]'
require 'maps.hero.十六夜咲夜.光速[光速跳跃]'
require 'maps.hero.十六夜咲夜.LastWord[收缩的世界]'

return ac.hero.create '十六夜咲夜'
{
	--物编中的id
	id = 'H00Z',

	production = '东方Project',

	model_source = '全明星战役',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'spell throw', 'attack', 'morph' },

	--技能数量
	skill_count = 4,

	skill_names = '速符[闪光弹跳] 银符[完美女仆] 幻符[杀人玩偶] [小夜的世界] 光速[光速跳跃] LastWord[收缩的世界]',

	attribute = {
		['生命上限'] = 920,
		['魔法上限'] = 700,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.4,
		['魔法脱战恢复'] = 0,
		['攻击']    = 33,
		['护甲']    = 12,
		['移动速度'] = 320,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 110,
		['魔法上限'] = 40,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.12,
		['攻击']    = 3.3,
		['护甲']    = 1.2,
	},

	weapon = {
		['弹道模型'] = [[fu.mdl]],
		['弹道速度'] = 900,
		['弹道弧度'] = 0,
		['弹道出手'] = {15, 0, 66},
	},

	difficulty = 4,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,
}
