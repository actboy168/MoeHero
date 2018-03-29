local towers = require 'maps.tower.init_tower'
local player = require 'ac.player'

local function create_jiecao(hero, source, team, where)
	local start = where or hero:get_point()
	local start =start:findMoveablePoint() or start
	local model
	local team = team or hero:get_owner():get_team()
	if team == 1 then
		model = [[ball_blue.mdl]]
	else
		model = [[ball_yellow_weak.mdl]]
	end

	local source = source and source:get_owner().hero
	if not source then
		return
	end
	local lv = hero:is_hero() and hero:get_level() or source:get_level()
	
	--创建一个光球
	local mvr = ac.mover.target
	{
		source = hero,
		start = start,
		target = ac.point(99999, 99999),
		skill = false,
		model = model,
		size = 5,
		hit_area = 300,
		speed = 0,
		damage = lv * 300,
		target_high = 100,
		height = 200,
		turn_speed = 360,
		high = 50,
	}

	if not mvr then
		return
	end

	local function find_target(self)
		local p0 = self.mover:get_point()
		local target = nil
		local distance = 999999
		for _, u in pairs(towers) do
			if not u:has_restriction '无敌' and u:is_enemy(source) then
				local dis = u:get_point() * p0
				if dis < distance then
					distance = dis
					target = u
				end
			end
		end
		if not target then
			if not poi.game_over then
				log.error('节操没有找到任何可攻击的防御塔')
			end
			return true
		end

		self.target = target
		--一个初始运动
		local p = self.mover:get_point():copy()
		local around = ac.mover.target
		{
			source = hero,
			speed = 1000,
			target = p,
			turn_speed = 720,
			skill = false,
			mover = self.mover,
			hit_range = -99999,
			high = 50,
			target_high = 50,
		}

		if not mvr then
			return
		end

		function around:on_move()
			--print('on_move', self.turn_speed)
			self.turn_speed = self.turn_speed - 6
			if self.turn_speed <= 360 then
				self:remove()
			end
		end

		function around:on_remove()
			--print('on_remove')
			mvr.speed = 750
			mvr.max_speed = 750
			mvr.angle = self.angle
			player.self:pingMinimap(mvr.target, 10, 255, 0, 0, true)
		end

		function mvr:on_finish()
			--如果目标已经死了,重新找一个
			if not self.target:is_alive() then
				find_target(self)
				return true
			end
			self.target:damage
			{
				source = self.source,
				damage = self.damage,
				skill = false,
			}
			self.mover:add_effect('origin', [[Abilities\Spells\Items\StaffOfPurification\PurificationCaster.mdl]]):remove()
			self.mover:kill()
		end
	end

	function mvr:on_hit(dest)
		if not dest:is_hero() then
			return
		end
		self.on_hit = nil
		self.source = dest
		self.mover:shareVisible(dest:get_owner())
		self.mover:addSight(600)
		find_target(self)
	end

	

	mvr.mover:addSight(900)
	mvr.missile = false
end

ac.game:event '玩家-注册英雄' (function(_, _, hero)
	hero:event '单位-死亡' (function(_, _, source)
		create_jiecao(hero, source)
	end)
end)

return create_jiecao
