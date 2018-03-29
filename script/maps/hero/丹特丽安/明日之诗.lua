local mt = ac.skill['明日之诗']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[replaceabletextures\commandbuttons\BTNdantalianR.blp]],
	title = '明日之诗',
	tip = [[
|cff00ccff主动|r:
吟唱%cast_channel_time%秒后，对周围的敌人造成%damage_base%(+%damage_plus%)伤害，并获得|cff00ccff明日之诗|r的效果。

|cff00ccff被动|r:
受到致命伤害时，无敌并硬直%god_time%秒。之后恢复%recover_rate%%的生命，并获得|cff00ccff明日之诗|r的效果。

|cff00ccff明日之诗|r:
你的所有幻书技能不需要吟唱，获得吟唱2秒后的特效。这个效果同一本幻书只能生效一次，持续%buff_time%秒。
	]],
	cool = {120, 80},
	cost = 80 * 3,
	-- 每秒扣蓝
	cost_channel = 80,
	-- 吟唱时间
	cast_channel_time = 3,
	-- 伤害
	damage_base = {200, 400},
	damage_plus = function(self, hero)
		return hero:get_ad() * 4.0
	end,
	-- 伤害范围
	area = 600,
	-- 无敌时间
	god_time = 1,
	-- 恢复生命
	recover_rate = {25, 35},
	-- buff持续时间
	buff_time = 10,
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
	self.effect = hero:add_effect('origin', [[model\dantalian\channel_red.mdl]])
	self.trigger = hero:event '单位-发布指令' (function(_, _, order)
		if order == 'stop' then
			self:stop()
		end
	end)
	local target_mark
	if hero:get_owner() == ac.player.self then
		target_mark = [[model\dantalian\target_mark.mdl]]
	else
		target_mark = ''
	end
	local mover = hero:follow
	{
		source = hero,
		model = target_mark,
		size = self.area / 400,
		skill = self,
		high = 50,
	}
	self.target_mark = mover
end

function mt:on_cast_stop()
	local hero = self.owner
	self.effect:remove()
	self.trigger:remove()
	if self.target_mark then
		self.target_mark:remove()
	end
end

function mt:on_cast_finish()
	local hero = self.owner
	local damage = self.damage_base + self.damage_plus
	hero:get_point():add_effect [[model\dantalian\foly_fire_slam.mdl]] :remove()
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
		}
	end
	hero:add_buff '明日之诗'
	{
		skill = self,
		time = self.buff_time,
	}
end

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '单位-即将死亡' (function()
		if not self:is_cooling() then
			local self = self:create_cast()
			self:active_cd()
			hero:add_effect('origin', [[batdietbattuyet.mdl]]):remove()
			hero:add_restriction '无敌'
			hero:add_restriction '硬直'
			hero:wait(self.god_time * 1000, function()
				hero:remove_restriction '无敌'
				hero:remove_restriction '硬直'
				hero:add('生命', hero:get '生命上限' * self.recover_rate / 100)
				hero:add_buff '明日之诗'
				{
					skill = self,
					time = self.buff_time,
				}
			end)
			return true
		end
	end)
end

function mt:on_remove()
	local hero = self.owner
	self.trg:remove()
end


local mt = ac.buff['明日之诗']

function mt:on_add()
	local hero = self.target
	self.eff = hero:add_effect('origin', [[model\dantalian\speicl_red.mdx]])
	self.mark = {}
	for _, name in ipairs {'妖精之书', '雷神之书', '冥界之书'} do
		local skill = hero:find_skill(name, '英雄', true)
		self.mark[name] = skill:add_blend('2', 'frame', 2)
	end
	self.trg = hero:event '技能-施法引导' (function(_, _, skill)
		if skill:get_type() == '英雄' and self.mark[skill.name] then
			self.mark[skill.name]:remove()
			self.mark[skill.name] = nil
			if not next(self.mark) then
				self:remove()
			end
			if skill.timer then
				skill.timer:on_timer()
			end
			skill:finish()
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	self.trg:remove()
	self.eff:remove()
	for _, blend in pairs(self.mark) do
		blend:remove()
	end
end
