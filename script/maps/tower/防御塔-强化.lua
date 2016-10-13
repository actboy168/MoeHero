
local mt = ac.skill['防御塔-强化']

--易伤持续时间
mt.time = 3
--易伤每次攻击增加的伤害(%)
mt.damage_rate = 50
--易伤最大层数
mt.max_stack = 1000

function mt:on_add()
	local u = self.owner
	self.trg1 = u:event '造成伤害前效果' (function(trg, damage)
		local target = damage.target
		local buff = target:find_buff '防御塔-易伤'
		if buff then
			buff:set_remaining(self.time)
			if buff:get_stack() < self.max_stack then
				buff:add_stack()
			end
		else
			buff = target:add_buff '防御塔-易伤'
			{
				source = u,
				time = self.time,
				skill = self,
			}
		end
		if buff then
			damage:mul(self.damage_rate / 100 * buff:get_stack())
		end
		--对镜像造成5倍伤害
		if target:is_illusion() then
			damage:mul(4)
		end
	end)

	self.trg2 = u:event '单位-即将获得状态' (function(_, _, buff)
		if buff.name == '晕眩' then
			return true
		end
	end)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
end

local mt = ac.buff['防御塔-易伤']

function mt:on_add()
	self:add_stack()
end
