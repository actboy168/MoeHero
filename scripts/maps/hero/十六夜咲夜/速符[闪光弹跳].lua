local math = math

local mt = ac.skill['速符[闪光弹跳]']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNsakuyaQ.blp]],

	--技能说明
	title = '速符[闪光弹跳]',
	
	tip = [[
后跳一小段距离，放出15把飞刀。每把飞刀造成%damage%(+%damage_plus%)伤害。
%buff_time%秒内，可以加强一次|cff11ccff银符[完美女仆]|r或|cff11ccff幻符[杀人玩偶]|r，穿透敌人且增加%buff_count%次反弹/穿透。
	]],

	--施法距离
	range = 9999,
	
	--耗蓝
	cost = {70, 50},

	--冷却
	cool = {14, 10},

	--动画
	cast_animation = 1,
	cast_animation_speed = 2,

	--施法前摇
	cast_start_time = 0.2,
	cast_channel_time = 0.2,
	break_order = 1,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--伤害
	damage = {40, 80},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,

	--弹道速度
	speed = {1200, 1400},

	--角度差
	angle = 17.5,

	--最大飞行距离
	distance = 1000,

	buff_time = 1,
	buff_count = {1, 5},
}

local create_knife = require 'maps.hero.十六夜咲夜.光速[光速跳跃]'

local function cast_spell_q(hero, target, skill, damage, do_damage)
end

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local damage = self.damage + self.damage_plus
	local speed = self.speed
	local mark = {}
	local has_w = hero:find_buff '银符[完美女仆]'
	local has_e = hero:find_buff '幻符[杀人玩偶]'
	if has_w then
		hero:remove_buff '银符[完美女仆]'
		speed = speed * (1 + has_w.rate / 100)
	end
	if has_e then
		hero:remove_buff '幻符[杀人玩偶]'
		damage = damage * (1 + has_e.rate / 100)
	end
	ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = target / hero:get_point(),
		accel = -4000,
		speed = 1000,
		distance = 120,
		skill = self,
		block = true,
	}
	local angle = hero:get_point() / target
	local start = hero:get_point()
	local function create_knife_wave(j)
		for i = -2, 2 do
			local mvr = create_knife
			{
				source = hero,
				start = start - { angle, 40 - j * 40 } - { angle + i * self.angle, 100 },
				speed = speed,
				angle = angle + i * (4 + j * 2),
				distance = self.distance,
				skill = self,
				damage = damage,
				size = 0.8,
				mark = mark,
				has_e = has_e,
			}
			if not has_w then
				mvr:pause(true)
				hero:wait(500, function ()
					mvr:pause(false)
				end)
			else
				if j > 0 then
					mvr:pause(true)
					hero:wait(100, function ()
						mvr:pause(false)
					end)
				end
			end
		end
	end
	create_knife_wave(1)
	hero:wait(100, function ()
		create_knife_wave(2)
		hero:wait(100, function ()
			create_knife_wave(3)
		end)
	end)
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:add_buff '速符[闪光弹跳]'
	{
		time = self.buff_time,
		count = self.buff_count,
	}
end

local mt = ac.buff['速符[闪光弹跳]']

function mt:on_add()
	local hero = self.target
	local has_w = hero:find_skill '银符[完美女仆]'
	local has_e = hero:find_skill '幻符[杀人玩偶]'
	if has_w then
		self.blend1 = has_w:add_blend('2', 'frame', 2)
	end
	if has_e then
		self.blend2 = has_e:add_blend('2', 'frame', 2)
	end
end

function mt:on_remove()
	if self.blend1 then self.blend1:remove() end
	if self.blend2 then self.blend2:remove() end
end
