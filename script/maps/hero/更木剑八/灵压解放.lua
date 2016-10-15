



local mt = ac.skill['灵压解放']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNjbw.blp]],

	--技能说明
	title = '灵压解放',
	
	tip = [[
解放灵压，降低附近敌人%move_speed_rate%%移动速度和%attack_speed%点攻击速度，持续%time%秒
在%buff_time%秒内提高下一次攻击%buff_range%射程，并瞬步到目标面前击晕目标%stun_time%秒
	]],

	--冷却
	cool = {16, 12},

	--耗蓝
	cost = 80,

	--瞬发
	instant = 1,

	--AOE伤害

	--范围
	area = 400,

	--减攻击速度
	attack_speed = {20, 40},

	--减移动速度(%)
	move_speed_rate = {20, 40},

	--减速持续时间
	time = 5,

--自身Buff

	--Buff持续时间
	buff_time = 5,

	--射程提升
	buff_range = {400, 600},

	--击晕目标
	stun_time = 0.5,
}

function mt:on_cast_channel()
	local hero = self.owner

	hero:get_point():add_effect([[devilslam_large.mdl]]):remove()

	--对附近单位减速
	for _, u in ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: ipairs()
	do
		u:add_buff '减速'
		{
			source = hero,
			time = self.time,
			move_speed_rate = self.move_speed_rate,
		}
		u:add_buff '减攻速'
		{
			source = hero,
			time = self.time,
			attack_speed = self.attack_speed,
		}
	end

	--获得状态
	hero:add_buff '灵压解放'
	{
		time = self.buff_time,
		range = self.buff_range,
		stun = self.stun_time,
	}
end

local mt = ac.buff['灵压解放']

mt.trg = nil
mt.eff = nil

function mt:on_add()
	local hero = self.target

	self.eff = hero:add_effect('weapon', [[war3mapimported\108.mdl]])
	--提高攻击距离
	hero:add('攻击范围', self.range)

	--监听下一次攻击
	self.trg = hero:event '单位-攻击开始' (function(trg, data)
		
		--瞬移到目标面前
		data.source:set_position(data.target:get_point() - {data.target:get_facing(), 150}, true)
		hero:get_point():add_effect([[devilslam.mdl]]):remove()
		
		--击晕目标
		data.target:add_buff '晕眩'
		{
			source = data.source,
			time = self.stun,
		}

		--移除当前Buff
		self:remove()
	end)
end

function mt:on_remove()
	local hero = self.target

	self.eff:remove()
	hero:add('攻击范围', - self.range)

	if self.trg then
		self.trg:remove()
	end
end
