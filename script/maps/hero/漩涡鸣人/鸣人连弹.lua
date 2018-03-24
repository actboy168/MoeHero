local mt = ac.skill['鸣人连弹']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNmre.blp]],

	--技能说明
	title = '鸣人连弹',
	
	tip = [[
跳向目标身边对目标进行一系列体术攻击造成%damage%(+%damage_plus%)伤害过程目标眩晕，目标周围%dummy_area%范围内的鸣人分身也会加入其中，每一个分身提高%add_damage%%伤害
		]],

	--耗蓝
	cost = 70,

	--施法距离
	range = 300,

	--冷却
	cool = 12,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--施法前摇
	cast_start_time = 0.333,
	
	--伤害
	damage = {70, 250},

	--眩晕时间
	stun = 1,

	--周围的分身
	dummy_area = 600,

	--分身提高伤害
	add_damage = 10,

	--跳跃速度
	speed = 1200,

	--伤害间隔
	interval = 0.1,
	
	--动画
	cast_animation = 3,

	damage_plus = function(self, hero)
		return hero:get_ad() * 2
	end,
}

mt.break_order = 1

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local damage = (self.damage + self.damage_plus)-- / (self.stun / self.interval)

	--接口
	local function Naturo_E(hero,target,true_hero)
		local damage2 = damage
		local animation_speed = 0.277 / ( math.abs(hero:get_point() * target:get_point()) / self.speed )
		hero:set_animation_speed(animation_speed)
		hero:add_restriction '硬直'
		if not hero:is_hero() then
			hero:wait(10,function()
				hero:set_animation(3)
				hero:set_facing(hero:get_point() / target:get_point())
			end)
			damage2 = damage2 * 0.1
		end
		ac.effect(hero:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
		local mover = ac.mover.target
		{
			true_hero = true_hero,
			damage2 = damage2 / 2,
			source = hero,
			mover = hero,
			skill = self,
			target = target,
			hit_range = 120,
			high = 0,
			speed = self.speed,
			on_remove = function(self)
				-- 第一弹，鸣人攻击
				target:add_effect('chest',[[modeldekan\ability\DEKAN_Naturo_E_Hit.mdl]]):remove()
				target:damage
				{
					source = true_hero,
					skill = self,
					damage = self.damage2,
					attack = true,
				}
				target:add_buff '击退'
				{
					angle = hero:get_point() / target:get_point(),
					distance = 100,
					speed = 600,
					accel = -10,
				}
				hero:add_buff '鸣人连弹'
				{
					source = hero,
					skill = self.skill,
					time = 1,--self.skill.stun,
					pulse = 0.3,
					skill_target = target,
					true_hero = true_hero,
					damage2 = self.damage2,
				}
				hero:remove_restriction '硬直'
				--print('damage2 = ',self.damage2)
			end,
		}
		
	end
	--print(animation_speed)
	target:add_buff '晕眩'
	{
		source = hero,
		time = self.stun,
	}

	--鸣人
	Naturo_E(hero, target, hero)

	--移动幻象
	local group = ac.selector()
		: in_range(hero, self.dummy_area)
		: is_ally(hero)
		: add_filter(function (u)
			return u:get_type_id() == hero:get_type_id() and u:is_illusion()
		end)
		: get()
	if #group > 0 then
		hero:loop(300, function(t)
			local u = group[1]
			if u then
				Naturo_E(u, target, hero)
			end
			table.remove(group, 1)
			if #group == 0 then
				t:remove()
			end
		end)
	end
end

local bff = ac.buff['鸣人连弹']

bff.pulse = 0.25
bff.damage2 = 0
bff.true_hero = nil

function bff:on_add()
	local hero = self.target
	hero:add_restriction '硬直'
end

function bff:on_remove()
	local hero = self.target
	hero:remove_restriction '硬直'
end

function bff:on_pulse()
	local hero = self.target
	local target = self.skill_target
	--print(self.pulse_count)
	if self.pulse_count == 1 then
		-- 鸣人 - 忍法
		hero:set_animation(14)
		hero:add_animation('stand')
		hero:set_animation_speed(1)
	elseif self.pulse_count == 2 then
		-- 第二弹，分身
		local point = hero:get_point() - {hero:get_facing() + 180,100}
		local dummy = hero:create_dummy(nil,point,hero:get_facing())
		dummy:add_restriction '硬直'
		dummy:set_class '马甲'
		dummy:setPoint(point)
		dummy:set_animation(13)	
		ac.effect(dummy:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
		local mover = ac.mover.target
		{
			source = dummy,
			mover = dummy,
			skill = self.skill,
			target = target,
			hit_range = 80,
			high = 30,
			speed = 800,
			true_hero = self.true_hero,
			damage2 = self.damage2,
			on_remove = function(self)
				target:add_effect('chest',[[modeldekan\ability\DEKAN_Naturo_E_Hit.mdl]])
				--print(self.true_hero)
				local t_high = 300
				local t_distance = 200
				local t_time = 0.5
				if hero ~= self.true_hero then
					t_high = t_high / 3
					t_distance = t_distance / 2
					t_time = t_time / 2
				end
				target:add_buff '击退'
				{
					angle = self.mover:get_point() / self.target:get_point(),
					distance = t_distance,
					time = t_time,
					high = t_high,
					speed = 200,
				}
				target:damage
				{
					source = self.true_hero,
					skill = self.skill,
					damage = self.damage2,
					attack = true,
				}
				
				--print('damage2 = ',self.damage2)
				target:add_buff '晕眩'
				{
					source = hero,
					time = 1,
				}
				hero:wait(400,function()
					local eff = ac.effect(dummy:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]])
					eff.unit:set_high(30)
					eff:remove()
					dummy:remove()
				end)
			end,
		}
		
	end
	--hero:set_animation(math.random(2,3))
end

function bff:on_cover()
	return false
end
