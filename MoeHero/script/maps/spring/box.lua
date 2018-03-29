
local player = require 'ac.player'
local rect = require 'types.rect'
local map = require 'maps.map'

local math = math
require 'maps.spring.box_buff_1'
require 'maps.spring.box_buff_2'
require 'maps.spring.box_buff_3'
require 'maps.spring.box_buff_4'

local self = {}

--奖金池
self.reward_pool_gold = 0
self.reward_pool_exp = 0

--宝箱Buff
--固定Buff

local buff = ac.buff['宝箱奖励']

buff.keep = true
buff.max_stack = 4
buff.count = 0
buff.keep = true

function buff:on_add()
	self.target:add_buff('宝箱奖励' .. self.count){}
	self.target:get_owner():sendMsg('宝箱奖励' .. self.count)

	self.target:add_effect('origin', [[Abilities\Spells\Items\TomeOfRetraining\TomeOfRetrainingCaster.mdl]]):remove()
end

function buff:on_remove()
	for i = 1, self.max_stack do
		self.target:remove_buff('宝箱奖励' .. i)
	end
end

function buff:on_cover(dest)
	self.count = dest.count
	self:on_add()
	self:send_tips()
	return false
end

local buff = ac.buff['宝箱奖励4']

buff.tip = '攻击增加|cffff8811%damage_rate_ex%%|r'
buff.send_tip = true
buff.keep = true
buff.trg = nil
buff.damage_rate = 1.5
buff.damage_rate_ex = 0

function buff:on_add()
	self.target:add('攻击%', self.damage_rate)
	self.damage_rate_ex = self.damage_rate_ex + self.damage_rate
end

function buff:on_remove()
	self.target:add('攻击%', - self.damage_rate_ex)
end

function buff:on_cover()
	self:on_add()
	self:send_tips()
	return false
end

local buff = ac.buff['宝箱奖励2']

buff.tip = '移速增加|cffff8811%speed_rate_ex%%|r'
buff.send_tip = true
buff.keep = true
buff.speed_rate = 1.5
buff.speed_rate_ex = 0

function buff:on_add()
	self.target:add('移动速度%', self.speed_rate)
	self.speed_rate_ex = self.speed_rate_ex + self.speed_rate
end

function buff:on_remove()
	self.target:add('移动速度%', - self.speed_rate_ex)
end

function buff:on_cover()
	self:on_add()
	self:send_tips()
	return false
end

local buff = ac.buff['宝箱奖励1']

buff.tip = '获得金钱增加|cffff8811%gold_rate_ex%%|r'
buff.send_tip = true
buff.keep = true
buff.trg = nil
buff.gold_rate = 1
buff.gold_rate_ex = 0

function buff:on_add()
	self.trg = self.target:get_owner():event '玩家-即将获得金钱' (function(trg, data)
		data.gold = data.gold + data.gold * self.gold_rate_ex / 100
	end)
	self.gold_rate_ex = self.gold_rate_ex + self.gold_rate
end

function buff:on_remove()
	self.trg:remove()
end

function buff:on_cover()
	self.gold_rate_ex = self.gold_rate_ex + self.gold_rate
	self:send_tips()
	return false
end


local mt = ac.buff['宝箱奖励3']

mt.tip = '防御增加|cffff8811%defence_rate_ex%%|r'
mt.send_tip = true

mt.keep = true

mt.defence_rate = 1.5
mt.defence_rate_ex = 0

function mt:on_add()
	self.target:add('护甲%', self.defence_rate)
	self.defence_rate_ex = self.defence_rate_ex + self.defence_rate
end

function mt:on_remove()
	self.target:add('护甲%', - self.defence_rate_ex)
end

function mt:on_cover()
	self:on_add()
	self:send_tips()
	return false
end

--随机Buff
self.random_buff_names = {
	'返老还童',
	'贪婪欲望',
	'无限火力',
	'奥能涌动',
}
	
--创建宝箱
local life = 2500
local defence = 25
local count = 0

function self.createBox()
	local box = player[13]:create_unit(self.box_id, self.box_rect)
	box.unit_type = '建筑'
	box:add_restriction '禁锢'
	map.box = box
	life = life + 2500
	defence = defence + 25
	count = count + 1
	local count = math.min(4, count)
	box:set('生命上限', life)
	box:set('生命', life)
	box:set('护甲', defence)
	box.selected_radius = 150
	--box:add_buff '铠甲'

	player.self:sendMsg('|cffffff11宝箱已经出现,大家快去抢啊!|r')

	box:shareVisible(player.com[1])
	box:shareVisible(player.com[2])

	self.reward_pool_gold = self.reward_pool_gold + 150

	--掉球
	local function drop()
		local mvr = ac.mover.line
		{
			source = box,
			angle = math.random(1, 360),
			distance = math.random(200, 600),
			speed = 500,
			model = [[ball_red_weak.mdl]],
			height = 200,
			skill = false,
			high = 50,
		}

		if not mvr then
			return
		end

		function mvr:on_finish()
			local mvr = ac.mover.line
			{
				source = box,
				mover = self.mover,
				distance = 999999,
				angle = 0,
				speed = 0,
				skill = false,
				hit_area = 100,
				hit_type = '别人',
				block = true,
			}

			if not mvr then
				return
			end

			function mvr:on_hit(dest)
				if dest:is_hero() then
					local team = dest:get_team()

					--全队获得一个奖励
					for hero in pairs(ac.hero.getAllHeros()) do
						if hero:get_team() == team then
							hero:add_buff('宝箱奖励' .. count){}
						end
					end

					ac.game:event_notify('游戏-宝箱奖励', team)

					dest:add_effect('origin', [[Abilities\Spells\Items\TomeOfRetraining\TomeOfRetrainingCaster.mdl]]):remove()
					self.mover:remove()
					return true
				end
			end

			

			self:remove(true)
		end

		
	end

	--player.self:sendMsg '神秘宝箱'
	--每损失1/6的血掉一个球
	local life_rate = 5
	box:event '受到伤害效果' (function(trg, damage)
		local rate = box:get '生命' / box:get '生命上限'
		while rate <= life_rate / 6 and life_rate > 0 do
			drop()
			life_rate = life_rate - 1
		end
	end)

	--死亡时掉5个球
	box:event '单位-死亡' (function(trg, target, source)
		if not source then
			return
		end

		for i = 1, 5 + life_rate do
			drop()
		end
		life_rate = 0

		--击杀者随机获得一个Buff
		local hero = source:get_owner().hero
		if hero then
			local buff_name = self.random_buff_names[math.random(1, #self.random_buff_names)]
			hero:add_buff(buff_name)
			{
				source = target,
			}
		end

		local team = source:get_team()

		--全队获得一个奖励
		for hero in pairs(ac.hero.getAllHeros()) do
			if hero:get_team() == team then
				hero:addGold(self.reward_pool_gold, box)
				hero:add_effect('origin', [[Abilities\Spells\Items\TomeOfRetraining\TomeOfRetrainingCaster.mdl]]):remove()
			end
		end

		self.reward_pool_gold = 0
	end)
	
end

function self.main()
	self.box_id = 'n002'
	self.box_rect = rect.j_rect 'treasure'
	
	return self
end

return self.main()
