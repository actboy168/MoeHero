



--物品名称
local mt = ac.skill['充能漩涡']

--图标
mt.art = [[BTNspeed1.blp]]

--说明
mt.tip = [[
移动时，你造成的伤害会逐渐提高。最高可达到你移动速度的%rate%%。
]]

--物品类型
mt.item_type = '鞋子'

--附魔价格
mt.gold = 1600

--物品等级
mt.level = 4

--物品唯一
mt.unique = true

mt.rate = 7

function mt:on_add()
	local hero = self.owner
	local last = hero:get_point()
	local count = 0
	local stack = 0
	local is_walking = false
	self.timer1 = hero:loop(20, function ()
		local now = hero:get_point()
		if now * last > 1 then
			is_walking = true
		else
			is_walking = false
		end
		last = now
	end)
	self.timer2 = hero:loop(200, function ()
		if is_walking then
			local max_stack = hero:get('移动速度') * self.rate / 100
			if self:get_stack() < max_stack then
				self:add_stack(1)
			elseif self:get_stack() > max_stack then
				self:add_stack(-1)
			end
		else
			if self:get_stack() > 0 then
				self:add_stack(-1)
			end
		end
	end)
	self.trg = hero:event '造成伤害' (function (trg, damage)
		damage:mul(self:get_stack() / 100)
	end)
end

function mt:on_remove()
	self.timer1:remove()
	self.timer2:remove()
	self.trg:remove()
end


