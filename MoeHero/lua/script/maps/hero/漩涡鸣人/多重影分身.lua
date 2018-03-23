local mt = ac.skill['多重影分身']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNmrw.blp]],

	--技能说明
	title = '多重影分身',
	
	tip = [[
召唤%count%个具有迷惑性的分身，分身没有主动技能，只造成%damage_percent%%伤害，分身在累计受到%life_percent%%生命上限的伤害时会消失
分身持续时间：%duration%秒
可累计使用次数：%charge_max_stack%次
		]],

	--耗蓝
	cost = 60,

	--冷却
	cool = 0.1,
	charge_cool = {25, 13},

	--目标类型
	target_type = ac.skill.TARGET_TYPE_NONE,

	--施法前摇
	cast_start_time = 0.2,

	--施法后摇
	cast_finish_time = 0.3,

	--动画
	cast_animation = 4,

	--分身数量
	count = 2,

	--分身伤害%
	damage_percent = {12, 20},

	--累计受到生命值上限伤害
	life_percent = {14, 18},

	--分身持续时间
	duration = 15,

	--可使用次数
	cooldown_mode = 1,
	charge_max_stack = 3,

	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,
}

function mt:on_cast_channel()
	local hero = self.owner
	local target = self.target

	local point = hero:get_point()
	local group = {hero}

	local angel = math.random(0,360)
	
	for i=1,self.count do
		local dummy = hero:create_illusion(hero:get_point())
		table.insert(group,dummy)
		dummy:set('移动速度', hero:get('移动速度'))

		--添加Buff
		dummy:add_buff '多重影分身'
		{
			source = hero,
			skill = self,
		}

		--把分身加进选择的队列
		hero:get_owner():addSelect(dummy)

		--伤害减免
		dummy:event '造成伤害' (function(trg,damage)
			damage:div(1 - self.damage_percent / 100)
		end)

		if dummy:is_ally(ac.player.self) then
			dummy:setColor(10,10,100)
		end

		dummy:event '单位-移除'(function()
			ac.effect(dummy:get_point(),[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]]):remove()
		end)
		
		hero:wait(self.duration*1000,function()
			if dummy then
				dummy:remove()
			end
		end)
	end

	for k,v in pairs(group) do
		v:blink((point - {angel + 120*k, 120}):findMoveablePoint(300))
		v:add_effect('origin',[[modeldekan\ability\DEKAN_Naturo_Smoke.mdl]])
	end
end

local bff = ac.buff['多重影分身']

bff.trg = nil
bff.take_damage = 0

function bff:on_add()
	local hero = self.target

	--伤害事件
	self.trg = hero:event '受到伤害效果' (function(trg,damage)
		self.take_damage = self.take_damage + damage:get_current_damage()

		if self.take_damage >= (hero:get '生命上限'*(self.skill.life_percent/100)) then
			self:remove()
		end
	end)
end

function bff:on_remove()
	self.trg:remove()
	self.target:remove()
end

function bff:on_cover()
	return false
end
