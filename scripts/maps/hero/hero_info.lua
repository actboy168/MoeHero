local damage = require 'types.damage'

local mt = ac.skill['英雄属性面板']
{
	level = 1,

	max_level = 1,

	never_copy = true,

	passive = true,
	
	ability_id = 'A889',

	tip = [[
生命:    %life%/%max_life% %life_recover% %life_recover_idle%
%resource_type%:    %mana%/%max_mana% %mana_recover% %mana_recover_idle%
%shield%
攻速:    %attack_speed%(每秒攻击%attack_rate%次)
暴击:    %crit_chance%%(造成%crit_damage%%伤害)
溅射:    %splash%%
破甲:    %pene%(%pene_rate%%)
吸血:    %life_steal%
冷却:    %cool_speed%%
减耗:    %cost_save%%
造成伤害:    %damage_rate%%

防御:    %defence%(减免%defence_rate%%的伤害)
格挡:    %block_chance%%(触发时减免%block_rate%%的伤害)
受到伤害:    %damaged_rate%%
]],
}

local life_color = 'ff00dd11'

local function get_resource_color(hero)
	return ac.resource[hero.resource_type].color
end

function mt:on_add()
	local hero = ac.player.self.hero
	if hero then
		self.art = hero:get_slk 'Art'
		self:fresh_art()
		if self.owner:get_owner():is_self() then
			local name = self.owner:get_owner():getColorWord() .. hero:get_name() .. '|r'
			self.title = name
		end
	end
end

function mt:life()
	return ('|c%s%.2f|r'):format(life_color, self.owner:get '生命')
end

function mt:max_life()
	return ('|c%s%.2f|r'):format(life_color, self.owner:get '生命上限')
end

function mt:life_recover()
	local recover = self.owner:get '生命恢复'
	local str = ('%.2f'):format(recover)
	if recover >= 0 then
		str = '+' .. str
	end
	if not self.owner.active then
		str = '|cff7f7f7f(' .. str .. ')|r'
	else
		str = '|cffffffff(|r|c' .. life_color .. str .. '|r|cffffffff)|r'
	end
	return str
end

function mt:life_recover_idle()
	local recover, recover_idle = self.owner:get '生命恢复', self.owner:get '生命脱战恢复'
	local str = ('%.2f'):format(recover + recover_idle)
	if recover >= 0 then
		str = '+' .. str
	end
	if self.owner.active then
		str = '|cff7f7f7f(' .. str .. ')|r'
	else
		str = '|cffffffff(|r|c' .. life_color .. str .. '|r|cffffffff)|r'
	end
	return str
end

function mt:mana()
	return ('|cff%s%.2f|r'):format(get_resource_color(self.owner), self.owner:get '魔法')
end

function mt:max_mana()
	return ('|cff%s%.2f|r'):format(get_resource_color(self.owner), self.owner:get '魔法上限')
end

function mt:mana_recover()
	local recover = self.owner:get '魔法恢复'
	local str = ('%.2f'):format(recover)
	if recover >= 0 then
		str = '+' .. str
	end
	if not self.owner.active then
		str = '|cff7f7f7f(' .. str .. ')|r'
	else
		str = '|cffffffff(|r|cff' .. get_resource_color(self.owner) .. str .. '|r|cffffffff)|r'
	end
	return str
end

function mt:mana_recover_idle()
	local recover, recover_idle = self.owner:get '魔法恢复', self.owner:get '魔法脱战恢复'
	local str = ('%.2f'):format(recover + recover_idle)
	if recover + recover_idle >= 0 then
		str = '+' .. str
	end
	if self.owner.active then
		str = '|cff7f7f7f(' .. str .. ')|r'
	else
		str = '|cffffffff(|r|cff' .. get_resource_color(self.owner) .. str .. '|r|cffffffff)|r'
	end
	return str
end

function mt:attack_speed()
	return ('%.3f'):format(self.owner:get '攻击速度')
end

function mt:attack_rate()
	local attack_cool = self.owner:get '攻击间隔'
	local attack_speed = self.owner:get '攻击速度'
	if attack_speed >= 0 then
		attack_cool = attack_cool / (1 + attack_speed / 100)
	else
		attack_cool = attack_cool * (1 - attack_speed / 100)
	end
	return ('%.3f'):format(1 / attack_cool)
end

function mt:crit_chance()
	return self.owner:get '暴击'
end

function mt:crit_damage()
	return self.owner:get '暴击伤害'
end

function mt:splash()
	return self.owner:get '溅射'
end

function mt:pene()
	return ('%.2f'):format(self.owner:get '破甲')
end

function mt:pene_rate()
	local rate = self.owner:get '穿透'
	return rate
end

function mt:life_steal()
	return self.owner:get '吸血'
end

function mt:cool_speed()
	return ('%.3f'):format(self.owner:getSkillCool(100))
end

function mt:cost_save()
	return ('%.3f'):format(self.owner:get '减耗')
end

function mt:defence()
	return self.owner:get '护甲'
end

function mt:defence_rate()
	local def = self.owner:get '护甲'
	local rate = 0
	if def > 0 then
		rate = def * damage.DEF_SUB * 100 / (1 + def * damage.DEF_SUB)
	else
		rate = - def * damage.DEF_ADD
	end
	return ('%.2f'):format(rate)
end

function mt:block_chance()
	return self.owner:get '格挡'
end

function mt:block_rate()
	local block_rate = self.owner:get '格挡伤害'
	return block_rate
end

function mt:resource_type()
	return '|r' .. self.owner.resource_type .. '|cffffffff'
end

function mt:damage_rate()
	return self.owner:getDamageRate()
end

function mt:damaged_rate()
	return self.owner:getDamagedRate()
end

function mt:shield()
    local v = self.owner:get '护盾'
    if v > 0 then
        return '|r护盾:    |cff77bbff' .. v .. '|r|n'
    end
    return ''
end
