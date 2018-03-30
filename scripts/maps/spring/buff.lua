local spring = require 'maps.spring'
local hero = require 'types.hero'
local player = require 'ac.player'
local jass = require 'jass.common'

--瀑布加速Buff
local buff = ac.buff['瀑布加速Buff']

buff.fast_speed = 300
buff.spd_buf = nil
buff.time = 1

function buff:on_add()
	local u = self.target
	u:remove_buff '瀑布减速Buff'
	u:add('移动速度', self.fast_speed)
end

function buff:on_remove()
	local u = self.target
	u:add('移动速度', -self.fast_speed)
end

function buff:on_cover(dest)
	--更改原来buff的持续时间
	if dest.time > self:get_remaining() then
		self:set_remaining(dest.time)
	end
	return false
end


--瀑布减速Buff
local buff = ac.buff['瀑布减速Buff']

buff.slow_speed = 50
buff.spd_buf = nil
buff.time = 1

function buff:on_add()
	local u = self.target;
	self.spd_buf = u:add_buff '减速'
	{
		source = self.source,
		move_speed_rate = self.slow_speed,
	}

	u:remove_buff '瀑布加速Buff'
end

function buff:on_remove()
	if self.spd_buf then self.spd_buf:remove() end
end

function buff:on_cover(dest)
	--更改原来buff的持续时间
	if dest.time > self:get_remaining() then
		self:set_remaining(dest.time)
	end
	return false
end


--瀑布检测Buff
local buff = ac.buff['瀑布检测Buff']

buff.river = nil
buff.angle = -45
buff.angle_tol = 60
buff.keep = true
buff.pulse = 0.2

function buff:on_pulse()
	local hero = self.target
	if not self.river then
		self.river = spring.river
	end

	if self.river < hero then
		local angle = ac.math_angle(hero:get_facing(), self.angle)
		if angle <= self.angle_tol then
			hero:add_buff '瀑布加速Buff' {}
		elseif angle >= 180 - self.angle_tol then
			hero:add_buff '瀑布减速Buff' {}
		end
	end
end

function spring.springStart()
	--player.self:sendMsg '踏浪而行'
	for hero in pairs(hero.getAllHeros()) do
		hero:add_buff '瀑布检测Buff' {}
	end
	jass.SetWaterBaseColor(255, 32, 255, 255)
end

function spring.springStop()
	for hero in pairs(hero.getAllHeros()) do
		hero:remove_buff '瀑布检测Buff'
	end
	jass.SetWaterBaseColor(0, 0, 255, 255)
end
