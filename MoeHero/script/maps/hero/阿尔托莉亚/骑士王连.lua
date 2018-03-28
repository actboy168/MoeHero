local math = math

local mt = ac.skill['骑士王连斩']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNsaberw.blp]],

	--技能说明
	title = '骑士王连斩',
	
	tip = [[
向指定方向冲锋,造成%damage%(+%damage_plus%)点伤害并击退

|cffffff11可以储存%charge_max_stack%次|r
	]],

	break_order = 1,

	--冷却
	cool = 0.3,
	charge_cool = 10,

	--消耗
	cost = 75,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--施法距离
	range = 9999,

	--冲锋距离
	distance = {400, 500},

	cast_start_time = 0.2,
	cast_channel_time = 10,

	cast_animation = 6,

	cast_animation_speed = 1.5,

	--冲锋速度
	speed = 1000,

	--击退速度
	beat_speed = 500,

	--判定宽度
	hit_area = 150,

	--伤害
	damage = {65, 225},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,

	--储存次数
	cooldown_mode = 1,
	charge_max_stack = 2,

	--触发系数
	proc = 0.5,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local damage = self.damage + self.damage_plus
	local beat_speed = self.beat_speed
	local angle = hero:get_point() / target:get_point()
	local distance = math.min(self.distance, hero:get_point() * target:get_point())
	local skill = self
	local proc = self.proc

	local target_point = hero:get_point() - {angle, distance}


	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = angle,
		distance = distance,
		hit_area = self.hit_area,
		speed = math.max(distance/(0.188), 1),
		skill = self,
	}

	if not mvr then
		self:stop()
		return
	end

	function mvr:on_hit(dest)
		local distance = dest:get_point() * target_point
		dest:add_buff '击退'
		{
			source = hero,
			angle = angle,
			speed = beat_speed,
			distance = distance,
			high = distance * 0.5,
		}
		
		dest:damage
		{
			source = hero,
			damage = damage,
			skill = skill,
			aoe = true,
			attack = true,
		}

		ac.effect(dest, [[modeldekan\ability\DEKAN_Saber_W_Flash.mdx]], math.random(0, 360), 0.3):remove()
		ac.effect(dest, [[modeldekan\ability\DEKAN_Saber_W_Flash.mdx]], math.random(0, 360), 0.3):remove()
	end

	function mvr:on_remove()
		skill:finish()
		hero:issue_order('attack',hero:get_point())
		--hero:set_animation_speed(1)
	end
end
