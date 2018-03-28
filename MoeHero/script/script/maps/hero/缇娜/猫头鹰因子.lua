local mt = ac.skill['猫头鹰因子']

mt{
	-- 判定范围
	range = 150,
	-- 后退距离
	distance = 200,
}

-- 攻击方式
local range_list = {1, 2}
local melee_list = {5, 13}

function mt:on_add()
	local hero = self.owner
	local distance = self.distance
	self.trg = hero:event '单位-攻击开始' (function(_, damage)
		local target = damage.target
		if target:is_in_range(hero, self.range) then
			hero:set_animation(melee_list[math.random(#melee_list)])
			hero:setMelee(true)
			damage:event '法球命中' (function()
				hero:set_animation 'spell four'
				--hero:set_animation_speed(3)
				hero:add_animation 'stand'
				local mover = ac.mover.line
				{
					source = hero,
					mover = hero,
					angle = target:get_point() / hero:get_point(),
					distance = distance,
					speed = 500,
					accel = -500,
					min_speed = 100,
					skill = self,
					block = true,
				}

				if not mover then
					hero:set_animation_speed(1)
					return
				end
				
				function mover:on_finish()
					hero:add_resource('子弹', 1)
					hero:get_owner():play_sound [[response\缇娜\skill\E.mp3]]
				end

				function mover:on_remove()
					hero:set_animation_speed(1)
				end
			end)
		else
			hero:set_animation(range_list[math.random(#range_list)])
			hero:setMelee(false)
		end
		hero:add_animation 'stand'
	end)
end

function mt:on_remove()
	self.trg:remove()
end
