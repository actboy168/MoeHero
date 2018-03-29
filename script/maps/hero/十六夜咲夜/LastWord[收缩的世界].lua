local mt = ac.skill['LastWord[收缩的世界]']

mt{
	level = 1,
	art = [[replaceabletextures\commandbuttons\BTNsakuyaR.blp]],
	title = 'LastWord[收缩的世界]',
	tip = [[
令时空收缩，连续射出大量的飞刀，每把飞刀造成%damage_base%(+%damage_plus%)伤害。
	]],
	target_type = ac.skill.TARGET_TYPE_NONE,
	area = 800,
	cast_channel_time = 3,
	speed = 800,
	damage_base = {40, 80},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	instant = 1,
	force_cast = 1,
}

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '单位-即将死亡' (function(trg, damage)
		local skl = hero:find_skill '[小夜的世界]'
		if not skl then
			return
		end
		if skl:get_stack() < 0 then
			return
		end
		hero:add_buff 'LastWord[收缩的世界]'
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

local create_knife = require 'maps.hero.十六夜咲夜.光速[光速跳跃]'

function mt:on_cast_channel()
	local hero = self.owner
	local speed = self.speed 
	local angle = -120
	hero:remove_buff 'LastWord[收缩的世界]'
	hero:set_facing(270)
	hero:set_animation 'morph'
	hero:add_restriction '无敌'
	self.timer1 = hero:loop(1000, function()
		angle = 120 + angle
		self.mvr = ac.mover.line
		{
			source = hero,
			mover = hero,
			target = hero:get_point() - {angle, 400},
			speed = 1000,
			skill = self,
		}
		if self.mvr then
			function self.mvr:on_move()
				local u = hero:create_dummy(nil, hero:get_point(), hero:get_facing())
				u:set_class '马甲'
				u:set_animation 'morph'
				u:add_buff '淡化*改'
				{
					source_alpha = 80,
					target_alpha = 0,
					time = 0.3,
				}
			end
		end

		self.timer3 = hero:wait(400, function()
			local n = 0
			local mark = {}
			local mvrs = {}
			self.timer2 = hero:timer(100, 6, function()
				n = n + 1
				if n == 1 then
					self.masterbuff = hero:add_buff 'LastWord[收缩的世界]-光环'
					{
						source = hero,
						time = 0.6,
						area = self.area,
						skill = self,
						selector = ac.selector()
							: in_range(hero:get_point(), self.area)
							: allow_god()
							,
					}
				end
				for i = 1, 12 do
					local start = hero:get_point() - { 30 * i, 100 } - { 30 * i + 40, n * 50 }
					local mvr = create_knife
					{
						source = hero,
						start = start,
						speed = speed,
						angle =  hero:get_point() / start + 30,
						distance = 2000,
						skill = self,
						damage = self.damage,
						mark = mark,
						has_q = {count = 2},
						has_e = true,
					}
					mvr:pause(true)
					table.insert(mvrs, mvr)
				end
				if n == 6 then
					self.masterbuff:remove()
					for _, mvr in ipairs(mvrs) do
						mvr:pause(false)
					end
				end
			end)
			self.timer2:on_timer()
		end)
	end)
	self.timer1:on_timer()
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:set_animation 'stand'
	hero:remove_restriction '无敌'
	self.masterbuff:remove()
	self.timer1:remove()
	self.timer2:remove()
	self.timer3:remove()
	self.mvr:remove()
end

local mt = ac.aura_buff['LastWord[收缩的世界]-光环']

mt.aura_pulse = 0.1
mt.child_buff = 'LastWord[收缩的世界]-时停'
mt.force = true

function mt:on_add()
	local hero = self.target
	self.block = hero:create_block { area = self.area }
	function self.block:on_entry(mover)
		mover:pause(true)
		if mover.source == hero and mover.mover:get_type_id() == 'e00E' then
			mover.mover:add_buff '淡化*改'
			{
				source_alpha = 100,
				target_alpha = 30,
				time = 0.4,
				remove_when_hit = false,
			}
		end
	end
end

function mt:on_remove()
	local hero = self.target
	for mover in pairs(self.block.movers) do
		mover:pause(false)
		if mover.source == self.target and mover.mover:get_type_id() == 'e00E' then
			mover.mover:remove_buff '淡化*改'
			mover.mover:setAlpha(100)
		end
	end
	self.block:remove()
end

local mt = ac.buff['LastWord[收缩的世界]-时停']

mt.cover_type = 1
mt.cover_max = 1
mt.force = true

function mt:on_add()
	if self.source == self.target then
		return
	end
	self.target:add_restriction '时停'
	self.target:add_restriction '无敌'
end

function mt:on_remove()
	if self.source == self.target then
		return
	end
	self.target:remove_restriction '无敌'
	self.target:remove_restriction '时停'
end

function mt:on_cover()
	return false
end


local mt = ac.buff['LastWord[收缩的世界]']

function mt:on_add()
	local hero = self.target
	hero:cast_stop()
	hero:set_animation 'spell throw'
	hero:wait(400, function()
		if hero:find_buff 'LastWord[收缩的世界]' then
			hero:set_animation_speed(0.01)
		end
	end)
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
	hero:replace_skill('[小夜的世界]', 'LastWord[收缩的世界]')
	self.filter = hero:get_owner():cinematic_filter
	{
		start = {100, 20, 20, 100},
		finish = {100, 20, 20, 0},
		time = 1,
	}
	hero:get_owner():setCameraTarget(hero)
	self.mvr = {}
	for i = 1, 4 do
		local mvr = hero:follow
		{
			source = hero,
			id = 'e00E',
			angle = i * 90,
			angle_speed = 400,
			distance = 120,
			skill = self.skill,
			face = 0,
		}
		if mvr then
			function mvr:on_remove()
				self.mover:remove()
			end
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
	local skl = hero:find_skill '[小夜的世界]'
	if skl then
		skl:add_stack(-2)
	end
end

function mt:on_remove()
	local hero = self.target
	hero:set_animation_speed(1)
	hero:set_animation 'stand'
	hero:remove_restriction '免死'
	hero:remove_restriction '硬直'
	for _, skill in ipairs(self.skills) do
		skill:enable()
	end
	hero:replace_skill('LastWord[收缩的世界]', '[小夜的世界]')
	self.filter:remove()
	hero:get_owner():setCamera()
	for _, mvr in ipairs(self.mvr) do
		mvr:remove()
	end
	if self.on_remove_success then
		self:on_remove_success()
	end
end
