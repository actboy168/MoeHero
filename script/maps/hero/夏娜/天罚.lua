


local mt = ac.skill['天罚']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNxne.blp]],

	--技能说明
	title = '天罚',
	
	tip = [[
飞向目标地点，对%area%范围内敌人造成%damage%(+%damage_plus%)伤害。
附加%debuff_stack%层|cff11ccff红莲太刀|r效果。
	]],

	--冷却
	cool = {28, 12},

	--耗蓝
	cost = 110,
	
	--施法动画
	cast_animation = 6,
	cast_channel_time = 10,

	--施法距离
	range = 700,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,
	
	--影响范围
	area = 350,

	--伤害
	damage = {100, 200},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,

	--飞行速度
	speed = 1000,

	--燃烧层数
	debuff_stack = 2,
}

function mt:on_cast_start()
	local hero = self.owner
	--最大距离时,动画速度为2.5
	local animation_speed = 2.5 * self.range / (hero:get_point() * self.target)
	hero:set_animation_speed(animation_speed)
end

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local area = self.area
	local damage = self.damage + self.damage_plus
	local skill = self
	local stack = self.debuff_stack

	local mover = ac.mover.target
	{
		source = hero,
		mover = hero,
		target = target,
		speed = self.speed,

		skill = self,
	}

	if not mover then
		return
	end

	function mover:on_finish()
		--造成AOE伤害
		--创建特效
		target:add_effect([[Abilities\Spells\Other\Doom\DoomDeath.mdl]]):remove()
		local count = 0
		hero:timer(100, 3, function(t)
			count = count + 1
			local d = count * 75
			local max = count + 3
			for i = 1, max do
				local p = target - {i * 360 / max, d}
				p:add_effect([[Abilities\Spells\Other\Doom\DoomDeath.mdl]]):remove()
			end
		end)
		
		local dest_skill = hero:find_skill '飞焰'

		--造成伤害
		for _, u in ac.selector()
			: in_range(hero, area)
			: is_enemy(hero)
			: ipairs()
		do
			--先叠2层燃烧
			if dest_skill then
				for i = 1, stack do
					dest_skill:castFire(u)
				end
			end
			
			u:damage
			{
				source = hero,
				damage = damage,
				skill = skill,
				aoe = true,
				attack = true,
			}
		end
	end

	function mover:on_remove()
		self.skill:finish()
		hero:set_animation_speed(1)
		hero:add_animation('stand')
		hero:issue_order('attack',hero:get_point())
	end

	
end