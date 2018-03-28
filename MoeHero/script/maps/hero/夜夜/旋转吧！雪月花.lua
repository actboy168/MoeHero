local mt = ac.skill['旋转吧！雪月花']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[replaceabletextures\commandbuttons\BTNYayaR.blp]],
	title = '旋转吧！雪月花',
	tip = [[
夜夜开始高速旋转，持续%cast_channel_time%秒。旋转中的夜夜，每秒对周围的敌人造成%damage_base%(+%damage_plus%)伤害。碰到敌人时，敌人也会跟着夜夜一起旋转，持续%rotate_time%秒。
期间|cff11ccff忘却水月|r变为|cff11ccff月影红莲|r。
	]],
	cost = {100, 180},
	cool = 60,
	range = 9999,
	target_type = ac.skill.TARGET_TYPE_POINT,
	cast_animation = 'spell channel one',
	cast_channel_time = {6, 8, 10},
	damage_base = {60, 80, 100},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.4
	end,
	damage = function(self, hero)
		return self.damage_base + self.damage_plus
	end,
	rotate_time = {1.2, 1.5, 1.8},
	hit_area = 200,
	damage_area = 400,
	speed = 300,
	break_order = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	self.follows = {}
	local hits = {}
	self.on_mover_hit = function(mvr, target)
		if hits[target] then
			return
		end
		hits[target] = true
		local follow = hero:follow
		{
			source = hero,
			mover = target,
			angle = hero:get_point() / target:get_point(),
			distance = target:get_point() * hero:get_point(),
			skill = self,
			angle_speed = 500,
		}
		if not follow then
			return
		end
		table.insert(self.follows, follow)
		hero:wait(3000, function()
			follow:remove()
		end)
	end
	self.mvr = ac.mover.line
	{
		source = hero,
		mover = hero,
		target = self.target,
		speed = self.speed + hero:get '移动速度' * 0.5,
		skill = self,
		hit_area = self.hit_area,
	}
	if not self.mvr then
		self:stop()
		return
	end
	self.mvr.on_hit = self.on_mover_hit
	self.trg = hero:event '单位-发布指令' (function(_, _, order, target)
		if order ~= 'smart' then
			return
		end
		self.mvr:remove()
		self.mvr = ac.mover.line
		{
			source = hero,
			mover = hero,
			target = target,
			speed = self.speed + hero:get '移动速度' * 0.5,
			skill = self,
			hit_area = self.hit_area,
		}
		if not self.mvr then
			self:stop()
		end
		self.mvr.on_hit = self.on_mover_hit
		hero:set_facing(hero:get_point() / target)
	end)
	self.trg2 = hero:event '单位-即将获得状态' (function(_, _, buff)
		if buff:is_control() then
			return true
		end
	end)
	self.timer = hero:loop(1000, function()
		for _, u in ac.selector()
			: in_range(hero, self.damage_area)
			: is_enemy(hero)
			: of_hero()
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = self.damage,
				skill = self,
				aoe = true,
				attack = true,
			}
		end
		for _, u in ac.selector()
			: in_range(hero, self.damage_area)
			: is_enemy(hero)
			: of_not_hero()
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = self.damage,
				skill = self,
				aoe = true,
				attack = true,
			}
		end
	end)
	hero:replace_skill('忘却水月', '月影红莲')
end

function mt:on_cast_stop()
	local hero = self.owner
	self.mvr:remove()
	self.trg:remove()
	self.trg2:remove()
	self.timer:remove()
	for _, follow in ipairs(self.follows) do
		follow:remove()
	end
	hero:replace_skill('月影红莲', '忘却水月')
end
