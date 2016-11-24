local mt = ac.skill['LastWord[掠日彗星]']

mt{
	level = 1,
	art = [[replaceabletextures\commandbuttons\BTNmarisaR.blp]],
	title = 'LastWord[掠日彗星]',
	tip = [[
魔理沙化身彗星，疯狂冲撞附近的敌人，每秒对后方直线区域造成%damage_base%(+%damage_plus%)伤害。
攻击中的魔理沙无敌。

|cffffff11需要引导|r
	]],

	target_type = ac.skill.TARGET_TYPE_NONE,
	cast_channel_time = 10,
	damage_base = {180, 240, 300},
	damage_plus = function(self, hero)
		return hero:get_ad() * 3.0
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	distance = 2400,
	hit_area = 150,
	speed = 1600,
	damage_distance = 900,
	damage_width = 300,
	instant = 1,
	force_cast = 1,
}

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '单位-即将死亡' (function(trg, damage)
		local skl = hero:find_skill '魔炮[究极火花]'
		if not skl then
			return
		end
		if skl:get_stack() < 0 then
			return
		end
		hero:add_buff 'LastWord[掠日彗星]'
		{
			skill = self,
			time = 1,
			damage = damage,
		}
		return true
	end)
end

function mt:on_remove()
	self.trg:remove()
end

function mt:on_cast_channel()
	local hero = self.owner
	local distance = self.distance
	hero:add_restriction '无敌'
	hero:add_restriction '阿卡林'
	hero:remove_buff 'LastWord[掠日彗星]'
	local count = 6
	local angle = 0
	local fogs = {}
	local function move_attack(from_loc, to_loc)
		table.insert(fogs, hero:get_owner():createFogmodifier(from_loc, 600))
		local angle = from_loc / to_loc
		local dummy1 = hero:create_dummy(nil, hero:get_point(), angle)
		dummy1:set_class '幻象'
		dummy1:add_restriction '缴械'
		dummy1:set('生命上限', hero:get '生命上限')
		dummy1:set('生命', hero:get '生命')
		dummy1:set_animation 'stand walk alternate'
		local dummy2 = hero:create_dummy('e00G', hero:get_point(), 180 + angle)
		dummy2:set_high(120)
		local mvr = ac.mover.line
		{
			source = hero,
			target = to_loc,
			mover = hero,
			speed = 2400,
			angle = angle,
			skill = self,
		}
		if not mvr then
			self:stop()
			dummy1:remove()
			dummy2:remove()
			return
		end
		function mvr:on_move()
			dummy1:setPoint(hero:get_point())
			dummy2:setPoint(hero:get_point())
			for _, u in ac.selector()
				: in_line(hero, 180 + angle, self.skill.damage_distance, self.skill.damage_width)
				: is_enemy(hero)
				: ipairs()
			do
				u:damage
				{
					source = hero,
					damage = self.skill.damage * 0.03,
					skill = self.skill,
					aoe = true,
					attack = true,
				}
			end
		end
		function mvr:on_remove()
			dummy1:remove()
			dummy2:remove()
			count = count - 1
			if count <= 0 then
				for _, fog in ipairs(fogs) do
					fog:remove()
				end
				self.skill:finish()
				return
			end
			if count == 1 then
				move_attack(to_loc, to_loc - {angle + 144, distance / 2})
			else
				move_attack(to_loc, to_loc - {angle + 144, distance})
			end
		end
	end
	move_attack(hero:get_point(), hero:get_point() - {angle, distance / 2})
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:remove_restriction '阿卡林'
	hero:remove_restriction '无敌'
end

local mt = ac.buff['LastWord[掠日彗星]']

local star = {
	[[marisastarm_1b.mdx]],
	[[marisastarm_1g.mdx]],
	[[marisastarm_1y.mdx]],
}

function mt:on_add()
	local hero = self.target
	hero:cast_stop()
	hero:set_animation 'stand walk alternate'
	hero:add_restriction '免死'
	hero:add_restriction '硬直'
	self.skills = {}
	for i = 1, 4 do
		local skl = hero:find_skill(i)
		if skl then
			skl:disable()
			table.insert(self.skills, skl)
		end
	end
	hero:replace_skill('魔炮[究极火花]', 'LastWord[掠日彗星]')
	self.filter = hero:get_owner():cinematic_filter
	{
		start = {100, 20, 20, 100},
		finish = {100, 20, 20, 0},
		time = 1,
	}
	hero:get_owner():setCameraTarget(hero)
	self.mvr = {}
	for i = 1, 3 do
		local mvr = hero:follow
		{
			source = hero,
			model = star[i],
			angle = i * 120,
			distance = 120,
			skill = self.skill,
			angle_speed = 400,
		}
		if mvr then
			table.insert(self.mvr, mvr)
		end
	end
end

function mt:on_finish()
	local hero = self.target
	self.on_remove_success = false
	self:on_remove()
	self.on_remove = false
	self.skill.trg:disable()
	hero:kill(self.damage.source)
	self.skill.trg:enable()
end

function mt:on_remove_success()
	local hero = self.target
	hero:set('生命', hero:get '生命上限' * 0.3)
	local skl = hero:find_skill '魔炮[究极火花]'
	if skl then
		skl:add_stack(-2)
	end
end

function mt:on_remove()
	local hero = self.target
	hero:remove_restriction '免死'
	hero:set_animation 'stand'
	hero:remove_restriction '硬直'
	for _, skill in ipairs(self.skills) do
		skill:enable()
	end
	hero:replace_skill('LastWord[掠日彗星]', '魔炮[究极火花]')
	self.filter:remove()
	hero:get_owner():setCamera()
	for _, mvr in ipairs(self.mvr) do
		mvr:remove()
	end
	if self.on_remove_success then
		self:on_remove_success()
	end
end
