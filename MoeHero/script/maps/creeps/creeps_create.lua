require 'maps.creeps.大火元素'
require 'maps.creeps.大地穴蜘蛛'
require 'maps.creeps.大狗熊'
require 'maps.creeps.幽灵'
require 'maps.creeps.大树精'
require 'maps.creeps.大土灵'
require 'maps.creeps.巨龙'

local creeps = require 'maps.creeps'
local table = table
local rect = require 'types.rect'

creeps.group = {
	--位置,怪物名*N,出生时间,刷新时间
	{'A1', '火元素 火元素 火元素 大火元素', 40, 60},
	{'B1', '小地穴蜘蛛 小地穴蜘蛛 大地穴蜘蛛', 40, 60},
	{'C1', '小狗熊 大狗熊', 40, 60},
	{'D1', '幽灵', 40, 60},
	{'E1', '树精 树精 大树精', 40, 120},
	{'F1', '土灵 土灵 大土灵', 40, 120},
	{'A2', '火元素 火元素 火元素 大火元素', 40, 60},
	{'B2', '小地穴蜘蛛 小地穴蜘蛛 大地穴蜘蛛', 40, 60},
	{'C2', '小狗熊 大狗熊', 40, 60},
	{'D2', '幽灵', 40, 60},
	{'E2', '树精 树精 大树精', 40, 120},
	{'F2', '土灵 土灵 大土灵', 40, 120},
	{'S', '巨龙', 0, 120},
}

--开始刷野
function creeps.start()

	--刷野玩家
	local creep_player = ac.player[13]

	--对每个野怪点分别计算
	for _, data in ipairs(creeps.group) do
		local rect_name, creeps_names, start_time, revive_time = table.unpack(data)

		--刷怪区域
		local rct = rect.j_rect('creeps' .. rect_name)
		--野怪单位组
		local group = {}
		--野怪数据
		local creeps_datas = {}
		for name in creeps_names:gmatch '%S+' do
			table.insert(creeps_datas, name)
		end
		--第几次刷新
		local revive_count = -1

		--创建该野怪点的野怪
		local function create()
			revive_count = revive_count + 1
			local count = #creeps_datas
			for i = 1, count do
				local name = creeps_datas[i]
				local data = ac.lni.unit[name]
				local p = rct:get_point() - {360 / count * i, 100}

				local u = creep_player:create_unit(name, p, 270)

				--设置奖励
				u.reward_gold = data['金钱'] * 2
				u.reward_exp = data['经验'] * 1.5

				--设置属性
				u:add('生命上限%', revive_count * 40)
				u:add('攻击%', revive_count * 40)
				--u:setMelee(false)
				if data.weapon then
					u.missile_art = data.weapon['弹道模型']
					u.missile_speed = data.weapon['弹道速度']
				end
				
				u:add_ability 'A00V'

				--将单位添加进单位组
				table.insert(group, u)
				--保存单位组
				u.creep_group = group

				--监听这个单位挂掉
				u:event '单位-死亡' (function()
					for _, uu in ipairs(group) do
						if uu:is_alive() then
							return
						end
					end
					ac.wait(revive_time * 1000, create)
				end)
			end
		end

		--刷第一波野
		ac.wait(start_time * 1000, create)
	end
end

return creeps
