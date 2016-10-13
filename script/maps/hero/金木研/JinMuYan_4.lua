local mt = ac.skill['JinMuYan_4']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNjmyr.blp]],

	--技能说明
	title = '半赫者',
	
	tip = [[
%reduce_time%秒内获得%reduce_rate%%的伤害减免，并解除自己受到的控制效果
提高%attack_range%射程与%move_speed%移速
|cff11ccff四爪突进|r技能释放后可在%skill_time%秒内释放第二次，若第一次没有命中，第二次造成伤害提高%skill_damage_rate%%
持续%time%秒

当受到英雄伤害导致生命低于%life_rate%%时，至少保留%life_recover%%生命并自动激活
如此激活时还会对附近单位造成一次%damage%(+%damage_plus%)伤害并击晕%stun_time%秒，但持续时间也会减少到%time2%秒
	]],

	--冷却
	cool = {100, 90, 80},

	--耗蓝
	cost = 0,

	--施法动画
	cast_animation = 24,

	--动画速度
	cast_animation_speed = 1.5,

	--施法后摇(硬直)
	cast_finish_time = 1,

	--伤害减免时间
	reduce_time = 4,

	--伤害减免(%)
	reduce_rate = 85,

	--射程提高
	attack_range = 100,

	--移动速度提升
	move_speed = {60, 120, 180},

	--额外使用时间
	skill_time = 3,

	--Q技能伤害提升(%)
	skill_damage_rate = 50,

	--持续时间
	time = {14, 17, 20},

	--强制开启生命阀值(%)
	life_rate = 20,

	--生命保留(%)
	life_recover = 20,

	--伤害范围
	area = 400,

	--伤害
	damage = {200, 350, 500},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 2
	end,

	--晕眩时间
	stun_time = 1,

	--持续时间
	time2 = {6, 8, 10},
}
--
mt.is_auto = false

function mt:on_cast_channel()
	local hero = self.owner
	local time

	if self.is_auto then
		--回血
		local life = hero:get '生命'
		local target_life = hero:get '生命上限' * self.life_recover / 100
		hero:heal
		{
			source = hero,
			heal = target_life - life,
			skill = self,
		}

		--对附近造成伤害
		local damage = self.damage + self.damage_plus
		local stun_time = self.stun_time

		for _, u in ac.selector()
			: in_range(hero, self.area)
			: is_enemy(hero)
			: ipairs()
		do
			u:add_buff '晕眩'
			{
				source = hero,
				time = stun_time,
			}
			u:damage
			{
				source = hero,
				damage = damage,
				aoe = true,
				skill = self,
			}
		end

		time = self.time2
	else
		time = self.time
	end

	--添加伤害减免效果
	hero:add_buff '半赫者-减伤'
	{
		time = self.reduce_time,
		reduce_rate = self.reduce_rate,
	}
	--变身效果
	hero:add_buff '半赫者'
	{
		time = time,
		attack_range = self.attack_range,
		move_speed = self.move_speed,
		skill_damage_rate = self.skill_damage_rate / 100,
		skill_time = self.skill_time,
	}
end

function mt:on_add()
	local hero = self.owner
	local life_rate = self.life_rate / 100

	--监听伤害,强制触发大招
	self.trigger1 = hero:event '受到伤害效果' (function(trg, damage)
		if hero:get '生命' / hero:get '生命上限' <= life_rate then
			self.is_auto = true
			hero:cast_spell(self:get_name())
			self.is_auto = false
		end
	end)
	
	--监听伤害,强制触发大招
	self.trigger2 = hero:event '单位-即将死亡' (function(trg, damage)
		self.is_auto = true
		local flag = hero:cast_spell(self:get_name())
		self.is_auto = false
		return flag
	end)
end

function mt:on_remove()
	local hero = self.owner

	hero:remove_buff '半赫者'
	hero:remove_buff '半赫者-减伤'

	--移除监听
	self.trigger1:remove()
	self.trigger2:remove()
end

local mt = ac.buff['半赫者']

function mt:on_add()
	local hero = self.target
	hero:add_animation_properties 'Alternate'
	hero:add('攻击范围', self.attack_range)
	hero:add('移动速度', self.move_speed)
end

function mt:on_remove()
	local hero = self.target
	hero:remove_animation_properties 'Alternate'
	hero:add('攻击范围', - self.attack_range)
	hero:add('移动速度', - self.move_speed)
end

function mt:on_cover()
	return true
end

local mt = ac.buff['半赫者-减伤']

function mt:on_add()
	local hero = self.target
	local reduce_rate = self.reduce_rate / 100

	self.trg = hero:event '受到伤害' (function(trg, damage)
		damage:div(reduce_rate)
	end)
	for buff in hero:each_buff() do
		if buff:is_control() then
			buff:remove()
		end
	end
end

function mt:on_remove()
	self.trg:remove()
end

function mt:on_cover()
	return true
end
