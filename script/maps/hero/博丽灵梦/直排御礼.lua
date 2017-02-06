local mt = ac.skill['直排御礼']{
	--范围
	area = 350,

	--弹幕数量
	count = 5,

	--目标数量
	target_count = 5,

	--重复伤害
	damage_rate = 15,
		
	--弹道速度
	speed = 1200,

	--角度差
	angle = 17.5,

	--最大飞行距离
	distance = 900,

	--飞行距离
	distance = 800,

	--自由碰撞时的碰撞半径
	hit_area = 100,
}

mt.passive = true
mt.level = 1

local function cast_spell_q(hero, target, skill, damage, do_damage)
	local angle = hero:get_point() / target
	--然后发射5枚弹道
	for i = 1, skill.count do
		--计算角度
		local angle = angle + (skill.count / 2 - skill.count - 0.5 + i) * skill.angle
		--创建弹幕
		local mvr = ac.mover.line
		{
			source = hero,
			model = [[fu.mdl]],
			speed = skill.speed,
			angle = angle,
			distance = skill.distance,
			high = 110,
			skill = skill,
			damage = damage,
			hit_area = skill.hit_area,
		}
		if not mvr then
			return
		end
		function mvr:on_hit(dest)
			do_damage(dest, self.mover)
			return true
		end
		
	end
end

function mt:on_add()
	local function range_attack_start(hero, damage)
		if damage.skill and damage.skill.name == self.name then
			return
		end
		local target = damage.target:get_point()
		local damage = damage.damage
		local damage_rate = self.damage_rate / 100
		local unit_mark = {}
        local cast = self:create_cast()
		cast_spell_q(hero, target, self, damage, function (dest, missile)
			if not unit_mark[dest] then
				unit_mark[dest] = true
				dest:damage
				{
					source = hero,
					damage = damage,
					skill = cast,
					missile = missile,
					attack = true,
					common_attack = true,
				}
			else
				dest:damage
				{
					source = hero,
					damage = damage * damage_rate,
					skill = cast,
					missile = missile,
					attack = true,
				}
			end
		end)
	end
	local hero = self.owner
	self.oldfunc = hero.range_attack_start
	hero.range_attack_start = range_attack_start
end

function mt:on_remove()
	local hero = self.owner
	hero.range_attack_start = self.oldfunc
end
