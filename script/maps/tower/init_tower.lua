local rect = require 'types.rect'
local table = table

local towers = {}

--初始化
ac.wait(0, function()
	for team_id, team in ipairs{'A', 'B'} do
		--基地
		local rect_name = ('tower_%s_base'):format(team)
		for _, u in ac.selector()
			: in_range(rect.j_rect(rect_name), 100)
			: of_building()
			: ipairs()
		do
			towers[rect_name] = u
			u.building_name = rect_name
			u:add_restriction '无敌'
			u.binding_count = 2
		end
		--基地塔
		for count = 1, 2 do
			local rect_name = ('tower_%s_h_%s'):format(team, count)
			for _, u in ac.selector()
				: in_range(rect.j_rect(rect_name), 100)
				: of_building()
				: ipairs()
			do
				towers[rect_name] = u
				u.building_name = rect_name
				u:add_restriction '无敌'
				u.binding_count = 1
				u.binding_buildings = {}
				table.insert(u.binding_buildings, towers[('tower_%s_base'):format(team)])
			end
		end
		--1/2/3塔
		for road in ('lmr'):gmatch('.') do
			for count = 3, 1, -1 do
				local rect_name = ('tower_%s_%s_%s'):format(team, road, count)
				for _, u in ac.selector()
					: in_range(rect.j_rect(rect_name), 100)
					: of_building()
					: ipairs()
				do
					towers[rect_name] = u
					u.building_name = rect_name
					if count >= 2 then
						u.binding_count = 1
						u:add_restriction '无敌'
					end
					if count == 3 then
					end
					if count < 3 then
						u.binding_buildings = {}
						table.insert(u.binding_buildings, towers[('tower_%s_%s_%s'):format(team, road, count + 1)])
					else
						u.binding_buildings = {}
						table.insert(u.binding_buildings, towers[('tower_%s_h_1'):format(team)])
						table.insert(u.binding_buildings, towers[('tower_%s_h_2'):format(team)])
					end
				end
			end
		end
	end
end)

ac.game:event '单位-死亡' (function(trg, u, source)
	if not u:is_type('建筑') then
		return
	end
	if u.building_name then
		towers[u.building_name] = nil
	end
	if u.binding_buildings then
		for _, dest in ipairs(u.binding_buildings) do
			if dest.binding_count then
				dest.binding_count = dest.binding_count - 1
				if dest.binding_count == 0 then
					dest:remove_restriction '无敌'
				end
			end
		end
	end
end)

return towers
