


local mt = ac.skill['飞焰']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNxnw.blp]],

	--技能说明
	title = '飞焰',
	
	tip = [[
射出%count%道火焰，对击中的目标造成%damage%(+%damage_plus%)伤害，立刻结算|cff00ccff红莲太刀|r所有效果，并在200范围内溅射50%伤害。

|cff00ccff红莲太刀|r
普通攻击引燃目标，每秒造成%damage2%(+%damage2_plus%)点伤害，持续%time%秒
	]],

	--耗蓝
	cost = 100,

	--冷却
	cool = 15,

	--施法前摇
	cast_start_time = 0.3,

	--施法后摇
	cast_finish_time = 0.3,

	--伤害
	damage2 = {1, 5},

	--伤害加成
	damage2_plus = function(self, hero)
		return hero:get_ad() * 0.04
	end,

	--持续时间
	time = 12,
	
	target_type = ac.skill.TARGET_TYPE_POINT,
	range = 800,
	cast_animation = 4,

	distance = 850,
	speed = 2200,
	count = 5,

	--伤害
	damage = {60, 120},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,
}

mt.eff = nil
mt.orb = nil

function mt:on_upgrade()
	if self:get_level() ~= 1 then
		return
	end
	local hero = self.owner
	local skill = self
	--武器上创建特效
	self.eff = hero:add_effect('weapon', [[war3mapImported\magicreceive_red.mdx]])
	--监听伤害事件
	self.buff = hero:add_buff '飞焰'
	{
		skill = self,
	}
end

function mt:on_remove()
	if self.eff then self.eff:remove() end
	if self.buff then self.buff:remove() end
end

function mt:castFire(target)
	self:update_data()
	
	local hero = self.owner
	target:add_buff '红莲太刀'
	{
		source = hero,
		damage = self.damage2 + self.damage2_plus,
		skill = self,
		time = self.time,
	}
end

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local skill = self
	local damage = self.damage + self.damage_plus
	local n = 0
	local units = {}

	hero:timer(100, self.count, function ()
		angle = angle + math.random(10, 20) * (n % 2 - 0.5)
		n = n + 1
		local mvr = ac.mover.line
		{
			source = hero,
			model = [[tx9.mdl]],
			angle = angle,
			distance = self.distance,
			speed = self.speed,
			skill = self,
			hit_area = 120,
			size = 1,
			high = 0,
			cast_animation_speed = 0.1,
		}

		if mvr then
			function mvr:on_hit(target)
				if units[target] then
					return
				end
				units[target] = true

				--造成伤害
				target:damage
				{
					source = hero,
					damage = damage,
					skill = skill,
					attack = true,
				}
				--结算红莲太刀
				local buff = target:find_buff '红莲太刀'
				if buff then
					local damage = 0
					for _, dmg in ipairs(buff.damages) do
						damage = damage + dmg
					end
					target:damage
					{
						source = hero,
						damage = damage * buff.pulse,
						skill = buff.skill,
					}
					for _, u in ac.selector()
						: in_range(target, 200)
						: is_enemy(hero)
						: ipairs()
					do
						if u ~= target then
							u:damage
							{
								source = hero,
								damage = damage * 0.5,
								aoe = true,
								skill = buff.skill,
							}
						end
					end
					buff:remove()
				end
				return true
			end
		end
	end)
end


local mt = ac.orb_buff['飞焰']

function mt:on_hit(damage)
	if damage:is_skill() then
		return
	end
	self.skill:castFire(damage.target)
end

local mt = ac.dot_buff['红莲太刀']

mt.debuff = true

function mt:on_add()
	self.eff = self.target:add_effect('chest', [[Abilities\Spells\Other\BreathOfFire\BreathOfFireDamage.mdl]])
end

function mt:on_remove()
	self.eff:remove()
end

function mt:on_pulse(damage)
	self.target:damage
	{
		source = self.source,
		damage = damage * self.pulse,
		skill = self.skill,
	}
end
