local mt = ac.skill['虚空赋予']

mt{
	level = 0,

	--技能图标
	art = [[BTNyqe.blp]],

	--技能说明
	title = '虚空赋予',
	
	tip = [[
赋予自己或者一个友方英雄%move_rate%%移动速度和%attack_damage%(+%attack_plus%)伤害提升，同一时间只能赋予一个目标。
		]],

	--耗蓝
	cost = 50,

	--冷却
	cool = 15,

	--施法距离
	range = 300,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--持续时间
	duration = 20,

	--伤害提升
	attack_damage = {10, 70},
	attack_plus = function(self, hero)
		return hero:get_ad() * 0.1
	end,

	--移动速率
	move_rate = {8, 20},

	target_data = '自己 玩家单位 联盟 英雄',
}

function mt:on_cast_shot()
	local hero = self.owner
	local current_target = self:get '当前目标'
	if current_target and current_target.target ~= self.target then
		current_target:remove()
	end
	self:set('当前目标', self.target:add_buff '虚空赋予'
	{
		source = hero,
		skill = self,
		time = self.duration,
		move_rate = self.move_rate,
		attack_damage = self.attack_damage + self.attack_plus,
	})
end

local mt = ac.buff['虚空赋予']

function mt:on_add()
	local hero = self.target
	self.eff = hero:add_effect('chest', [[modeldekan\ability\DEKAN_Inori_E_Buff.mdl]])
	hero:add('移动速度%', self.move_rate)
	hero:add('攻击', self.attack_damage)
end

function mt:on_remove()
	local hero = self.target
	hero:add('移动速度%', -self.move_rate)
	hero:add('攻击', -self.attack_damage)
	self.eff:remove()
end

function mt:on_cover(dest)
	self:set_remaining(dest.time)
	return false
end
