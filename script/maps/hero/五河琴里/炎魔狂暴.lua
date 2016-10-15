local mt = ac.skill['炎魔狂暴']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[BTNqlr.blp]],
	title = '炎魔狂暴',
	tip = [[
|cff11ccff被动：|r
攻击可额外造成%damage_base%(+%damage_plus%)伤害并在%area%范围内溅射%aoe_rate%%。
这个效果每%orb_cool%秒可触发一次。

|cff11ccff主动：|r
怒气快速减少,造成的伤害提高%damage_rate%%。|cff11ccff不灭之焰|r的被动效果一直生效。
可使用|cff11ccff灼烂歼鬼·炮|r

|cff11ccff灼烂歼鬼·炮|r
将灼烂歼鬼从斧变形为炮,对一条直线造成伤害。
	]],
	cool = 75,
	damage_base = { 40, 60, 80 },
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	area = 300,
	aoe_rate = 50,
	orb_cool = {3.5, 2.5},
	mana_lose = 12.5,
	damage_rate = {20, 30},
	proc = 0.1,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '炎魔狂暴'
	{
		skill = self,
		damage_rate = self.damage_rate,
	}
end

function mt:on_add()
	self:on_cooldown()
end

function mt:on_remove()
	local hero = self.owner
	hero:remove_buff '炎魔狂暴-法球'
	hero:remove_buff '炎魔狂暴'
end

function mt:on_cooldown()
	local hero = self.owner
	hero:add_buff '炎魔狂暴-法球'
	{
		skill = self,
	}
end

local mt = ac.buff['炎魔狂暴']

mt.pulse = 0.5

function mt:on_add()
	local hero = self.target
	self.count = 0
	hero:get_point():add_effect([[firenova2.mdl]]):remove()
	hero:addDamageRate(self.damage_rate)
	local skl = hero:find_skill '不灭之焰'
	if skl then
		self.e_buff_timer = hero:loop(100, function ()
			hero:add_buff '不灭之焰-记录'
			{
				time = 0.2,
				skill = skl,
			}
		end)
		self.e_buff_timer:on_timer()
	end
	hero:replace_skill('炎魔狂暴', '灼烂歼鬼·炮')
end

function mt:on_remove()
	local hero = self.target
	hero:addDamageRate(-self.damage_rate)
	if self.e_buff_timer then
		self.e_buff_timer:remove()
	end
	hero:replace_skill('灼烂歼鬼·炮', '炎魔狂暴')
end

function mt:on_pulse()
	local hero = self.target
	hero:add_resource('怒气', - self.skill.mana_lose * self.pulse - self.count)
	self.count = self.count + 1
	if hero:get_resource '怒气' < 0.01 then
		self:remove()
	end
end

function mt:on_cover()
	return true
end

local mt = ac.orb_buff['炎魔狂暴-法球']

mt.keep = true
mt.orb_count = 1
mt.model = [[war3mapImported\magicreceive_red.mdx]]
mt.ref = 'weapon'

function mt:on_hit(damage)
	local hero = self.target
	local skill = self.skill
	local dmg = skill.damage
	damage.target:damage
	{
		source = hero,
		damage = dmg,
		attack = true,
		skill = skill,
	}
	dmg = dmg * skill.aoe_rate / 100
	for _, u in ac.selector()
		: in_range(damage.target, skill.area)
		: is_enemy(hero)
		: is_not(damage.target)
		: ipairs()
	do
		u:damage
		{
			source = hero,
			damage = dmg,
			attack = true,
			aoe = true,
			skill = skill,
		}
	end
	damage.target:get_point():add_effect([[slam.mdl]]):remove()
end

function mt:on_remove()
	local hero = self.target
	hero:add_buff ('炎魔狂暴-法球', self.skill.orb_cool)
	{
		skill = self.skill
	}
end

function mt:on_cover()
	return true
end

local mt = ac.skill['灼烂歼鬼·炮']

mt{
	level = 0,
	max_level = 3,
	art = [[BTNqlr2.blp]],
	title = '灼烂歼鬼·炮',
	tip = [[
对前方直线区域的敌方单位造成%damage_base%(+%damage_plus%)伤害。
	]],
	range = 9999,
	cast_animation = 9,
	cast_animation_speed = 2.5,
	cast_start_time = 0.8,
	target_type = ac.skill.TARGET_TYPE_POINT,
	len = 2000,
	width = 300,
	damage_base = {250, 450, 650},
	damage_plus = function(self, hero)
		return hero:get_ad() * 4
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	proc = 0.1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local poi = hero:get_point()
	local angle = poi / self.target
	hero:replace_skill('灼烂歼鬼·炮', '炎魔狂暴')

	local eff = ac.effect(poi, [[exshexian.mdl]], angle, 0.3)
	eff.unit:set_high(100)
	eff:remove()

	hero:wait(200, function()
		hero:timer(100, 10, function()
			for _, u in ac.selector()
				: in_line(poi, angle, self.len, self.width)
				: is_enemy(hero)
				: ipairs()
			do
				u:damage
				{
					source = hero,
					damage = self.damage / 10,
					attack = true,
					aoe = true,
					skill = self,
				}
			end
		end)
	end)
end
