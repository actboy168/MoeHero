




--物品名称
local mt = ac.skill['修罗化身']

--图标
mt.art = [[BTNdefence13.blp]]

--说明
mt.tip = [[
受到来自敌方英雄伤害时，他对你造成的伤害减少%damage%%，他受到你的伤害提高%damage%%，持续%cool%秒。
这个效果每%cool%秒只能触发一次。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.time = 10
mt.damage = 15
mt.cool = 10

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.trg = hero:event '受到伤害开始' (function(trg, damage)
		if not damage.source:is_hero() then
			return
		end
		if self:is_cooling() then
			return
		end
		self:active_cd()
		damage.source:add_buff '修罗化身'
		{
			source = hero,
			time = self.time,
			value = self.damage,
		}
	end)
end

function mt:on_remove()
	if self.trg then self.trg:remove() end
end



local buff = ac.buff['修罗化身']

buff.debuff = true

function buff:on_add()
	local hero = self.target
	local source = self.source
	local eff_dir = ''
	local value = self.value / 100.0
	if source:get_owner():is_self() then
		eff_dir = [[snipe target.mdl]]
	end
	self.eff = hero:add_effect('overhead', eff_dir)
	self.trg1 = hero:event '造成伤害' (function(trg, damage)
		if damage.target == source then
			damage:div(value)
		end
	end)
	self.trg2 = hero:event '受到伤害' (function(trg, damage)
		if damage.source == source then
			damage:mul(value)
		end
	end)
end

function buff:on_remove()
	self.eff:remove()
	self.trg1:remove()
	self.trg2:remove()
end

function buff:on_cover(dst)
	return true
end
