local mt = ac.skill['魔符[星屑幻想]']

mt{
	--范围
	area = 350,

	--重复伤害
	damage_rate = 15,
		
	--弹道速度
	speed = 1200,

	--最大飞行距离
	distance = 900,

	--飞行距离
	distance = 800,

	--自由碰撞时的碰撞半径
	hit_area = 100,
}

mt.passive = true
mt.level = 1

local star = {
	[[marisastarm_1b.mdx]],
	[[marisastarm_1g.mdx]],
	[[marisastarm_1y.mdx]],
}

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
		
		local angle = hero:get_point() / target
		local function cast_shot(model, detal)
			ac.mover.line
			{
				source = hero,
				model = model,
				speed = self.speed,
				angle = angle + detal,
				distance = self.distance,
				high = 60,
				skill = cast,
				damage = damage,
				hit_area = self.hit_area,
				on_hit = function (self, target)
					if not unit_mark[target] then
						unit_mark[target] = true
						target:damage
						{
							source = hero,
							damage = damage,
							skill = self.skill,
							missile = self,
							attack = true,
							common_attack = true,
						}
					else
						target:damage
						{
							source = hero,
							damage = damage * damage_rate,
							skill = self.skill,
							missile = self,
							attack = true,
						}
					end
					return true
				end,
			}
		end

		local r = math.random(1, 3)
		cast_shot(star[(r + 0) % 3 + 1], 0)
		hero:wait(100, function ()
			cast_shot(star[(r + 1) % 3 + 1], -20 + math.random(-20, 10))
			hero:wait(100, function ()
				cast_shot(star[(r + 2) % 3 + 1], 30 + math.random(-10, 20))
			end)
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
