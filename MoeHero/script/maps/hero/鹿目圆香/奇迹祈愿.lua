
local mt = ac.skill['奇迹祈愿']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNxye.blp]],

	--技能说明
	title = '奇迹祈愿',
	
	tip = [[ 
闪烁到目标位置，附近英雄每秒恢复%life_recover%(+%life_recover_plus%)生命，持续%time%秒
在此期间受到致命伤害的英雄会将剩余生命恢复量转化为持续%shield_time%秒的护盾
小圆触发该效果时还会移除负面效果，并在%buff_time%秒内免疫死亡并提高%buff_speed%移动速度
	]],

	--冷却
	cool = {25, 15},

	--耗蓝
	cost = 150,

	area = 400,

	range = 9999,

	distance = 600,

	--目标类型
	target_type = mt.TARGET_TYPE_POINT,

	--Buff持续时间
	time = 4,

	--回血速度
	life_recover = {30, 50},

	--回血速度加成
	life_recover_plus = function(self, hero)
		return hero:get_ad() * 0.2
	end,

	--护盾时间
	shield_time = 1,

	--免死时间
	buff_time = 1,

	--移速加成
	buff_speed = 200,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local distance = math.min(hero:get_point() * target, self.distance)
	local target = hero:get_point() - { angle, distance}
	local recover = self.life_recover + self.life_recover_plus

	hero:blink(target, true)
	
	for _, u in ac.selector()
		: in_range(target, self.area)
		: of_hero()
		: is_ally(hero)
		: ipairs()
	do
		u:add_buff '奇迹祈愿'
		{
			source = hero,
			time = self.time,
			recover = recover,
			shield_time = self.shield_time,
			buff_time = self.buff_time,
			buff_speed = self.buff_speed,
		}
	end
end



local mt = ac.buff['奇迹祈愿']

mt.buff = true

mt.eff = nil
mt.trg = nil

function mt:on_add()
	local source, target = self.source, self.target

	self.eff = target:add_effect('origin', [[war3mapimported\crippletarget2.mdl]])

	--增加生命恢复速度
	target:add('生命恢复', self.recover)

	--监听死亡事件
	self.trg = target:event '单位-即将死亡' (function(trg, damage)
		--创建一个护盾
		damage.target:add_buff '奇迹祈愿护盾'
		{
			time = self.shield_time,
			life = self:get_remaining() * self.recover,
			effect = [[Abilities\Spells\Human\DispelMagic\DispelMagicTarget.mdl]]
		}

		--如果是小圆触发
		if damage.target == source then
			--驱散,免死,加速
			damage.target:add_buff '奇迹祈愿加速'
			{
				time = self.buff_time,
				speed = self.buff_speed
			}
		end 

		--移除当前Buff
		self:remove()
		return true
	end)
end

function mt:on_remove()
	local target = self.target
	
	self.eff:remove()
	self.trg:remove()
	target:add('生命恢复', - self.recover)
end



local mt = ac.shield_buff['奇迹祈愿护盾']



local mt = ac.buff['奇迹祈愿加速']

mt.buff = true

function mt:on_add()
	local hero = self.target

	hero:add_effect('origin', [[Abilities\Spells\Human\DispelMagic\DispelMagicTarget.mdl]]):remove()
	hero:add('移动速度', self.speed)
	hero:add_restriction '免死'

	--移除负面Buff
	for buff in hero:each_buff() do
		if buff.debuff then
			buff:remove()
		end
	end
end

function mt:on_remove()
	local hero = self.target

	hero:add('移动速度', - self.speed)
	hero:remove_restriction '免死'
end