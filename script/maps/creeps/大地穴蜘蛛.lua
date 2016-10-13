local mt = ac.skill['大地穴蜘蛛吸血']
{
	--吸血(%)
	heal = 25,
}

function mt:on_add()
	local u = self.owner
	u:add('吸血', self.heal)
end

function mt:on_remove()
	local u = self.owner
	u:add('吸血', -self.heal)
end


local rect = require 'types.rect'

local mt = ac.skill['野区随机传送门']
{
	gate_unit_id = 'n00F',
	--传送门持续时间
	time = 10,
	--进入传送门需要的距离
	distance = 100,
}

local function get_random_gate(poi)
	local gates = {}
	local min_distance = 999999999
	local min_index = 0
	for i = 1, 4 do
		local gate = rect.j_point('creeps_gate_' .. i)
		local distance = gate * poi
		if distance < min_distance then
			min_distance = distance
			min_index = i
		end
		gates[i] = gate
	end
	table.remove(gates, min_index)
	return gates[math.random(1, #gates)]
end

function mt:on_add()
	local u = self.owner

	self.trg = u:event '单位-死亡' (function(trg, target, source)
		local this_point = u:get_point()
		local target_point = get_random_gate(this_point)

		--2边各创建个传送门的模型出来
		local target_gate = ac.player[16]:create_unit(self.gate_unit_id, target_point, 270)
		local this_gate = ac.player[16]:create_unit(self.gate_unit_id, this_point, 270)
		target_gate:set_animation 'birth'
		target_gate:add_animation 'stand'
		target_gate:set_animation_speed(2)

		this_gate:set_animation 'birth'
		this_gate:add_animation 'stand'
		this_gate:set_animation_speed(2)

		--设置目标传送门不能点击
		target_gate:set_class '马甲'

		--设置当前传送门无敌
		this_gate:add_restriction '无敌'

		--当前传送门添加Buff
		this_gate:add_buff '野区随机传送门'
		{
			time = self.time,
			distance = self.distance,
			target_gate = target_gate,
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end


local mt = ac.buff['野区随机传送门']

mt.pulse = 0.1

function mt:on_add()
	self.group = {}
	self.trg = ac.game:event '单位-发布指令' (function(trg, hero, order, target)
		if hero:is_hero() then
			if target == self.target and order == 'smart' then
				self.group[hero.handle] = hero
				self:on_pulse()
			else
				self.group[hero.handle] = nil
			end
		end
	end)
end

function mt:on_pulse()
	local poi = self.target:get_point()
	local distance = self.distance
	for _, u in pairs(self.group) do
		if u:get_point() * poi <= distance then
			u:blink(self.target_gate, true)
			u:get_owner():setCamera(self.target_gate)
			self:remove()
			return
		end
	end
end

function mt:on_remove()
	self.trg:remove()
	self.target:kill()
	self.target_gate:kill()
end
