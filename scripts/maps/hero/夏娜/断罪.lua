local mt = ac.skill['断罪']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNxnr.blp]],

	--技能说明
	title = '断罪',
	
	tip = [[
发出多道火焰冲击，造成%damage%(+%damage_plus%)点伤害。
附加%debuff_stack%层|cff11ccff红莲太刀|r效果。
	]],

	cool = { 105, 90, 75 },
	cost = 200,
	target_type = ac.skill.TARGET_TYPE_POINT,

	--施法前摇
	cast_start_time = 0.3,

	--施法后摇
	cast_finish_time = 0.7,

	--伤害
	damage = {10, 30, 50},

	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,

	range = 1000,
	cast_animation = 4,

	debuff_stack = 1,

	distance = 1200,
	speed = 500,
	count = 5,
	area = 600,
	time = 3,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target:get_point()
	local angle = hero:get_point() / target
	local skill = self
	local damage = self.damage + self.damage_plus
	local stack = self.debuff_stack
	local dest_skill = hero:find_skill '飞焰'
	hero:timer(500, self.count, function ()
		local mark = {}
		for i = -2, 2 do
			local mvr = ac.mover.line
			{
				source = hero,
				model = [[redchongji_large.mdl]],
				angle = i * 30 + angle,
				distance = self.distance,
				speed = self.speed,
				skill = self,
				hit_area = 250,
				size = 0.4,
			}

			if mvr then
				function mvr:on_hit(target)
					if mark[target] then
						return
					end
					mark[target] = true

					if dest_skill then
						for i = 1, stack do
							dest_skill:castFire(target)
						end
					end
					target:add_effect([[Abilities\Spells\Other\Incinerate\IncinerateBuff.mdl]]):remove()
					target:damage
					{
						source = hero,
						damage = damage,
						skill = skill,
						aoe = true,
						attack = true,
					}
				end
			end
		end
	end)
end
