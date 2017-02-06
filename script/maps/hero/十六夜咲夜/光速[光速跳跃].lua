local mt = ac.skill['光速[光速跳跃]']

mt{
	--范围
	area = 350,

	--重复伤害
	damage_rate = 15,
		
	--弹道速度
	speed = 2000,

	--角度差
	angle = 17.5,

	--最大飞行距离
	distance = 900,

	--飞行距离
	distance = 800,

	--自由碰撞时的碰撞半径
	hit_area = 100,
}

mt.passive = true
mt.level = 1

local function block_tangent(poi, angle)
	local poi_a
	local poi_b
	for d = 10, 360, 10 do
		local p = poi - {angle + d, 32}
		if p:is_block() then
			poi_a = p
			break
		end
	end
	for d = 10, 360, 10 do
		local p = poi - {angle - d, 32}
		if p:is_block() then
			poi_b = p
			break
		end
	end
	if not poi_a or not poi_b then
		print('#1', angle, poi:get())
		return angle + 90
	end
	return poi_b / poi_a
end

local function create_knife(tbl)
	local block_count = 1
	if tbl.has_q then
		block_count = block_count + tbl.has_q.count
	end
	local mvr = ac.mover.line
	{
		source = tbl.source,
		start = tbl.start,
		id = 'e00E',
		angle = tbl.angle,
		speed = tbl.speed,
		distance = tbl.distance,
		high = 110,
		skill = tbl.skill,
		damage = tbl.damage,
		hit_area = 100,
		size = tbl.size,
		block_count = block_count,
		mark = tbl.mark,
		has_q = tbl.has_q,
		has_e = tbl.has_e,
		block = true,
	}
	if not mvr then
		return
	end
	if tbl.has_e then
		mvr.mover:setColor(100,20,20)
	end
	function mvr:on_hit(target)
		if not self.mark[target] then
			self.mark[target] = true
			target:damage
			{
				source = self.source,
				damage = self.damage,
				skill = self.skill,
				missile = self.mover,
				attack = true,
				aoe = true,
			}
			if self.has_q and self.block_count > 0 then
				self.block_count = self.block_count - 1
				self.distance = self.distance + 1000
				return
			end
			return true
		else
			target:damage
			{
				source = self.source,
				damage = self.damage * 0.15,
				skill = self.skill,
				missile = self.mover,
				attack = true,
				aoe = true,
			}
			return
		end
	end
	function mvr:on_block()
		if self.block_count <= 0 then
			return true
		end
		self.block_count = self.block_count - 1
		local tangent = block_tangent(self.next_point, self.angle + 180)
		local poi = self.mover:get_point()
		self.angle = 2 * tangent - self.angle
		self.distance = self.distance + 1000
		self.mover:remove()
		self.mover = self.source:create_dummy('e00E', poi, self.angle)
		if self.has_e then
			self.mover:setColor(100,20,20)
		end
		self.hited_units = nil
	end
	function mvr:on_remove()
		self.mover:remove()
	end
	return mvr
end

function mt:on_add()
	local function range_attack_start(hero, damage)
		if damage.skill and damage.skill.name == self.name then
			return
		end
		local target = damage.target:get_point()
		local damage = damage.damage
		local damage_rate = self.damage_rate / 100
		local unit_mark = {}
        local cast = self:create_cast()
		
		local angle = hero:get_point() / target
		for i = -2, 2 do
			local mvr = ac.mover.line
			{
				source = hero,
				start = hero:get_point() - { angle + i * self.angle, 100 },
				id = 'e00E',
				speed = self.speed,
				angle = angle + i * 7,
				distance = self.distance,
				high = 110,
				skill = cast,
				damage = damage,
				hit_area = self.hit_area,
				size = 0.8,
			}
			if mvr then
				function mvr:on_hit(dest)
					if not unit_mark[dest] then
						unit_mark[dest] = true
						dest:damage
						{
							source = hero,
							damage = damage,
							skill = self.skill,
							missile = self.mover,
							attack = true,
							common_attack = true,
						}
						return true
					else
						dest:damage
						{
							source = hero,
							damage = damage * damage_rate,
							skill = self.skill,
							missile = self.mover,
							attack = true,
						}
						return
					end
				end
				function mvr:on_remove()
					self.mover:remove()
				end
				mvr:pause(true)
				hero:wait(500, function ()
					mvr:pause(false)
				end)
			end
		end
	end
	local hero = self.owner
	self.oldfunc = hero.range_attack_start
	hero.range_attack_start = range_attack_start
end

function mt:on_remove()
	local hero = self.owner
	hero.range_attack_start = self.oldfunc
end

return create_knife
