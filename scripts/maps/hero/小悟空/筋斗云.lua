

local math = math

local mt = ac.skill['筋斗云']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNwke.blp]],

	--技能说明
	title = '筋斗云',
	
	tip = [[
召唤筋斗云来自己脚下，移动速度提高%move_rate%%并且可以穿地形。
筋斗云可以承受%life%次英雄攻击。
持续%time%秒。
	]],

	--冷却
	cool = {50, 30},
	--耗蓝
	cost = 100,
	--动画
	cast_animation = 9,
	cast_shot_time = 0.6,
	--变身单位类型
	unit_type_id = 'H00D',
	--移速提高(%)
	move_rate = {30, 50},
	--持续时间
	time = 15,
	--筋斗云生命值
	life = {1, 5},
	--小兵伤害系数(%)
	army_rate = 25,
	--技能伤害系数(%)
	spell_rate = 0,
}

function mt:on_cast_shot()
	local hero = self.owner

	--改变高度
	hero:add_buff '高度'
	{
		time = 0.6,
		speed = 200,
	}

	--创建筋斗云
	self.dummy = hero:create_dummy('e00A', hero:get_point() - {hero:get_facing(), 5}, hero:get_facing())
	self.dummy:set_high(120)
	self.dummy:set_size(1.2)
	self.dummy:add_buff '淡化*改'
	{
		source_alpha = 10,
		target_alpha = 100,
		time = 0.6,
		remove_when_hit = true,
	}
end

function mt:on_cast_finish()
	local hero = self.owner

	local bff = hero:add_buff '筋斗云'
	{
		time = self.time,
		move_rate = self.move_rate,
		life = self.life,
		army_rate = self.army_rate / 100,
		spell_rate = self.spell_rate / 100,
		unit_type_id = self.unit_type_id,
		high = 120,
	}
end

function mt:on_remove()
	local hero = self.owner
	hero:remove_buff '筋斗云'
end

local mt = ac.buff['筋斗云']

mt.pulse = 0.02
mt.trg = nil
mt.origin_id = ''

function mt:on_add()
	local hero = self.target
	
	--变身
	self.origin_id = hero:get_type_id()
	hero:transform(self.unit_type_id)

	self.eff = hero:add_effect('origin', [[model\Wukong\Mr.War3_JDY.mdl]])

	--设置层数
	self:set_stack(math.ceil(self.life))
	hero:add_animation_properties 'Alternate'

	--增加移动速度
	hero:add('移动速度%', self.move_rate)

	--监听被攻击事件
	self.trg = hero:event '受到伤害效果' (function(trg, damage)
		if damage:get_current_damage() > 0 then
			local dmg = 1
			if damage.skill then
				dmg = dmg * self.spell_rate
			end
			if not damage.source:is_hero() then
				dmg = dmg * self.army_rate
			end
			if dmg ~= 0 then
				self.life = self.life - dmg
				if self.life <= 0 then
					--筋斗云挂啦
					self:remove()
				else
					self:set_stack(math.ceil(self.life))
				end
			end
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	hero:transform(self.origin_id)
	hero:remove_animation_properties 'Alternate'
	hero:add('移动速度%', - self.move_rate)
	hero:add_high(- self.high)
	self.eff:remove()
	self.trg:remove()
	self.dummy = hero:create_dummy('e00A', hero:get_point() - {hero:get_facing(), 5}, hero:get_facing())
	self.dummy:set_high(120)
	self.dummy:set_size(1.2)
	self.dummy:add_buff '淡化*改'
	{
		source_alpha = 100,
		target_alpha = 0,
		time = 0.6,
		remove_when_hit = true,
	}
end

function mt:on_cover(dest)
	return true
end
