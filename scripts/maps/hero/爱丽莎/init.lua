require 'maps.hero.爱丽莎.剑技-胧月'
require 'maps.hero.爱丽莎.剑技-升天阵'
require 'maps.hero.爱丽莎.剑技-幻影突刺'
require 'maps.hero.爱丽莎.剑技-樱花残月'
require 'maps.hero.爱丽莎.血技-不动明王阵'

return ac.hero.create '爱丽莎'
{
	--物编中的id
	id = 'H013',

	production = '噬神者',

	model_source = 'U9模型区',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'spell channel one', 'attack' },

	--技能数量
	skill_count = 4,

	skill_names = '剑技-胧月 剑技-升天阵 剑技-幻影突刺 剑技-樱花残月 血技-不动明王阵',

	attribute = {
		['生命上限'] = 1040,
		['魔法上限'] = 200,
		['生命恢复'] = 4,
		['魔法恢复'] = 20,
		['魔法脱战恢复'] = 20,
		['攻击']    = 30,
		['护甲']    = 14,
		['移动速度'] = 320,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 130,
		['魔法上限'] = 0,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0,
		['攻击']    = 3,
		['护甲']    = 1.4,
	},

	weapon = {
	},

	resource_type = '体力',

	--触发系数
	proc = 1,

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
