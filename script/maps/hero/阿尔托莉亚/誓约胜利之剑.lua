local mt = ac.skill['誓约胜利之剑']

mt{
	--初始等级
	level = 0,
	
	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},
	
	--技能图标
	art = [[BTNsaberr.blp]],

	--技能说明
	title = '誓约胜利之剑',
	
	tip = [[
对一条直线的单位造成%damage%(+%damage_plus%)伤害并击晕最多%stun_time%秒,额外消耗大量剩余法力值,根据额外消耗的法力值加成伤害
使用该技能后激活 |cff00ccff遥远的理想乡|r,持续%buff_time%秒

|cff00ccff遥远的理想乡|r
每秒治疗损失生命的%life_recover_rate%%,且生命不会低于%life_rate%%
	]],

	--消耗
	cost = 200,
	--冷却
	cool = 100,
	--施法距离
	range = 1500,
	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,
	--施法时间
	cast_start_time = 1,
	cast_shot_time = 0.3,
	--动画
	cast_animation = 10,
	cast_animation_speed = 0.6,
	--长度
	distance = 1550,
	--宽度
	width = 300,
	--伤害
	damage = {200, 650},
	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 3.2
	end,
	--伤害周期
	pulse = 0.1,
	--最大晕眩时间
	stun_time = 0.5,
	--消耗剩余法力(%)
	cost_ex_rate = 60,
	--每100法力值提升的伤害(%)
	cost_damage_rate = 5,
	--触发系数
	proc = 0.2,
	--生命恢复(%)
	life_recover_rate = 10,
	--最小生命值(%)
	life_rate = 30,
	--持续时间
	buff_time = 5,
}

function mt:on_cast_channel()
	local hero = self.owner
	local damage = self.damage + self.damage_plus
	local angle = hero:get_point() / self.target
	local distance = self.distance
	local width = self.width
	local stun_time = self.stun_time

	--伤害次数 dekan,5次改为3次，为配合视觉时间，总伤害不变
	local count = 3--self.stun_time / self.pulse

	--消耗额外法力值
	local ex_cost = self.cost_ex_rate * hero:get '魔法' / 100
	hero:add('魔法', - ex_cost)
	local damage_rate = ex_cost / 100 * self.cost_damage_rate / 100
	local damage = (damage + damage * damage_rate) / count

	local timer = hero:timer(self.pulse * 1000, count, function()
		for _, u in ac.selector()
			: in_line(hero, angle, distance, width)
			: is_enemy(hero)
			: ipairs()
		do
			u:add_buff '晕眩'
			{
				source = hero,
				time = stun_time,
			}
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self,
				aoe = true,
				attack = true,
			}
		end
		stun_time = stun_time - self.pulse
	end)
	timer:on_timer()

	hero:add_buff '遥远的理想乡'
	{
		time = self.buff_time,
		life_recover_rate = self.life_recover_rate,
		life_rate = self.life_rate,
		skill = self,
	}

	local p = hero:get_point()
	
	--特效
	local mvr = ac.mover.line
	{
		source = hero,
		distance = 20,
		angle = angle,
		start = hero:get_point() - {angle, 200},
		speed = 100,
		size = 1,
		skill = self,
		model = [[modeldekan\ability\DEKAN_Saber_R_Missile.mdl]],
	}
	
	for i=1,10 do
		local point = p - {angle, distance/10 * i}
		point:add_effect([[modeldekan\ability\DEKAN_Saber_R_Blust.mdl]]):remove()
	end
end

function mt:on_cast_start()
	local hero = self.owner
	local angle = hero:get_point() / self.target

	self.eff = hero:get_point():add_effect([[modeldekan\ability\DEKAN_Saber_R_Light.mdl]])

	hero:get_owner():play_sound [[response\阿尔托莉亚\skill\R.mp3]]
end

function mt:on_cast_stop()
	self.eff:remove()
end

local mt = ac.buff['遥远的理想乡']

mt.pulse = 1
mt.eff = nil
mt.trg = nil
mt.mover = nil

function mt:on_add()
	local hero = self.target
	local life_rate = self.life_rate / 100

	hero:add_restriction '免死'

	self.trg = hero:event '受到伤害效果' (function()
		local life = hero:get '生命'
		local max_life = hero:get '生命上限'
		local target_life = max_life * life_rate
		if life < target_life then
			hero:set('生命', target_life)
		end
	end)
	
	self.eff = hero:add_effect('origin', [[modeldekan\ability\DEKAN_Saber_R_Buff.mdl]])
end

function mt:on_remove()
	local hero = self.target

	hero:remove_restriction '免死'

	self.trg:remove()
	self.eff:remove()
	--self.mover:remove()
end

function mt:on_pulse()
	local hero = self.target

	local life = hero:get '生命'
	local max_life = hero:get '生命上限'

	hero:heal
	{
		source = hero,
		skill = self.skill,
		heal = (max_life - life) * self.life_recover_rate / 100,
	}
end

function mt:on_cover()
	return true
end
