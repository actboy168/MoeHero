require 'maps.hero.岛风.93式酸素鱼雷'
require 'maps.hero.岛风.94式深水炸弹'
require 'maps.hero.岛风.连装炮酱'
require 'maps.hero.岛风.25毫米高射炮'

return ac.hero.create '岛风'
{
	id = 'H009',

	production = '舰队Collection',

	model_source = '动漫明星大乱斗',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'spell slam', 'spell' },

	--技能数量
	skill_count = 4,

	skill_names = '93式酸素鱼雷 94式深水炸弹 连装炮酱 25毫米高射炮',

	attribute = {
		['生命上限'] = 1000,
		['魔法上限'] = 600,
		['生命恢复'] = 3,
		['魔法恢复'] = 1,
		['攻击']    = 31,
		['护甲']    = 14,
		['移动速度'] = 345,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 125,
		['魔法上限'] = 30,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.1,
		['护甲']    = 1.4,
	},

	weapon = {
		['弹道模型'] = [[model\\shimakaze\\multiple_gun_missile.mdl]],
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
