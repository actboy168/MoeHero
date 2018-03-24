
local player = require 'ac.player'
local hero = require 'types.hero'

--2个电脑
player.com = {}

	player.com[1] = player[11]
	player.com[2] = player[12]

	player.com['沉沦遗迹'] = player[11]
	player.com['幻想神社'] = player[12]

--2组玩家
player.force = {}

	player.force[1] = {
		[0] = player.com[1],
		player[1],
		player[2],
		player[3],
		player[4],
		player[5],
	}

	player.force[2] = {
		[0] = player.com[2],
		player[6],
		player[7],
		player[8],
		player[9],
		player[10],
	}

--玩家结盟
for x = 0, 5 do
	for y = 0, 5 do
		player.force[1][x]:setAllianceSimple(player.force[1][y], true)
		player.force[1][x]:setAllianceSimple(player.force[2][y], false)
		player.force[2][x]:setAllianceSimple(player.force[1][y], false)
		player.force[2][x]:setAllianceSimple(player.force[2][y], true)
	end
	player.force[1][x]:setTeam(1)
	player.force[2][x]:setTeam(2)
	--允许控制中立被动的单位
	player.force[1][x]:enableControl(player[16])
	player.force[2][x]:enableControl(player[16])
end

--电脑与野怪互相友好
player.force[1][0]:setAllianceSimple(player[13], true)
player.force[2][0]:setAllianceSimple(player[13], true)
player[13]:setAllianceSimple(player.force[1][0], true)
player[13]:setAllianceSimple(player.force[2][0], true)

player.self:clearMsg()

--设置名字
player.com[1]:setName '沉沦遗迹'
player.com[2]:setName '幻想神社'

--玩家离开通报
ac.game:event '玩家-离开' (function(trg, p)
	local hero = p.hero
	local hero_name
	if hero then
		hero_name = hero:get_name()
	else
		hero_name = '没有英雄'
	end
	player.self:sendMsg(('%s%s(%s)|r |cffff1111哭着逃跑了!|r'):format(p:getColorWord(), p:getBaseName(), hero_name))
end)

--玩家离开删除英雄并分钱
ac.game:event '玩家-离开' (function(trg, tp)
	local h = tp.hero
	if h then
		h:add_restriction '隐藏'
		h:add_restriction '缴械'
		h:add_restriction '无敌'
		h:set_high(10000)
		hero.getAllHeros()[h] = nil
	end
end)