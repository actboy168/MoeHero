require 'maps.hero.阿尔托莉亚.风王结界'
require 'maps.hero.阿尔托莉亚.骑士王连'
require 'maps.hero.阿尔托莉亚.直觉'
require 'maps.hero.阿尔托莉亚.誓约胜利之剑'
require 'maps.hero.阿尔托莉亚.风王结界-解放'

return ac.hero.create '阿尔托莉亚'
{
	--物编中的id
	id = 'H00X',

	production = 'Fate/stay night',

	model_source = 'U9模型区',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐',

	show_animation = { 'spell ready' },

	--技能数量
	skill_count = 4,

	skill_names = '骑士王连斩 风王结界 直觉 誓约胜利之剑',

	attribute = {
		['生命上限'] = 1040,
		['魔法上限'] = 750,
		['生命恢复'] = 3.5,
		['魔法恢复'] = 1.5,
		['魔法脱战恢复'] = 0,
		['攻击']    = 32,
		['护甲']    = 17,
		['移动速度'] = 320,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 135,
		['魔法上限'] = 35,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.15,
		['攻击']    = 3.1,
		['护甲']    = 1.5,
	},

	weapon = {
	},

	--触发系数
	proc = 1,

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,
}
