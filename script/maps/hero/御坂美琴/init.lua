
require 'maps.hero.御坂美琴.电击使'
require 'maps.hero.御坂美琴.电磁牵引'
require 'maps.hero.御坂美琴.铁砂之剑'
require 'maps.hero.御坂美琴.超电磁炮'

return ac.hero.create '御坂美琴'
{
	--物编中的id
	id = 'H00G',

	production = '科学超电磁炮',

	model_source = '全明星战役(作者:柳生)',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐',

	show_animation = 'spell one',

	--技能数量
	skill_count = 4,

	skill_names = '电击使 电磁牵引 铁砂之剑 超电磁炮',

	attribute = {
		['生命上限'] = 920,
		['魔法上限'] = 650,
		['生命恢复'] = 3.2,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 35,
		['护甲']    = 12,
		['移动速度'] = 300,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 115,
		['魔法上限'] = 42,
		['生命恢复'] = 0.21,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.3,
		['护甲']    = 1.2,
	},

	weapon = {
		['弹道模型'] = [[war3mapimported\C9_toushewu.mdl]],
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
}