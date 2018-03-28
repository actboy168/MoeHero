local mt = ac.skill['乱舞夜樱']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNYayaW.blp]],
	title = '乱舞夜樱',
	tip = [[
|cff11ccff被动|r：
夜夜受到伤害时，会将其中%damaged_rate%%的伤害储存起来。储存的伤害，每秒会流逝%reduce_per_second%%。

|cff11ccff主动|r：
释放最多%damage%(+%damage_plus%)点存储的伤害，对周围%area%范围的敌人造成伤害。

当前存量： %save_damage_show%
		]],
	cost = 50,
	cool = 14,
	instant = 1,
	target_type = ac.skill.TARGET_TYPE_NONE,
	damaged_rate = {18, 30},
	reduce_per_second = {6, 4},
	save_damage_show = function(self, hero)
		return ('%.2f'):format(self.save_damage or 0)
	end,
	damage = {60, 100},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,
	area = 400,
}

mt.save_damage = 0

function mt:on_can_cast()
	local hero = self.owner
	return self.save_damage > 0, '夜夜需要补充魔力'
end

function mt:on_cast_channel()
	local hero = self.owner
	local damage = math.min(self.damage + self.damage_plus, self.save_damage)
	if damage <= 0 then
		return
	end
	self:set('save_damage', self:get 'save_damage' - damage)
	hero:add_effect('origin', [[Abilities\Spells\Other\Doom\DoomDeath.mdl]]):remove()
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: of_hero()
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
			attack = true,
		}
	end
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: of_not_hero()
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
			attack = true,
		}
	end
end

function mt:on_add()
	local hero = self.owner
	self.skill_trg = hero:event '受到伤害' (function(_, damage)
		damage:div(self.damaged_rate / 100, function(damage)
			self.save_damage = self.save_damage + damage:get_current_damage() * self.damaged_rate / 100
		end)
	end)
	self.skill_timer = hero:loop(1000, function()
		if self.save_damage <= 0 then
			return
		end
		if not hero:is_alive() then
			return
		end
		local life = hero:get '生命'
		local reduce = math.min(life - 1, math.min(math.max(self.reduce_per_second / 100 * self.save_damage, 10), self.save_damage))
		hero:set('生命', hero:get '生命' - reduce)
		self.save_damage = self.save_damage - reduce
	end)
end

function mt:on_remove()
	self.skill_trg:remove()
	self.skill_timer:remove()
end
