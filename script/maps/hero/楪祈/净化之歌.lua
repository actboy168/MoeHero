local mt = ac.skill['净化之歌']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNyqr.blp]],

	--技能说明
	title = '净化之歌',
	
	tip = [[
使%area%范围内敌方无法攻击，驱散友方单位的负面状态并持续恢复%heal_base%(+%heal_plus%)生命，持续%cast_channel_time%秒。

自己处于|cff11ccff虚空赋予|r状态下时，该技能改为对%area%范围内敌方单位造成%damage_base%(+%damage_plus%)伤害，持续%cast_channel_time%秒。
|cffffff11施法时无敌。|r
		]],

	--耗蓝
	cost = {120, 200},

	--冷却
	cool = {70, 50},
	
	--施法距离
	range = 300,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_NONE,

	--施法时间
	cast_channel_time = 2,

	--恢复生命值
	heal_base = {300, 900},
	heal_plus = function(self, hero)
		return hero:get_ad() * 4.8
	end,
	heal = function(self, hero)
		return self.heal_base + self.heal_plus
	end,

	--作用范围
	area = 1000,

	--伤害
	damage_base = {200, 600},
	damage_plus = function(self, hero)
		return hero:get_ad() * 3.2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	
	break_move = 0,
}

function mt:on_cast_channel_er()
	local hero = self.owner
	local damage = self.damage / (self.cast_channel_time / 0.2)
	self.eff1 = hero:add_effect('origin',[[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]])
	self.eff2 = hero:add_effect('chest',[[Abilities\Weapons\ZigguratMissile\ZigguratMissile.mdl]])
	hero:add_restriction '无敌'
	hero:set_animation('spell channel three')
	local angle = hero:get_facing()
	self.timer1 = hero:loop(100, function()
		for i = 0, 1 do
			local dummy = hero:create_dummy(nil, hero:get_point() - {angle + 180*i, math.random(40,60)}, angle + 180*i)
			dummy:add_restriction '硬直'
			dummy:set_class '马甲'
			if math.random(1,2)==1 then
				dummy:set_animation_speed(2)
				dummy:set_animation(3)
			else	
				dummy:set_animation(5)
			end
			dummy:add_buff '淡化'
			{
				time = 0.4,
			}
		end
		angle = angle + math.random(30,45)
	end)
	self.timer2 = hero:loop(200, function()
		for _, u in ac.selector()
			: in_range(hero, self.area)
			: is_enemy(hero)
			: ipairs()
		do
			local mvr = ac.mover.target
			{
				source = hero,
				target = u,
				speed = 2500,
				model = [[modeldekan\ability\DEKAN_Inori_R_Missile.mdl]],
				skill = self,
				high = 75,
				height = 25,
			}
			if mvr then
				function mvr:on_finish()
					u:damage
					{
						source = hero,
						skill = self,
						damage = damage,
						aoe = true,
						attack =true,
					}
				end
			end
		end
	end)
end

function mt:on_cast_stop_er()
	self.owner:remove_restriction '无敌'
	self.eff1:remove()
	self.eff2:remove()
	self.timer1:remove()
	self.timer2:remove()
end

function mt:on_cast_channel_r()
	local hero = self.owner
	self.casterbuff = hero:add_buff '净化之歌-光环'
	{
		source = hero,
		time = self.cast_channel_time,
		area = self.area,
		skill = self,
		selector = ac.selector()
			: in_range(hero, self.area)
			,
		data = {
			heal = self.heal / self.cast_channel_time,
		},
	}
end

function mt:on_cast_stop_r()
	self.casterbuff:remove()
end

function mt:on_cast_channel()
	if self.owner:find_buff '虚空赋予' then
		self:on_cast_channel_er()
		self.on_cast_stop = self.on_cast_stop_er
	else
		self:on_cast_channel_r()
		self.on_cast_stop = self.on_cast_stop_r
	end
end

local mt = ac.aura_buff['净化之歌-光环']
mt.aura_pulse = 0.1
mt.child_buff = '净化之歌'

function mt:on_add()
	local hero = self.target
	hero:set_animation 'spell channel two'
	self.eff = hero:add_effect('origin', [[modeldekan\ability\DEKAN_Inori_R_Music.mdl]])
end

function mt:on_remove()
	local hero = self.target
	hero:set_animation 'stand'
	self.eff:remove()
end

local mt = ac.buff['净化之歌']

mt.cover_type = 1
mt.cover_max = 1
mt.pulse = 0.5

function mt:on_add()
	local hero = self.source
	local u = self.target
	if u:is_enemy(hero) then
		u:add_restriction '缴械'
		self.eff = u:add_effect('origin', [[modeldekan\ability\DEKAN_Inori_R_Buff_Enemy.mdl]])
	end
end

function mt:on_remove()
	local hero = self.source
	local u = self.target
	if u:is_enemy(hero) then
		u:remove_restriction '缴械'
		self.eff:remove()
	end
end

function mt:on_pulse()
	local hero = self.source
	local u = self.target
	if not u:is_enemy(hero) then
		for buff in u:each_buff() do
			if buff.debuff then
				buff:remove()
			end
		end
		u:heal 
		{
			source = hero,
			heal = self.data.heal * self.pulse,
			skill = self.skill,
		}
		if u ~= hero then
			u:add_effect('chest', [[modeldekan\ability\DEKAN_Inori_R_Buff_Ally.mdl]]):remove()
		end
	end
end


function mt:on_cover(new)
	return false
end
