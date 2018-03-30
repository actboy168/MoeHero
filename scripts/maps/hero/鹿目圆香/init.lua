
require 'maps.hero.鹿目圆香.净化箭矢'
require 'maps.hero.鹿目圆香.虹之雨'
require 'maps.hero.鹿目圆香.奇迹祈愿'
require 'maps.hero.鹿目圆香.圆环之理'

return ac.hero.create '鹿目圆香'
{
	--物编中的id
	id = 'H00I',

	production = '魔法少女小圆',

	model_source = '全明星战役(作者:柳生)',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐',

	show_animation = { 'spell four', 'attack' },

	--技能数量
	skill_count = 4,

	skill_names = '净化箭矢 虹之雨 奇迹祈愿 圆环之理',

	attribute = {
		['生命上限'] = 880,
		['魔法上限'] = 950,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.6,
		['魔法脱战恢复'] = 0,
		['攻击']    = 32,
		['护甲']    = 10,
		['移动速度'] = 325,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 110,
		['魔法上限'] = 70,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.25,
		['攻击']    = 2.8,
		['护甲']    = 1.0,
	},

	weapon = {
		['弹道模型'] = [[Abilities\Spells\Other\BlackArrow\BlackArrowMissile.mdl]],
		['弹道速度'] = 900,
		['弹道弧度'] = 0,
		['弹道出手'] = {15, 0, 60},
	},

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,
}
