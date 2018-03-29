



local mt = ac.skill['银符[完美女仆]']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNsakuyaW.blp]],

	--技能说明
	title = '银符[完美女仆]',
	
	tip = [[
以飞刀将自己团团围住，消失%cast_channel_time%秒后，瞬移到目标地点。每把飞刀造成%damage%(+%damage_plus%)伤害。
%buff_time%秒内，可以加速一次|cff11ccff速符[闪光弹跳]|r或|cff11ccff幻符[杀人玩偶]|r，降低延迟且移动速度提高%buff_speed_rate%%。
	]],

	--消耗
	cost = {100, 80},

	--冷却
	cool = {32, 16},

	--施法距离
	range = 9999,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,
	
	--施法前摇和动作等
	cast_start_time = 0.1,
	cast_channel_time = 0.3,
	cast_animation = 4,

	distance = {500, 700},

	speed = {2000, 2400},

	count = {8, 12},

	--伤害
	damage = {40, 80},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	
	buff_time = 1,
	buff_speed_rate = { 80, 120 }
}

local create_knife = require 'maps.hero.十六夜咲夜.光速[光速跳跃]'

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local distance = math.min(hero:get_point() * target, self.distance)
	local target = hero:get_point() - { angle, distance }
	local damage = self.damage + self.damage_plus
	local mark = {}
	local has_q = hero:find_buff '速符[闪光弹跳]'
	local has_e = hero:find_buff '幻符[杀人玩偶]'
	if has_q then
		hero:remove_buff '速符[闪光弹跳]'
	end
	if has_e then
		hero:remove_buff '幻符[杀人玩偶]'
		damage = damage * (1 + has_e.rate / 100)
	end
	self.has_r = hero:find_buff '[小夜的世界]-时停'
	if self.has_r then
		self.count = self.count - 4
	end
	self.feidao = {}
	for i = 1, self.count do
		local mvr = create_knife
		{
			source = hero,
			start = hero:get_point() - { 360 / self.count * i, 200 },
			speed = self.speed,
			angle =   360 / self.count * i - 180 + 10,
			distance = 2000,
			skill = self,
			damage = damage,
			size = 0.8,
			has_q = has_q,
			has_e = has_e,
			mark = mark,
		}
		mvr:pause(true)
		table.insert(self.feidao, mvr)
	end
	hero:add_restriction '无敌'
	hero:add_restriction '阿卡林'
	if self.has_r then
		return
	end
	self.fog = hero:get_owner():createFogmodifier(target, 400)
	local info = {
		start = { target - {angle + 90, 200}, target - {angle - 90, 200}, hero:get_point(), hero:get_point() },
		angle = { angle - 90, angle - 270, angle + 90, angle - 90 },
		source_alpha = { 0, 0, 80, 80 },
		target_alpha = { 80, 80, 0, 0 },
	}
	self.dummy = {}
	for i = 1, 4 do
		local u = hero:create_dummy(nil, info.start[i], angle)
		u:set_class '马甲'
		u:add_buff '淡化*改'
		{
			source_alpha = info.source_alpha[i],
			target_alpha = info.target_alpha[i],
			time = self.cast_channel_time,
		}
		ac.mover.line
		{
			source = hero,
			mover = u,
			angle = info.angle[i],
			distance = 200,
			speed = 200 / self.cast_channel_time,
			skill = self,
		}
		self.dummy[i] = u
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local distance = math.min(hero:get_point() * target, self.distance)
	local target = hero:get_point() - { angle, distance }
	hero:blink(target, false, true)
	for _, mvr in ipairs(self.feidao) do
		mvr:pause(false)
	end
	hero:set_animation('stand')
	hero:remove_restriction '无敌'
	hero:remove_restriction '阿卡林'
	if self.has_r then
		for i = 1, 3 do
			local skl = hero:find_skill(i)
			if skl and skl:is_cooling() then
				skl:set_cd(0)
			end
		end
	else
		self.fog:remove()
		for i = 1, 4 do
			self.dummy[i]:remove()
		end
	end
	hero:add_buff '银符[完美女仆]'
	{
		time = self.buff_time,
		rate = self.buff_speed_rate,
	}
end

local mt = ac.buff['银符[完美女仆]']

function mt:on_add()
	local hero = self.target
	local has_q = hero:find_skill '速符[闪光弹跳]'
	local has_e = hero:find_skill '幻符[杀人玩偶]'
	if has_q then
		self.blend1 = has_q:add_blend('2', 'frame', 2)
	end
	if has_e then
		self.blend2 = has_e:add_blend('2', 'frame', 2)
	end
end

function mt:on_remove()
	if self.blend1 then self.blend1:remove() end
	if self.blend2 then self.blend2:remove() end
end
