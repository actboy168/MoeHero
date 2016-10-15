local mt = ac.skill['冥界之书']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNdantalianE.blp]],
	title = '冥界之书',
	tip = [[
吟唱中以及停止吟唱后%ex_time%秒内，你受到的伤害减少%damage_rate%%，免疫负面状态。吟唱最多持续%cast_channel_time%秒。

如果吟唱超过%channel_time%秒，你的下一个幻书技能不需要吟唱。

在吟唱其他幻书时，你可以激活|cff00ccff冥界之书|r，但不会获得吟唱%channel_time%秒后的特效。
	]],
	cool = {14, 6},
	cost = 40 * 2,
	-- 每秒扣蓝
	cost_channel = 40,
	-- 瞬发
	instant = 1,
	-- 吟唱时间
	cast_channel_time = {6, 10},
	break_cast_channel = 1,
	-- 额外延迟时间
	ex_time = 2,
	-- 伤害减免
	damage_rate = {55, 75},
	-- 获得buff需要的吟唱时间
	channel_time = 2,
}

function mt:on_can_cast()
	local hero = self.owner
	for _, skill in hero:each_cast() do
		if skill:get_type() ~= '英雄' then
			return false
		end
	end
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
	self.clock = hero:clock()
	self.buff = hero:add_buff '冥界之书-护盾'
	{
		skill = self,
		damage_rate = self.damage_rate,
	}

	for _, skill in hero:each_cast() do
		if skill:get_type() == '英雄' and skill ~= self then
			hero:event '技能-施法停止' (function(trg, _, dest)
				trg:remove()
				if dest == skill then
					self.buff:set_remaining(self.ex_time)
					self:stop()
				end
			end)
			return
		end
	end

	self.timer = hero:wait(self.channel_time * 1000, function()
		hero:add_buff '冥界之书'
		{
			skill = self,
		}
	end)
	self.effect = hero:add_effect('origin', [[model\dantalian\channel_yellow.mdl]])
end

function mt:on_cast_stop()
	local hero = self.owner

	if self.timer then
		self.effect:remove()
		self.timer:remove()
		if self.buff then
			self.buff:set_remaining(self.ex_time)
		end
	end
end


local mt = ac.buff['冥界之书-护盾']

function mt:on_add()
	local hero = self.target
	local damage_rate = self.damage_rate / 100
	self.eff = hero:add_effect('origin', [[chaosrunicaura.mdl]])
	self.trg1 = hero:event '受到伤害' (function(_, damage)
		damage:div(damage_rate)
	end)
	self.trg2 = hero:event '单位-即将获得状态' (function(_, _, buff)
		if buff.debuff then
			return true
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	self.eff:remove()
	self.trg1:remove()
	self.trg2:remove()
end


local mt = ac.buff['冥界之书']

function mt:on_add()
	local hero = self.target
	self.eff = hero:add_effect('origin', [[model\dantalian\speicl_yellow.mdx]])
	self.trg = hero:event '技能-施法引导' (function(_, _, skill)
		if skill:get_type() == '英雄' and not skill._has_cast_finish then
			local buff = hero:find_buff '明日之诗'
			if buff and buff.mark[skill.name] then
				return
			end
			self:remove()
			skill:finish()
		end
	end)
end

function mt:on_remove()
	local hero = self.target
	self.eff:remove()
	self.trg:remove()
end
