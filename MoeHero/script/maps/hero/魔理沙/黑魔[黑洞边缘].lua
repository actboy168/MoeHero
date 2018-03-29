local math = math

local mt = ac.skill['黑魔[黑洞边缘]']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNmarisaQ.blp]],

	--技能说明
	title = '黑魔[黑洞边缘]',
	
	tip = [[
魔理沙释放很多星弹，向目标地点飞去，每颗星弹造成%damage%(+%damage_plus%)伤害。

|cffffff11可充能%charge_max_stack%次|r
	]],

	--施法距离
	range = {600, 800},
	
	--耗蓝
	cost = {60, 80},

	--冷却
	cool = 1,
	charge_cool = {12, 8},

	--动画
	cast_animation = 'attack',

	--施法前摇
	cast_start_time = 0.2,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--范围
	area = 500,

	--弹幕数量
	count = 9,

	--伤害
	damage = {60, 100},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.0
	end,

	--弹道速度
	speed = 500,

	cooldown_mode = 1,
	charge_max_stack = 3,
	instant = 1,
}

local star = {
	[[marisastarm_1b.mdx]],
	[[marisastarm_1g.mdx]],
	[[marisastarm_1y.mdx]],
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local damage = self.damage + self.damage_plus
	local mark = {}

	for i = 1, self.count do
		local angle = i * (360.0 / self.count)
		local mvr = ac.mover.line
		{
			source = hero,
			start = target - {angle, self.area},
			model = star[i % 3 + 1],
			angle = angle - 180 + 50,
			distance = self.area * 2,
			speed = self.speed,
			high = 60,
			size = 1.5,
			skill = self,
			damage = damage,
			hit_type = ac.mover.HIT_TYPE_ENEMY,
			hit_area = 100,
		}
		if mvr then
			function mvr:on_move()
				self.angle = self.angle - 4
			end
			function mvr:on_hit(target)
				if mark[target] then
					target:damage
					{
						source = hero,
						damage = damage * 0.30,
						skill = self.skill,
						attack = true,
					}
					return
				end
				mark[target] = true
				target:damage
				{
					source = hero,
					damage = damage,
					skill = self.skill,
					attack = true,
				}
				return true
			end
		end
	end
end
