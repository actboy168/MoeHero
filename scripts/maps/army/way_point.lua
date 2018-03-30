
local rect = require 'types.rect'
local region = require 'types.region'
local map = require 'maps.map'

function map.initWayPoint()
	--小兵进入拐弯点后向下个路径点移动
	for _, rct in ipairs {
		rect.j_rect 'army_l_2',
		rect.j_rect 'army_l_3',
		rect.j_rect 'army_r_2',
		rect.j_rect 'army_r_3',
	} do
		local way_region = region.create(rct)
		way_region:event '区域-进入' (function(self, unit)
			local rects = unit:get_data '移动路径'
			if not rects then
				return
			end

			--找到这是第几个路径
			for n, r in ipairs(rects) do
				if r == rct then
					local rct = rects[n + 1]
					if rct then
						unit:issue_order('attack', rct)
					end
					break
				end
			end
		end)
	end
end
