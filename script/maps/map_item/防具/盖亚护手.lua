




--物品名称
local mt = ac.skill['盖亚护手']

--图标
mt.art = [[BTNdefence12.blp]]

--说明
mt.tip = [[
受到控制效果影响时，减少30%的控制时间，并且造成的伤害提高，持续5秒。
提高伤害效果可以叠加，最高%max_atk%%。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1600

--物品唯一
mt.unique = true

mt.max_atk = 40

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '单位-即将获得状态' (function(trg, _, buff)
		if not buff:is_control() then
			return
		end
		if buff.time <= 0 then
			return
		end
		local buff_val = buff.time * buff.control * 1.2
		if buff_val > 20 then
			buff_val = 20
		end
		hero:add_buff '盖亚护手'
		{
			time = 5,
			val = buff_val,
			skill = self,
		}
		buff.time = buff.time * 0.7
		hero:add_effect('origin', [[Abilities\Spells\Items\SpellShieldAmulet\SpellShieldCaster.mdl]]):remove()
	end)
end

function mt:on_remove()
	self.trg:remove()
end


local buff = ac.buff['盖亚护手']

function buff:on_add()
	self.target:addDamageRate(self.val)
	self.skill:set_stack(math.floor(self.val))
end

function buff:on_remove()
	self.target:addDamageRate(-self.val)
	self.skill:set_stack(0)
end

function buff:on_cover(dst)
	if self.val >= self.max_atk then
		return false
	end
	local nxt = self.val + dst.val
	if nxt > self.max_atk then
		nxt = self.max_atk
	end
	self.target:addDamageRate(nxt - self.val)
	self.val = nxt
	self.skill:set_stack(math.floor(self.val))
	self:set_remaining(5)
	return false
end


