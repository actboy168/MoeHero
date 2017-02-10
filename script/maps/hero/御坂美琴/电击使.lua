local mt = ac.skill['电击使']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNpjw.blp]],

	--技能说明
	title = '电击使',

	tip = [[
从刘海射出放电对最多%max_targets%个敌方单位造成%damage%(+%damage_plus%)伤害，眩晕%stun_time%秒。
并为这些单位添加|cff11ccff电磁牵引|r状态。
	]],
	
	--前摇
	cast_start_time = 0.3,

	--施法距离
	range = 650,

	--冷却
	cool = 10,

	--耗蓝
	cost = {80, 60},

	--目标类型
	target_type = mt.TARGET_TYPE_POINT,

	--技能范围
	area = 350,

	--伤害
	damage = {100, 340},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 2
	end,

	--晕眩
	stun_time = 0.1,

	--最大目标
	max_targets = 5,

	--分散伤害(%)
	damage_sub = 10,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target

	--创建一个光束
	local ln = ac.lightning('CLPB', hero, target, 175, 0)
	target:add_effect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]]):remove()
	hero:wait(400, function()
		ln:remove()
	end)

	--搜寻区域内的单位
	local count = 0
	local group = ac.selector()
		: in_range(target, self.area)
		: is_enemy(hero)
		: sort_nearest_hero(target)
		: get()
	if #group == 0 then
		return
	end
	while #group > self.max_targets do
		table.remove(group)
	end

	--计算伤害
	local dmg = self.damage + self.damage_plus
	dmg = dmg * (1 - (#group - 1) * self.damage_sub / 100)

	--添加Q技能Buff
	local skl = hero:find_skill '电磁牵引'
	if skl and skl:is_enable() then
		skl:update_data()
		for _, u in ipairs(group) do
			skl:add_unit_buff(u)
		end
	end

	--造成伤害
	for _, u in ipairs(group) do
		local light_1 = ac.lightning('CLPB', hero, u, 175, 175)
		local light_2 = ac.lightning('CLPB', u, target, 175, 0)
		light_1:fade(-5)
		light_2:fade(-5)
		u:add_effect('origin',[[Abilities\Weapons\Bolt\BoltImpact.mdl]]):remove()
		u:add_buff '晕眩'
		{
			source = hero,
			time = self.stun_time,
		}
		
		u:damage
		{
			source = hero,
			damage = dmg,
			skill = self,
			aoe = true,
			attack = true,
		}

		hero:wait(400, function()
			light_1:remove()
			light_2:remove()
		end)
	end
end
