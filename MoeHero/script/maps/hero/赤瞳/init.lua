
require 'maps.hero.赤瞳.赤红之刺'
require 'maps.hero.赤瞳.斩红跳砍'
require 'maps.hero.赤瞳.妖刀村雨'
require 'maps.hero.赤瞳.葬送'

return ac.hero.create '赤瞳'
{
	--物编中的id
	id = 'H00V',

	production = '斩·赤红之瞳！',

	model_source = '刀剑物语(该模型不共享)',

	hero_designer = '幻雷',

	hero_scripter = '裸奔的代码君',

	show_animation = { 'spell three', 'attack' },

	--技能数量
	skill_count = 4,

	skill_names = '赤红之刺 斩红跳砍 妖刀村雨 葬送',

	attribute = {
		['生命上限'] = 920,
		['魔法上限'] = 600,
		['生命恢复'] = 3.5,
		['魔法恢复'] = 1,
		['魔法脱战恢复'] = 0,
		['攻击']    = 40,
		['护甲']    = 14,
		['移动速度'] = 340,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 105,
		['魔法上限'] = 30,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.5,
		['护甲']    = 1.4,
	},

	weapon = {
	},

	difficulty = 4,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,
}
