
require 'maps.hero.五河琴里.炎斧回旋'
require 'maps.hero.五河琴里.破焰炸裂'
require 'maps.hero.五河琴里.不灭之焰'
require 'maps.hero.五河琴里.炎魔狂暴'

return ac.hero.create '五河琴里'
{
	--物编中的id
	id = 'H00Q',

	production = '约会大作战',

	model_source = '全明星战役(作者:柳生)',

	hero_designer = '幻雷 (actboy168)',

	hero_scripter = '最萌小汐 actboy168',

	show_animation = { 'spell four', 'spell two', 'spell one' },

	--技能数量
	skill_count = 4,

	skill_names = '炎斧回旋 破焰炸裂 不灭之焰 炎魔狂暴',

	attribute = {
		['生命上限'] = 1120,
		['魔法上限'] = 200,
		['生命恢复'] = 4,
		['魔法恢复'] = -1,
		['魔法脱战恢复'] = -9,
		['攻击']    = 34,
		['护甲']    = 15,
		['移动速度'] = 300,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 140,
		['魔法上限'] = 0,
		['生命恢复'] = 0.25,
		['魔法恢复'] = 0,
		['攻击']    = 3,
		['护甲']    = 1.5,
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

	--平胸
	loli = true,
}
