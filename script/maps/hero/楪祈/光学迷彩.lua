local mt = ac.skill['光学迷彩']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNyqw.blp]],

	--技能说明
	title = '光学迷彩',
	
	tip = [[
隐身并提高%move_rate%%移动速度，持续%duration%秒。附近没有敌方单位时，持续时间提高到%duration_none%秒。
隐身状态下|cff11ccff快速射击|r不会破隐，且造成的伤害提高%damage_rate%%。
		]],

	--耗蓝
	cost = 60,

	--冷却
	cool = {22, 14},

	--目标类型
	target_type = ac.skill.TARGET_TYPE_NONE,

	--持续时间
	duration = 1.5,

	--周围无敌人持续时间
	duration_none = 6,

	--检测范围
	area = 600,

	--移动速率
	move_rate = {20, 40},
	damage_rate = {20, 36},

	cast_animation_channel = 0.25,
	break_move = 0,
}


function mt:on_add()
	local hero = self.owner
	self.timer = hero:loop(100, function()
		local g = ac.selector()
			: in_range(hero, self.area)
			: is_enemy(hero)
			: get()
		if #g <= 0 then
			if not self.blend then
				self.blend = self:add_blend('2', 'frame', 2)
			end
		else
			if self.blend then
				self.blend:remove()
				self.blend = nil
			end
		end
	end)
end

function mt:on_remove()
	self.timer:remove()
	if self.blend then
		self.blend:remove()
		self.blend = nil
	end
end

function mt:on_cast_shot()
	local hero = self.owner
	local time = 0
	local g = ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: get()
	--如果大于0隐身持续时间为1.5秒
	if #g > 0 then
		time = self.duration
	else
		time = self.duration_none
	end
	hero:get_point():add_effect([[modeldekan\ability\DEKAN_Inori_W_Effect.mdl]]):remove()
	hero:add_buff '光学迷彩'
	{
		time = time,
		move_speed_rate = self.move_rate,
		skill = self,
	}
end

local mt = ac.buff['光学迷彩']

mt.cover_type = 1

function mt:on_add()
	local hero = self.target
	local skl = hero:find_skill '快速射击'
	if skl then
		self.blend = skl:add_blend('2', 'frame', 2)
	end
	self.target:add_restriction '隐身'
	self.target:add('移动速度%', self.move_speed_rate)
	self.trg_attack = self.target:event '单位-攻击出手' (function()
		self:remove()
	end)
	self.trg_spell = self.target:event '技能-施法开始' (function(trg, _, skill)
		if skill.name ~= '快速射击' then
			self:remove()
			return
		end
		skill.damage_rate = self.skill.damage_rate
	end)
	self.skill:show_buff(self)
	self.skill:set_option('show_cd', 0)
end

function mt:on_remove()
	if self.blend then
		self.blend:remove()
	end
	self.target:remove_restriction '隐身'
	self.target:add('移动速度%', -self.move_speed_rate)
	self.trg_attack:remove()
	self.trg_spell:remove()
	self.skill:set_option('show_cd', 1)
end
