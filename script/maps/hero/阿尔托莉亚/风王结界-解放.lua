


local mt = ac.skill['风王结界-解放']

local skl = ac.skill['风王结界']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNsaberq.blp]],

	--技能说明
	title = '风王结界-解放',
	
	tip = [[
解放风王结界,对%stun_area%范围造成%stun_time%秒晕眩,下次攻击额外造成%damage%(+%damage_plus%)点伤害
	]],

	--前摇
	cast_start_time = 0.3,

	cast_finish_time = 0.1,
	
	--施法动作
	cast_animation = 8,

	--动画播放速度
	cast_animation_speed = 2,
	
	--晕眩范围
	stun_area = skl.data.stun_area,

	--晕眩时间
	stun_time = skl.data.stun_time,

	--额外伤害
	damage = skl.data.damage,

	--额外伤害加成
	damage_plus = skl.data.damage_plus,

	--解放Buff持续时间
	attack_buff_time = skl.data.attack_buff_time,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:remove_buff '风王结界-激活'
	local stun_time = self.stun_time
	for _, u in ac.selector()
		: in_range(hero, self.stun_area)
		: is_enemy(hero)
		: ipairs()
	do
		u:add_buff '晕眩'
		{
			source = hero,
			time = stun_time,
		}
	end
	hero:add_buff '风王结界-解放'
	{
		damage = self.damage + self.damage_plus,
		time = self.attack_buff_time,
		skill = self,
	}
	hero:get_point():add_effect([[modeldekan\ability\DEKAN_Saber_Q_Effect.mdx]]):remove()
	--hero:get_point():add_effect([[epipulse_9_12.mdx]]):remove()
end

local mt = ac.orb_buff['风王结界-解放']

mt.damage = 0

mt.eff = nil
mt.orb = nil

function mt:on_add()
	local hero = self.target

	self.eff = hero:add_effect('weapon', [[modeldekan\ability\DEKAN_Saber_Q_HandEffect.mdx]])
end

function mt:on_remove()
	local hero = self.target

	self.eff:remove()
end

function mt:on_cover()
	return true
end

function mt:on_hit(damage)
	local dmg = self.damage
	local skill = self.skill
	local dest = damage.target
	dest:damage
	{
		source = damage.source,
		damage = dmg,
		skill = skill,
	}
	dest:add_effect('origin', [[Abilities\Spells\Items\StaffOfPurification\PurificationCaster.mdl]]):remove()
	self:remove()
end
