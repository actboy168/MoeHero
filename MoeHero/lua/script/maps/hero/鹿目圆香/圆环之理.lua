
local mt = ac.skill['圆环之理']

mt{
	--初始等级
	level = 0,
	
	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNxyr.blp]],

	--技能说明
	title = '圆环之理',
	
	tip = [[
获得%mana_up%(+%mana_up_plus%)法力值，并将所有敌方单位法力值消除，小圆进入不可干涉状态但期间不能移动、攻击或使用物品技能，期间第一次[净化箭矢]射程提高到%power_range%，并同时攻击%power_count%个目标
持续%lock_time%秒
	]],

	--施法动画
	cast_animation = 5,

	--施法时间
	cast_start_time = 0.6,

	--冷却时间
	cool = {110, 95, 80},

	--耗蓝
	cost = {200, 250, 300},

	mana_up = {200, 400, 600},
	
	mana_up_plus = function (self, hero)
		return hero:get_ad() * 4
	end,
	
	--延迟时间
	delay = 0.9,

	--法力流失时间
	lossing_time = 0.5,

	--法力恢复时间
	recover_time = 0.5,

	--法力锁定时间
	lock_time = {4, 5, 6},

	--空中视野半径
	fog_area = 2000,

	--净化箭矢(神)
	power_range = 2000,

	power_area = 600,

	power_count = 3,
}

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_facing()
	local skill = self

	hero:get_owner():play_sound [[response\鹿目圆香\skill\R.mp3]]

	--发射一枚箭矢
	local mvr = ac.mover.line
	{
		source = hero,
		start = hero:get_point() - {angle + 180, 50},
		id = 'e005',
		angle = angle,
		speed = 0,
		distance = 100,
		high = 200,
		skill = false,
	}

	if mvr then
		function mvr:on_move()
			local dummy = self.mover
			local high = dummy:get_high() + 50

			dummy:set_high(high)

			if high > 1100 then
				local p = hero:get_point()
				local dummy2 = hero:create_dummy('e001', p)
				dummy2:set_size(2.5)
				dummy2:set_high(700)
				local eff2 = dummy2:add_effect('origin', [[dtpink.mdx]])
				self:remove()
				dummy:remove()
				local t = hero:wait(1500, function()
					eff2:remove()
					dummy2:remove()
				end)
			end
		end
	end
	
	--延迟1.5秒
	hero:add_restriction '硬直'

	hero:wait(self.delay * 1000, function()
		hero:remove_restriction '硬直'
		
		if not hero:is_alive() then
			return
		end
		
		--令所有敌方英雄的蓝消除
		local mana = hero:get '魔法'
		for _, u in ac.selector()
			: is_enemy(hero)
			: of_hero()
			: ipairs()
		do
			u:add_buff '圆环之理-法力流失'
			{
				source = hero,
				time = self.lossing_time,
				recover_time = self.recover_time,
				lock_time = self.lock_time,
			}
		end
		--起飞
		hero:add_buff '圆环之理'
		{
			time = self.lock_time,
			radius = self.radius,
			count = self.count,
			fog_area = self.fog_area,
			mana_up = self.mana_up + self.mana_up_plus,
		}
	end)

	--延迟起飞
	hero:wait(500, function ()
		hero:add_buff '高度'
		{
			time = 0.5,
			speed = 600,
			reduction_when_remove = true,	--当Buff被提前删除时还原高度
		}
		hero:set_animation(1)
	end)
end



local mt = ac.buff['圆环之理']

mt.fog = nil

function mt:on_add()
	local hero = self.target

	hero:add_restriction '无敌'
	hero:add_restriction '定身'
	hero:add_restriction '缴械'
	hero:add('魔法上限', self.mana_up)
	hero:add('魔法', self.mana_up)
	
	hero:replace_skill('净化箭矢', '净化箭矢(神)', true)

	self.fog = hero:get_owner():createFogmodifier(hero, self.fog_area)
end

function mt:on_remove()
	local hero = self.target

	hero:remove_restriction '无敌'
	hero:remove_restriction '缴械'
	hero:remove_restriction '定身'
	hero:add('魔法上限', - self.mana_up)

	hero:replace_skill('净化箭矢(神)', '净化箭矢', true)

	self.fog:remove()

	if hero:is_alive() then
		--落下
		hero:add_buff '高度'
		{
			time = 0.3,
			speed = - 1000,
		}
	else
		hero:set_high(0)
	end
		
	hero:set_animation(1)
end



local mt = ac.buff['圆环之理-法力锁定']

mt.keep = true

function mt:on_add()
	self.target:add('魔法恢复', -10000)
end

function mt:on_remove()
	self.target:add('魔法恢复', 10000)
end

function mt:on_finish()
	self.target:add_buff '圆环之理-法力恢复'
	{
		source = self.source,
		time = self.recover_time,
		recover = self.recover,
		eff = self.eff,
		mana = self.mana,
	}
end



local mt = ac.buff['圆环之理-法力流失']

mt.keep = true
		
mt.recover = 0
mt.eff = nil

function mt:on_add()
	local hero = self.target
	local mana = hero:get '魔法'
	local recover = hero:get '魔法恢复'

	self.recover = mana * 2 + recover * 2
	self.mana = mana
	hero:add('魔法恢复', - self.recover)

	self.eff = hero:add_effect('origin', [[gate keeper.mdl]])
end

function mt:on_remove()
	local hero = self.target
	
	hero:add('魔法恢复', self.recover)
end

function mt:on_finish()
	local hero = self.target

	hero:add_buff '圆环之理-法力锁定'
	{
		source = self.source,
		time = self.lock_time,
		recover_time = self.recover_time,
		recover = self.recover * self.time / self.recover_time,
		mana = self.mana,
		eff = self.eff,
	}
	hero:set('魔法', 0)
end



local mt = ac.buff['圆环之理-法力恢复']

mt.keep = true

function mt:on_add()
	self.target:add('魔法恢复', self.recover)
end

function mt:on_remove()
	self.target:add('魔法恢复', - self.recover)
	self.target:set('魔法', self.mana)
	self.eff:remove()
end