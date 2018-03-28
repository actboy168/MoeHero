local mt = ac.skill['如意棒']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[PASBTNwkw.blp]],

	--技能说明
	title = '如意棒',
	
	tip = [[
|cff11ccff被动：|r
下一次攻击距离提高%attack_range%并造成%damage_rate%倍的伤害。
	]],

	--冷却
	cool = {18, 6},
	
	--射程提高
	attack_range = 450,

	--暴击伤害
	damage_rate = {2, 2.8},
}
	--
	
--标记为被动技能
mt.passive = true

function mt:on_upgrade()
	if self:get_cd() == 0 and self:get_level() > 0 then
		self:on_cooldown()
	end
end

function mt:on_cooldown()
	local hero = self.owner

	--添加如意棒Buff
	hero:add_buff '如意棒'
	{
		attack_range = self.attack_range,
		damage_rate = self.damage_rate,
		skill = self,
	}
end

function mt:on_remove()
	local hero = self.owner

	hero:remove_buff '如意棒'
end

function mt:on_enable()
	if self:get_cd() <= 0 then
		self:on_cooldown()
	end
end

function mt:on_disable()
	self:on_remove()
end


local mt = ac.orb_buff['如意棒']

--暴击
mt.eff = nil
mt.keep = true

function mt:on_start(damage)
	if not damage:is_common_attack() then
		return true
	end
	self.target:set_animation(8)
end

function mt:on_cast(damage)
	--激活技能冷却
	self.skill:active_cd()
	self:remove()
	ac.effect(damage.target, [[war3mapimported\288.mdl]], 0.5):remove()
	damage:mul(self.damage_rate - 1)
end

function mt:on_add()
	local hero = self.target
	local bff = self
	
	self.eff = hero:add_effect('chest',[[modeldekan\ability\dekan_goku_goldencudgel.mdl]])
	
	--增加攻击距离
	hero:add('攻击范围', self.attack_range)
end

function mt:on_remove()
	local hero = self.target

	self.eff:remove()

	--降低攻击距离
	hero:add('攻击范围', - self.attack_range)
end

function mt:on_cover(dest)
	return true
end
