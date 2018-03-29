require 'maps.hero.黑雪姬.死亡穿刺'
require 'maps.hero.黑雪姬.黑之睡莲'
require 'maps.hero.黑雪姬.死亡旋转'
require 'maps.hero.黑雪姬.绝对切断'
require 'maps.hero.黑雪姬.假想体'

return ac.hero.create '黑雪姬'
{
	--物编中的id
	id = 'H00H',

	production = '加速世界',

	model_source = '刀剑物语(该模型不共享)',

	hero_designer = 'actboy168',

	hero_scripter = '最萌小汐',

	show_animation = { 'spell', 'spell one' },

	--技能数量
	skill_count = 5,

	skill_names = '死亡穿刺 黑之睡莲 死亡旋转 绝对切断 假想体',

	attribute = {
		['生命上限'] = 960,
		['魔法上限'] = 700,
		['生命恢复'] = 3,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 32,
		['护甲']    = 12,
		['移动速度'] = 330,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 800,
	},

	upgrade = {
		['生命上限'] = 120,
		['魔法上限'] = 43,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.2,
		['护甲']    = 1.2,
	},

	weapon = {
		['弹道模型'] = [[units\nightelf\Vengeance\Vengeance.mdl]],
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
