
local jass = require 'jass.common'
local japi = require 'jass.japi'
local dbg = require 'jass.debug'
local unit = require 'types.unit'
local player = require 'ac.player'
local damage = require 'types.damage'
local slk = require 'jass.slk'
local math = math

local hero = {}
setmetatable(hero, hero)

--结构
local mt = {}
hero.__index = mt

--hero继承unit
setmetatable(mt, unit)

--类型
mt.unit_type = '英雄'

--当前经验值
mt.xp = 0

--下句英雄回应的最早时间
mt.response_idle_time = -99999

--复活英雄
function mt:revive(where)
	if self:is_alive() then
		return
	end
	if not where then
		where = self:getBornPoint()
	end
	local origin = self:get_point()
	--print('正在复活', self:get_name())
	jass.ReviveHero(self.handle, where:get_point():get())
	self:set('生命', self:get '生命上限')
	self._is_alive = true
	self:get_owner():selectUnit(self)
	if self.wait_to_transform_id then
		local target = self.wait_to_transform_id
		self.wait_to_transform_id = nil
		self:transform(target)
	end
	for it in self:each_skill '物品' do
		if it._wait_fresh_item then
			it._wait_fresh_item = nil
			it:fresh_item()
		end
	end
	self:event_notify('单位-复活', self)
	self:event_notify('单位-传送完成', self, origin, where)
end

--获得经验值
function mt:addXp(xp)
	jass.SetHeroXP(self.handle, jass.GetHeroXP(self.handle) + xp, true);
	self.xp = jass.GetHeroXP(self.handle);
end

-- 变身
local dummy
function mt:transform(target_id)
	if not self:is_alive() then
		--死亡状态无法变身
		self.wait_to_transform_id = target_id
		return
	end

	--获取攻击间隔
	local attack_cool = self:get '攻击间隔'
	if not dummy then
		dummy = ac.dummy
		dummy:add_ability 'AEme'
	end
	--变身
	japi.EXSetAbilityDataInteger(japi.EXGetUnitAbility(dummy.handle, base.string2id 'AEme'), 1, 117, base.string2id(self:get_type_id()))
	self:add_ability 'AEme'
	japi.EXSetAbilityAEmeDataA(japi.EXGetUnitAbility(self.handle, base.string2id 'AEme'), base.string2id(target_id))
	self:remove_ability 'AEme'

	--修改ID
	self.id = target_id

	--恢复攻击距离
	self.default_attack_range = nil
	self:add('攻击范围', 0)

	--恢复攻击力
	self:add('攻击', 0)

	--恢复移动速度
	self:add('移动速度', 0)

	--恢复攻击间隔
	self:add('攻击间隔', 0)

	--可以飞行
	self:add_ability 'Arav'
	self:remove_ability 'Arav'
	self:set_high(self:get_high())

	--动画混合时间
	jass.SetUnitBlendTime(self.handle, self:get_slk('blend', 0))

    -- 恢复特效
    if self._effect_list then
        for _, eff in ipairs(self._effect_list) do
            if eff.handle then
                jass.DestroyEffect(eff.handle)
                dbg.handle_unref(eff.handle)
                eff.handle = jass.AddSpecialEffectTarget(eff.model, self.handle, eff.socket or 'origin')
                dbg.handle_ref(eff.handle)
            end
        end
    end
end

--获得属性
function mt:getStr()
	return jass.GetHeroStr(self.handle, true)
end

function mt:getAgi()
	return jass.GetHeroAgi(self.handle, true)
end

function mt:getInt(self)
	return jass.GetHeroInt(self.handle, true)
end

--设置属性
function mt:setStr(n)
	jass.SetHeroStr(self.handle, n, true)
end

function mt:setAgi(n)
	jass.SetHeroAgi(self.handle, n, true)
end

function mt:setInt(n)
	jass.SetHeroInt(self.handle, n, true)
end

--创建单位
--	id:单位id(字符串)
--	where:创建位置(type:point;type:circle;type:rect;type:unit)
--	face:面向角度
function player.__index.createHero(p, name, where, face)
	local hero_data = hero.hero_list[name].data
	local u = p:create_unit(hero_data.id, where, face)
	setmetatable(u, hero_data)

	u:add_ability 'AInv'
	u.hero_data = hero_data

	for k, v in pairs(hero_data.attribute) do
		u:set(k, v)
	end
	return u
end

function hero.create(name)
	return function(data)
		hero.hero_datas[name] = data
		--继承英雄属性
		setmetatable(data, hero)
		data.__index = data

        function data:__tostring()
            local player = self:get_owner()
            return ('%s|%s|%s'):format('hero', self:get_name(), player.base_name)
        end
		
		--注册技能
		data.skill_datas = {}
		if type(data.skill_names) == 'string' then
			for name in data.skill_names:gmatch '%S+' do
				table.insert(data.skill_datas, ac.skill[name])
			end
		elseif type(data.skill_names) == 'table' then
			for _, name in ipairs(data.skill_names) do
				table.insert(data.skill_datas, ac.skill[name])
			end
		end
		return data
	end
end

function hero.getAllHeros()
	return hero.all_heros
end

function hero.registerJassTriggers()
	--英雄升级事件
	local j_trg = war3.CreateTrigger(function()
		local hero = unit.j_unit(jass.GetTriggerUnit())
		local new_lv = jass.GetHeroLevel(hero.handle)
		local old_lv = hero.level
		for i = hero.level + 1, new_lv do
			hero.level = i
			hero:event_notify('单位-英雄升级', hero)
		end

	end)
	for i = 1, 12 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_HERO_LEVEL, nil)
	end
end

--刷新伤害属性信息
function mt:freshDamageInfo()
	local atk = self:get '攻击'
	local pene, pener = self:get '破甲', self:get '穿透'
	local crit, critr = self:get '暴击', self:get '暴击伤害'
	local crit_up = crit * (critr/100 - 1) / 100 + 1
	local damage = atk * crit_up * (self:getDamageRate() / 100.0) * 60
	self:setStr(damage)
	return damage
end

--刷新坚韧属性信息
function mt:freshDefenceInfo()
	local life = self:get '生命上限'
	local def = self:get '护甲'
	local damaged_rate = self:getDamagedRate()
	local block_chance, block_rate = self:get '格挡', self:get '格挡伤害'
	if block_chance > 100 then block_chance = 100 end
	if block_rate > 100 then block_rate = 100 end
	local def_up = 1
	if def > 0 then
		def_up = 1 + def * damage.DEF_SUB
	else
		def_up = 1 / (1 - def * damage.DEF_ADD)
	end
	local block_up = 1 / (1.0 - block_chance * block_rate / 10000.0)
	local defence = life * def_up * block_up
	if damaged_rate > 5 then
		defence = defence * 100.0 / damaged_rate
	end
	self:setAgi(defence)
	return defence
end

--刷新移动速度信息
function mt:freshMoveSpeedInfo()
	self:setInt(math.max(0, self:get('移动速度')))
end

function hero.init()
	--注册英雄
	hero.hero_datas = {}
	
	hero.registerJassTriggers()

	--记录英雄
	local heros = {}
	hero.all_heros = heros
	ac.game:event '玩家-注册英雄' (function(_, _, hero)
		heros[hero] = true
		local resource = ac.resource[hero.resource_type]
		if not resource then
			hero:set('魔法', hero:get '魔法上限')
			return
		end
		if resource.on_add then
			resource.on_add(hero)
		end
		if resource.reborn_type == 0 then
			hero:set('魔法', 0)
			hero:event '单位-复活' (function ()
				hero:set('魔法', 0)
			end)
		elseif resource.reborn_type == 1 then
			hero:set('魔法', hero:get '魔法上限')
			local mana = 0
			hero:event '单位-死亡' (function ()
				mana = hero:get('魔法')
			end)
			hero:event '单位-复活' (function ()
				hero:set('魔法', mana)
			end)
		elseif resource.reborn_type == 2 then
			hero:set('魔法', hero:get '魔法上限')
			hero:event '单位-复活' (function ()
				hero:set('魔法', hero:get '魔法上限')
			end)
		end
		hero:loop(100, function()
			hero:updateActive()
		end)
	end)
end

--修改英雄技能点数
function mt:addSkillPoint(points)
	self.skill_points = self.skill_points + points
	local skl = self:find_skill('技能升级', nil, true)
	if not skl then
		return
	end
	skl:call_updateSkillPoint()
end

ac.hero = hero

return hero
