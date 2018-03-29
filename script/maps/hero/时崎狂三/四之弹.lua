local mt = ac.skill['四之弹']

mt{
	--初始等级
	level = 0,
	--技能图标
	art = [[model\Kurumi\BTNKurumiE.blp]],

	--技能说明
	title = '四之弹',
	
	tip = [[
吞噬一个分身，回溯位置与生命，并对直线范围的敌人造成%damage_base%(+%damage_plus%)的伤害。
你的下一次|cffffff00旋风射击|r或|cffffff00七之弹|r进化为|cffff8811旋风射击[刻]|r或|cffff8811七之弹[刻]|r。
	]],
	cost = 30,
	cool = 0.2,
	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,
	--施法距离
	range = 1000,
	--施法动画
	cast_animation = 'attack',
	cast_animation_speed = 1.2,
	--施法前摇
	cast_start_time = 0.3,
	cast_finish_time = 0.5,
	--判定距离
	select = 400,
	--弹道速度
	speed = 2000,
	--碰撞半径
	hit_area = 150,
	--伤害
	damage_base = {80, 120},
	damage_plus = function(self, hero)
		return hero:get_ad() * 2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
}

function mt:on_can_order(target)
	local hero = self.owner
	local skill = hero:find_skill '八之弹'
	if not skill then
		return false
	end
	local u
	local select = self.select
	for _, dummy in ipairs(skill.dummys) do
		local dis = dummy:get_point() * target
		if dis < select then
			select = dis
			u = dummy
		end
	end
	if not u then
		return false, '必须以狂三的分身为目标'
	end
	return true
end

function mt:on_can_cast()
	local hero = self.owner
	local target = self.target
	local skill = hero:find_skill '八之弹'
	if not skill then
		return false
	end
	local u
	local select = self.select
	for _, dummy in ipairs(skill.dummys) do
		local dis = dummy:get_point() * target
		if dis < select then
			select = dis
			u = dummy
		end
	end
	if not u then
		return false, '必须以狂三的分身为目标'
	end
	self.dummy = u
	return true
end

function mt:on_cast_start()
	local hero = self.owner
	local target = self.dummy
	hero:set_facing(hero:get_point() / target:get_point())
end

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.dummy
	local skill = hero:find_skill '八之弹'
	if not skill then
		return false
	end
	target.remove_timer:pause()
end

function mt:on_cast_finish()
	local hero = self.owner
	local target = self.dummy
	local damage = self.damage

	self:disable()
	
	local mover = ac.mover.target
	{
		source = hero,
		start = hero:get_launch_point(),
		skill = self,
		target = target,
		target_high = 100,
		speed = self.speed,
		model = [[model\kurumi\ball.mdl]],
		size = 2,
		hit_area = self.hit_area,
	}

	if not mover then
		self:enable()
		if target:is_alive() then
			target.remove_timer:resume()
		end
	end

	function mover:on_hit(dest)
		dest:damage
		{
			source = hero,
			damage = damage,
			aoe = true,
			attack = true,
			skill = self.skill,
		}
	end

	function mover:on_remove()
		self.skill:enable()
		self.mover:remove()
		if target:is_alive() then
			target.remove_timer:resume()
		end
	end

	function mover:on_finish()
		if not hero:is_alive() or not target:is_alive() then
			return
		end
		hero:blink(target, true, true)
		hero:set('生命', hero:get '生命上限' * target:get '生命' / target:get '生命上限')
		if target:get_type_id() ~= hero:get_type_id() then
			hero:transform(target:get_type_id())
		end
		hero:add_buff '四之弹'
		{
			skill = self.skill
		}
		target:remove()
		local skill = hero:find_skill '八之弹'
		if skill then
			for i = 1, #skill.dummys do
				if target == skill.dummys[i] then
					table.remove(skill.dummys, i)
					break
				end
			end
		end
	end

	ac.wait(2000, function()
		mover:remove()
	end)
end

function mt:on_add()
	local hero = self.owner
	self.skills = {}
	for _, name in ipairs{'七之弹', '旋风射击'} do
		local skill = hero:find_skill(name, nil, true)
		if skill then
			table.insert(self.skills, skill)
		end
	end
end

local mt = ac.buff['四之弹']

function mt:on_add()
	local hero = self.target
	self.blends = {}
	for i, skill in ipairs(self.skill.skills) do
		self.blends[i] = skill:add_blend('1', 'frame', 1)
		skill.cost_stack = skill.cost_stack - 1
		skill:fresh()
	end
end

function mt:on_remove()
	local hero = self.target
	if self.buff then
		self.buff:remove()
	end
	for _, blend in ipairs(self.blends) do
		blend:remove()
	end
	for i, skill in ipairs(self.skill.skills) do
		skill.cost_stack = skill.cost_stack + 1
		skill:fresh()
	end
end

function mt:on_cover()
	local hero = self.target
	local power = hero:find_buff '食时之城-额外强化'
	if power then
		local buff = hero:add_buff '四之弹-时'
		{
			skill = self.skill,
			cent = power.cent,
			time = power:get_remaining()
		}
		power:remove()
		if buff then
			self.buff = buff
		end
	end
	return false
end


local mt = ac.buff['四之弹-时']

function mt:on_add()
	local hero = self.target
	self.blends = {}
	for i, skill in ipairs(self.skill.skills) do
		self.blends[i] = skill:add_blend('2', 'frame', 2)
		skill.cost_stack = skill.cost_stack - 1
		skill:fresh()
	end
end

function mt:on_remove()
	local hero = self.target
	for _, blend in ipairs(self.blends) do
		blend:remove()
	end
	for i, skill in ipairs(self.skill.skills) do
		skill.cost_stack = skill.cost_stack + 1
		skill:fresh()
	end
end

function mt:on_cover()
	return false
end
