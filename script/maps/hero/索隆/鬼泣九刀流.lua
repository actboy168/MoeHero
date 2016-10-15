local mt = ac.skill['鬼泣九刀流']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNZoroE.blp]],

	--技能说明
	title = '鬼泣九刀流',
	
	tip = [[
	在%time%秒内提升自己%attack_speed%的攻击速度和%move_speed_rate%%移动速度
	]],

	--耗蓝
	cost = 50,

	--冷却
	cool = 12,
	
	--攻击速度加成
	attack_speed = 80,
	
	--移动速度加成
	move_speed_rate = {10,20},

	--持续时间
	time = {2,6},

}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '鬼泣九刀流_buff'
	{
		source = hero,
		time = self.time,
		attack_speed = self.attack_speed,
		move_speed_rate = self.move_speed_rate,
		skill = self,
	}
end

local bff = ac.buff['鬼泣九刀流_buff']

bff.eff1 = nil
bff.eff2 = nil
bff.eff3 = nil

function bff:on_add()
	local hero = self.target
	self.eff1 = hero:add_effect('chest',[[modeldekan\ability\DEKAN_Zoro_E_Buff.mdx]])
	self.eff2 = hero:add_effect('hand left',[[modeldekan\ability\DEKAN_Zoro_E_Buff_Hand.mdx]])
	self.eff3 = hero:add_effect('hand right',[[modeldekan\ability\DEKAN_Zoro_E_Buff_Hand.mdx]])
	
	self.target:add('攻击速度', self.attack_speed)
	self.target:add('移动速度%', self.move_speed_rate)
end

function bff:on_remove()
	self.eff1:remove()
	self.eff2:remove()
	self.eff3:remove()
	self.target:add('攻击速度', - self.attack_speed)
	self.target:add('移动速度%', - self.move_speed_rate)
end

function bff:on_cover(dest)
	self:set_remaining(dest.time)
	return false
end
