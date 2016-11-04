local jass = require 'jass.common'
local slk = require 'jass.slk'
local setmetatable = setmetatable
local tostring = tostring
local math = math
local ac_event_dispatch = ac.event_dispatch
local ac_event_notify = ac.event_notify
local table_insert = table.insert
local table_remove = table.remove

local damage = {}
setmetatable(damage, damage)

local mt = {}
damage.__index = mt

--类型
mt.type = 'damage'

--来源
mt.source = nil

--目标
mt.target = nil

--初始伤害
mt.damage = 0

--当前伤害
mt.current_damage = 0

--是否成功
mt.success = true

--关联技能
mt.skill = nil

--关联弹道
mt.missile = nil

--是否是普通攻击
mt.common_attack = false

--是否触发攻击特效
mt.attack = false

--是否是Aoe伤害
mt.aoe = false

--是否是暴击
mt.crit_flag = nil

--累计的伤害倍率变化
mt.change_rate = 1

--武器音效
mt.weapon = false

--是否是暴击
function mt:is_crit()
	return self.crit_flag
end

--伤害是否是技能造成的
function mt:is_skill()
	return self.skill
end

--伤害是否触发攻击效果
function mt:is_attack()
	return self.attack
end

--是否是普通攻击
function mt:is_common_attack()
	return self.common_attack
end

--是否是AOE
function mt:is_aoe()
	return self.aoe
end

--是否是物品
function mt:is_item()
	return self.skill and self.skill:get_type() == '物品'
end

--获取原始伤害
function mt:get_damage()
	return self.damage
end

--获取当前伤害
function mt:get_current_damage()
	return self.current_damage
end

function mt:mul(n, callback)
	if callback then
		if not self.cost_mul then
			self.cost_mul = {}
		end
		table_insert(self.cost_mul, {n, callback})
		return
	end
	self.change_rate = self.change_rate * (1 + n)
end

function mt:div(n, callback)
	if callback then
		if not self.cost_div then
			self.cost_div = {}
		end
		table_insert(self.cost_div, {n, callback})
		return
	end
	self.change_rate = self.change_rate * (1 - n)
end

-- 初始化属性
function mt:on_attribute_attack()
	if self.has_attribute_attack then
		return
	end
	self.has_attribute_attack = true
	local source = self.source
	if not self['破甲'] then
		self['破甲'] = source:get '破甲'
	end
	if not self['穿透'] then
		self['穿透'] = source:get '穿透'
	end
	if not self['暴击'] then
		self['暴击'] = source:get '暴击'
	end
	if not self['暴击伤害'] then
		self['暴击伤害'] = source:get '暴击伤害'
	end
	if not self['吸血'] then
		self['吸血'] = source:get '吸血'
	end
	if not self['溅射'] then
		self['溅射'] = source:get '溅射'
	end
	if self.crit_flag == nil then
		self.crit_flag = self.attack and self['暴击'] >= math.random(100)
	end
end

function mt:on_attribute_defence()
	if self.has_attribute_defence then
		return
	end
	self.has_attribute_defence = true
	local target = self.target
	if not self['护甲'] then
		self['护甲'] = target:get '护甲'
	end
	if not self['格挡'] then
		self['格挡'] = target:get '格挡'
	end
	if not self['格挡伤害'] then
		self['格挡伤害'] = target:get '格挡伤害'
	end
end

local function on_damage_a(self)
	self.current_damage = self.current_damage
		* (self.source and self.source:getDamageRate() / 100 or 1)
		* (self.target:getDamagedRate() / 100)
end

local function show_block(u)
	local x, y = u:get_point():get()
	local z = u:get_point():getZ()
	ac.texttag
	{
		string = '格挡!',
		size = 8,
		position = ac.point(x - 60, y, z + 30),
		speed = 86,
		angle = 135,
		red = 100,
		green = 20,
		blue = 20,
	}
end

-- 计算暴击伤害
local function on_crit(self)
	if self:is_crit() then
		self:mul(self['暴击伤害'] / 100 - 1)
	end
end

local function on_block(self)
	local hero = self.target
	if self['格挡'] > math.random(0, 99) then
		if self['格挡伤害'] >= 100 then
			self.current_damage = 0
		else
			self:div(self['格挡伤害'] / 100)
		end
		show_block(hero)
		self.source:event_notify('造成伤害格挡', self)
		self.target:event_notify('受到伤害格挡', self)
	end
end

--护甲减免伤害
mt.DEF_SUB = tonumber(slk.misc.Misc.DefenseArmor)
mt.DEF_ADD = tonumber(slk.misc.Misc.DefenseArmor)

local function on_defence(self)
	local target = self.target
	local pene, pene_rate = self['破甲'], self['穿透']
	local def = self['护甲']
	if def > 0 then
		if pene_rate < 100 then
			def = def * (1 - pene_rate / 100)
		else
			def = 0
		end
	end
	if pene then
		def = def - pene
	end
	if def < 0 then
		--每点负护甲相当于受到的伤害加深
		local def = - def
		self.current_damage = self.current_damage * (1 + self.DEF_ADD * def)
	elseif def > 0 then
		--每点护甲相当于生命值增加 X%
		self.current_damage = self.current_damage / (1 + self.DEF_SUB * def)
	end
end

local function on_life_steal(self)
	if not self:is_attack() then
		return
	end
	local life_steal = self['吸血']
	if life_steal == 0 then
		return
	end
	self.source:heal
	{
		source = self.source,
		heal = self.current_damage * life_steal / 100,
		skill = self.skill,
		damage = self,
		life_steal = true,
	}
	--在身上创建特效
	self.source:add_effect('origin', [[Abilities\Spells\Undead\VampiricAura\VampiricAuraTarget.mdl]]):remove()
end

local function on_splash(self)
	if not self:is_attack() or self:is_aoe() then
		return
	end
	local source, target = self.source, self.target
	local splash = self['溅射']
	if splash == 0 then
		return
	end
	local dmg = self.current_damage * splash / 100
	for _, u in ac.selector()
		: in_range(target, 275)
		: is_enemy(source)
		: is_not(target)
		: ipairs()
	do
		u:damage
		{
			source = source,
			damage = dmg,
			aoe = true,
			skill = self.skill,
		}
	end
	--在地上创建特效
	target:get_point():add_effect([[ModelDEKAN\Weapon\Dekan_Weapon_Sputtering.mdl]]):remove()
end

--攻击溅射(直接加深AOE伤害)
local function on_splash_aoe(self)
	if not self:is_attack() or not self:is_aoe() then
		return
	end
	local source, target = self.source, self.target
	local splash = self['溅射']
	if splash == 0 then
		return
	end
	self:mul(splash / 1000)
	target:get_point():add_effect([[ModelDEKAN\Weapon\Dekan_Weapon_Sputtering.mdl]]):remove()
end

--伤害音效
local function on_sound(self)
	local weapon = self.weapon
	if not weapon then
		return
	end
	if weapon == true then
		weapon = nil
	end
	local name = self.source:get_weapon_sound(self.target, weapon, nil)
	self.target:play_sound(name)
end

local function on_damage_mul_div(self)
	--禁止获取伤害
	self.get_damage = false
	self.get_current_damage = false
	
	self.source:event_notify('造成伤害', self)
	self.target:event_notify('受到伤害', self)

	self.get_damage = nil
	self.get_current_damage = nil

	self.current_damage = self.current_damage * self.change_rate

	if self.cost_mul then
		for _, data in ipairs(self.cost_mul) do
			local n, callback = data[1], data[2]
			callback(self)
			self.current_damage = self.current_damage * (1 + n)
		end
	end

	if self.cost_div then
		for _, data in ipairs(self.cost_div) do
			local n, callback = data[1], data[2]
			callback(self)
			self.current_damage = self.current_damage * (1 - n)
		end
	end
end

local function cost_shield(self)
	local target = self.target
	local effect_damage = self.current_damage
	local shields = target.shields
	if not shields then
		return effect_damage
	end
	while #shields > 0 do
		local shield = shields[1]
		if effect_damage < shield.life then
			shield.life = shield.life - effect_damage
			target:add('护盾', - effect_damage)
			return 0
		end
		effect_damage = effect_damage - shield.life
		target:add('护盾', - shield.life)
		shield.life = 0
		table_remove(shields, 1)
		shield:remove()
	end
	target:set('护盾', 0)
	return effect_damage
end

local function on_texttag(self)
	if self.source:get_owner() ~= ac.player.self and self.target ~= ac.player.self.hero and not self:is_crit() then
		return
	end
	
	if self:is_crit() then
		local tag = self.target.damage_texttag_crit
		if tag and ac.clock() - tag.time < 2000 then
			tag.damage = tag.damage + self.current_damage
			if self['暴击伤害'] > tag.crit_damage then
				tag.crit_damage = self['暴击伤害']
			end
			tag:setText(('%.f(×%.2f)'):format(tag.damage, tag.crit_damage / 100), 8 + (tag.damage ^ 0.5) / 5 + tag.crit_size)
		else
			local x, y = self.target:get_point():get()
			local z = self.target:get_point():getZ()
			local tag = ac.texttag
			{
				string = ('%.f(×%.2f)'):format(self.current_damage, self['暴击伤害'] / 100),
				size = 8 + (self.current_damage ^ 0.5) / 5,
				position = ac.point(x - 60, y, z + 30),
				speed = 86,
				angle = 45,
				red = 100,
				green = 20,
				blue = 20,
				damage = self.current_damage,
				crit_damage = self['暴击伤害'],
				crit_size = 0,
				time = ac.clock(),
			}
			local i = 0
			ac.timer(10, 16, function()
				i = i + 1
				if i < 10 then
					tag.crit_size = tag.crit_size + 1
				else
					tag.crit_size = tag.crit_size - 1
				end
				tag:setText(nil, tag.size + tag.crit_size)
			end)
			self.target.damage_texttag_crit = tag
		end
	else
		local tag = self.target.damage_texttag
		if tag and ac.clock() - tag.time < 2000 then
			tag.damage = tag.damage + self.current_damage
			tag:setText(('%.f'):format(tag.damage), 8 + (tag.damage ^ 0.5) / 5)
		else
			local x, y = self.target:get_point():get()
			local z = self.target:get_point():getZ()
			local tag = ac.texttag
			{
				string = ('%.f'):format(self.current_damage),
				size = 8 + (self.current_damage ^ 0.5) / 5,
				position = ac.point(x - 60, y, z + 30),
				speed = 86,
				angle = 135,
				red = 100,
				green = 20,
				blue = 20,
				damage = self.current_damage,
				time = ac.clock(),
			}
			self.target.damage_texttag = tag
		end
	end
end

--死亡
function mt:kill()
	local target = self.target
	if target:has_restriction '免死' then
		target:set('生命', 0)
		return false
	end
	if target:event_dispatch('单位-即将死亡', self) then
		return false
	end
	return target:kill(self.source)
end

--创建伤害
function damage:__call()
	local source, target = self.source, self.target
	self.success = false
	if not target or self.damage == 0 then
		self.current_damage = 0
		return
	end
	if self.common_attack then
		if target:has_restriction '物免' then
			self.current_damage = 0
			return
		end
	else
		if target:has_restriction '魔免' then
			self.current_damage = 0
			return
		end
	end
	
	if not source then
		self.source = self.target
		source = target
		log.error('伤害没有伤害来源')
	end

	if self.skill == nil then
		log.error('伤害没有传入技能或物品')
	end

	self:on_attribute_attack()
	self:on_attribute_defence()

	self.current_damage = self.damage
	
	if source then
		source:setActive(target)
		target:setActive(source)
	end

	--检验伤害有效性
	if source:event_dispatch('造成伤害开始', self) then
		self.current_damage = 0
		return
	end
	
	if target:event_dispatch('受到伤害开始', self) then
		self.current_damage = 0
		return
	end

	if not self.real_damage then
		source:event_notify('造成伤害前效果', self)
		target:event_notify('受到伤害前效果', self)
		
		--攻击命中在伤害有效性后结算
		if self:is_attack() then
			if self.common_attack then
				ac_event_notify(self, '法球命中', self)
			else
				ac_event_notify(source, '法球命中', self)
			end
		end
		-- 计算暴击
		on_crit(self)
		--计算格挡
		on_block(self)
		--溅射AOE加成
		on_splash_aoe(self)
		--计算A类加成
		on_damage_a(self)
		--计算护甲
		on_defence(self)
		--加成和减免
		on_damage_mul_div(self)
	end

	self.success = true

	--造成伤害
	if self.current_damage < 0 then
		self.current_damage = 0
	end

	--消耗护盾
	local effect_damage = cost_shield(self)
	local life = target:get '生命'
	if life <= effect_damage then
		self:kill()
	else
		target:set('生命', life - effect_damage)
	end

	--音效
	on_sound(self)
	--漂浮文字
	on_texttag(self)
	
	if not self.real_damage then

		if not target:is_type('建筑') then
			--吸血
			on_life_steal(self)
			--溅射
			on_splash(self)
		end
		
		--伤害效果
		source:event_notify('造成伤害效果', self)
		target:event_notify('受到伤害效果', self)
	end

	source:event_notify('造成伤害结束', self)
	target:event_notify('受到伤害结束', self)

	return self
end

function mt:on_attack_start()
	self.source:event_notify('单位-攻击开始', self)
	self.target:event_notify('单位-被攻击开始', self)
end

function mt:on_attack_cast()
	self.source:event_notify('单位-攻击出手', self)
	self.target:event_notify('单位-被攻击出手', self)
end

local event = { 
	['单位-攻击开始'] = mt.on_attack_start,
	['单位-攻击出手'] = mt.on_attack_cast,
	['单位-造成伤害'] = mt.dispatch,
	['单位-受到伤害'] = mt.dispatch,
}

function mt:event_dispatch(name)
	return event[name](self)
end

function mt:event_notify(name)
	return event[name](self)
end

function mt:event(name)
	local events = self.events
	if not events then
		events = {}
		self.events = events
	end
	local event = events[name]
	if not event then
		event = {}
		events[name] = event
	end
	return function (f)
		return ac.trigger(event, f)
	end
end

function damage.init()
end

return damage
