


local mt = ac.skill['妖刀村雨']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[PASBTNcte.blp]],

	--技能说明
	title = '妖刀村雨',
	
	tip = [[
|cff11ccff被动：|r
赤瞳的攻击和技能可以提高自己的破防，持续%duration_zero%秒。
赤瞳的破防超过目标的50%护甲时，伤害附加咒毒，使目标%move_speed_rate%%移动速度并持续受到%damage%(+%damage_plus%)伤害，持续%duration%秒。
切换目标会使破防清零。
		]],

	--持续时间
	duration = 4,

	--降低移动速度%
	move_speed_rate = 50,

	--伤害
	damage = {40, 120},

	damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,

	--护甲穿透清零时间
	duration_zero = 5,

	--护甲穿透增加数值-攻击
	armor_pene_attack = {1, 5},

	--护甲穿透增加数值-施放技能
	armor_pene_skill = {2, 10},

	armor_pene_max = 80,
}

mt.passive = true

function mt:on_add()
	local hero = self.owner
	
	--造成伤害
	self.event1 = hero:event '造成伤害效果' (function(trg, damage)
		if not damage:is_attack() then
			return
		end
		local def = damage['护甲'] * (1 - damage['穿透'] / 100) - damage['破甲']
		if damage['穿透'] >= 50 or damage['护甲'] < 0 or damage['护甲'] >= damage['破甲'] / (damage['穿透']/100 - 0.5) then
			if damage.skill and damage.skill.name == '葬送' then
				damage.target:add_buff '沉默'
				{
					source = hero,
					time = self.duration * 0.5,
				}
			end
			damage.target:add_buff '妖刀村雨-咒毒'
			{
				source = hero,
				skill = self,
				time = self.duration,
				damage = self.damage + self.damage_plus,
			}
		end
	end)

	--攻击出手
	self.event2 = hero:event '单位-攻击出手' (function(trg, data)
		hero:add_buff '妖刀村雨-破防'
		{
			source = hero,
			skill = self,
			time = self.duration_zero,
			pene = self.armor_pene_attack,
			target = data.target,
		}
	end)

	--发动技能
	self.event3 = hero:event '技能-施法出手' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		local target
		if skill.target and skill.target.type == 'unit' then
			target = skill.target
		end
		hero:add_buff '妖刀村雨-破防'
		{
			source = hero,
			skill = self,
			time = self.duration_zero,
			pene = self.armor_pene_skill,
			target = target,
		}
	end)
end

function mt:on_remove()
	if self.event1 then self.event1:remove() end
	if self.event2 then self.event2:remove() end
	if self.event3 then self.event3:remove() end
end

local mt = ac.buff['妖刀村雨-破防']

function mt:on_cover(new)
	local hero = self.target
	if not self.target then
		self.target = new.target
	elseif new.target and new.target ~= self.target then
		hero:add('破甲', -self.pene)
		self.pene = 0
		self.target = new.target
	end
	local pene = math.min(self.skill.armor_pene_max, self.pene + new.pene)
	hero:add('破甲', pene - self.pene)
	self.pene = pene
	self:set_remaining(self.skill.duration_zero)
	return false
end

function mt:on_add()
	local hero = self.target
	hero:add('破甲', self.pene)
end

function mt:on_remove()
	local hero = self.target
	hero:add('破甲', -self.pene)
end

local mt = ac.buff['妖刀村雨-咒毒']

mt.debuff = true
mt.eff = nil
mt.pulse = 0.5

function mt:on_add()
	local hero = self.source
	local target = self.target
	self.damage = self.damage / (self.time / self.pulse)
	self.eff = target:add_effect('head', [[modeldekan\ability\dekan_Akame_E_buff.mdl]])
	target:add_buff '减速'
	{
		source = hero,
		time = self.time,
		move_speed_rate = self.skill.move_speed_rate,
	}
end

function mt:on_pulse()
	local hero = self.source
	local target = self.target
	target:damage
	{
		source = hero,
		skill = self.skill,
		damage = self.damage,
	}
end

function mt:on_cover(dest)
	return false
end

function mt:on_remove()
	local hero = self.source
	self.eff:remove()
end
