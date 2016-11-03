
local rawget = rawget
local rawset = rawset
local math = math

local mt = ac.skill['旋击挑斩']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNtrw.blp]],

	--技能说明
	title = '旋击挑斩',
	
	tip = [[
|cff11ccff主动：|r
对周围%radius%范围（前方%angle%°内提高到%distance%距离）敌方单位造成%damage%(+%damage_plus%)伤害并击飞0.5秒

|cff11ccff被动：|r
造成伤害时加速该技能%cool_sub%秒冷却
	]],

	--施法距离
	range = 9999,

	--技能类型
	target_type = mt.TARGET_TYPE_POINT,

	--施法时间
	cast_start_time = 0.1,

	cast_animation_speed = 2,

	--后摇时间
	cast_finish_time = 0.1,

	--播放动作
	cast_animation = 8,-- 'Spell',

	--冷却
	cool = 9,

	--耗蓝
	cost = 60,

	--圆形选取范围
	radius = 150,

	--角度
	angle = 120,

	--距离
	distance = 250,

	--伤害
	damage = {70, 210},

	damage_plus = function(self, hero)
		return hero:get_ad() * 1.5
	end,

	--减少冷却
	cool_sub = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local p = hero:get_point()
	local angle = p / self.target
	local damage = self.damage + self.damage_plus
	
	for _, u in ac.selector()
		: in_range(hero, self.distance)
		: is_enemy(hero)
		: add_filter(function(u)
			return u:is_in_range(p, self.radius) or ac.math_angle(p / u:get_point(), angle) <= self.angle / 2
		end)
		: ipairs()
	do
		u:add_effect('chest', [[modeldekan\ability\dekan_kirito_w_ribbon.mdl]]):remove()
		
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
			attack = true,
		}

		u:add_buff '击退'
		{
			source = hero,
			angle = angle,
			distance = 1,
			high = 320,
			time = 0.7,
		}
	end
end

mt.trg = nil

function mt:on_upgrade()
	if self:get_level() ~= 1 then
		return
	end
	local hero = self.owner

	--监听桐人造成伤害
	self.trg = hero:event '造成伤害效果' (function(trg, damage)
		local cool = self:get_cd()
		
		if cool <= 0 then
			return
		end

		if damage:is_item() then
			return
		elseif not damage:is_skill() then
			goto doSub
		elseif damage.skill.type == 'item' then
			return
		else
			--该技能本身不能触发减冷却
			if damage.skill.name == self.name then
				return
			end
			if not rawget(damage.skill, '旋击挑斩标记') or not damage:is_aoe() then
				rawset(damage.skill, '旋击挑斩标记', true)
				goto doSub
			end
			return
		end

		:: doSub ::

		cool = cool - self.cool_sub
		self:set_cd(cool)
	end)
end

function mt:on_remove()
	if self.trg then
		self.trg:remove()
	end
end
