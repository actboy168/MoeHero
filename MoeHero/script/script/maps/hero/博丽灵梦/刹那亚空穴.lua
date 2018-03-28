


local math = math

local mt = ac.skill['刹那亚空穴']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNlme.blp]],

	--技能说明
	title = '刹那亚空穴',
	
	tip = [[
瞬移到目标位置，在接下来%buff_time%秒内受到伤害时无敌%god_time%秒并触发|cff11ccff封魔针|r

再次按下技能可主动触发|cff11ccff封魔针|r

|cff11ccff封魔针|r
瞬移回原来的位置
释放%count_x%x%count_y%枚封魔针,造成%damage%(+%damage_plus%)点伤害
	]],

	--冷却
	cool = {27, 15},

	--耗蓝
	cost = 120,

	--瞬发
	instant = 1,

	--施法距离
	range = 9999,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--最大距离
	max_range = 400,

	--分身保护时间
	buff_time = 3,

	--无敌时间
	god_time = 0.33,

	--封魔针数量
	count_y = 4,
	
	count_x = 5,

	--封魔针飞行速度
	speed = 1200,

	--封魔针的伤害
	damage = {2, 10},

	damage_plus = function(self, hero)
		return hero:get_ad() * 0.18
	end,

	--最大飞行距离
	distance = 800,

	--碰撞半径
	hit_area = 100,

	--主动使用时,搜索目标的范围
	find_area = 600,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local distance = math.min(hero:get_point() * target, self.distance)
	local speed = self.speed
	local damage = (self.damage + self.damage_plus)
	local hit_area = self.hit_area
	local target = hero:get_point() - { angle, distance}
	local skill = self
	
	hero:blink(target, true)

	--创建一个指示器
	local mvr = hero:follow
	{
		source = hero,
		angle = angle,
		distance = -distance,
		model = [[reimu04.mdl]],
		skill = self,
		size = 0.2
	}

	--触发封魔针
	local function callback(dest)
		--传送一小段距离
		local p = hero:get_point()
		p:add_effect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]]):remove()
		
		local p = p - { angle, -distance}
		hero:add_effect('origin', [[Abilities\Spells\NightElf\Blink\BlinkTarget.mdl]]):remove()
		
		hero:blink(p, true)
		
		--添加Hard
		hero:add_restriction '硬直'
		hero:wait(self.god_time * 1000, function()
			hero:remove_restriction '硬直'
		end)

		--如果没有给定目标,则搜索一个目标
		if not dest then
			local group = ac.selector()
				: in_range(hero, self.find_area)
				: is_enemy(hero)
				: sort_nearest_hero(hero)
				: get()
			if #group == 0 then
				dest = target
			else
				dest = group[1]
			end
		end

		--转向目标,并播动画
		local angle = hero:get_point() / dest:get_point()
		hero:set_facing(angle)
		hero:set_animation(3)

		local count_x = self.count_x
		local count_y = self.count_y
		hero:timer(self.god_time / self.count_y * 3, self.count_y, function()
			for i = 1, skill.count_x do
				local mvr = ac.mover.line
				{
					source = hero,
					start = hero:get_point() - { 90 + angle, (i - 0.5 - skill.count_x / 2) * 50 } - { angle, math.abs(skill.count_x / 2 + 0.5 - i) * -50 },
					angle = angle,
					model = [[Abilities\Spells\Other\HealingSpray\HealBottleMissile.mdl]],
					size = 0.5,
					speed = speed,
					distance = skill.distance,
					damage = damage,
					skill = skill,
					high = 110,
					hit_area = hit_area,
				}
				if not mvr then
					return
				end
				function mvr:on_hit(dest)
					dest:damage
					{
						source = self.source,
						damage = damage,
						skill = self.skill,
						missile = self.mover,
						attack = true,
					}
					return true
				end
			end
		end)
	end

	--添加Buff
	hero:add_buff '刹那亚空穴-保护'
	{
		time = self.buff_time,
		god_time = self.god_time,
		callback = callback,
		mvr = mvr,
	}
end

local mt = ac.skill['封魔针']

mt{
	art = [[BTNlme.blp]],
}

function mt:on_cast_channel()
	local hero = self.owner
	local bff = hero:find_buff '刹那亚空穴-保护'

	if bff then
		bff:onEffect()
	end
end


local mt = ac.buff['刹那亚空穴-保护']

mt.trg = nil

function mt:on_add()
	local hero = self.target
	self.trg = hero:event '受到伤害开始' (function(trg, damage)
		hero:add_buff '刹那亚空穴-免疫伤害'
		{
			time = self.god_time
		}
		self:onEffect(damage.source)
		return true
	end)
	--切换技能
	hero:replace_skill('刹那亚空穴', '封魔针')
end

function mt:on_remove()
	local hero = self.target
	self.trg:remove()
	if self.mvr then
		self.mvr:remove()
	end
	hero:replace_skill('封魔针', '刹那亚空穴')
end

function mt:onEffect(dest)
	self:remove()
	--回调
	self.callback(dest)
end

local mt = ac.buff['刹那亚空穴-免疫伤害']

mt.cover_type = 1
mt.cover_max = 1

function mt:on_add()
	self.trg = self.target:event '受到伤害开始' (function()
		return true
	end)
end

function mt:on_remove()
	self.trg:remove()
end
