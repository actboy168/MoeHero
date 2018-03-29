require 'maps.hero.亚丝娜.星屑泪光'
require 'maps.hero.亚丝娜.狂暴补师'
require 'maps.hero.亚丝娜.闪光穿刺'
require 'maps.hero.亚丝娜.圣母圣咏'

return ac.hero.create '玉置亚子'
{
	id = 'H008',

	production = '线上游戏的老婆不可能是女生？',

	model_source = '鬼畜万华镜',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'attack alternate 1', 'attack alternate 2', 'attack alternate 3', 'attack slam alternate', 'death alternate', 'spell one alternate', 'spell two alternate' },

	--技能数量
	skill_count = 4,

	skill_names = '星屑泪光 狂暴补师 闪光穿刺 圣母圣咏',

	attribute = {
		['生命上限'] = 1000,
		['魔法上限'] = 600,
		['生命恢复'] = 3,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 31,
		['护甲']    = 14,
		['移动速度'] = 335,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
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
	},

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
