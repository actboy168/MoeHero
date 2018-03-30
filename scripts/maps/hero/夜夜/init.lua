require 'maps.hero.夜夜.忘却水月'
require 'maps.hero.夜夜.月影红莲'
require 'maps.hero.夜夜.乱舞夜樱'
require 'maps.hero.夜夜.楸木太刀影'
require 'maps.hero.夜夜.旋转吧！雪月花'

return ac.hero.create '夜夜'
{
	--物编中的id
	id = 'H00T',

	production = '机巧少女不会受伤',

	model_source = '全明星战役',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'spell channel one', 'spell slam one', 'spell slam two' },

	--技能数量
	skill_count = 4,

	skill_names = '忘却水月 乱舞夜樱 楸木太刀影 旋转吧！雪月花',

	attribute = {
		['生命上限'] = 1200,
		['魔法上限'] = 600,
		['生命恢复'] = 4,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 29,
		['护甲']    = 19,
		['移动速度'] = 300,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 140,
		['魔法上限'] = 30,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0.1,
		['攻击']    = 2.9,
		['护甲']    = 1.9,
	},

	weapon = {
	},

	difficulty = 2,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
