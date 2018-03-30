require 'maps.hero.惠惠.爆裂魔法'
require 'maps.hero.惠惠.练习爆裂魔法'
require 'maps.hero.惠惠.适合剧情展开的结界'
require 'maps.hero.惠惠.强化爆裂魔法'

return ac.hero.create '惠惠'
{
	--物编中的id
	id = 'H003',

	production = '为美好的世界献上祝福！',

	model_source = '日常Special（小黑）',

	hero_designer = 'actboy168',

	hero_scripter = 'actboy168',

	show_animation = { 'spell alternate', 'spell channel four', 'spell channel two', 'spell four alternate', 'spell slam' },

	--技能数量
	skill_count = 4,

	skill_names = '爆裂魔法 练习爆裂魔法 适合剧情展开的结界 强化爆裂魔法 爆裂魔法-释放 爆裂魔法-硬直',

	attribute = {
		['生命上限'] = 880,
		['魔法上限'] = 100,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.14,
		['魔法脱战恢复'] = 0,
		['攻击']    = 38,
		['护甲']    = 10,
		['移动速度'] = 320,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 110,
		['魔法上限'] = 0,
		['生命恢复'] = 0.3,
		['魔法恢复'] = 0.08,
		['攻击']    = 3.8,
		['护甲']    = 1.0,
	},

	weapon = {
	},

	resource_type = '魔力',

	difficulty = 2,

	--选取半径
	selected_radius = 32,

	yuri = true,
	pad = true,
	loli = true,
}
