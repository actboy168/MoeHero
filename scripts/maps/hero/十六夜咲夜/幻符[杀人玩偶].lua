


local math = math

local mt = ac.skill['幻符[杀人玩偶]']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNsakuyaE.blp]],

	--技能说明
	title = '幻符[杀人玩偶]',
	
	tip = [[
向周围放出%count%把飞刀，随后朝目标地点飞去。每把飞刀造成%damage%(+%damage_plus%)伤害。
%buff_time%秒内，可以加强一次|cff11ccff速符[闪光弹跳]|r或|cff11ccff银符[完美女仆]|r，造成的伤害提高%buff_damage_rate%%。
	]],

	--冷却
	cool = {28, 24},

	--耗蓝
	cost = {90, 70},

	--施法距离
	range = 700,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	cast_start_time = 0.4,
	cast_animation = 2,
	cast_animation_speed = 2.4,

	speed = {1200, 1400},
	damage = {40, 80},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,

	count = {12, 16},

	buff_time = 1,
	buff_damage_rate = {24, 40},
}

local create_knife = require 'maps.hero.十六夜咲夜.光速[光速跳跃]'

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local speed = self.speed
	local damage = self.damage + self.damage_plus
	local mark = {}
	local has_q = hero:find_buff '速符[闪光弹跳]'
	local has_w = hero:find_buff '银符[完美女仆]'
	if has_q then
		hero:remove_buff '速符[闪光弹跳]'
	end
	if has_w then
		hero:remove_buff '银符[完美女仆]'
		speed = speed * (1 + has_w.rate / 100)
	end
	self.has_r = hero:find_buff '[小夜的世界]-时停'
	if self.has_r then
		self.count = self.count - 4
	end
	hero:set_animation('stand')
	for i = 1, self.count do
		local start = hero:get_point() - { 360 / self.count * i, 250 }
		local mvr = create_knife
		{
			source = hero,
			start = start,
			speed = speed,
			angle = start / target,
			distance = 2000,
			skill = self,
			damage = damage,
			has_q = has_q,
			mark = mark,
		}
		mvr.mover:set_animation('stand channel')
		mvr.mover:set_animation_speed(1+math.random(0, 20)/10)
		mvr:pause(true)
		if not has_w then
			hero:wait(800, function ()
				mvr.mover:set_animation('stand')
				mvr:pause(false)
			end)
		else
			hero:wait(100, function ()
				mvr.mover:set_animation('stand')
				mvr:pause(false)
			end)
		end
	end
	hero:add_buff '幻符[杀人玩偶]'
	{
		time = self.buff_time,
		rate = self.buff_damage_rate,
	}
end

local mt = ac.buff['幻符[杀人玩偶]']

function mt:on_add()
	local hero = self.target
	local has_q = hero:find_skill '速符[闪光弹跳]'
	local has_w = hero:find_skill '银符[完美女仆]'
	if has_q then
		self.blend1 = has_q:add_blend('2', 'frame', 2)
	end
	if has_w then
		self.blend2 = has_w:add_blend('2', 'frame', 2)
	end
end

function mt:on_remove()
	if self.blend1 then self.blend1:remove() end
	if self.blend2 then self.blend2:remove() end
end
