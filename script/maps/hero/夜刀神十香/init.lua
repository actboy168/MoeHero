require 'maps.hero.夜刀神十香.暴虐斩'
require 'maps.hero.夜刀神十香.暴虐舞'
require 'maps.hero.夜刀神十香.空间震'
require 'maps.hero.夜刀神十香.终焉之剑'

return ac.hero.create '夜刀神十香'
{
	--物编中的id
	id = 'H011',

	production = '约会大作战',

	model_source = 'U9模型区',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'spell one', 'spell two', 'spell three' },

	--技能数量
	skill_count = 4,

	skill_names = '暴虐斩 暴虐舞 空间震 终焉之剑',

	attribute = {
		['生命上限'] = 1040,
		['魔法上限'] = 200,
		['生命恢复'] = 4,
		['魔法恢复'] = -1,
		['魔法脱战恢复'] = -9,
		['攻击']    = 35,
		['护甲']    = 13,
		['移动速度'] = 300,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 130,
		['魔法上限'] = 0,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0,
		['攻击']    = 3.1,
		['护甲']    = 1.3,
	},

	weapon = {
	},

	resource_type = '怒气',

	--触发系数
	proc = 1,

	difficulty = 2,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
