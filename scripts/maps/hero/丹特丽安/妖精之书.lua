local mt = ac.skill['妖精之书']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNdantalianQ.blp]],
	title = '妖精之书',
	tip = [[
吟唱%cast_channel_time%秒后，瞬移到目标地点，对周围的敌人造成%damage_base%(+%damage_plus%)伤害，并定身%debuff_time%秒。

吟唱中再次使用该技能，可以立刻释放，但技能效果取决于吟唱的时间。

如果吟唱超过%channel_time%秒，你的下一个幻书技能可以在移动中吟唱。
	]],
	cool = {7, 3},
	-- 每秒扣蓝
	cost = 120,
	cost_channel = 40,
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 1000,
	-- 吟唱时间
	cast_channel_time = 3,
	break_cast_channel = 1,
	-- 定身时间
	debuff_time = 1,
	-- 影响范围
	area = 400,
	-- 伤害
	damage_base = {120, 240},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.2
	end,
	-- 获得buff需要的吟唱时间
	channel_time = 2,
}

function mt:on_can_cast()
	local hero = self.owner
	if hero:find_buff '妖精之书' then
		hero:remove_buff '妖精之书'
		self.break_move = 0
	else
		self.break_move = 1
	end
	return true
end

function mt:on_cast_start()
	self.cost = 0
end

function mt:on_cast_channel()
	local hero = self.owner
	hero:replace_skill('妖精之书', '妖精之书-发动')
	self.effect = hero:add_effect('origin', [[model\dantalian\channel_green.mdl]])
	self.clock = hero:clock()
	self.timer = hero:wait(self.channel_time * 1000, function()
		hero:add_buff '妖精之书'
		{
			skill = self,
		}
	end)
	local clock = hero:clock()
	local target_mark
	if hero:get_owner() == ac.player.self then
		target_mark = [[model\dantalian\target_mark.mdl]]
	else
		target_mark = ''
	end
	local mark = ac.effect(hero, target_mark, 0, self.area / 400)
	self.target_mark = mark
	self.target_mark_timer = hero:loop(20, function()
		local p = hero:get_point()
		local angle = p / self.target
		local distance = p * self.target / self.cast_channel_time * (hero:clock() - clock) / 1000
		mark.unit:setPoint(p - {angle, distance})
	end)
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:replace_skill('妖精之书-发动', '妖精之书')
	self.effect:remove()
	self.timer:remove()
	self.target_mark:remove()
	self.target_mark_timer:remove()
end

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target_mark.unit:get_point()
	local damage = self.damage_base + self.damage_plus
	local rate = (hero:clock() - self.clock) / 1000 / self.cast_channel_time
	if not self['妖精之书-发动'] then
		target = self.target
		rate = 1
	end
	damage = damage * rate
	hero:get_point():add_effect('blinkcaster.mdl'):remove()
	hero:blink(target, true, true)
	target:add_effect('firenova2_green.mdl'):remove()
	self.target_mark.unit:setPoint(target)
	for _, u in ac.selector()
		: in_range(target, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		u:add_buff '定身'
		{
			source = hero,
			skill = self,
			time = self.debuff_time,
			ref = 'overhead',
			model = [[Objects\Spawnmodels\NightElf\EntBirthTarget\EntBirthTarget.mdx]],
		}
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
		}
	end
end


local mt = ac.skill['妖精之书-发动']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNdantalianQ.blp]],
	title = '妖精之书',
	tip = [[
立即发动妖精之书
	]],
	instant = 1,
}

function mt:on_cast_finish()
	local hero = self.owner
	for _, skill in hero:each_cast '妖精之书' do
		skill['妖精之书-发动'] = true
		skill:finish()
	end
end


local mt = ac.buff['妖精之书']

function mt:on_add()
	local hero = self.target
	self.eff = hero:add_effect('origin', [[model\dantalian\speicl_green.mdx]])
end

function mt:on_remove()
	local hero = self.target
	self.eff:remove()
end
