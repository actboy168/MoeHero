local mt = ac.skill['绝对切断']
{
	--初始等级
	level = 0,
	--最大等级
	max_level = 3,
	--需要的英雄等级
	requirement = {6, 11, 16},
	--技能图标
	art = [[btnkrykr.blp]],
	--技能说明
	title = '绝对切断',
	tip = [[
下一次的|cff11ccff死亡穿刺|r与|cff11ccff死亡旋转|r黑雪姬会和假想体一起使用，且这次技能造成伤害时，被护甲抵消的伤害的%damage_rate%%会附加到下一次普通攻击中，持续%time%秒。
	]],

	--冷却
	cool = {60, 45, 30},
	damage_rate = {80, 100, 120},
	--耗蓝
	cost = 100,
	--瞬发
	instant = 1,
	--持续时间
	time = 10,
}

function mt:on_cast_finish()
	local hero = self.owner
	hero:add_buff '绝对切断'
	{
		skill = self,
		time = self.time,
		damage_rate = self.damage_rate,
	}
end


local mt = ac.buff['绝对切断']

mt.buff = true

function mt:on_add()
	local hero = self.target
	local skill = hero:find_skill '假想体'
	local damage_rate = self.damage_rate / 100
	self.skills = {}
	for _, name in ipairs{'死亡穿刺', '死亡旋转'} do
		local skill = hero:find_skill(name, nil, true)
		if skill then
			self.skills[name] = skill:add_blend('2', 'frame', 2)
		end
	end
	self.eff = hero:add_effect('origin', [[modeldekan\ability\DEKAN_Inori_W_Effect.mdl]])
	self.trg1 = hero:event '技能-施法开始' (function(_, _, skill)
		local name = skill.title or skill.name
		if not self.skills[name] then
			return
		end
		self.skills[name]:remove()
		self.skills[name] = nil
		skill[self.name] = true
		if not next(self.skills) then
			self:remove()
		end
	end)
	self.trg2 = hero:event '造成伤害效果' (function(_, damage)
		local skill = damage.skill
		if not skill or not skill[self.name] then
			return
		end
		
		local target = damage.target
		if target:is_type('建筑') then
			return
		end
		--检查是否计算护甲
		if damage.ignore_defence then
			return
		end
		
		local def = damage['护甲']
		if def > 0 then
			def = def * (1 - damage['穿透'] / 100)
		end
		def = def - damage['破甲']
		if def > 0 then
			--每点护甲相当于生命值增加 X%
			local damage = damage.DEF_SUB * def * damage.damage
			hero:add_buff '绝对切断-法球'
			{
				skill = self.skill,
				damage = damage * damage_rate,
				time = self.time,
			}
		end
	end)
	self.skill:show_buff(self)
	self.skill:set_option('show_cd', 0)
end

function mt:on_remove()
	local hero = self.target
	local skills = self.skills
	for skill in hero:each_skill() do
		local name = skill.title or skill.name
		if skills[name] then
			skills[name]:remove()
		end
	end
	self.eff:remove()
	self.trg1:remove()
	self.trg2:remove()
	self.skill:set_option('show_cd', 1)
end


local mt = ac.orb_buff['绝对切断-法球']

mt.orb_count = 1

function mt:on_cast(damage)
	if not damage.common_attack then
		return true
	end
end

function mt:on_hit(damage)
	local hero = self.target
	local target = damage.target
	target:damage
	{
		source = hero,
		skill = self.skill,
		damage = self.damage,
	}
	target:add_effect('origin', [[Abilities\Spells\Undead\DeathCoil\DeathCoilSpecialArt.mdl]]):remove()
end

function mt:on_add()
	local hero = self.target
	local skill = hero:find_skill '假想体'
	if not skill then
		return
	end
	local dummy = skill.dummy
	if not dummy then
		return
	end
	skill.buff = self
	self.eff1 = dummy:add_effect('hand left', [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]])
	self.eff2 = dummy:add_effect('hand right', [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]])
end

function mt:on_remove()
	local hero = self.target
	if self.eff1 then
		self.eff1:remove()
	end
	if self.eff2 then
		self.eff2:remove()
	end
end

function mt:on_cover(new)
	self.damage = self.damage + new.damage
	self:set_remaining(new.time)
	return false
end

function mt:dummy(dummy)
	if self.removed then
		return
	end
	if self.eff1 then
		self.eff1:remove()
	end
	if self.eff2 then
		self.eff2:remove()
	end
	self.eff1 = dummy:add_effect('hand left', [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]])
	self.eff2 = dummy:add_effect('hand right', [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]])
end
