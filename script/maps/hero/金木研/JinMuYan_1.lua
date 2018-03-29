local mt = ac.skill['JinMuYan_1']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNjmyq.blp]],

	--技能说明
	title = '四爪突进',
	
	tip = [[
向目标方向突进%distance%距离，对命中单位造成%damage%(+%damage_plus%)伤害并击晕目标%stun_time%秒
	]],

	--耗蓝
	cost = 75,

	--冷却
	cool = 9,

	--施法距离
	range = 9999,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--动画
	cast_animation = 'Spell two',

	--动画速度
	cast_animation_speed = 2,

	--施法前摇
	cast_start_time = 0.4,
	cast_channel_time = 10,
	cast_shot_time = 0.3,

	--飞行距离
	distance = 600,

	--飞行速度
	speed = 1200,

	--碰撞半径
	hit_area = 75,

	--伤害
	damage = {30, 150},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,

	--击晕时间
	stun_time = 0.1,

	break_order = 1,

	replace = false,
}

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local damage = self.damage + self.damage_plus
	local stun_time = self.stun_time

	--检查是否是2段
	local bff = hero:find_buff '四爪突进'
	if bff then
		damage = damage * bff.damage_rate
		bff:remove()
	end

	--播放动画
	hero:set_animation 'Spell three'
	hero:add_animation 'stand'

	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		speed = self.speed,
		angle = angle,
		distance = self.distance,
		skill = self,
		hit_area = self.hit_area,
	}

	if not mvr then
		self:stop()
		return
	end

	function mvr:on_hit(dest)
		hero:set_animation 'Spell one'
		hero:add_animation 'stand'
		hero:set_facing(hero:get_point() / dest:get_point())

		dest:add_effect('origin', [[Objects\Spawnmodels\Human\HumanBlood\BloodElfSpellThiefBlood.mdl]]):remove()
		dest:add_effect('chest', [[Objects\Spawnmodels\Human\HumanBlood\BloodElfSpellThiefBlood.mdl]]):remove()

		--造成伤害
		dest:damage
		{
			source = self.source,
			damage = damage,
			skill = self.skill
		}

		--晕眩目标
		dest:add_buff '晕眩'
		{
			source = self.source,
			time = stun_time,
		}
		self.skill:finish()
		return true
	end

	function mvr:on_remove()
		self.skill:stop()
		--恢复动画速度
		hero:set_animation_speed(1)

		local bff = hero:find_buff '半赫者'
		if bff then
			local b = hero:find_buff '四爪突进'
			if not b then
				hero:add_buff '四爪突进'
				{
					time = bff.skill_time,
					damage_rate = bff.skill_damage_rate,
					skill = self.skill,
				}
			end
		end
	end
end

local mt = ac.buff['四爪突进']

function mt:on_add()
	local hero = self.target
	self.skill:set_cd(0)
end

function mt:on_remove()
	local hero = self.target
end

function mt:on_cover()
	return true
end
