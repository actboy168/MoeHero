
require 'maps.hero.金木研.JinMuYan_1'
require 'maps.hero.金木研.JinMuYan_2'
require 'maps.hero.金木研.JinMuYan_2_Sub'
require 'maps.hero.金木研.JinMuYan_3'
require 'maps.hero.金木研.JinMuYan_4'

require 'maps.hero.金木研.JinMuYan_2_Buff'
require 'maps.hero.金木研.JinMuYan_3_Buff'

return ac.hero.create '金木研'
{
	--物编中的id
	id = 'H00P',

	production = '东京食尸鬼',

	model_source = '二次元血战',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐',

	show_animation = 'spell one',

	--技能数量
	skill_count = 4,

	skill_names = 'JinMuYan_1 JinMuYan_2 JinMuYan_3 JinMuYan_4',

	attribute = {
		['生命上限'] = 1040,
		['魔法上限'] = 600,
		['生命恢复'] = 6,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 32,
		['护甲']    = 13,
		['移动速度'] = 320,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 130,
		['魔法上限'] = 30,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.1,
		['护甲']    = 1.3,
	},

	weapon = {
	},

	difficulty = 1,

	--选取半径
	selected_radius = 32,
}
