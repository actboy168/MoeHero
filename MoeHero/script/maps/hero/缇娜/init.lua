require 'maps.hero.缇娜.震撼弹'
require 'maps.hero.缇娜.爆裂弹'
require 'maps.hero.缇娜.战术姿态'
require 'maps.hero.缇娜.仙费尔德'
require 'maps.hero.缇娜.猫头鹰因子'

return ac.hero.create '缇娜'
{
	--物编中的id
	id = 'H012',

	production = '漆黑的子弹',

	model_source = '全明星战役',

	hero_designer = '最萌小汐',

	hero_scripter = '最萌小汐',

	show_animation = { 'attack 2', 'spell five', 'spell four' },

	--技能数量
	skill_count = 4,

	skill_names = '震撼弹 爆裂弹 战术姿态 仙费尔德 猫头鹰因子',

	attribute = {
		['生命上限'] = 800,
		['魔法上限'] = 5,
		['生命恢复'] = 4,
		['魔法恢复'] = 0,
		['魔法脱战恢复'] = 0,
		['攻击']    = 31,
		['护甲']    = 10,
		['移动速度'] = 310,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 600,
	},

	upgrade = {
		['生命上限'] = 110,
		['魔法上限'] = 0,
		['生命恢复'] = 0.26,
		['魔法恢复'] = 0,
		['攻击']    = 3.4,
		['护甲']    = 1.1,
	},

	weapon = {
		['弹道模型'] = [[Abilities\Weapons\Rifle\RifleImpact.mdl]],
		['弹道速度'] = 2000,
		['弹道弧度'] = 0.15,
		['弹道出手'] = {15, 0, 66},
	},

	resource_type = '子弹',

	difficulty = 2,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,

	--萝莉
	loli = true,
}
