
local mt = ac.skill['星爆气流斩']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNtrr.blp]],

	--技能说明
	title = '星爆气流斩',
	
	tip = [[
发动%count%次斩击，每次斩击击晕附近随机目标%stun_time%秒，造成%damage%(+%damage_plus%)点伤害及%damage_rate%%的溅射伤害
开启后额外激活|cff11ccff二刀流|r

|cffffff11攻击速度影响斩击间隔|r
	]],


	--冷却
	cool = 75,

	--耗蓝
	cost = {150, 175, 200},

	--施法后摇
	cast_finish_time = 1,
	cast_channel_time = 10,

	--施法动作
	cast_animation = 'attack alternate slam',

	--范围
	area = 400,

	--攻击次数
	count = 20,

	--击晕
	stun_time = 0.1,

	--间隔
	damage_cool = 0.2,

	--二段动画间隔
	damage_cool2 = 0.2,

	--伤害
	damage = {360, 410, 560},
	damage_plus = function(self, hero)
		return hero:get_ad() * 4
	end,

	--伤害溅射(%)
	damage_rate = 75,

	--溅射范围
	damage_area = 400,
}

function mt:on_cast_channel()
	local hero = self.owner
	local attack_cool = self.owner:get '攻击间隔'
	local attack_speed = self.owner:get '攻击速度'
	if attack_speed >= 0 then
		attack_cool = attack_cool / (1 + attack_speed / 100)
	else
		attack_cool = attack_cool * (1 + attack_speed / 100)
	end
	hero:set_animation_speed(attack_speed * 4)
	
	hero:add_buff '星爆气流斩'
	{
		pulse = self.damage_cool * attack_cool,
		area = self.area,
		count = self.count,
		stun = self.stun_time,
		damage = (self.damage + self.damage_plus) / self.count,
		damage_rate = self.damage_rate / 100,
		damage_area = self.damage_area,
		skill = self,
	}

	--自动开启二刀流
	local skl = hero:find_skill '二刀流'
	if not skl or skl:get_level() == 0 then
		return
	end
	skl:update_data()
	
	hero:add_buff '二刀流'
	{
		time = skl.time,
		attack_speed_rate = skl.attack_speed_rate,
		block_chance = skl.block_chance_up,
		skill = skl,
	}
end

function mt:on_remove()
	local hero = self.owner

	hero:remove_buff '星爆气流斩'
end

local mt = ac.buff['星爆气流斩']

function mt:on_add()
	local hero = self.target

	self:set_stack(self.count)

	--视觉动画
	local timer_index = 0
	self.timer = hero:loop(100, function()
		hero:set_facing(hero:get_facing() + 90)
		hero:set_high(math.random(120,240), false)
		hero:set_animation('attack alternate')
		timer_index = timer_index + 1
		local size = math.random(7,13)/10
		local i = math.random(1,2)
		local angle = 0
		local str = [[]]
		if i == 1 then
		 	str = [[_45Angle]]
		 	angle = timer_index * math.random(20,45)
		 	angle = math.random(90,270) 
	 	else
		 	angle = math.random(135,225)
		end
		local eff = nil
		if timer_index % 2 == 1 then
			eff = ac.effect(hero:get_point(),[[modeldekan\ability\DEKAN_Kirito_R_Flash_Blue]]..str..[[.mdl]],angle,size)
		else
			eff = ac.effect(hero:get_point(),[[modeldekan\ability\DEKAN_Kirito_R_Flash_Red]]..str..[[.mdl]],angle - 90,size)
		end
		hero:add_effect('chest',[[modeldekan\ability\dekan_kirito_r_wind_blue.mdl]]):remove()
		eff.unit:set_high(200)
		eff:remove()
	end)
end

function mt:on_remove()
	local hero = self.target

	hero:set_animation_speed(1)
	hero:set_animation 'stand'
	hero:set_high(0)

	--解除硬直
	self.skill:finish()
	self.timer:remove()
end

function mt:on_pulse()
	local hero = self.target

	self:add_stack(- 1)
	local count = self:get_stack()
	
	--对附近随机单位造成伤害
	local u = ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: random()

	if u then

		u:add_buff '晕眩'
		{
			source = hero,
			time = self.stun,
		}
		
		u:damage
		{
			source = hero,
			damage = self.damage,
			skill = self.skill,
			attack = true,
		}

		u:add_effect('chest', [[modeldekan\ability\dekan_kirito_r_hit_effect.mdl]]):remove()

		--对附近单位造成溅射伤害
		for _, u in ac.selector()
			: in_range(u, self.damage_area)
			: is_not(u)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = self.damage * self.damage_rate,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
		end
	end

	if count == 0 then
		self:remove()
		return
	end

	--根据攻击速度改变下一次周期
	local attack_cool = hero:get '攻击间隔'
	local attack_speed = hero:get '攻击速度'
	if attack_speed >= 0 then
		attack_cool = attack_cool / (1 + attack_speed / 100)
	else
		attack_cool = attack_cool * (1 + attack_speed / 100)
	end
	hero:set_animation_speed(attack_speed * 4)
	if count >= 8 then
		self:set_pulse(self.skill.damage_cool * attack_cool)
	else
		self:set_pulse(self.skill.damage_cool2 * attack_cool)
	end
	
end

function mt:on_cover()
	return true
end
