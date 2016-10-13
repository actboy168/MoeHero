local mt = ac.skill['月影红莲']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNYayaRQ.blp]],
	title = '月影红莲',
	tip = [[
夜夜的高速旋转机动。
		]],

	instant = 1,
	cost = 30,
	cool = 3,
	range = 9999,
	max_distance = 700,
	min_distance = 300,
	target_type = ac.skill.TARGET_TYPE_POINT,
	speed = 2000,
	area = 200,
}

function mt:on_cast_channel()
	local hero = self.owner
	local master_skill = hero:find_cast '旋转吧！雪月花'
	if not master_skill then
		return
	end
	local target = self.target
	local distance =  math.max(self.min_distance, math.min(self.max_distance, hero:get_point() * target))
	self.eff = hero:add_effect("foot left", [[Abilities\Weapons\FaerieDragonMissile\FaerieDragonMissile.mdl]])
	hero:set_animation('spell channel two')

	local mover = ac.mover.line
	{
		source = hero,
		mover = hero,
		angle = hero:get_point() / target - 90,
		distance = distance * 3.14,
		speed = self.speed,
		skill = self,
		hit_area = self.area,
	}
	if not mover then
		return
	end
	self:set_option('passive', true)
	master_skill.mvr = mover
	master_skill.mvr.on_hit = master_skill.on_mover_hit
	local tick = mover.distance / mover.speed / 0.03
	function mover:on_move()
		self.angle = self.angle + 360 / tick
	end
	function mover:on_remove()
		self.skill:set_option('passive', false)
		local master_skill = hero:find_cast '旋转吧！雪月花'
		if master_skill then
			hero:set_animation('spell channel one')
		else
			hero:add_animation 'stand'
		end
	end
end

function mt:on_cast_stop()
	if self.eff then
		self.eff:remove()
	end
end
