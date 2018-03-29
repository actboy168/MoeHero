
	local mover = require 'types.mover'
	local math = math

	--目标运动
		mover.target = {}
		setmetatable(mover.target, mover.target)

		--结构
		mover.target.__index = {
			--类型
			mover_type = 'target',

			--判定距离
			hit_range = nil,

			--转身速度限制
			turn_speed = 99999,

			--检查是否击中目标
			checkHit = function(self)
				local hit_range = self.target.type == 'unit' and self.target:get_selected_radius() or 0
				if self.distance < hit_range + (self.hit_range or self.speed * mover.FRAME * self.time_scale) then
					local p = self.target:get_point()
					self.mover:set_position(p - {p / self.mover:get_point(), hit_range}, not self.block, self.super)
					if self.target.owner then
						self.target = self.target
						if self:isMissile() and self.target:event_dispatch('单位-即将被投射物击中', self.target, self) then
							self:remove()
							return
						end
					end
					mover.on_finish(self)
				end
			end,

			--每个周期的运动
			next = function(self)
				
				local speed = self.speed * self.time_scale * mover.FRAME
				local p1, p2 = self.mover:get_point(), self.target:get_point()
				self.distance = p1 * p2
				local target_angle = p1 / p2

				--检查转身速度限制
				local turn_speed = self.turn_speed * self.time_scale * mover.FRAME
				if ac.math_angle(target_angle, self.angle) <= turn_speed then
					self.angle = target_angle
				else
					if ac.math_angle(target_angle, self.angle + turn_speed) < ac.math_angle(target_angle, self.angle - turn_speed) then
						self.angle = self.angle + turn_speed
					else
						self.angle = self.angle - turn_speed
					end
				end

				if self.missile and self.angle then
					self.mover:set_facing(self.angle + self.off_angle)
				end
				
				--向前位移
				self.next_point = p1 - {self.angle, speed}
			end,

			create = function(self)
				if not self.angle then
					self.angle = self.start:get_point() / self.target:get_point()
				end
				if not self.target_high then
					if self.target.type == 'unit' then
						self.target_high = self.target:get_size() * math.random(0, self.target:get_slk('impactZ', 0))
					else
						self.target_high = 0
					end
				end
				self.distance = self.start:get_point() * self.target:get_point()
				if not self.path and not self.on_block then
					self.path = true
				end
				return self
			end,
			
		}

		setmetatable(mover.target.__index, mover)
