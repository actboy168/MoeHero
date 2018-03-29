
require 'maps.hero.楪祈.快速射击'
require 'maps.hero.楪祈.光学迷彩'
require 'maps.hero.楪祈.虚空赋予'
require 'maps.hero.楪祈.净化之歌'

return ac.hero.create '楪祈'
{
	--物编中的id
	id = 'H00U',

	production = '罪恶王冠',

	model_source = 'u9模型区',

	hero_designer = '幻雷',

	hero_scripter = '裸奔的代码君 德堪',

	show_animation = { 'spell channel two', 'spell throw' },

	--技能数量
	skill_count = 4,

	skill_names = '快速射击 光学迷彩 虚空赋予 净化之歌',

	attribute = {
		['生命上限'] = 920,
		['魔法上限'] = 660,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 31,
		['护甲']    = 13,
		['移动速度'] = 310,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 115,
		['魔法上限'] = 32,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.0,
		['护甲']    = 1.3,
	},

	weapon = {
		['弹道模型'] = [[Abilities\Weapons\Rifle\RifleImpact.mdl]],
		['弹道速度'] = 2000,
		['弹道弧度'] = 0,
		['弹道出手'] = {15, 0, 66},
	},

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
