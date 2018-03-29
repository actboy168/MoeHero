



--物品名称
local mt = ac.skill['困者之灾']

--图标
mt.art = [[BTNattack13.blp]]

--说明
mt.tip = [[
敌人受到控制效果影响时，你对他们造成的伤害提高%dmg_mul%%。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

mt.dmg_mul = 20

local function do_once(f)
	local first = true
	return function(...)
		if first then
			first = false
			f(...)
		end
	end
end

local register_control_buff = do_once(function ()
	ac.game:event '单位-获得状态' (function (trg, u, buff)
		if buff:is_control() then
			if u.control_buff then
				u.control_buff = u.control_buff + 1
			else
				u.control_buff = 1
			end
		end
	end)
	ac.game:event '单位-失去状态' (function (trg, u, buff)
		if buff:is_control() then
			if u.control_buff then
				u.control_buff = u.control_buff - 1
			else
				u.control_buff = 0
			end
		end
	end)
end)

function mt:on_add()
	register_control_buff()
	local hero = self.owner
	local dmg_mul = self.dmg_mul / 100.0
	self.trg = hero:event '造成伤害' (function(trg, damage)
		if damage.target.control_buff and damage.target.control_buff > 0 then
			damage:mul(dmg_mul)
		end
	end)
end

function mt:on_remove()
	self.trg:remove()
end


