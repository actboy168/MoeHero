
local math = math

local mt = ac.skill['狂暴']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNwkr.blp]],

	--技能说明
	title = '狂暴',
	
	tip = [[
悟空举头望满月，变身巨猿横冲直撞，免疫控制效果，降低%damage_reduce%%正面承受的所有伤害，攻击力增加%attack%，生命上限提高%max_life%，对建筑造成%crush%%的额外伤害，移动速度提高%move_speed%，持续%time%秒。

|cffff1111该状态下无法使用技能|r
	]],

	--冷却
	cool = {90, 85, 80},
	--耗蓝
	cost = 100,
	--变身单位类型
	unit_type_id = 'H00F',
	--正面伤害减免(%)
	damage_reduce = {30, 40, 50},
	--正面判定角度
	angle = 120,
	--攻击力增加
	attack = {50, 85, 120},
	--对建筑造成额外伤害(%)
	crush = 35,
	--生命
	max_life = {400, 800, 1200},
	--生命恢复速度提高
	life_recover = {25, 50, 75},
	--移动速度提升
	move_speed = 150,
	--攻击范围增加
	attack_range = 150,
	--溅射提升
	splash = 50,
	--持续时间
	time = 10,
}

function mt:on_cast_channel()
	local hero = self.owner
	
	hero:remove_buff '筋斗云'
	hero:add_buff '狂暴'
	{
		time			= self.time,
		unit_type_id	= self.unit_type_id,
		damage_reduce	= self.damage_reduce / 100,
		attack			= self.attack,
		crush			= self.crush / 100,
		max_life		= self.max_life,
		life_recover	= self.life_recover,
		move_speed		= self.move_speed,
		attack_range	= self.attack_range,
		splash			= self.splash,
		angle			= self.angle / 2
	}
end

function mt:on_remove()
	local hero = self.owner

	hero:remove_buff '狂暴'
end



local mt = ac.buff['狂暴']

mt.keep = true
mt.origin_id = 0
mt.trg1 = nil
mt.trg2 = nil
mt.trg3 = nil

function mt:on_add()
	local hero = self.target

	--特效
	hero:get_point():add_effect([[modeldekan\ability\dekan_goku_r_effect_add.mdl]]):remove()
	
	self.origin_id = hero:get_type_id()

	--变身
	hero:transform(self.unit_type_id)

	--增加攻击力与生命恢复速度
	hero:add('攻击', self.attack)
	hero:add('生命上限', self.max_life)
	hero:add('生命恢复',self.life_recover)
	hero:add('移动速度', self.move_speed)
	hero:add('攻击范围', self.attack_range)
	hero:add('溅射', self.splash)

	--禁止使用技能
	hero:add_restriction '禁魔'
	self.dest_skill = hero:find_skill('如意棒', '英雄', true)
	if self.dest_skill then
		self.dest_skill:disable()
	end

	--降低受到的正面伤害
	self.trg1 = hero:event '受到伤害' (function(trg, damage)
		local angle = damage.target:get_point() / damage.source:get_point()
		local face = damage.target:get_facing()
		if ac.math_angle(angle, face) <= self.angle then
			damage:div(self.damage_reduce)
		end
	end)

	--对建筑物造成额外伤害
	self.trg2 = hero:event '造成伤害' (function(trg, damage)
		if damage.target:is_type('建筑') then
			damage:mul(self.crush)
		end
	end)

	--免疫软控
	self.trg3 = hero:event '单位-即将获得状态' (function(trg, _, bff)
		if bff:is_control() then
			return true
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	
	--特效x
	hero:get_point():add_effect([[modeldekan\ability\dekan_goku_r_effect_remove.mdl]]):remove()
			
	--变回去
	hero:transform(self.origin_id)

	--降低攻击力与生命恢复
	hero:add('攻击', - self.attack)
	hero:add('生命上限', - self.max_life)
	hero:add('生命恢复', - self.life_recover)
	hero:add('移动速度', - self.move_speed)
	hero:add('攻击范围', - self.attack_range)
	hero:add('溅射', - self.splash)

	--允许使用技能
	hero:remove_restriction '禁魔'
	if self.dest_skill then
		self.dest_skill:enable()
	end
	
	--移除触发器
	self.trg1:remove()
	self.trg2:remove()
	self.trg3:remove()
end

function mt:on_cover()
	return true
end
