




--物品名称
local mt = ac.skill['灵象异动']

--图标
mt.art = [[BTNspeed4.blp]]

--说明
mt.tip = [[
技能引导时，你的造成的伤害每0.1秒提高%damage_rate%%，最高%max_damage_rate%%。
引导结束后，这个效果可以保持%time%秒。
]]

--物品类型
mt.item_type = '鞋子'

--附魔价格
mt.gold = 1600

--物品等级
mt.level = 4

--物品唯一
mt.unique = true

--属性
mt.damage_rate = 5
mt.max_damage_rate = 30
mt.time = 2

function mt:on_add()
	local hero = self.owner
	local skills = {}
	self.trg1 = hero:event '造成伤害' (function(trg, damage)
		damage:mul(self:get_stack() / 100)
	end)
	self.trg2 = hero:event '技能-施法引导' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		if skill.cast_channel_time < 0.1 then
			return
		end
		if skill._has_cast_stop then
			return
		end
		if self.timer then
			self.timer:remove()
		end
		hero:remove_buff '灵象异动'
		self.timer = hero:loop(math.floor(100 / self.damage_rate), function()
			hero:add_buff '灵象异动'
			{
				source = hero,
				skill = self,
				time = self.time,
				stack = 1,
			}
		end)
		skills[skill] = true
	end)
	self.trg3 = hero:event '技能-施法出手' (function(trg, _, skill)
		for _, skill in hero:each_cast() do
			if skills[skill] and skill.cast_channel_time >= 0.1 and not skill._has_cast_shot then
				skills[skill] = nil
				return
			end
		end
		if self.timer then
			self.timer:remove()
		end
	end)
	self.trg4 = hero:event '技能-施法停止' (function(trg, _, skill)
		for _, skill in hero:each_cast() do
			if skills[skill] and skill.cast_channel_time >= 0.1 and not skill._has_cast_stop then
				skills[skill] = nil
				return
			end
		end
		if self.timer then
			self.timer:remove()
		end
	end)
end

function mt:on_remove()
	local hero = self.owner
	if self.trg1 then
		self.trg1:remove()
	end
	if self.trg2 then
		self.trg2:remove()
	end
	if self.trg3 then
		self.trg3:remove()
	end
	if self.trg4 then
		self.trg4:remove()
	end
	if self.timer then
		self.timer:remove()
	end
end



local mt = ac.buff['灵象异动']

function mt:on_add()
	self.skill:add_stack(self.stack)
end

function mt:on_remove()
	self.skill:add_stack(-self.stack)
end

function mt:on_cover(new)
	self.stack = self.stack + new.stack
	if self.skill.max_damage_rate < self.stack then
		self.stack = self.skill.max_damage_rate
	end
	self.skill:set_stack(self.stack)
	self:set_remaining(new.time)
	return false
end
