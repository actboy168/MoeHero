
require 'maps.hero.桐人.格挡突进'
require 'maps.hero.桐人.旋击挑斩'
require 'maps.hero.桐人.二刀流'
require 'maps.hero.桐人.星爆气流斩'

return ac.hero.create '桐人'
{
	--物编中的id
	id = 'H00L',

	production = '刀剑神域',

	model_source = 'U9下载,请指正(修改:德堪)',

	hero_designer = '幻雷',

	hero_scripter = '最萌小汐',

	show_animation = { 'alternate attack - 1', 'alternate attack - 2', 'alternate attack slam', },

	--技能数量
	skill_count = 4,

	skill_names = '格挡突进 旋击挑斩 二刀流 星爆气流斩',

	attribute = {
		['生命上限'] = 1000,
		['魔法上限'] = 600,
		['生命恢复'] = 3.4,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 31,
		['护甲']    = 18,
		['移动速度'] = 325,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 125,
		['魔法上限'] = 30,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.1,
		['护甲']    = 1.8,
	},

	weapon = {
	},

	difficulty = 4,

	--选取半径
	selected_radius = 32,
}
