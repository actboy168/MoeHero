local mt = ac.skill['狂暴补师']

mt{
	level = 0,
	art = [[PASBTNasnw.blp]],
	title = '狂暴补师',
	tip = [[
|cff11ccff被动：|r
每次挥剑随机治疗%area%范围内的一个友方英雄%heal_base%(+%heal_plus%)生命，并提高%attack_speed%%攻速，持续%time%秒。
	]],
	heal_base = {30, 60},
	heal_plus = function(self, hero)
		return hero:get_ad() * 0.6
	end,
	heal = function(self, hero)
		return self.heal_base + self.heal_plus
	end,
	attack_speed = {12, 20},
	time = 3,
	area = 300,
}

mt.passive = true

function mt:on_hit()
	self:update_data()

	local hero = self.owner
	local target = (ac.selector()
		: in_range(hero, self.area)
		: of_hero()
		: is_ally(hero)
		: random()
	) or hero
	target:heal
	{
		source = hero,
		skill = self,
		heal = self.heal
	}
	target:add_buff '狂暴补师'
	{
		source = hero,
		skill = self,
		time = self.time,
		attack_speed = self.attack_speed,
	}
end

local mt = ac.buff['狂暴补师']

function mt:on_add()
	local hero = self.target
	hero:add('攻击速度', self.attack_speed)
	self:set_stack(1)
	self.trg = hero:event '受到治疗开始' (function (_, heal)
		if not heal.skill or not heal.skill:is(self.skill) then
			return
		end
		heal.heal = heal.heal * (0.80 ^ self:get_stack(1))
	end)
end

function mt:on_remove()
	local hero = self.target
	hero:add('攻击速度', - self.attack_speed)
	self.trg:remove()
end

function mt:on_cover(new)
	local hero = self.target
	self:add_stack(1)
	self.attack_speed = self.attack_speed + new.attack_speed
	hero:add('攻击速度', new.attack_speed)
	self:set_remaining(new.time)
	return false
end
