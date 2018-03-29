require 'maps.hero.丹特丽安.妖精之书'
require 'maps.hero.丹特丽安.雷神之书'
require 'maps.hero.丹特丽安.冥界之书'
require 'maps.hero.丹特丽安.明日之诗'

return ac.hero.create '丹特丽安'
{
	--物编中的id
	id = 'H010',

	production = '丹特丽安的书架',

	model_source = '全明星战役(水银灯)',

	hero_designer = 'actboy168',

	hero_scripter = '最萌小汐',
	
	show_animation = 'attack',

	--技能数量
	skill_count = 4,

	skill_names = '妖精之书 雷神之书 冥界之书 明日之诗',

	attribute = {
		['生命上限'] = 800,
		['魔法上限'] = 959,
		['生命恢复'] = 4,
		['魔法恢复'] = 2,
		['攻击']    = 31,
		['护甲']    = 10,
		['移动速度'] = 340,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 110,
		['魔法上限'] = 65,
		['生命恢复'] = 0.26,
		['魔法恢复'] = 0.3,
		['攻击']    = 3.1,
		['护甲']    = 1.1,
	},

	weapon = {
		['弹道模型'] = [[Abilities\Weapons\ProcMissile\ProcMissile.mdl]],
		['弹道速度'] = 2000,
		['弹道弧度'] = 0.15,
		['弹道出手'] = {15, 0, 66},
	},

	difficulty = 5,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,

	--萝莉
	loli = true,
}
