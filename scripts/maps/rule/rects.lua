
local rect = require 'types.rect'
local map = require 'maps.map'
local region = require 'types.region'
local slk = require 'jass.slk'
local jass = require 'jass.common'
local player = require 'ac.player'
local fogmodifier = require 'types.fogmodifier'

local effect = require 'types.effect'

map.rects = {}

--选人区域
map.rects['选人区域'] = rect.j_rect 'choose_hero'

--刷兵区域
map.rects['刷兵区域'] = {}
	map.rects['刷兵区域']['沉沦遗迹'] = {}
		map.rects['刷兵区域']['沉沦遗迹']['上路'] = {
			rect.j_rect 'army_l_1',
			rect.j_rect 'army_l_2',
			rect.j_rect 'army_l_3',
			rect.j_rect 'army_l_4',
		}
		map.rects['刷兵区域']['沉沦遗迹']['中路'] = {
			rect.j_rect 'army_m_1',
			rect.j_rect 'army_m_2',
		}
		map.rects['刷兵区域']['沉沦遗迹']['下路'] = {
			rect.j_rect 'army_r_1',
			rect.j_rect 'army_r_2',
			rect.j_rect 'army_r_3',
			rect.j_rect 'army_r_4',
		}
	map.rects['刷兵区域']['幻想神社'] = {}
		map.rects['刷兵区域']['幻想神社']['上路'] = {
			rect.j_rect 'army_l_4',
			rect.j_rect 'army_l_3',
			rect.j_rect 'army_l_2',
			rect.j_rect 'army_l_1',
		}
		map.rects['刷兵区域']['幻想神社']['中路'] = {
			rect.j_rect 'army_m_2',
			rect.j_rect 'army_m_1',
		}
		map.rects['刷兵区域']['幻想神社']['下路'] = {
			rect.j_rect 'army_r_4',
			rect.j_rect 'army_r_3',
			rect.j_rect 'army_r_2',
			rect.j_rect 'army_r_1',
		}

--英雄出生点
map.rects['出生点'] = {
	rect.j_rect 'player_home_1',
	rect.j_rect 'player_home_2',
}

--全地图
map.rects['全地图'] = rect.create(-6000, -6000, 6000, 6000)

--注册不可通行区域
--point.path_region = region.create()

function map.pathRegionInit()
	jass.EnumDestructablesInRect(jass.Rect(-8192, -8192, 8192, 8192), nil, function()
		local dstrct = jass.GetEnumDestructable()
		local id = jass.GetDestructableTypeId(dstrct)
		if tonumber(slk.destructable[id].walkable) == 1 then
			return
		end
		local x0, y0 = jass.GetDestructableX(dstrct), jass.GetDestructableY(dstrct)
		
		--将附近的区域加入不可通行区域
		--local rng = 64
		--point.path_region = point.path_region + rect.create(x - rng, y - rng, x + rng, y + rng)
		local fly = false
		if id == base.string2id 'YTfb' then
			fly = true
		end
		--关闭附近的通行
		for x = x0 - 64, x0 + 64, 32 do
			for y = y0 - 64, y0 + 64, 32 do
				jass.SetTerrainPathable(x, y, 1, false)
				if fly then
					jass.SetTerrainPathable(x, y, 2, false)
				end
			end
		end
		
	end)
end

--禁用边界渲染
jass.EnableWorldFogBoundary(false)
--在天空处创建视野修整器
for i = 1, 2 do
	local p = player.com[i]
	for x = 1, 4 do
		fogmodifier.create(p, rect.j_rect('air_visible_' .. x))
	end
end
--出地图者死
local out_reg = region.create()
for x = 1, 4 do
	out_reg = out_reg + rect.j_rect('air_visible_' .. x)
end

out_reg:event '区域-进入' (function(trg, hero)
	if hero:is_hero() and not hero.out_map_dying then
		--标记已经在死了
		hero.out_map_dying = true
		--附近找个地方
		local p = hero:get_point() - {hero:get_facing() + math.random(-60, 60), math.random(800, 1000)}
		--创建一个黑洞
		local eff = ac.effect(p, [[cosmic field_65.mdl]])
		eff.unit:set_size(1)
		eff.unit:shareVisible(hero:get_owner())
		eff.unit:addSight(400)

		local mvr = ac.mover.target
		{
			source = eff.unit,
			mover = hero,
			start = hero,
			target = eff.unit,
			speed = 0,
			accel = 100,
			skill = false,
			super = true,
		}

		local function kill()
			hero:add_buff '晕眩'
			{
				source = hero,
				time = 1,
			}
			hero:set_animation('death')
			local count = 45
			ac.loop(20, function(t)
				if count <= 0 then
					hero:kill()
					eff:remove()
					hero.out_map_dying = false
					hero:set_size(1)
					hero:set_high(0)
					if not hero:is_alive() then
						hero:add_restriction '阿卡林'
						hero:event '单位-复活' (function(trg)
							trg:remove()
							hero:remove_restriction '阿卡林'
						end)
					end
					t:remove()
					return
				end
				count = count - 1
				hero:set_size(0.022*count)
				hero:set_high(135-3*count)
				hero:blink(p,true,true)
				if count == 15 then
					ac.effect(p, [[shadowexplosion.mdl]]):remove()
				end
				if count > 15 then
					eff.unit:set_size(1.9-0.02*count)
				else
					eff.unit:set_size(0.1*count)
				end
			end)
		end
		
		if not mvr then
			kill()
			return
		end

		function mvr:on_remove()
			kill()
		end
	end
end)
