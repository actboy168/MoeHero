
local mt = ac.skill['二刀流']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNtre.blp]],

	--技能说明
	title = '二刀流',
	
	tip = [[
|cff11ccff被动：|r
增加%block_chance%格挡

|cff11ccff主动：|r
对最近%area%码内目标发起冲锋，造成%damage%(+%damage_plus%)点伤害并进入|cff11ccff二刀流|r状态，

|cff11ccff二刀流：|r
增加%block_chance_up%格挡
攻击间隔缩短%attack_speed_rate%%
持续%time%秒
	]],

	--冷却
	cool = 20,

	--耗蓝
	cost = 75,

	cast_channel_time = 10,

	--瞬发
	instant = 1,
	
	--格挡几率
	block_chance = {4, 20},

	--格挡值提升(%)
	block_chance_up = 20,

	--冲锋速度
	speed = 1500,

	--伤害
	damage = {40, 200},

	damage_plus = function(self, hero)
		return hero:get_ad() * 1.5
	end,

	--最近的目标范围
	area = 400,

	--攻速提高(%)
	attack_speed_rate = {30, 50},

	--持续时间
	time = 7,
}

function mt:on_cast_channel()
	local hero = self.owner
	local p = hero:get_point()
	local damage = self.damage + self.damage_plus
	local skill = self

	hero:add_buff '二刀流'
	{
		time = self.time,
		attack_speed_rate = self.attack_speed_rate,
		block_chance = self.block_chance_up,
		skill = self,
	}

	--对附近的一个单位冲锋
	local g = ac.selector()
		: in_range(hero, self.area)
		: is_enemy(hero)
		: sort_nearest_hero(hero)
		: get()
	local u = g[1]

	if not u then
		self:stop()
		hero:wait(1, function()
			hero:set_animation('attack alternate slam')
			hero:add_animation('stand alternate')
		end)
		return
	end

	hero:set_facing(p / u:get_point())
	hero:set_animation(0)

	--冲锋过去
	local mover = ac.mover.target
	{
		source = hero,
		target = u,
		speed = self.speed,
		mover = hero,
		skill = self,
		hit_area = 150,
	}

	if not mover then
		self:stop()
		hero:wait(1, function()
			hero:set_animation('attack alternate slam')
			hero:add_animation('stand alternate')
		end)
		return
	end
	
	function mover:on_finish()
		self.target:damage
		{
			source = hero,
			damage = damage,
			skill = skill,
			attack = true,
		}

		hero:set_animation(2)

		hero:issue_order('attack', self.target)

		hero:add_effect('origin', [[basicstrike01.mdl]]):remove()
	end

	function mover:on_remove()
		self.skill:finish()
	end
end

mt.buff = nil
mt.block_now = 0

function mt:on_remove()
	if self.block then self.block:remove() end
	if self.buff then self.buff:remove() end
	self.owner:add('格挡', -self.block_chance)
end

function mt:on_upgrade()
	local hero = self.owner
	hero:add('格挡', -self.block_now)
	self.block_now = self.block_chance
	hero:add('格挡', self.block_chance)
end



local mt = ac.buff['二刀流']

function mt:on_add()
	local hero = self.target
	hero:add('格挡', self.block_chance)
	--缩短攻击间隔
	hero:add('攻击间隔%', - self.attack_speed_rate)
	--设置动画后缀
	hero:add_animation_properties('alternate')
end

function mt:on_remove()
	local hero = self.target
	hero:add('格挡', -self.block_chance)
	hero:add('攻击间隔%', self.attack_speed_rate)
	hero:remove_animation_properties('alternate')
end

function mt:on_cover(dest)
	dest:set_remaining(dest.time + self:get_remaining())
	return false
end
