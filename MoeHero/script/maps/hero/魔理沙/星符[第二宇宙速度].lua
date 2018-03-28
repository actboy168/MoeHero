


local math = math

local mt = ac.skill['星符[第二宇宙速度]']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNmarisaE.blp]],

	--技能说明
	title = '星符[第二宇宙速度]',
	
	tip = [[
魔理沙骑上魔帚，向目标地点冲刺，对沿途的敌人造成%damage%(+%damage_plus%)伤害。
	]],
	
	--冷却
	cool = {24, 16},

	--耗蓝
	cost = {80, 120},

	--施法距离
	range = 9999,
	cast_start_time = 0.2,
	cast_channel_time = 10,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--飞行速度
	speed = {1200, 1600},

	--伤害
	damage = {80, 160},

	damage_plus = function(self, hero)
		return hero:get_ad() * 1.5
	end,

	--最大飞行距离
	distance = { 600, 800 },

	--碰撞半径
	hit_area = 200,

	break_order = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local skill = self

	self.eff = hero:add_effect("origin",[[marisastars.mdx]])
	hero:set_animation(7)

	local mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = hero:get_point() / target,
		distance = math.min(self.distance, hero:get_point() * target),
		speed = self.speed,
		skill = self,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
		hit_area = self.hit_area,
	}

	if not mvr then
		self:stop()
		self.eff:remove()
		return
	end
	
	function mvr:on_hit(target)
		target:damage
		{
			source = hero,
			damage = skill.damage + skill.damage_plus,
			skill = skill,
			aoe = true,
			attack = true,
		}
	end

	function mvr:on_remove()
		skill:finish()
		skill.eff:remove()
		hero:set_animation 'stand'
	end
end
