local mt = ac.skill['[小夜的世界]']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNsakuyaR.blp]],

	--技能说明
	title = '[小夜的世界]',
	
	tip = [[
令周围的时间完全停止，持续%time%秒。
在你的领域内，你的能量消耗减少%cost_save%%，每次使用|cff11ccff银符[完美女仆]|r都会重置|cff11ccff速符[闪光弹跳]|r、|cff11ccff银符[完美女仆]|r、|cff11ccff幻符[杀人玩偶]|r的冷却。
	]],

	--冷却
	charge_cool = {200, 160},

	--耗蓝
	cost = 200,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_NONE,

	--范围
	area = 400,

	--施法动作相关
	cast_start_time = 0.6,
	cast_animation = 3,
	cast_animation_speed = 2,
	cooldown_mode = 1,
	charge_max_stack = 1,
	show_stack = 0,
	show_charge = 0,

	cost_save = {60, 65, 70},
	time = {1.7, 2.1, 2.5},
}

function mt:on_cast_channel()
	local hero = self.owner
	ac.player.self:play_sound [[response\十六夜咲夜\skill\R.mp3]]
	hero:add_buff '[小夜的世界]'
	{
		source = hero,
		time = self.time,
		area = self.area,
		skill = self,
		data = {
			cost_save = self.cost_save,
		},
		selector = ac.selector()
			: in_range(hero:get_point(), self.area)
			: allow_god()
			,
	}
end


local mt = ac.aura_buff['[小夜的世界]']

mt.aura_pulse = 0.1
mt.child_buff = '[小夜的世界]-时停'
mt.force = true

function mt:on_add()
	local hero = self.target
	self.dummy = hero:create_dummy('e00F', hero:get_point(), -90)
	self.dummy:setAlpha(80)
	self.dummy:set_animation_speed(21.333 / self.time)
	self.block = self.dummy:create_block { area = self.area }
	function self.block:on_entry(mover)
		mover:pause(true)
		if mover.skill and mover.skill.name == '幻符[杀人玩偶]' then
			mover.mover:set_animation('stand')
		end
		if mover.source == hero and mover.mover:get_type_id() == 'e00E' then
			mover.mover:add_buff '淡化*改'
			{
				source_alpha = 100,
				target_alpha = 30,
				time = 0.4,
				remove_when_hit = false,
			}
		end
	end
end

function mt:on_remove()
	local hero = self.target
	self.dummy:remove()
	for mover in pairs(self.block.movers) do
		mover:pause(false)
		if mover.source == self.target and mover.mover:get_type_id() == 'e00E' then
			mover:pause(false)
			mover.mover:remove_buff '淡化*改'
			mover.mover:setAlpha(100)
		end
	end
	self.block:remove()
end

local mt = ac.buff['[小夜的世界]-时停']

mt.cover_type = 1
mt.cover_max = 1
mt.force = true

function mt:on_add()
	if self.source == self.target then
		self.target:add('减耗', self.data.cost_save)
		return
	end
	self.target:add_restriction '时停'
	self.target:add_restriction '无敌'
end

function mt:on_remove()
	if self.source == self.target then
		self.target:add('减耗', -self.data.cost_save)
		return
	end
	self.target:remove_restriction '无敌'
	self.target:remove_restriction '时停'
end

function mt:on_cover(new)
	return false
end
