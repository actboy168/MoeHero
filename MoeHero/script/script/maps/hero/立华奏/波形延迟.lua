
local mt = ac.skill['波形延迟']

mt{
	level = 0,
	art = [[BTNzw.blp]],
	title = '波形延迟',
	tip = [[
向前突进%distance%距离，突进过程中格挡所有普通攻击，对命中的第一个敌人触发|cff11ccff音速穿刺|r的效果。
	]],
	cool = {17, 13},
	cost = 60,
	range = 9999,
	cast_channel_time = 10,
	cast_animation = 3,
	target_type = mt.TARGET_TYPE_POINT,
	distance = {400, 600},
	passive_distance = 350,
	speed = {800, 1200},
	hit_area = 150,
}

function mt:on_cast_channel()
	local hero = self.owner
	local p = hero:get_point()
	local distance = self.distance
	local face = p / self.target:get_point()
	local speed = self.speed
	
	hero:set_facing(face)

	self.trg = hero:event '受到伤害前效果' (function(_, damage)
		if damage:is_common_attack() then
			damage['格挡'] = damage['格挡'] + 100
			damage['格挡伤害'] = damage['格挡伤害'] + 100
		end
	end)
	
	hero:get_point():add_effect([[distorsionnewsfxbydeckai_nodeath.mdl]]):remove()
	
	local follower = {}
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = face,
		distance = distance,
		speed = speed,
		hit_area = self.hit_area,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
		skill = self,
		on_move_skip = 3,
	}
	if not mvr then
		self:stop()
		return
	end

	function mvr:on_move()
		local dummy = hero:create_dummy(nil, self.mover, self.angle)
		dummy:add_buff '淡化'
		{
			alpha = 50,
			time = 0.5,
		}
		dummy:add_restriction '硬直'
		dummy:add_restriction '缴械'
		dummy:set_class '马甲'
		dummy:get_point():add_effect([[distorsionnewsfxbydeckai_nodeath.mdl]]):remove()
		dummy:set_animation(3)
	end
	
	function mvr:on_hit(dest)
		local mover = hero:follow
		{
			source = hero,
			mover = dest,
			skill = self,
			angle = hero:get_point() / dest:get_point(),
			distance = hero:get_point() * dest:get_point(),
			block = true,
		}
		if not mover then
			return
		end
		table.insert(follower, mover)
		
	end

	function mvr:on_finish()
		if #follower > 0 and follower[1].mover then
			local dest = follower[1].mover
			local skl = hero:find_skill(1, '英雄')
			if skl then
				skl:cast(dest, { instant = 1, force_cast = 1 })
			end
			hero:set_facing(hero:get_point() / dest:get_point())
			hero:issue_order('attack', dest)
			dest:add_effect('origin', [[war3mapimported\blinknew2.mdl]]):remove()
		end
	end

	function mvr:on_remove()
		self.skill:finish()
		for _, mover in ipairs(follower) do
			mover:remove()
		end
		follower = nil
		hero:issue_order('attack',hero:get_point())
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	self.trg:remove()
	hero:set_animation_speed(1)
	hero:set_animation 'stand'
end
