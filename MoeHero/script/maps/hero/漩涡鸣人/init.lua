require 'maps.hero.漩涡鸣人.螺旋丸'
require 'maps.hero.漩涡鸣人.多重影分身'
require 'maps.hero.漩涡鸣人.鸣人连弹'
require 'maps.hero.漩涡鸣人.风遁螺旋手里剑'

return ac.hero.create '漩涡鸣人'
{
	--物编中的id
	id = 'H00W',

	production = '火影忍者',

	model_source = '忍者村大战',

	hero_designer = '幻雷',

	hero_scripter = '裸奔的代码君 德堪',

	--技能数量
	skill_count = 4,

	skill_names = '螺旋丸 多重影分身 鸣人连弹 风遁螺旋手里剑',

	attribute = {
		['生命上限'] = 1000,
		['魔法上限'] = 700,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.5,
		['魔法脱战恢复'] = 0,
		['攻击']    = 30,
		['护甲']    = 13,
		['移动速度'] = 310,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 125,
		['魔法上限'] = 33,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.15,
		['攻击']    = 3.0,
		['护甲']    = 1.3,
	},

	weapon = {
	},

	difficulty = 4,

	--选取半径
	selected_radius = 32,
}
