require 'maps.hero.更木剑八.双手剑道'
require 'maps.hero.更木剑八.灵压解放'
require 'maps.hero.更木剑八.狂战'
require 'maps.hero.更木剑八.始解[吞噬吧野晒]'

return ac.hero.create '更木剑八'
{
	--物编中的id
	id = 'H00J',

	production = '死神',

	model_source = '死神无JB混战',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐',

	show_animation = 'stand ready',

	--技能数量
	skill_count = 4,

	skill_names = '双手剑道 灵压解放 狂战 始解[吞噬吧野晒]',

	attribute = {
		['生命上限'] = 1200,
		['魔法上限'] = 600,
		['生命恢复'] = 5,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 36,
		['护甲']    = 15,
		['移动速度'] = 285,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 150,
		['魔法上限'] = 25,
		['生命恢复'] = 0.3,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.2,
		['护甲']    = 1.5,
	},

	weapon = {
	},

	difficulty = 2,

	--选取半径
	selected_radius = 32,
}
