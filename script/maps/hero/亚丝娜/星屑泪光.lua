local mt = ac.skill['星屑泪光']

mt{
	level = 0,
	art = [[BTNasnq.blp]],
	title = '星屑泪光',
	tip = [[
对目标区域五连击，每击造成%damage%(+%damage_plus%)点伤害。
	]],
	cost = 70,
	cool = {16, 12},
	range = 800,
	distance = 800,
	cast_start_time = 0.2,
	cast_channel_time = 10,
	target_type = ac.skill.TARGET_TYPE_POINT,
	damage = {20, 60},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.6
	end,
	break_order = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local distance = self.distance
	local damage = self.damage + self.damage_plus
	local angle = hero:get_point() / target:get_point() - 18
	local w_skill = hero:find_skill '狂暴补师'
	local count = 5
	hero:add_restriction '无敌'
	hero:add_restriction '阿卡林'
	local mark  = {}
	local function attack_one(from_loc, to_loc)
		local angle = from_loc / to_loc
		local dummy = hero:create_dummy(nil, from_loc, angle)
		dummy:set_class '幻象'
		dummy:add_restriction '缴械'
		dummy:set_animation('attack')
		dummy:set_animation_speed(5)
		dummy.eff = dummy:add_effect('chest',[[model\asuna\e_sprintribbon.mdl]])
		hero:wait(100, function()
			dummy:set_animation_speed(0.4)
		end)
		local mvr = ac.mover.line
		{
			source = hero,
			target = to_loc,
			mover = dummy,
			speed = 3000,
			accel = 18000,
			angle = angle,
			hit_area = 200,
			skill = self,
		}
		if not mvr then
			dummy:remove()
			self:finish()
		end
		function mvr:on_move()
			hero:setPoint(dummy:get_point())
		end
		function mvr:on_hit(u)
			if not mark[u] then
				mark[u] = 0
			end
			local rate = 1 - 0.08 * mark[u]
			mark[u] = mark[u] + 1
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self.skill,
				attack = true,
				aoe = true,
			}
			u:add_effect('chest', [[model\asuna\r_hit.mdl]]):remove()
		end
		function mvr:on_remove()
			dummy.eff:remove()
			if w_skill then
				w_skill:on_hit()
			end
			count = count - 1
			if count <= 0 then
				dummy:remove()
				self.skill:finish()
				return
			end
			dummy:set_class '马甲'
			dummy:add_buff '淡化'
			{
				time = 0.4,
			}
			attack_one(to_loc, to_loc - {angle + 144, distance})
		end
	end
	attack_one(hero:get_point(), hero:get_point() - {angle, distance})
end

function mt:on_cast_shot()
	local hero = self.owner
	local angle = hero:get_point() / self.target:get_point() - 18
	local distance = self.distance
	local from_loc = hero:get_point()
	for i = 1, 5 do
		local to_loc = from_loc - {angle, distance}
		local loc = ac.point((from_loc[1] + to_loc[1]) / 2, (from_loc[2] + to_loc[2]) / 2)
		local fog = hero:get_owner():createFogmodifier(loc, 300)
		ac.wait(500, function()
			fog:remove()
		end)
		ac.effect(loc, [[model\asuna\q_effect.mdl]], angle):remove()
		angle = angle + 144
		from_loc = to_loc
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:remove_restriction '阿卡林'
	hero:remove_restriction '无敌'
end
