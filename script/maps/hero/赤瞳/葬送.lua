local mt = ac.skill['葬送']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNctr.blp]],

	--技能说明
	title = '葬送',
	
	tip = [[
对目标造成一次%damage%(+%damage_plus%)伤害，该伤害护甲穿透提高%armor_pene_percent%%+(%armor_pene%点)，如果该技能伤害足以触发咒毒，还会在咒毒期间沉默目标
		]],

	--耗蓝
	cost = {90, 145, 200},

	--施法动画
	cast_animation = 7,

	--施法前摇
	cast_start_time = 0.2,

	--冷却
	cool = 60,

	--施法距离
	range = 400,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--伤害
	damage = {200, 250, 300},

	damage_plus = function(self, hero)
		return hero:get_ad() * 3.0
	end,

	--攻击力提高护甲穿透
	armor_pene = function(self, hero)
		return hero:get_ad() * 0.14
	end,

	--百分比护甲穿透
	armor_pene_percent = {10, 15, 20},
}

function mt:on_cast_channel()
	local hero = self.owner
	self.target:damage
	{
		source = hero,
		damage = self.damage + self.damage_plus,
		skill = self,
		attack = true,
		['破甲'] = hero:get '破甲' + self.armor_pene,
		['穿透'] = hero:get '穿透' + self.armor_pene_percent,
	}
	self.target:add_effect('origin', [[crimsonwake.mdl]]):remove()
	local unit = hero:create_dummy('e003', hero:get_point(), hero:get_facing())
	unit:add_effect('chest', [[crescentslashredfix.mdl]]):remove()
	hero:wait(2000, function()
		unit:remove()
	end)
end
