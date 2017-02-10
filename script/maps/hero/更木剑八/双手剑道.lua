



local mt = ac.skill['双手剑道']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNjbq.blp]],

	--技能说明
	title = '双手剑道',
	
	tip = [[
|cff11ccff主动：|r
将剑横扫，对前方近身范围内的敌方单位造成%damage%(+%damage_plus%)伤害

|cff11ccff被动：|r
普通攻击使目标移动速度减少%move_rate%%，持续时间为攻击间隔的一半
	]],

	--施法时间
	cast_start_time = 0.3,

	--后摇时间
	cast_finish_time = 0.3,

	--耗蓝
	cost = 70,

	--冷却
	cool = {7, 5},

	--施法动作
	cast_animation = function(self, hero)
		if hero:find_buff '卍解[吞噬吧野晒]' then
			return 3
		end
		return 2
	end,

	--该动画不能被跳过
	important_animation = true,
	
	--施法距离
	range = 300,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--伤害半径
	radius = 300,

	--判定角度
	angle = 120,

	--伤害
	damage = {50, 150},

	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,

	--移速降低(%)
	move_rate = 50,

	--持续时间比例(%)
	time_rate = 50,
}

function mt:on_cast_start()
	local hero = self.owner
	--在武器上绑定一个特效

	local eff = hero:add_effect('weapon', [[Abilities\Weapons\PhoenixMissile\Phoenix_Missile.mdl]])
	hero:wait(600, function()
		eff:remove()
	end)
end

function mt:on_cast_channel()
	local hero = self.owner
	local damage = self.damage + self.damage_plus
	local p = hero:get_point()
	local face = p / self.target

	for _, u in ac.selector()
		: in_sector(hero, self.radius, face, self.angle)
		: is_enemy(hero)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			attack = true,			--触发攻击效果
			aoe = true,
		}
	end
end

--法球
mt.orb = nil

function mt:on_upgrade()

	if self:get_level() ~= 1 then
		return
	end
	
	local hero = self.owner

	self.buff = hero:add_buff '双手剑道'
	{
		skill = self,
	}
end

function mt:on_remove()
	if self.buff then self.buff:remove() end
end


local mt = ac.orb_buff['双手剑道']

function mt:on_hit(damage)	
	if damage.target:is_type('建筑') then
		return
	end
	local skill = self.skill
	local move_rate = skill.move_rate
	local time_rate = skill.time_rate
	local attack_cool = damage.source:get '攻击间隔'
	local attack_speed = damage.source:get '攻击速度'
	if attack_speed >= 0 then
		attack_cool = attack_cool / (1 + attack_speed / 100)
	else
		attack_cool = attack_cool * (1 - attack_speed / 100)
	end

	damage.target:add_buff '减速'
	{
		source = damage.source,
		time = attack_cool * time_rate / 100,
		move_speed_rate = move_rate,
	}
end
