local mt = ac.skill['楸木太刀影']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNYayaE.blp]],
	title = '楸木太刀影',
	tip = [[
下一次攻击造成%damage_plus%加上目标%life_percent%%的最大生命值的伤害，持续%duration%秒。
		]],
	cost = 35,
	cool = {7, 3},
	target_type = ac.skill.TARGET_TYPE_NONE,
	duration = 4,
	instant = 1,
	life_percent = {6, 8},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '楸木太刀影'
	{
		source = hero,
		life_percent = self.life_percent,
		damage_plus = self.damage_plus,
		skill = self,
		time = 3,
	}
end

local mt = ac.orb_buff['楸木太刀影']

mt.orb_count = 1

function mt:on_add()
	local hero = self.target
	self.eff1 = hero:add_effect("origin", [[model\asuna\e_starparticle.mdl]])
	self.eff2 = hero:add_effect("hand right", [[ModelDEKAN\Ability\DEKAN_Asuna_W_Blust.mdl]])
	self.eff3 = hero:add_effect("origin", [[model\asuna\e_starparticle.mdl]])
end

function mt:on_hit(damage)
	local hero = self.target
	local target = damage.target
	target:add_effect('origin', [[war3mapimported\epipulse_9_12.mdl]]):remove()
	target:damage
	{
		source = hero,
		damage = target:get '生命上限'*(self.life_percent/100) + self.damage_plus,
		skill = self.skill,
		attack = true,
	}
end

function mt:on_remove()
	self.eff1:remove()
	self.eff2:remove()
	self.eff3:remove()
end

function mt:on_cover(new)
	self:set_remaining(new.time)
	return false
end
