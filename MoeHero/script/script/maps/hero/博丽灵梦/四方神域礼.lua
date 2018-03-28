local mt = ac.skill['四方神域礼']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNlmw.blp]],

	--技能说明
	title = '四方神域礼',
	
	tip = [[
投掷组成结界抵挡敌方弹道，持续%time%秒。
撞向结界的单位受到%damage%(+%damage_plus%)伤害并定身%buff_time%秒。
	]],

	--冷却
	cool = 12,

	--消耗
	cost = {90, 110},

	--施法距离
	range = 800,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--施法前摇和动作等
	cast_finish_time = 0.5,

	cast_animation = 3,

	--礼符飞行速度
	speed = 1000,

	--生效延迟
	delay = 0.5,

	--宽度
	len = 350,

	--伤害
	damage = {40, 140},

	damage_plus = function(self, hero)
		return hero:get_ad() * 0.7
	end,

	--定身
	buff_time = 1,

	--持续时间
	time = 6,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local len = self.len
	local area = len / 2
	local p0 = hero:get_point()
	local angle = p0 / target
	local speed = self.speed
	local buff_time = self.buff_time
	local damage = self.damage + self.damage_plus

	--求弹幕发射点
	local start = p0 - {angle, 40}

	--先求2个投影点
	local points = {}
	points[1] = target - {angle - 90, area}
	points[2] = target - {angle + 90, area}

	--弹幕运动全部结束后创建符卡
	local count = 4
	local onEffect
	local function on_finish()
		count = count - 1
		if count == 0 then
			onEffect()
		end
	end

	--创建弹幕运动
	for x = 1, 2 do
		local p = points[x]

		local mvr = ac.mover.line
		{
			source = hero,
			start = start,
			model = [[fu.mdl]],
			speed = speed,
			angle = start / p,
			distance = start * p,
			high = 110,
			target_high = 0,
			on_finish = on_finish,

			skill = self,
		}

		local mvr = ac.mover.line
		{
			source = hero,
			start = start,
			model = [[fu.mdl]],
			speed = speed,
			angle = start / p,
			distance = start * p,
			high = 110,
			target_high = 120,
			on_finish = on_finish,

			skill = self,
		}
	end

	--阻挡生效
	function onEffect()
		--在目标地点创建马甲
		local dummy = hero:get_owner():create_dummy('e007', target, angle + 90)
		dummy:set_size(12)
		dummy:set_high(100)
		dummy:set_class '马甲'
		dummy:add_restriction '硬直'
		dummy:add_restriction '无敌'

		--墙体参数
		local start = points[1] 			--射线起点
		local angle = points[1] / points[2]	--射线角度

		--创建一条直线的碰撞
		local blocks = {}
		local max = 5
		for i = 0, max do
			local p = start - {angle, len / max * i}
			local block = hero:create_block
			{
				area = len / max,
				point = p,
			}

			table.insert(blocks, block)

			function block:on_entry(mover)
				if mover.missile and mover.source and mover.source:is_enemy(hero) then
					if mover.source:is_type('建筑') then
						return
					end
					return true
				end
			end
		end

		--周期选取附近单位,判断是否和墙发生了碰撞
		local unit_mark = {}
		local timer = dummy:loop(100, function()
			--进行直线选取
			for _, u in ac.selector()
				: in_line(start, angle, len, 50)
				: is_enemy(hero)
				: ipairs()
			do
				if not unit_mark[u] then
					unit_mark[u] = true

					--造成伤害并定身
					u:add_buff '定身'
					{
						source = hero,
						time = buff_time,
					}

					u:damage
					{
						source = hero,
						damage = damage,
						skill = self,
						aoe = true,
						attack = true,
					}

					u:add_effect('chest', [[Abilities\Weapons\SpiritOfVengeanceMissile\SpiritOfVengeanceMissile.mdl]]):remove()
				end
			end
		end)
		timer:on_timer()
		dummy:wait(self.time * 1000, function()
			dummy:remove()
			timer:remove()
			for _, block in ipairs(blocks) do
				block:remove()
			end
		end)
	end
end
