
local mt = ac.skill['铁砂之剑']

mt{
	level = 0,
	art = [[BTNpje.blp]],
	title = '铁砂之剑',
	tip = [[
|cff11ccff主动：|r
将铁砂固定成剑型，增加%damage_base%(+%damage_plus%)点攻击，持续%damage_time%秒。持续时间内，被动效果不再有冷却。

|cff11ccff被动：|r
受到控制效果影响时，免疫此效果并获得一个护盾，吸收%shield_base%(+%shield_plus%)伤害，持续%shield_time%秒。
这个效果每%shield_cool%秒内只会触发一次。
	]],
	cool = { 20, 12 },
	cost = { 80, 60 },
	instant = 1,
	damage_base = {20, 40},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.4
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	damage_time = 6,
	shield_base = {100, 200},
	shield_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	shield = function(self, hero)
		return self.shield_base + self.shield_plus
	end,
	shield_time = 3,
	shield_cool = 15,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '铁砂之剑-增伤'
	{
		time = self.damage_time,
		damage = self.damage,
		skill = self,
	}
	hero:add_buff '铁砂之剑-护盾就绪'
	{
		skill = self,
	}
end

function mt:on_add()
	local hero = self.owner
	hero:add_buff '铁砂之剑-护盾就绪'
	{
		skill = self,
	}
end

function mt:on_remove()
	local hero = self.owner
	hero:remove_buff '铁砂之剑-护盾就绪'
	hero:remove_buff '铁砂之剑-护盾'
	hero:remove_buff '铁砂之剑-增伤'
end

local mt = ac.orb_buff['铁砂之剑-增伤']

function mt:on_add()
	local hero = self.target
	self.missile_art = hero.missile_art
	hero.missile_art = [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]
	hero:add('攻击', self.damage)
	self.blend = self.skill:add_blend('2', 'frame', 2)
	self.skill:show_buff(self)
	self.skill:set_option('show_cd', 0)
	self.skill:set_option('passive', true)
end

function mt:on_remove()
	local hero = self.target
	hero.missile_art = self.missile_art
	hero:add('攻击', -self.damage)
	self.blend:remove()
	self.skill:active_cd()
	self.skill:set_option('show_cd', 1)
	self.skill:set_option('passive', false)
end

function mt:on_hit(damage)
	damage.target:add_effect('overhead', [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
end

local mt = ac.buff['铁砂之剑-护盾就绪']

mt.keep = true

function mt:on_add()
	local hero = self.target
	local skl = self.skill
	self.blend = self.skill:add_blend('1', 'frame', 1)
	self.eff = hero:add_effect('origin', [[Abilities\Spells\Orc\Purge\PurgeBuffTarget.mdl]])
	self.trg = hero:event '单位-即将获得状态' (function(trg, _, buff)
		if not buff:is_control() then
			return
		end
		if buff.time <= 0 then
			return
		end
		hero:add_effect('origin', [[Abilities\Spells\Human\DispelMagic\DispelMagicTarget.mdl]]):remove()
		local cast = skl:create_cast()
		hero:add_buff '铁砂之剑-护盾'
		{
			time = cast.shield_time,
			life = cast.shield,
		}
		if nil == hero:find_buff '铁砂之剑-法球' then
			self:remove()
			skl.buff = hero:add_buff(self.name, skl.shield_cool)
			{
				skill = skl
			}
		end
		return true
	end)
end

function mt:on_remove()
	self.blend:remove()
	self.trg:remove()
	self.eff:remove()
end

function mt:on_cover()
	return false
end

local mt = ac.shield_buff['铁砂之剑-护盾']
