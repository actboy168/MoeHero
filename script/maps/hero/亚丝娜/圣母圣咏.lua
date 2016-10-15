local mt = ac.skill['圣母圣咏']

mt{
	--初始等级
	level = 0,
	--最大等级
	max_level = 3,
	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[BTNasnr.blp]],

	--技能说明
	title = '圣母圣咏',
	
	tip = [[
获得绝剑的力量，十一连击，每击造成%damage%(+%damage_plus%)点伤害。
	]],

	--冷却
	cool = {120, 100, 80},
	--消耗
	cost = 120,
	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,
	--施法距离
	range = 600,
	--施法动画
	cast_animation = 'attack',
	--施法前摇
	cast_start_time = 0.2,
	cast_channel_time = 10,
	--斩击次数
	count = 11,
	--伤害
	damage = {40, 60, 80},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.8
	end,
	--冲锋速度（初始速度）
	speed = 1200,
	--穿越到背后的距离
	distance = 200,
	--随机选择的范围
	attack_area = 400,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local speed = self.speed
	local damage = self.damage + self.damage_plus
	local distance = self.distance
	local count = self.count
	local attack_area = self.attack_area
	local w_skill = hero:find_skill '狂暴补师'
	hero:add_restriction '无敌'
	hero:add_restriction '阿卡林'
	local mark  = {}
	local function attack_one(start, target)
		if not target then
			self:finish()
			return
		end
		local angle = hero:get_point() / target:get_point() + math.random(5,10) * -1^math.random(1,2)
		local dummy = hero:create_dummy(nil, start, angle)
		dummy:set_class '幻象'
		dummy:add_restriction '缴械'
		dummy:set_animation('attack')
		dummy:set_animation_speed(5)
		dummy:set('生命上限', hero:get '生命上限')
		dummy:set('生命', hero:get '生命')
		dummy.eff = dummy:add_effect('weapon',[[model\asuna\r_sprintribbon.mdl]])
		hero:wait(100, function()
			dummy:set_animation_speed(0.4)
		end)
		local mvr = ac.mover.line
		{
			source = hero,
			mover = dummy,
			speed = speed,
			accel = 18000,
			angle = angle,
			distance = distance + dummy:get_point() * target:get_point(),
			hit_area = 150,
			skill = self,
		}
		if not mvr then
			dummy:remove()
			self:finish()
			return
		end
		function mvr:on_hit(u)
			if not mark[u] then
				mark[u] = 0
			end
			local rate = 1 - 0.08 * mark[u]
			if target == u then
				mark[u] = mark[u] + 1
				u:damage
				{
					source = hero,
					damage = damage * rate,
					skill = self.skill,
					attack = true,
				}
			else
				mark[u] = mark[u] + 0.5
				u:damage
				{
					source = hero,
					damage = damage * rate * 0.5,
					skill = self.skill,
					attack = true,
					aoe = true,
				}
			end
			u:add_effect('chest', [[model\asuna\r_hit.mdl]]):remove()
		end
		function mvr:on_move()
			hero:setPoint(dummy:get_point())
		end
		function mvr:on_remove()
			dummy.eff:remove()
			if w_skill then
				w_skill:on_hit()
			end
			count = count - 1
			if count <= 0 then
				dummy:remove()
				self.skill:finish()
				return
			end
			dummy:set_class '马甲'
			dummy:add_buff '淡化'
			{
				time = 0.4,
			}
			attack_one(dummy:get_point(), ac.selector():in_range(target, attack_area):is_enemy(hero):random())
		end
	end
	attack_one(hero:get_point(), self.target)
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:remove_restriction '阿卡林'
	hero:remove_restriction '无敌'
end
