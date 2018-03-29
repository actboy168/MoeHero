require 'maps.hero.魔理沙.黑魔[黑洞边缘]'
require 'maps.hero.魔理沙.仪符[太阳仪]'
require 'maps.hero.魔理沙.星符[第二宇宙速度]'
require 'maps.hero.魔理沙.魔炮[究极火花]'
require 'maps.hero.魔理沙.魔符[星屑幻想]'
require 'maps.hero.魔理沙.LastWord[掠日彗星]'

return ac.hero.create '魔理沙'
{
	--物编中的id
	id = 'H00S',

	production = '东方Project',

	model_source = '东方武斗祭',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = 'stand walk alternate',

	--技能数量
	skill_count = 4,

	skill_names = '黑魔[黑洞边缘] 仪符[太阳仪] 星符[第二宇宙速度] 魔炮[究极火花] 魔符[星屑幻想] LastWord[掠日彗星]',

	attribute = {
		['生命上限'] = 840,
		['魔法上限'] = 850,
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
		['魔法上限'] = 55,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.15,
		['攻击']    = 3.2,
		['护甲']    = 1.2,
	},

	weapon = {
		['弹道模型'] = [[marisastarm_1b.mdl]],
		['弹道速度'] = 900,
		['弹道弧度'] = 0,
		['弹道出手'] = {15, 0, 66},
	},

	difficulty = 1,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,
}
