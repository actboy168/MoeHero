require 'maps.hero.时崎狂三.七之弹'
require 'maps.hero.时崎狂三.旋风射击'
require 'maps.hero.时崎狂三.四之弹'
require 'maps.hero.时崎狂三.食时之城'
require 'maps.hero.时崎狂三.八之弹'

return ac.hero.create '时崎狂三'
{
	--物编中的id
	id = 'H004',

	production = '约会大作战',

	model_source = '全明星战役',

	hero_designer = '最萌小汐',

	hero_scripter = '最萌小汐',

	show_animation = { 'attack', 'spell one', 'spell two', 'spell three' },

	--技能数量
	skill_count = 4,

	skill_names = '旋风射击 七之弹 四之弹 食时之城 八之弹',

	attribute = {
		['生命上限'] = 840,
		['魔法上限'] = 800,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.3,
		['魔法脱战恢复'] = 0,
		['攻击']    = 31,
		['护甲']    = 10,
		['移动速度'] = 325,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 105,
		['魔法上限'] = 40,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.13,
		['攻击']    = 3.1,
		['护甲']    = 1.0,
	},

	weapon = {
		['弹道模型'] = [[Abilities\Weapons\GyroCopter\GyroCopterMissile.mdl]],
		['弹道速度'] = 0,
		['弹道弧度'] = 0,
		['弹道出手'] = {15, 0, 66},
	},

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
