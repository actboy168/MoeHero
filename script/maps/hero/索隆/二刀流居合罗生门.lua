local mt = ac.skill['二刀流居合罗生门']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNZoroW.blp]],

	--技能说明
	title = '二刀流居合罗生门',
	
	tip = [[
	依次对目标%area%范围内的每一个敌人快速攻击一次，然后回到施法时的位置，过程中索隆无敌。
	]],

	--耗蓝
	cost = 80,

	--冷却
	cool = {30, 10},

	--施法前摇
	cast_start_time = 0.1,

	--施法距离
	range = 700,
	
	--影响范围
	area = {250, 550},

	--伤害加成
	damage_plus_hero = {20, 80},

	--攻击间隔
	attack_apart = 0.2,	

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,
}

mt.eff = nil

function mt:on_cast_start()
	local hero = self.owner
	if self.eff then
		self.eff:remove()
	end
	self.eff = hero:add_effect('chest',[[modeldekan\ability\DEKAN_Zoro_W_Ribbon.mdl]])
end

function mt:on_cast_break()
	if self.eff then
		self.eff:remove()
	end
end

function mt:on_cast_channel()
	local hero = self.owner
	local cast_location = hero:get_point()
	local target = self.target
	local distance = self.area
	local group = ac.selector()
		: in_range(target, distance)
		: is_enemy(hero)
		: sort_nearest_hero(target)
		: get()
	local damage = hero:get_ad()
	hero:add_restriction '无敌'

	--画圆
	local c_angle = 0
	local c_pt = target - {c_angle, distance}
	local size = distance / 250
	ac.effect(target,[[DEKAN_Zoro_R_Circle.mdx]],0,size,'origin'):remove()
	hero:wait(3, function(t)
		c_angle = c_angle + 10
		c_pt = target - {c_angle, distance}
		c_pt:add_effect([[modeldekan\ability\DEKAN_Zoro_W_CircleDeath.mdx]]):remove()
		if c_angle >= 360 then
			t:remove()
		end
	end)

	--原地出现影子
	local dummy = hero:get_owner():create_dummy('e00C',hero:get_point(),hero:get_facing())
	dummy:set_class '马甲'
	dummy:add_restriction '硬直'
	dummy:setColor(0,0,0)
	dummy:setAlpha(80)
	--dummy:add_effect('origin',[[modeldekan\ability\DEKAN_Zoro_R_DarkFire.mdl]])
	hero:setAlpha(40)
	
	hero:wait(0, function()
		hero:issue_order 'holdposition'
	end)
	
	hero:loop(self.attack_apart * 1000, function(t)
		local p = hero:get_point()
		local u = group[1]
		if u then
			local angle = math.random(0,360)
			local point = u:get_point() - {angle,60}
			hero:blink(point,false,true)
			hero:set_facing(angle + 180)
			hero:set_animation_speed(5)
			hero:set_animation(3)
			u:damage
			{
				source = hero,
				damage = damage,
				attack = true,
				skill = self,
			}
			table.remove(group, 1)
		end
		if #group == 0 then
			hero:setPoint(cast_location)
			hero:set_animation('stand')
			hero:set_animation_speed(1)
			hero:remove_restriction '无敌'
			if self.eff then
				self.eff:remove()
			end
			hero:setAlpha(100)
			dummy:remove()
			t:remove()
		end
	end)
end
