local math = math
local mt = ac.skill['不灭之焰']

mt{
	level = 0,
	art = [[BTNqle.blp]],
	title = '不灭之焰',
	tip = [[
|cff11ccff主动：|r
烈焰环绕自身，每秒对周围敌方单位造成%damage_base%(+%damage_plus%)伤害，持续%buff_time%秒。重复使用可以叠加。

|cff11ccff被动：|r
受到眩晕或时停后的%stun_time%秒内，受到伤害的%recover_rate%%会在%recover_time%秒内持续恢复。
这个效果每%recover_cool%秒只能触发一次。
	]],
	cool = 3,
	cost = 40,
	instant = 1,
	area = 250,
	damage_base = {12, 40},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	buff_time = 10,
	stun_time = 1,
	recover_time = 3,
	recover_rate = 50,
	recover_cool = {18, 10},
	proc = 0.01,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '不灭之焰-燃烧'
	{
		time = self.buff_time,
		damage = self.damage,
		area = self.area,
		skill = self,
	}
end

function mt:on_add()
	local hero = self.owner
	hero:add_buff '不灭之焰-就绪'
	{
		skill = self,
	}
end

function mt:on_remove()
	local hero = self.owner
	hero:remove_buff '不灭之焰-燃烧'
	hero:remove_buff '不灭之焰-就绪'
	hero:remove_buff '不灭之焰-记录'
	hero:remove_buff '不灭之焰-治疗'
end

local mt = ac.dot_buff['不灭之焰-燃烧']

mt.buff = true

function mt:on_add()
	self.eff = self.target:add_effect('origin', [[war3mapimported\flame aura.mdl]])
end

function mt:on_remove()
	self.eff:remove()
end

function mt:on_pulse(damage)
	local hero = self.target
	local skill = self.skill
	local damage = damage * self.pulse
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = damage,
			aoe = true,
			skill = skill,
		}
	end
end

local mt = ac.buff['不灭之焰-就绪']

mt.keep = true

function mt:on_add()
	local hero = self.target
	local function f()
		self:remove()
		hero:add_buff('不灭之焰-就绪', self.recover_cool)
		{
			skill = self.skill,
		}
		hero:add_buff '不灭之焰-记录'
		{
			skill = self.skill,
			time = self.skill.stun_time,
		}
	end
	self.trg1 = hero:event '单位-获得状态' (function(_, _, buff)
		if buff.name == '晕眩' then
			f()
		end
	end)
	self.trg2 = hero:event '单位-时停开始' (f)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
end

function mt:on_cover()
	return true
end

local mt = ac.buff['不灭之焰-记录']

function mt:on_add()
	local hero = self.target
	self.blend = self.skill:add_blend('2', 'frame', 2)
	self.trg = hero:event '受到伤害效果' (function(_, damage)
		hero:add_buff '不灭之焰-治疗'
		{
			time = self.skill.recover_time,
			recover = damage:get_current_damage() * self.skill.recover_rate / 100,
			skill = self.skill,
		}
	end)
end

function mt:on_remove()
	self.blend:remove()
	self.trg:remove()
end

function mt:on_cover(new)
	if self:get_remaining() < new.time then
		self:set_remaining(new.time)
	end
	return false
end

local mt = ac.buff['不灭之焰-治疗']

mt.pulse = 0.5
mt.recover = 0

function mt:on_pulse()
	local hero = self.target
	local heal = self.recover / math.floor(self:get_remaining() / self.pulse + 1)
	hero:heal
	{
		heal = heal,
		skill = self.skill,
	}
	self.recover = self.recover - heal
end

function mt:on_cover(new)
	self:set_remaining(new.time)
	self.recover = self.recover + new.recover
	return false
end
