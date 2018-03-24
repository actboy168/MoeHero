


local math = math

local mt = ac.skill['暴虐斩']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNtonkaQ.blp]],

	--技能说明
	title = '暴虐斩',
	
	tip = [[
向目标方向突进%distance%，对沿途的敌人造成%damage%(+%damage_plus%)伤害，对目标区域的敌人造成%damage%(+%damage_plus%)伤害。

|cff888888消耗20%怒气，每点怒气会提高1%伤害。如果消耗超过30怒气，立刻重置|cff00ccff暴虐斩|cff888888的冷却。|r

|cff00ccff被动|r：
每次使用技能，你的攻击速度提高%attack_speed%，持续4秒。这个效果最多可以叠加10层。
	]],

	--技能数据
	--冷却
	cool = {20, 12},

	--耗蓝
	cost = 0,

	--施法距离
	range = 9999,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--施法前摇
	cast_start_time = 0.2,
	cast_channel_time = 10,
	cast_shot_time = 0.5,
	cast_finish_time = 0.3,

	--飞行距离
	distance = 600,

	--飞行速度
	speed = 2000,

	--碰撞半径
	hit_area = 250,
	area = 250,

	--伤害
	damage = {60, 120},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,

	attack_speed = {12, 20},

	--触发系数
	proc = 0.7,
}

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local damage = self.damage + self.damage_plus
	local fury = hero:get_resource '怒气' * 0.2
	hero:add_resource('怒气', -fury)
	damage = damage * (1 + 0.01 * fury)
	if fury > 30 then
		self:set_cd(0)
	end

	hero:set_animation(4)
	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		speed = self.speed,
		angle = angle,
		distance = self.distance,
		skill = self,
		hit_area = self.hit_area,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
		block = true,
	}

	if not mvr then
		self:stop()
		return
	end

	function mvr:on_hit(target)
		target:damage
		{
			source = self.source,
			damage = damage,
			skill = self.skill,
			aoe = true,
			attack = true,
		}
	end

	function mvr:on_remove(dest)
		self.skill:finish()
		hero:set_animation(4)
		hero:set_animation_speed(2)
		hero:wait(300, function()
			hero:set_animation_speed(1)
		end)
		for _, u in ac.selector()
			: in_range(hero:get_point() - {self.angle, 200}, self.skill.area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = self.source,
				damage = damage,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
		end
	end
end

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '技能-施法出手' (function (_, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		local skl = self:create_cast()
		hero:add_buff '暴虐公'
		{
			time = 4,
			value = skl.attack_speed,
		}
	end)
end

function mt:on_remove()
	self.trg:remove()
end

local mt = ac.buff['暴虐公']

function mt:on_add()
	local hero = self.target
	self:add_stack(1)
	hero:add('攻击速度', self.value)
end

function mt:on_remove()
	local hero = self.target
	hero:add('攻击速度', - self.value)
end

function mt:on_cover(new)
	if self:get_stack() < 10 then
		local hero = self.target
		self:add_stack(1)
		self.value = self.value + new.value
		hero:add('攻击速度', new.value)
	end
	self:set_remaining(new.time)
	return false
end
