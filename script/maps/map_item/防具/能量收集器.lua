--物品名称
local mt = ac.skill['能量收集器']

--图标
mt.art = [[BTNdefence8.blp]]

--说明
mt.tip = [[
护盾会减少敌方弹道%speed%%的移动速度,持续5秒。
护盾消失时，每个受到影响的弹道会使你受到的伤害减少%damage%%,持续5秒,最多减少%max_damage%%。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.speed = 85
mt.damage = 5
mt.max_damage = 30
mt.area = 400
mt.cool = 5

function mt:on_add()
	local hero = self.owner
	self:enable_block()
	self:active_cd()
	self.trg1 = hero:event '单位-死亡' (function ()
		self:disable()
	end)
	self.trg2 = hero:event '单位-复活' (function ()
		self:enable()
	end)
end

function mt:on_remove()
	self:on_disable()
	self.trg1:remove()
	self.trg2:remove()
end

function mt:on_cooldown()
	if self.is_enable_block then
		local dmg = self.damage * self:get_stack()
		if dmg > self.max_damage then
			dmg = self.max_damage
		end
		self.owner:add_buff '能量收集器'
		{
			time = 5,
			value = dmg,
		}
		self:disable_block()
		self:active_cd()
	else
		self:enable_block()
		self:active_cd()
	end
end

function mt:enable_block()
	self:disable_block()
	self.is_enable_block = true

	local hero = self.owner
	if not hero:is_illusion() then
		local speed = 1 - self.speed / 100.0
		local movers = {}
		local skill = self
		self.block = hero:create_block { area = self.area }
		self.block:follow_unit(hero)
		function self.block:on_entry(mover)
			if mover.missile and mover.source:is_enemy(hero) then
				skill:add_stack(1)
				movers[mover] = true
				mover.time_scale = mover.time_scale * speed
			end
		end
		function self.block:on_leave(mover)
			if mover.missile and movers[mover] then
				skill:add_stack(-1)
				movers[mover] = nil
				mover.time_scale = mover.time_scale / speed
			end
		end
	end
	self.mover = hero:follow
	{
		source = hero,
		skill = self,
		model = [[war3mapimported\barrier.mdx]],
	}
	self.blend = self:add_blend('2', 'frame', 2)
end

function mt:disable_block()
	self.is_enable_block = false 
	if self.mover then self.mover:remove() end
	if self.block then self.block:remove() end
	if self.blend then self.blend:remove() end
end

function mt:on_enable()
	self:enable_block()
	self:active_cd()
end

function mt:on_disable()
	self:disable_block()
end

local buff = ac.buff['能量收集器']

function buff:on_add()
	self.target:addDamagedRate(-self.value)
end

function buff:on_remove()
	self.target:addDamagedRate(self.value)
end

function buff:on_cover(dst)
	return true
end


