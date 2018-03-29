
local mt = ac.skill['直觉']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNsabere.blp]],

	--技能说明
	title = '直觉',
	
	tip = [[
准备闪避下一次近战攻击或弹道,成功闪避后获得%attack_speed%的攻击速度与%move_speed_rate%%的移动速度,持续%buff_time%秒
	]],

	--耗蓝
	cost = 40,

	--冷却
	cool = {10, 6},

	--闪避状态持续
	dodge_time = 5,

	--攻击速度
	attack_speed = {20, 80},

	--移动速度
	move_speed_rate = {10, 30},

	--加速时间
	buff_time = 5,
}

function mt:on_cast_channel()
	local hero = self.owner

	hero:add_buff '直觉-准备'
	{
		time = self.dodge_time,
		attack_speed = self.attack_speed,
		move_speed_rate = self.move_speed_rate,
		buff_time = self.buff_time,
		skill = self,
	}
end

local mt = ac.buff['直觉-准备']

function mt:on_add()
	local hero = self.target
	local has_dodged = false
	
	local function dodge()
		if has_dodged then
			return
		end
		has_dodged = true

		hero:add_buff '直觉-加速'
		{
			attack_speed = self.attack_speed,
			move_speed_rate = self.move_speed_rate,
			time = self.buff_time,
			ref = 'weapon',
			model = [[modeldekan\ability\DEKAN_Saber_E_Weapon_Effect.mdl]],
			skill = self.skill,
		}
		self:remove()
	end

	self.trg1 = hero:event '受到伤害开始' (function(trg, damage)
		if damage:is_common_attack() then
			dodge()
			return true
		end
	end)

	self.trg2 = hero:event '单位-即将被投射物击中' (function(trg, _, mover)
		dodge()
		return true
	end)

	self.eff = hero:add_effect('origin', [[modeldekan\ability\DEKAN_Saber_E_Buff.mdl]])
	self.skill:show_buff(self)
end

function mt:on_remove()
	local hero = self.target
	self.trg1:remove()
	self.trg2:remove()
	self.eff:remove()
end

function mt:on_cover()
	return true
end

local mt = ac.buff['直觉-加速']

mt.attack_speed = 0
mt.attack_speed_rate = 0
mt.move_speed_rate = 0
mt.model = ''
mt.ref = 'origin'
mt.effect = nil

function mt:on_add()
	self.target:add('攻击速度', self.attack_speed)
	self.target:add('移动速度%', self.move_speed_rate)
	self.effect = self.target:add_effect(self.ref, self.model)
	self.blend = self.skill:add_blend('2', 'frame', 2)
end

function mt:on_remove()
	self.target:add('攻击速度', - self.attack_speed)
	self.target:add('移动速度%', - self.move_speed_rate)
	self.blend:remove()
	self.effect:remove()
end

function mt:on_cover()
	return true
end
