require 'maps.hero.亚丝娜.星屑泪光'
require 'maps.hero.亚丝娜.狂暴补师'
require 'maps.hero.亚丝娜.闪光穿刺'
require 'maps.hero.亚丝娜.圣母圣咏'

return ac.hero.create '亚丝娜'
{
	--物编中的id
	id = 'H00R',

	production = '刀剑神域',

	model_source = 'SAO紫月之光',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'attack slam', 'spell one', 'spell two', 'spell three' },

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
