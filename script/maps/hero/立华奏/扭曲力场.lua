local mt = ac.skill['扭曲力场']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNze.blp]],

	--技能说明
	title = '扭曲力场',
	
	tip = [[
抵挡超过%distance%距离的弹道或攻击，受到的范围伤害减免%aoe_reduce%%。
持续%time%秒，每次抵挡减少持续时间。
	]],

	--冷却
	cool = {40, 20},

	--耗蓝
	cost = {60, 20},

	--瞬发
	instant = 1,

	--距离
	distance = 250,

	--阻挡半径
	radius = 100,

	--范围伤害减免(%)
	aoe_reduce = 50,

	--Buff持续时间
	time = {6, 10},

	--抵挡普通攻击消耗的时间
	attack_cost = 1,

	--抵挡技能消耗的时间
	skill_cost = 4,

	--小兵攻击比例(%)
	army_rate = 25,
}

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		hero:add_effect('origin', [[energyshield_l.mdl]])
	end
end

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '扭曲力场'
	{
		time = self.time,
		radius = self.radius,
		distance = self.distance,
		attack_cost = self.attack_cost,
		skill_cost = self.skill_cost,
		aoe_reduce = self.aoe_reduce,
		army_rate = self.army_rate / 100,
		skill = self,
	}
end

local mt = ac.buff['扭曲力场']

function mt:on_add()
	local hero = self.target
	local distance = self.distance
	local radius = self.radius
	local bff = self
	local attack_cost = self.attack_cost
	local skill_cost = self.skill_cost
	local aoe_reduce = self.aoe_reduce / 100
	local army_rate = self.army_rate
	self.eff = hero:add_effect('origin', [[energyshield_l.mdl]])

	self.block = hero:create_block
	{
		area = radius,
	}
	self.block:follow_unit(hero)
	function self.block:on_entry(mover)
		if mover.missile and mover:get_moved() >= distance and mover.source:is_enemy(hero) then
			local source = mover.mover
			local eff = ac.effect(hero:get_point(), [[Abilities\Spells\Items\SpellShieldAmulet\SpellShieldCaster.mdl]], hero:get_point() / source:get_point())
			eff.unit:wait(300, function ()
				eff.unit:remove()
			end)
			if mover:is_skill() then
				bff:set_remaining(bff:get_remaining() - skill_cost)
			else
				local source = mover.source
				if source:is_hero() or source:is_type('建筑') then
					bff:set_remaining(bff:get_remaining() - attack_cost)
				else
					bff:set_remaining(bff:get_remaining() - attack_cost * army_rate)
				end
			end
			return true
		end
	end

	self.trg1 = hero:event '受到伤害开始' (function(_, damage)
		if not damage:is_attack() then
			return
		end
		if damage.source:get_point() * hero:get_point() >= distance then
			local source = damage.source
			local eff = ac.effect(hero:get_point(), [[Abilities\Spells\Items\SpellShieldAmulet\SpellShieldCaster.mdl]], hero:get_point() / source:get_point())
			eff.unit:wait(300, function ()
				eff.unit:remove()
			end)
			if source:is_hero() or source:is_type('建筑') then
				bff:set_remaining(bff:get_remaining() - attack_cost)
			else
				bff:set_remaining(bff:get_remaining() - attack_cost * army_rate)
			end
			return true
		end
	end)
	self.trg2 = hero:event '受到伤害' (function(_, damage)
		if not damage:is_aoe() then
			return
		end
		damage:div(aoe_reduce)
	end)
	self.blend = self.skill:add_blend('2', 'frame', 2)
	self.skill:show_buff(self)
	self.skill:set_option('show_cd', 0)
	self.skill:set_option('passive', true)
end

function mt:on_remove()
	self.eff:remove()
	self.block:remove()
	self.trg1:remove()
	self.trg2:remove()
	self.blend:remove()
	self.skill:active_cd()
	self.skill:set_option('show_cd', 1)
	self.skill:set_option('passive', false)
end
