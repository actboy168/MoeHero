local mt = ac.skill['爆裂弹']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNTinaW.blp]],
	title = '爆裂弹',
	tip = [[
|cff00ccff强袭姿态|r：
缇娜向后飞退%move_distance%距离并发射一枚爆裂弹，对第一个命中的敌人造成%damage_base%(+%damage_plus%)点伤害并对其身后的敌人造成%splash_rate%%的伤害。

|cff00ccff战术姿态|r：
缇娜飞速跑向目标位置。
若缇娜跑向了一个没有敌方英雄的位置或没有使用过这个技能，缇娜将在回到强袭姿态后提高%sub_move_rate%%的移动速度，持续%sub_move_time%秒。
	]],
	cool = 3,
	cost = 1,
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 900,
	cast_start_time = 0.3,
	cast_shot_time = 0.2,
	cast_animation = 'spell one',
	-- 判定半径
	hit_area = 150,
	-- 飞行速度
	speed = 1500,
	-- 位移距离
	move_distance = 400,
	-- 位移速度
	move_speed = 1500,
	-- 伤害
	damage_base = {60, 140},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
	-- 溅射范围
	splash_area = 600,
	-- 溅射角度
	splash_angle = 60,
	-- 溅射比例(%)
	splash_rate = 50,

	-- 子技能
	sub_move_rate = function()
		return ac.skill['雷霆奔袭'].data.move_rate
	end,
	sub_move_time = function()
		return ac.skill['雷霆奔袭'].data.move_time
	end,
}

function mt:on_cast_shot()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local damage = self.damage_base + self.damage_plus
	local splash_area = self.splash_area
	local splash_angle = self.splash_angle
	local splash_damage = damage * self.splash_rate / 100
	hero:play_sound([[response\缇娜\skill\Q.mp3]])
	local mover = ac.mover.line
	{
		source = hero,
		model = [[model\tina\TN_Q_missile.mdl]],
		angle = angle,
		distance = self.range,
		speed = self.speed,
		skill = self,
		high = 50,
		hit_area = self.hit_area,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
	}

	if not mover then
		return
	end

	function mover:on_hit(target)
		target:damage
		{
			source = hero,
			damage = damage,
			skill = self.skill,
		}
		for _, u in ac.selector()
			: in_sector(self.mover, splash_area, angle, splash_angle)
			: is_enemy(hero)
			: is_not(target)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = splash_damage,
				skill = self.skill,
				aoe = true,
			}
		end
		local dummy = hero:create_dummy('e00I', self.mover, angle)
		dummy:set_size(1.8)
		dummy:set_high(100)
		dummy:kill()
		dummy:set_animation 'birth'
		return true
	end

	local mover = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = angle + 180,
		distance = self.move_distance,
		speed = self.move_speed,
		skill = self,
		block = true,
	}
end
