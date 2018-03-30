local math = math

local function table_random(t)
	local t2 = {}
	for _, u in pairs(t) do
		if u:is_alive() then
			table.insert(t2, u)
		end
	end
	if #t2 > 0 then
		return t2[math.random(1, #t2)]
	end
	return nil
end

local mt = ac.skill['谐波叠加']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[BTNzr.blp]],
	title = '谐波叠加',
	
	tip = [[
复制一个不可操作的分身拥有技能并自动行动，分身每%pulse%秒增加一个。
分身死亡或持续时间结束会被回收，分身所受伤害的%damage_rate%%会反馈给英雄。
	]],
	cool = {100, 80, 60},
	cost = 200,
	pulse = {4, 3.5, 3},
	damage_rate = 25,
	area = 800,
	time = 15,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '谐波叠加'
	{
		pulse = self.pulse,
		damage_rate = self.damage_rate / 100.0,
		area = self.area,
		time = self.time,
		skill = self,
	}
end

local mt = ac.buff['谐波叠加']

function mt:on_add()
	local hero = self.target
	self.dummy_group = {}
	self.trg = hero:event '单位-发布指令' (function(trg, hero, order, target, player_order)
		if not player_order then
			return 
		end
		if order ~= 'attack' and order ~= 'smart' then
			return
		end
		if order == 'smart' and target.type == 'point' then
			return
		end
		for _, dummy in pairs(self.dummy_group) do
			dummy:issue_order(order, target)
		end
	end)
	self:on_pulse()
	self.blend = self.skill:add_blend('2', 'frame', 2)
	self.skill:show_buff(self)
	self.skill:set_option('show_cd', 0)
	self.skill:set_option('passive', true)
end

function mt:on_remove()
	self.trg:remove()
	for _, dummy in pairs(self.dummy_group) do
		local buff = dummy:find_buff '谐波叠加-马甲'
		if buff then
			buff.dummy_group = nil
			buff:remove()
		end
	end
	self.blend:remove()
	self.skill:active_cd()
	self.skill:set_option('show_cd', 1)
	self.skill:set_option('passive', false)
end

function mt:on_pulse()
	--最后一次不创建马甲出来
	if self:get_remaining() < 0.1 then
		return
	end

	local hero = self.target
	local source = table_random(self.dummy_group) or hero
	local face = 270
	source:add_restriction '幽灵'
	local dummy = source:create_illusion(source)
	if not dummy then
		return
	end
	self.dummy_group[dummy.handle] = dummy
	dummy:add_restriction '幽灵'
	dummy:add_restriction '飞行'
	source:remove_restriction '幽灵'
	dummy:cast_spell('扭曲力场')
	dummy:event '造成伤害' (function(_, damage)
		damage:div(0.5)
	end)
	dummy:set_search_range(1000)
	dummy:add_restriction '硬直'
	dummy:add_buff '谐波叠加-无法选择'
	{
		source = hero,
	}
	dummy:add_buff '谐波叠加-马甲'
	{
		source = hero,
		dummy_group = self.dummy_group,
		skill = self.skill,
		damage_rate = self.damage_rate
	}

	local mvr = ac.mover.line
	{
		source = hero,
		mover = dummy,
		skill = self.skill,
		angle = math.random(1, 360),
		distance = 200,
		speed = 1000,
		block = true,
		on_move_skip = 3,
	}

	if not mvr then
		return
	end
	
	function mvr:on_move()
		local dummy = hero:create_dummy(nil, self.mover, face)
		dummy:add_buff '淡化'
		{
			alpha = 50,
			time = 0.5,
		}
		dummy:add_restriction '硬直'
		dummy:add_restriction '缴械'
		dummy:set_class '马甲'
	end
	function mvr:on_remove()
		dummy:remove_restriction '硬直'
		dummy:remove_restriction '幽灵'
		dummy:remove_restriction '飞行'
	end
end

local mt = ac.buff['谐波叠加-马甲']

function mt:on_add()
	local dummy = self.target
	self.start_life = dummy:get '生命'
end

function mt:on_remove()
	local hero = self.source
	local dummy = self.target
	local life = dummy:get '生命'
	dummy:remove()
	if self.dummy_group then
		self.dummy_group[dummy.handle] = nil
	end
	dummy:get_point():add_effect([[war3mapImported\A15_lei.mdx]]):remove()
	if life < self.start_life then
		local dmg = (self.start_life - life) * self.damage_rate
		hero:damage
		{
			source = hero,
			damage = dmg,
			skill = self.skill,
		}
	end
end

local jass = require 'jass.common'

local mt = ac.buff['谐波叠加-无法选择']

mt.cover_type = 1
mt.cover_max = 1
mt.pulse = 0.01

function mt:on_pulse()
	local u = self.target
	if u:get_owner():is_self() then
		jass.SelectUnit(u.handle, false)
	end
end
