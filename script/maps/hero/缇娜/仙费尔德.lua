local jass = require 'jass.common'

local mt = ac.skill['仙费尔德']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[replaceabletextures\commandbuttons\BTNTinaR.blp]],
	title = '仙费尔德',
	tip = [[
缇娜指挥仙费尔德飞向目标位置，锁定并追踪扫描到的敌方英雄。缇娜可以对被锁定的英雄来一发|cff00ccff黑风|r。仙费尔德在被摧毁前可以运作%life_time%秒。

|cff00ccff黑风|r
缇娜专注瞄准，对第一个击中的英雄造成%damage%(+%damage_plus%)点伤害。
	]],
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 999999,
	cast_animation = 'spell five',
	cast_start_time = 1.55,
	cast_animation_speed = 1,
	cool = 90,
	-- 仙费尔德持续时间
	life_time = 30,
	-- 黑风伤害
	damage = {200, 300},
	damage_plus = function(self, hero)
		return hero:get_ad() * 5
	end,
}

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local dummy = hero:create_unit('e00L', hero:get_point() - {angle, 4} - {angle - 90, 10}, angle)
	dummy:add_high(210)
	dummy:add_buff '高度'
	{
		time = 0.5,
		speed = 250,
		skill = self,
	}
	dummy:wait(self.life_time * 1000, function()
		dummy:kill()
	end)
	dummy:wait(500, function()
		local mover = ac.mover.line
		{
			source = hero,
			mover = dummy,
			skill = self,
			target = target,
			speed = 0,
			accel = 100,
			max_speed = 2000,
		}

		dummy:add_buff '仙费尔德-扫描'
		{
			source = hero,
			skill = self,
			mover = mover,
		}
	end)
end


local mt = ac.buff['仙费尔德-扫描']

mt.pulse = 0.5

function mt:on_pulse()
	local hero = self.source
	local dummy = self.target
	if dummy:find_buff '仙费尔德-锁定' then
		return
	end
	local g = ac.selector()
		: in_range(dummy, 1000)
		: is_enemy(hero)
		: of_hero()
		: get()
	local target = g[1]
	if not target then
		return
	end
	if self.mover then
		self.mover:remove()
	end
	dummy:add_buff '仙费尔德-锁定'
	{
		source = hero,
		skill = self.skill,
		lock = target,
	}
end

function mt:on_remove()
	local dummy = self.target
	dummy:add_buff '高度'
	{
		speed = -1000,
		time = dummy:get_high() / 1000,
		skill = self.skill,
		keep = true,
	}
end

local mt = ac.buff['仙费尔德-锁定']

mt.pulse = 0.1

function mt:on_add()
	local dummy = self.target
	local target = self.lock
	local hero = self.source
	self.ln = ac.lightning('LN01', dummy, target, 335, 50)
	self.ln:setColor(100, 0, 0)
	self.mover = ac.mover.target
	{
		source = hero,
		target = target,
		skill = self.skill,
		mover = dummy,
		min_speed = 0,
		max_speed = 500,
		target_high = dummy:get_high(),
		hit_range = -999999,
		block = true,
	}
	self.buff = hero:add_buff '仙费尔德-狙击'
	{
		lock = target,
		skill = self.skill,
	}
end

function mt:on_remove()
	self.ln:remove()
	if self.mover then
		self.mover:remove()
	end
	if self.buff then
		self.buff:remove()
	end
end

function mt:on_pulse()
	local dummy = self.target
	local target = self.lock
	if not target:is_alive() then
		self:remove()
		return
	end
	local distance = dummy:get_point() * target:get_point()
	if distance > 1500 then
		self:remove()
		return
	end
	if distance < 750 then
		self.mover.accel = - 500
	else
		self.mover.accel = 500
	end
end


local mt = ac.buff['仙费尔德-狙击']

mt.keep = true

function mt:on_add()
	local hero = self.source
	hero:replace_skill('仙费尔德', '黑风')
end

function mt:on_remove()
	local hero = self.source
	hero:replace_skill('黑风', '仙费尔德')
	hero:remove_skill '黑风'
end


local mt = ac.skill['黑风']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[replaceabletextures\commandbuttons\BTNTinaRR.blp]],
	title = '黑风',
	tip = [[
缇娜专注瞄准，对第一个击中的英雄造成%damage%(+%damage_plus%)点伤害。
	]],
	cost = 1,
	
	cast_animation = 'spell two',
	cast_start_time = 0.2,
	cast_channel_time = 1.6,
	cast_shot_time = 0.4,

	width = 300,
	damage = {200, 300},
	damage_plus = function(self, hero)
		return hero:get_ad() * 5
	end,
}

function mt:on_can_cast()
	local hero = self.owner
	local buff = hero:find_buff '仙费尔德-狙击'
	if not buff then
		return false, '需要通过仙费尔德锁定一个目标'
	end
	self.target = buff.lock
	return true
end

function mt:on_cast_start()
	local hero = self.owner
	local buff = hero:find_buff '仙费尔德-狙击'
	if not buff then
		return
	end
	hero:play_sound([[response\缇娜\skill\R.mp3]])
	hero:remove_buff '战术姿态'
	local target = buff.lock
	self.target = target
	self.ln = {}
	for i = 1, 20 do
		local ln = ac.lightning('LN06', hero, hero)
		ln.keep_visible = true
		ln.offset_z = false
		self.ln[i] = ln
	end
	self.timer = hero:timer(50, 20, function()
		local angle = hero:get_point() / target:get_point()
		hero:set_facing(angle)
		local p = hero:get_point()
		local z = p:getZ()
		for i, ln in ipairs(self.ln) do
			ln:move(p - {angle, i * 1000 + 200}, p - {angle, i * 1000 - 900}, z, z)
		end
	end)
	self.timer:on_timer()
end

function mt:on_cast_break()
	self.timer:remove()
	for _, ln in ipairs(self.ln) do
		ln:remove()
	end
end

function mt:on_cast_channel()
	local hero = self.owner
	hero:set_animation_speed(0)
end

function mt:on_cast_shot()
	self:disable()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target:get_point()
	ac.player.self:play_sound([[response\缇娜\skill\RR.mp3]])
	hero:set_animation_speed(1)
	self.timer:remove()
	for _, ln in ipairs(self.ln) do
		ln:remove()
	end

	local width = self.width
	local g = ac.selector()
		: in_line(hero, angle, 1000000, width)
		: is_enemy(hero)
		: get()

	local p = hero:get_point()
	local first_hero = nil
	local min_dis = 1000000
	for _, u in ipairs(g) do
		if u:is_hero() then
			local dis = p * u:get_point()
			if dis < min_dis then
				min_dis = dis
				first_hero = u
			end
		end
	end

	local damage = self.damage + self.damage_plus
	for _, u in ipairs(g) do
		if not u:is_hero() or u == first_hero then
			u:damage
			{
				source = hero,
				damage = damage,
				aoe = true,
				attack = true,
				skill = self,
			}
			u:add_effect('origin', [[Abilities\Spells\Orc\LightningBolt\LightningBoltMissile.mdl]]):remove()
		end
	end
	
	for i = 1, 200 do
		local p = p - {angle, i * 150}
		;(p - {angle + 90, 100}):add_effect([[Objects\Spawnmodels\Undead\ImpaleTargetDust\ImpaleTargetDust.mdl]]):remove()
		;(p - {angle - 90, 100}):add_effect([[Objects\Spawnmodels\Undead\ImpaleTargetDust\ImpaleTargetDust.mdl]]):remove()
		local uber = jass.CreateUbersplat(p[1], p[2], 'THND', 255, 255, 255, 255, false, false)
		jass.SetUbersplatRenderAlways(uber, true)
		jass.FinishUbersplat(uber)
	end
	for _, i in ipairs{-90, 90} do
		local start = p - {angle + i, 100}
		local target = start - {angle, 30000}
		local ln = ac.lightning('LN01', start, target)
		ln:setColor(100, 100, 0)
		local alpha = 100
		ac.loop(100, function(t)
			alpha = alpha - 5
			if alpha <= 0 then
				ln:remove()
				t:remove()
				return
			end
			ln:setAlpha(alpha)
		end)
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	self.timer:remove()
	for _, ln in ipairs(self.ln) do
		ln:remove()
	end
end
