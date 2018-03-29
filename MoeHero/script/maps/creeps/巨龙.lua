local create_jiecao = require 'maps.tower.bigbang'
local mt = ac.skill['巨龙血统']
{
	--全属性提升(%)
	rate = 15,
	--持续时间
	time = 180,
}

function mt:on_add()
	local u = self.owner
	u:add_restriction '禁锢'

	self.trg1 = u:event '受到伤害' (function(_, damage)
		damage:div(0.9)
	end)

	self.trg2 = u:event '单位-死亡' (function(_, target, source)
		if not source then
			return
		end

		for hero in pairs(ac.hero:getAllHeros()) do
			if hero:is_ally(source) then
				hero:add_buff '巨龙血统'
				{
					source = u,
					time = self.time,
					rate = self.rate,
				}
			end
		end	

		--掉落节操
		local p = u:get_point()
		for i = 1, 3 do
			create_jiecao(target, source, (source:get_owner():get_team() % 2) + 1, p - {i * 120, 200})
		end
	end)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
end


local buff = ac.buff['巨龙血统']

buff.tip = '全属性增加%rate%%'
buff.send_tip = true
buff.buff = true
buff.eff = nil

function buff:on_add()
	local hero = self.target
	local rate = self.rate

	self.eff = hero:add_effect('origin', [[ceiling rays.mdl]])

	--加全属性
	hero:add('生命上限%', rate)
	hero:add('生命恢复%', rate)
	hero:add('攻击%', rate)
	hero:add('护甲%', rate)
	hero:add('魔法上限%', rate)
	hero:add('魔法恢复%', rate)
	hero:add('攻击速度%', rate)
	hero:add('移动速度%', rate)
end

function buff:on_remove()
	local hero = self.target
	local rate = self.rate
	
	self.eff:remove()

	--扣全属性
	hero:add('生命上限%', - rate)
	hero:add('生命恢复%', - rate)
	hero:add('攻击%', - rate)
	hero:add('护甲%', - rate)
	hero:add('魔法上限%', - rate)
	hero:add('魔法恢复%', - rate)
	hero:add('攻击速度%', - rate)
	hero:add('移动速度%', - rate)
end
