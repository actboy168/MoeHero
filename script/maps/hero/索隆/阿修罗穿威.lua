local mt = ac.skill['阿修罗穿威']

mt{
	--初始等级
	level = 0,
	
	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},
	
	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNZoroR.blp]],

	--技能说明
	title = '鬼泣·九刀流·阿修罗·穿威',
	
	tip = [[
	朝目标点放一个索隆影子，再次释放则突进刀影子的位置。突进后对周围%_area%范围的敌人造成%damage%(+%damage_plus%)点伤害。|n|n可以储存%charge_max_stack%次。
	]],

	--耗蓝
	cost = 100,

	--冷却
	cool = 0.1,
	charge_cool = { 90, 70, 50 },

	--施法距离
	range = 1500,

	--影响区域
	_area = 450,
	
	--影子持续时间
	dur_time = 35,
	
	--储存次数
	cooldown_mode = 1,
	charge_max_stack = 3,
	
	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,
	
	--影响区域
	_area = 450,
	
	--伤害
	damage = {100, 200},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / self.target
	local distance = hero:get_point() * target
	local speed = hero:get('移动速度') * 2.5
	
	local dummy = hero:get_owner():create_dummy('e00C',hero:get_point(),angle)
	hero.zoro_r_dummy = dummy
	dummy:set_class '马甲'
	dummy:add_restriction '硬直'
	dummy:add_restriction '无敌'
	dummy:wait(self.dur_time * 1000, function()
		dummy:remove()
	end)
	dummy:setColor(0,0,0)
	--dummy:setAlpha(80)
	dummy:add_effect('origin',[[modeldekan\ability\DEKAN_Zoro_R_DarkFire.mdl]])
	dummy:set_animation(8)
	--dummy:set_animation_speed(5)

	dummy:event '单位-移除' (function()
		hero:replace_skill('阿修罗穿威-突进', '阿修罗穿威')
	end)
	
	local mvr = ac.mover.line
	{
		source = hero,
		mover = dummy,
		angle = angle,
		distance = distance,
		speed = speed,
		skill = self,
	}
	
	hero:replace_skill('阿修罗穿威', '阿修罗穿威-突进')
end


local mt = ac.skill['阿修罗穿威-突进']

local skl = ac.skill['阿修罗穿威']

mt{
	--最大等级
	max_level = 3,
	
	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNZoroR.blp]],

	--技能说明
	title = '阿修罗穿威-突进',
	
	tip = [[
	朝影子突进，到达目标后对周围%_area%范围的敌人造成%damage%(+%damage_plus%)点伤害。
	]],

	--影响区域
	_area = skl.data._area,
	
	--伤害
	damage = skl.data.damage,

	--伤害加成
	damage_plus = skl.data.damage_plus,

	--突进速度
	speed = 1500,
	
	--突进加速度
	accel = 3000,
}

function mt:on_cast_channel()
	local hero = self.owner
	local dummy = hero.zoro_r_dummy
	local damage = self.damage + self.damage_plus

	hero:add_restriction '硬直'
	local eff = hero:add_effect('chest',[[modeldekan\ability\DEKAN_Zoro_R_Missile.mdl]])
	hero:setAlpha(1)
	hero:add_restriction '无敌'
	local mvr = ac.mover.target
	{
		source = hero,
		mover = hero,
		speed = self.speed,
		accel = self.accel,
		target = dummy,
		skill = self,
		damage = damage,
		area = self._area,
		eff = eff,
		on_remove = function( self )
			hero:remove_restriction '无敌'
			self.target:kill()
			hero:remove_restriction '硬直'
			self.eff:remove()
			self.source:setAlpha(100)
			for _, u in ac.selector()
				: in_range(hero, self.area)
				: is_enemy(hero)
				: ipairs()
			do
				u:damage
				{
					source = hero,
					damage = self.damage,
					skill = self.skill,
				}
			end
		end,
	}
	
	hero:replace_skill('阿修罗穿威-突进', '阿修罗穿威')
end
