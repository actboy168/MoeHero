local math = math

local mt = ac.skill['超电磁炮']

mt{
	--初始等级
	level = 0,
	
	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNpjr.blp]],

	--技能说明
	title = '超电磁炮',
	
	tip = [[
向指定方向射出一枚硬币，对命中的第一个单位造成%damage_base%(+%damage_plus%)伤害并击飞，其他单位受到%damage_rate%%伤害。
	]],

	--不恢复指令
	break_order = 1,

	--施法时间
	cast_start_time = 1,
	cast_animation = 'spell one',
	cast_animation_speed = 1.433,

	--施法距离
	range = 1200,

	--冷却
	cool = {60, 50},

	--耗蓝
	cost = {160, 200, 240},

	--目标类型
	target_type = mt.TARGET_TYPE_POINT,

	--射程
	distance = 1250,

	--半径
	hit_area = 200,

	--伤害
	damage_base = {250, 500},
	damage_plus = function(self, hero)
		return hero:get_ad() * 3.75
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,

	--击飞距离
	beat_distance = 300,

	--击退时间
	beat_time = 0.5,

	--击退高度
	beat_high = 200,

	--较小伤害(%)
	damage_rate = {70, 80},
}

--
mt.trg = nil
mt.bff1 = nil
mt.bff2 = nil	

function mt:on_cast_finish()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	ac.effect(hero:get_point(),[[modeldekan\ability\Dekan_MisakaMikoto_R_Missile_start.mdl]], angle):remove()
	hero:get_owner():play_sound [[response\御坂美琴\skill\R.mp3]]
	local mvr = ac.mover.line
	{
		source = hero,
		model = [[modeldekan\ability\Dekan_MisakaMikoto_R_Missile_rotation.mdl]],
		distance = self.distance,
		speed = 5000,
		angle = angle,
		skill = self,
		hit_area = self.hit_area,
		size = 2,
	}
	if not mvr then
		return
	end
	function mvr:on_move()
		ac.effect(self.mover:get_point(),[[modeldekan\ability\Dekan_MisakaMikoto_R_Missile_dust.mdl]], self.angle):remove()
	end
	local first = true
	function mvr:on_hit(dest)
		local skill = self.skill
		local damage = self.skill.damage
		if first then
			dest:add_buff '击退'
			{
				time = skill.beat_time,
				source = hero,
				distance = skill.beat_distance,
				angle = angle,
				skill = skill,
				high = skill.beat_high,
			}
		else
			damage = damage * skill.damage_rate / 100
		end

		dest:damage
		{
			damage = damage,
			source = hero,
			skill = skill,
			aoe = true,
			attack= true,
			missile = self.mover,
		}
		first = false
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	if self.bff1 then
		self.bff1:remove()
	end
	if self.bff2 then
		self.bff2:remove()
	end
end
