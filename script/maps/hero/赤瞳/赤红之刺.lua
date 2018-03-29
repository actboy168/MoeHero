local mt = ac.skill['赤红之刺']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNctq.blp]],

	--技能说明
	title = '赤红之刺',
	
	tip = [[
击晕并降低目标%defence_rate%%护甲，持续%stun%秒，随后造成%damage%(+%damage_plus%)伤害
		]],

	--耗蓝
	cost = 80,

	--冷却
	cool = 11,

	--施法距离
	range = 500,

	--施法动画
	cast_animation = 5,

	--该动画不能被跳过
	important_animation = true,

	--施法前摇
	cast_start_time = 0.2,

	--引导时间
	cast_channel_time = 10,

	--打断
	break_cast_channel = 0,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--眩晕时间
	stun = 1.5,

	--伤害
	damage = {80, 160},
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
	defence_rate = {8, 12},

	break_order = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target
	local skill = self
	local dmin = 40
	local distance = math.max(hero:get_point() * target:get_point() - dmin,dmin)

	hero:set_animation_speed(0.3)
	self.mvr = ac.mover.line
	{
		source = hero,
		target = target,
		mover = hero,
		speed = distance / 5 * 33,
		skill = self,
		accel = 200,
		distance = distance,
		angle = hero:get_point() / target:get_point(),
	}
	if not self.mvr then
		skill:stop()
		return
	end
	function self.mvr:on_move()
		local count = math.max(5 - self.move_count, 1)
		self.speed = (hero:get_point() * target:get_point() - dmin ) / count * 33
		if count == 1 then
			self:remove()
		end
	end
	function self.mvr:on_remove()
		target:add_buff '晕眩'
		{
			source = hero,
			skill = self.skill,
			time = self.skill.stun,
		}
		target:add_buff '赤红之刺'
		{
			source = hero,
			time = self.skill.stun,
			defence_rate = self.skill.defence_rate,
		}

		hero:set_animation_speed(1.7)
		self.mvr = ac.mover.line
		{
			source = hero,
			start = hero,
			mover = hero,
			speed = 800,
			skill = self,
			accel = 10,

			angle = target:get_point() / hero:get_point(),
			distance = 550,
			speed = 600,
			height = 400,
		}
		if not self.mvr then
			skill:stop()
			return
		end
		function self.mvr:on_remove()
			hero:set_animation(6)
			hero:set_animation_speed(0.05)
			self.mvr = ac.mover.target
			{
				source = hero,
				mover = hero,
				target = target,
				speed = 3000,
				accel = 10,
				skill = skill,
			}
			if not self.mvr then
				skill:stop()
				return
			end
			function self.mvr:on_remove()
				if target:is_alive() then
					target:damage
					{
						source = hero,
						damage = skill.damage + skill.damage_plus,
						skill = skill,
						attack = true,
					}
					target:add_effect("origin",[[bloodex-special-2 (4).mdl]]):remove()
				end
				hero:set_animation_speed(1)
				hero:issue_order('attack',target)
				skill:finish()
			end
		end
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	hero:set_animation_speed(1)
	self.mvr:remove()
end

local mt = ac.buff['赤红之刺']

mt.cover_type = 1
mt.debuff = true
mt.eff = nil
mt.defence = 0
mt.defence_rate = 0

function mt:on_add()
	self.eff = self.target:add_effect('head', [[modeldekan\ability\dekan_Akame_E_buff.mdl]])
	self.target:add('护甲', - self.defence)
	self.target:add('护甲%', - self.defence_rate)
end

function mt:on_remove()
	self.eff:remove()
	self.target:add('护甲', self.defence)
	self.target:add('护甲%', self.defence_rate)
end
