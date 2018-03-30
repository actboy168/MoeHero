local mt = ac.skill['食时之城']

mt{
	--初始等级
	level = 0,
	--最大等级
	max_level = 3,
	--需要的英雄等级
	requirement = {6, 11, 16},
	--技能图标
	art = [[model\Kurumi\BTNKurumiR.blp]],

	--技能说明
	title = '食时之城',
	
	tip = [[
展开食时之城，每秒召唤一个分身，持续%time%秒。
食时之城内的敌方英雄减少%slow_rate%%的运动速度，非英雄陷入|cffffff00时停|r。
狂三可以通过|cffffff00四之弹|r将|cffff8811旋风射击[刻]|r或|cffff8811七之弹[刻]|r进化为|cffff1111旋风射击[时]|r或|cffff1111七之弹[时]|r，每次食时之城限一次。

|cffff1111旋风射击[时]|r:
阻止敌人离开食时之城。

|cffff1111七之弹[时]|r:
作用范围扩大到整个食时之城。
	]],
	cost = 200,
	cool = {90, 60},
	--影响范围
	area = 600,
	--持续时间
	time = {6, 8, 10},
	--影子出现间隔
	summon_time = 1,
	--减速(%)
	slow_rate = {60, 80},
}

function mt:on_cast_shot()
	local hero = self.owner

	hero:add_buff '食时之城'
	{
		skill = self,
		time = self.time,
		pulse = self.summon_time,
		cent = hero:get_point(),
		slow_rate = self.slow_rate,
	}

	hero:add_buff '食时之城-光环'
	{
		skill = self,
		time = self.time,
		selector = ac.selector()
			: in_range(hero:get_point(), self.area)
			: add_filter(function (u)
				return u:get_owner() ~= hero:get_owner()
			end)
			,
	}

	hero:add_buff '食时之城-额外强化'
	{
		skill = self,
		time = self.time,
		cent = hero:get_point(),
	}
end


local mt = ac.buff['食时之城']

function mt:on_add()
	local hero = self.target
	local slow_rate = self.slow_rate
	local n = math.floor(self.time) + 1
	self.angles = {}
	for i = 1, n do
		table.insert(self.angles, 360 / n * (i + math.random()/2))
	end
	for i = 1, n do
		local k = math.random(n)
		local tmp = self.angles[k]
		self.angles[k] = self.angles[i]
		self.angles[i] = tmp
	end
	self:on_pulse()
	self.eff1 = self.cent:effect
	{
		model = [[model\Kurumi\r_effect_block_1.mdx]], 
		angle = -90,
		size = 2,
	}
	self.eff2 = self.cent:effect
	{
		model = [[model\Kurumi\clockwisetimer.mdx]], 
		angle = -90,
		size = 5,
	}
	self.block = hero:create_block
	{
		area = self.skill.area,
		point = self.cent,
		hit_area = false,
	}
	function self.block:on_entry(mover)
		if mover.source == hero then
			return
		end
		if mover.source:is_hero() or mover.source:is_type('建筑') then
			mover.time_scale = mover.time_scale * (1 - slow_rate / 100)
		else
			mover:pause(true)
		end
	end
	function self.block:on_leave(mover)
		if mover.source == hero then
			return
		end
		if mover.source:is_hero() or mover.source:is_type('建筑') then
			mover.time_scale = mover.time_scale / (1 - slow_rate / 100)
			if not mover.missile then
				mover:remove()
			end
		else
			mover:pause(false)
		end
	end
	self.skill:show_buff(self)
	self.skill:set_option('show_cd', 0)
end

function mt:on_remove()
	self.eff1:kill()
	self.eff2:kill()
	if self.timer then
		self.timer:remove()
	end
	self.block:remove()
	self.skill:set_option('show_cd', 1)
end

function mt:power()
	local skill = self.skill
	local hero = self.target
	self.eff1:remove()
	self.eff1 = self.cent:effect
	{
		model = [[model\Kurumi\r_effect_block_2.mdx]],
		angle = -90,
		size = 2,
	}
	local g = {}
	local selector = ac.selector()
		: in_range(self.cent, skill.area + 100)
		: add_filter(function (u)
			return u:get_owner() ~= hero:get_owner()
		end)
	self.timer = ac.loop(100, function()
		for _, u in selector:ipairs() do
			if u:get_point() * self.cent > skill.area then
				if g[u] then
					u:blink(self.cent - {u:get_point() / self.cent, skill.area}, true, true)
				end
			else
				g[u] = true
			end
		end
	end)
end

function mt:on_pulse()
	local hero = self.target
	local skill = self.skill
	local angle = self.angles[#self.angles]
	self.angles[#self.angles] = nil
	hero:force_cast('八之弹', self.cent - {angle, skill.area - 300}, {call_back = function(_, dummy)
		dummy:set_animation 'spell channel two'
		dummy:add_animation 'stand'
		dummy:set_size(0)
		ac.wait(100, function()
			dummy:set_size(1)
		end)
		dummy:add_restriction '缴械'
		ac.wait(600, function()
			dummy:remove_restriction '缴械'
		end)
	end})
end


local mt = ac.aura_buff['食时之城-光环']

mt.cover_type = 1
mt.cover_max = 1

function mt:on_add()
	if self.source == self.target then
		return
	end
	local target = self.target
	if target:is_type('英雄') then	
		self.buff = target:add_buff '减速'
		{
			skill = self.skill,
			source = self.source,
			move_speed_rate = self.skill.slow_rate,
		}
	elseif not target:is_type('建筑') then
		target:add_restriction '时停'
	end
end

function mt:on_remove()
	if self.source == self.target then
		return
	end
	local target = self.target
	if target:is_type('英雄') then
		if self.buff then self.buff:remove() end
	elseif not target:is_type('建筑') then
		target:remove_restriction '时停'
	end
end


local mt = ac.buff['食时之城-额外强化']

function mt:on_add()
	self.blend = self.skill:add_blend('2', 'frame', 1)
end

function mt:on_remove()
	self.blend:remove()
end
