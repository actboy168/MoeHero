


local mt = ac.skill['终焉之剑']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[replaceabletextures\commandbuttons\BTNtonkaR.blp]],

	--技能说明
	title = '终焉之剑',
	
	tip = [[
击飞前方%hit_area%范围的敌人三次，造成%damage1%(+%damage_plus1%)伤害。随后对一条直线的敌人造成%damage2%(+%damage_plus2%)伤害。

|cffffff11施法时无敌。|r

|cff888888消耗全部怒气，每点怒气会提高0.3%伤害。|r
	]],

	--冷却
	cool = {160, 100},

	cost = 0,

	range = 9999,
	target_type = ac.skill.TARGET_TYPE_POINT,

	--动画
	cast_animation = 7,
	cast_start_time = 0.4,
	cast_shot_time = 2,
	cast_finish_time = 0.6,
 
	--伤害
	damage1 = {30, 60},
	damage_plus1 = function(self, hero)
		return hero:get_ad() * 0.5
	end,
	damage2 = {90, 180},
	damage_plus2 = function(self, hero)
		return hero:get_ad() * 1.5
	end,

	damage_distance = 1300,
	damage_width = 250,
	hit_area = 300,

	--触发系数
	proc = 0.8,
}

local function once_damage(self, hero, start, angle, damage, mark)
	for _, u in ac.selector()
		: in_range(start - {angle, 200}, self.hit_area)
		: is_enemy(hero)
		: ipairs()
	do
		u:add_buff '击退'
		{
			source = hero,
			angle = start / u:get_point(),
			speed = 100,
			distance = math.max(0, 300 - start * u:get_point()),
			accel = 1000,
			high = 100,
		}
		u:damage
		{
			source = hero,
			damage = damage,
			skill = self,
			aoe = true,
			attack = true,
		}
		if not mark[u] then
			mark[u] = true
			table.insert(mark, u)
		end
	end
end

function mt:on_cast_shot()
	local hero = self.owner
	local angle = hero:get_point() / self.target
	local start = hero:get_point()
	local damage1 = self.damage1 + self.damage_plus1
	local damage2 = self.damage2 + self.damage_plus2
	local mark = {}
	local fury = hero:get_resource '怒气'
	hero:add_resource('怒气', -fury)
	damage1 = damage1 * (1 + 0.003 * fury)
	damage2 = damage2 * (1 + 0.003 * fury)

	hero:add_restriction '无敌'
	once_damage(self, hero, start, angle, damage1, mark)
	hero:wait(500, function()
		local start = start - {angle, 100}
		once_damage(self, hero, start, angle, damage1, mark)
		hero:wait(500, function()
			local start = start - {angle, 200}
			once_damage(self, hero, start, angle, damage1, mark)
			hero:wait(500, function()
				for _, u in ac.selector()
					: in_line(hero, angle, self.damage_distance, self.damage_width)
					: is_enemy(hero)
					: ipairs()
				do
					u:damage
					{
						source = hero,
						damage = damage2,
						skill = self,
						aoe = true,
						attack = true,
					}
					mark[u] = nil
				end
				for _, u in ipairs(mark) do
					if mark[u] then
						u:damage
						{
							source = hero,
							damage = damage2,
							skill = self,
							aoe = true,
							attack = true,
						}
					end
				end
			end)
		end)
	end)
end

function mt:on_cast_finish()
	local hero = self.owner
	hero:remove_restriction '无敌'
end
