
local math = math
local table = table

local mt = ac.skill['音速穿刺']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNzq.blp]],

	--技能说明
	title = '音速穿刺',
	
	tip = [[
|cff11ccff主动：|r
对%range%范围内最近的%count%个敌人造成%damage_base%(+%damage_plus%)点伤害。

|cff11ccff被动：|r
普通攻击附加%passive_damage_base%(+%passive_damage_plus%)点额外伤害。该效果每%passive_cool%秒触发一次。
	]],

	--施法距离
	range = {600, 800},
	
	--耗蓝
	cost = {60, 40},

	--冷却
	cool = {8, 4},

	--动画
	cast_animation = 'attack',
	cast_channel_time = 10,

	--目标类型
	target_type = mt.TARGET_TYPE_UNIT_OR_POINT,

	--角度判定
	angle = 120,

	--敌人数量
	count = 3,

	--伤害
	damage_base = {80, 160},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.2
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,

	--冲锋速度
	speed = 2000,
	
	--被动冷却
	passive_cool = 6,

	--被动额外伤害
	passive_damage_base = {40, 120},
	passive_damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	passive_damage = function(self, hero)
		return self.passive_damage_base + self.passive_damage_plus
	end,
}

function mt:on_cast_channel()
	local hero = self.owner
	local speed = self.speed
	local damage = self.damage
	local p = hero:get_point()
	local angle = p / self.target:get_point()
	local face = hero:get_facing()

	--查找扇形区域内的敌人
	local units = ac.selector()
		: in_sector(hero, self.range, angle, self.angle)
		: is_enemy(hero)
		: sort_nearest_hero(self.target)
		: get()
	units[4] = nil

	--对表中的第一个单位进行伤害
	local function damage_once()
		local u = units[1]
		if not u or not hero:is_alive() then
			self:finish()
			--如果没有攻击目标,则移除Hard
			return
		end

		table.remove(units, 1)

		hero:wait(100, function()
			--进行冲锋
			local mvr = ac.mover.line
			{
				source = hero,
				angle = hero:get_point() / u:get_point(),
				distance = math.max(0, hero:get_point() * u:get_point() - 100),
				speed = speed,
				mover = hero,
				skill = self,
			}

			if not mvr then
				self:stop()
				return
			end

			function mvr:on_finish()
				u:damage
				{
					source = hero,
					damage = damage,
					skill = self.skill,
					attack = true,
				}
				u:add_effect('origin', [[war3mapimported\blinknew2.mdl]]):remove()
			end

			function mvr:on_remove()
				--瞬移回来
				hero:set_position(p)
				--进行下一次
				damage_once()
				hero:set_facing(face)
			end

			--创建残影
			function mvr:on_move()
				--创建残影
				local dummy = hero:create_dummy(nil, self.mover, self.angle)
				dummy:add_buff '淡化'
				{
					alpha = 50,
					time = 0.5,
				}
				dummy:add_restriction '硬直'
				dummy:add_restriction '缴械'
				dummy:set_class '马甲'
				dummy:set_animation 'attack'
				dummy:set_animation_speed(5)
			end
		end)
	end

	damage_once()
end

function mt:on_add()
	local hero = self.owner
	self.buff = hero:add_buff '音速穿刺'
	{
		skill = self,
	}
	if hero:is_hero() then
		return
	end
	self.trigger = hero:event '单位-攻击开始' (function(trg, data)
		hero:cast_spell(self.name, self:get_level(), data.target:get_point())
	end)
end

function mt:on_remove()
	local hero = self.owner
	if self.buff then
		self.buff:remove()
	end
	if self.trigger then
		self.trigger:remove()
	end
end


local mt = ac.orb_buff['音速穿刺']

mt.keep = true
mt.orb_count = 1
mt.model = [[war3mapimported\djs_weak.mdl]]

function mt:on_add()
	local hero = self.target
	self.damage = self.skill.passive_damage
end

function mt:on_hit(damage)
	damage.target:damage
	{
		source = damage.source,
		damage = self.damage,
		skill = self.skill,
	}
	damage.target:add_effect('origin', [[war3mapimported\blinknew2.mdl]]):remove()
end

function mt:on_remove()
	local hero = self.target
	self.skill:update_data()
	self.skill.buff = hero:add_buff(self.name, self.skill.passive_cool)
	{
		skill = self.skill,
	}
end
