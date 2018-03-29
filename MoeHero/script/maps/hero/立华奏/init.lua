
require 'maps.hero.立华奏.音速穿刺'
require 'maps.hero.立华奏.波形延迟'
require 'maps.hero.立华奏.扭曲力场'
require 'maps.hero.立华奏.谐波叠加'

return ac.hero.create '立华奏'
{
	--物编中的id
	id = 'H00O',

	production = 'Angel Beats!',

	model_source = '全明星战役',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐 actboy168',

	show_animation = { 'spell throw', 'attack' },

	--技能数量
	skill_count = 4,

	skill_names = '音速穿刺 波形延迟 扭曲力场 谐波叠加',

	attribute = {
		['生命上限'] = 1080,
		['魔法上限'] = 600,
		['生命恢复'] = 3,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 30,
		['护甲']    = 18,
		['移动速度'] = 320,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 135,
		['魔法上限'] = 30,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.0,
		['护甲']    = 1.8,
	},

	weapon = {
	},

	difficulty = 2,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,
}