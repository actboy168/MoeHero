local mt = ac.skill['真红']

mt{
	level = 0,
	art = [[BTNxnq.blp]],
	title = '真红',
	tip = [[
横扫前方%area%距离内敌方单位，造成%damage_base%(+%damage_plus%)点伤害并束缚%time%秒。
附加%debuff_stack%层|cff11ccff红莲太刀|r效果。
	]],
	cost = {120, 80},
	cool = 11,
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 99999,
	cast_animation = 4,
	cast_animation_speed = 1.3,
	cast_start_time = 0.4,
	cast_finish_time = 0.3,
	damage_base = {100, 200},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	time = {1, 2.2},
	angle = 180,
	area = 350,
	debuff_stack = 2,
}

function mt:on_cast_start()
	local hero = self.owner
	self.dummy = hero:create_dummy('e006', hero:get_point(), hero:get_facing())
	self.dummy:set_animation_speed(2)
	self.dummy:wait(2000, function()
		self.dummy:kill()
	end)
	local mvr = hero:follow
	{
		source = hero,
		mover = self.dummy,
		skill = self,
		face_follow = true,
	}
end

function mt:on_cast_break()
	self.dummy:remove()
end

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target:get_point()
	local skl = hero:find_skill '飞焰'
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		if ac.math_angle(angle, hero:get_point() / u:get_point()) <= self.angle / 2 then
			if skl then
				for i = 1, self.debuff_stack do
					skl:castFire(u)
				end
			end
			u:add_buff '束缚'
			{
				source = hero,
				time = self.time,
				model = [[war3mapImported\Burning_Cage_1.mdx]],
			}
			u:damage
			{
				source = hero,
				damage = self.damage,
				skill = self,
				aoe = true,
				attack = true,
			}
		end
	end
end
