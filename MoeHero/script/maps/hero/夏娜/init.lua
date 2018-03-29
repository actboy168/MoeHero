require 'maps.hero.夏娜.真红'
require 'maps.hero.夏娜.飞焰'
require 'maps.hero.夏娜.天罚'
require 'maps.hero.夏娜.断罪'

return ac.hero.create '夏娜'
{
	--物编中的id
	id = 'H00M',

	production = '灼眼的夏娜',

	model_source = '刀剑物语(作者:柳生)(该模型不共享)',

	hero_designer = 'ZN(旧) 幻雷(新)',

	hero_scripter = '最萌小汐(旧) actboy168(新)',

	show_animation = 'attack',

	--技能数量
	skill_count = 4,

	skill_names = '真红 飞焰 天罚 断罪',

	attribute = {
		['生命上限'] = 960,
		['魔法上限'] = 600,
		['生命恢复'] = 3,
		['魔法恢复'] = 1.2,
		['魔法脱战恢复'] = 0,
		['攻击']    = 33,
		['护甲']    = 15,
		['移动速度'] = 320,
		['攻击间隔'] = 1.1,
		['攻击范围'] = 128,
	},

	upgrade = {
		['生命上限'] = 120,
		['魔法上限'] = 33,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.1,
		['攻击']    = 3.2,
		['护甲']    = 1.5,
	},

	weapon = {
	},

	difficulty = 3,

	--选取半径
	selected_radius = 32,

	--妹子
	yuri = true,

	--平胸
	pad = true,

	--萝莉
	loli = true,
}
