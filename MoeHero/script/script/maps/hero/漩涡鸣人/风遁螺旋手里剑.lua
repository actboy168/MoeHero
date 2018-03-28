local mt = ac.skill['风遁螺旋手里剑']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},
	
	--技能图标
	art = [[BTNmrr.blp]],

	--技能说明
	title = '风遁螺旋手里剑',
	
	tip = [[
掷出巨大的螺旋手里剑，将路径上的敌人推动，并在目标点逐渐产生%area%范围，持续%duration%秒的旋风造成持续%damage%(+%damage_plus%)伤害，敌方单位在伤害期间内保持眩晕状态
引导%channel_time%秒，打断冷却%cool_break%秒
		]],

	--耗蓝
	cost = {200,270,340},

	--冷却
	cool = 90,

	--施法距离
	range = {1400,1700,2000},

	--打断冷却时间
	cool_break = 15,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--动画
	cast_animation = 4,

	--施法前摇
	cast_start_time = 0.2,

	--引导时间
	channel_time = 1.5,

	--逐渐产生范围时间
	--change_area_time = 0.5,

	--速度
	speed = 2000,

	--伤害
	damage = {250,475,700},

	--范围
	area = 500,

	--持续时间
	duration = 1.5,

	--手里剑飞行过程中检测范围
	hit_area = 250,

	damage_plus = function(self, hero)
		return hero:get_ad() * 3.2
	end,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local skill = self
	local damage = (self.damage + self.damage_plus) / (self.duration / 0.1)
	
	hero:set_animation(self.cast_animation)
	hero:add_restriction '硬直'
	--创建马甲
	ac.effect(hero:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]],270,2):remove()
	local dummy = {}
	local point = hero:get_point() - {(hero:get_point()/target:get_point())-70,100}
	dummy[1] = hero:create_dummy(nil,point,point/hero:get_point())
	dummy[1]:add_restriction '硬直'
	dummy[1]:set_class '马甲'
	dummy[1]:setPoint(point)
	dummy[1]:set_animation(5)
	ac.effect(dummy[1]:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]],270,1.2):remove()

	point = hero:get_point() - {(hero:get_point()/target:get_point())+70,100}
	dummy[2] = hero:create_dummy(nil,point,point/hero:get_point())
	dummy[2]:add_restriction '硬直'
	dummy[2]:set_class '马甲'
	dummy[2]:setPoint(point)
	dummy[2]:set_animation(5)
	ac.effect(dummy[2]:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]],270,1.2):remove()
	--创建手里剑
	local unit = hero:create_dummy('e001',hero:get_point(),hero:get_facing())
	unit:set_high(150)
	unit:setPoint(hero:get_point())
	unit:addSight(500)

	--伤害
	local timer_damage
	local DealDamage = function()
		timer_damage = hero:loop(100, function()
			for _, u in ac.selector()
				: in_range(unit, skill.area)
				: is_enemy(hero)
				: ipairs()
			do
				u:damage
				{
					source = hero,
					skill = skill,
					damage = damage,
					attack = true,
					aoe = true,
				}
				u:add_effect('chest',[[modeldekan\ability\DEKAN_Naturo_R_Damage.mdl]]):remove()
			end
		end)
	end

	local br = false
	--施法打断
	local event = hero:event '单位-施法被打断' (function(trg)
		self:set_cd(self.cool_break)
		--删除马甲
		for i,v in ipairs(dummy) do
			v:remove()
		end
		unit:remove()
		hero:remove_restriction '硬直'
		br = true
		trg:remove()
		if timer_damage then timer_damage:remove() end
	end)
	hero:wait(500,function()
		if br then
			return
		end
		local eff = hero:add_effect('hand',[[DEKAN_Naturo_R_FDSLJ.mdl]]) 
		hero:get_point():add_effect([[modeldekan\ability\DEKAN_Naturo_R_Start.mdl]]):remove()
		--删除马甲
		for i,v in ipairs(dummy) do
			v:get_point():add_effect([[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
			v:remove()
		end
		hero:set_animation(7)
		hero:wait(500,function()
			if br then
				eff:remove()
				return
			end
			hero:set_animation(8)
			event:remove()
			hero:wait(500, function()
				local mover = ac.mover.target 
				{
					source = hero,
					mover = unit,
					target = target,
					skill = self,
					speed = self.speed,
					hit_area = self.hit_area,
					target_high = unit:get_high(),
					hit_same = true,
					missile = true,

					on_finish = function(self)
						self:remove(true)
						for _, u in ac.selector()
							: in_range(unit, skill.area)
							: is_enemy(hero)
							: ipairs()
						do
							u:add_buff '晕眩'
							{
								source = hero,
								time = skill.duration,
							}
						end
						DealDamage()
						unit.eff2 = unit:add_effect('origin',[[modeldekan\ability\DEKAN_Naturo_R_Tornado.mdl]])
						hero:wait(skill.duration*1000, function()
							unit:kill()
							unit.eff1:remove()
							unit.eff2:remove()
							if timer_damage then timer_damage:remove() end
						end)
					end,
				}
				if mover then
					function mover:on_hit(dest)
						dest:setPoint(self.mover:get_point()-{(self.mover:get_point()/dest:get_point()),75})
					end
				end
				hero:remove_restriction '硬直'
				hero:set_animation_speed(1)
				eff:remove()
				unit.eff1 = unit:add_effect('origin',[[DEKAN_Naturo_R_FDSLJ_NoBith.mdl]])
				ac.effect(unit:get_point() - {hero:get_facing(),100},[[modeldekan\ability\DEKAN_Naturo_R_Launch.mdl]],270,1):remove()
				
			end)
		end)
	end)
end
