local rawget = rawget
local rawset = rawset
local math = math

local mt = ac.skill['狂战']
	
mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[PASBTNjbe.blp]],

	--技能说明
	title = '狂战',
	
	tip = [[
受到伤害时，提高此次伤害值%attack_rate%%的攻击，持续%time%秒。
造成伤害时，提高此次伤害值%defence_rate%%的护甲和%life_recover_rate%%的生命恢复，持续%time%秒。
血量低于%life_rate%%后，受到伤害或造成伤害都会同时提升攻击、护甲和生命恢复。

攻击叠加上限：%add_attack_max%
护甲叠加上限：%add_defence_max%
生命恢复叠加上限：%add_recover_max%
	]],

	--攻击提升(%)
	attack_rate = {4, 8},

	--护甲提升(%)
	defence_rate = {0.5, 2.5},

	--生命恢复提升(%)
	life_recover_rate = {0.5, 2.5},

	--持续时间
	time = 6,

	--血量阀值(%)
	life_rate = 50,

	--攻击叠加上限
	add_attack_max = 80,
	
	--护甲叠加上限
	add_defence_max = 30,
	
	--生命恢复叠加上限
	add_recover_max = 30,
}

--标记为被动技能
mt.passive = true

mt.trg1 = nil
mt.trg2 = nil

local dot_mt = {}
function dot_mt:__add(rht)
	return {
		attack = self.attack + rht.attack,
		defence = self.defence + rht.defence,
		recover = self.recover + rht.recover,
	}
end

function mt:on_upgrade()
	if self:get_level() ~= 1 then
		return
	end
	local hero = self.owner
	--监听造成伤害
	self.trg1 = hero:event '造成伤害效果' (function(trg, damage)
		if damage:is_skill() then
			if damage:is_item() then
				return
			end
			if damage.skill['更木剑八狂战标记'] then
				return
			end
			damage.skill['更木剑八狂战标记'] = true
		end

		local d = damage.damage
		local defence = d * self.defence_rate / 100
		local recover = d * self.life_recover_rate / 100
		local attack = 0
		if hero:get '生命' / hero:get '生命上限' * 100 <= self.life_rate then
			attack = d * self.attack_rate / 100
		end
		hero:add_buff '狂战'
		{
			time = self.time,
			skill = self,
			damage = setmetatable({attack = attack, defence = defence, recover = recover}, dot_mt),
		}
	end)

	--监听受到伤害
	self.trg2 = hero:event '受到伤害效果' (function(trg, damage)
		local d = damage.damage
		local defence = 0
		local recover = 0
		local attack = d * self.attack_rate / 100
		if hero:get '生命' / hero:get '生命上限' * 100 <= self.life_rate then
			defence = d * self.defence_rate / 100
			recover = d * self.life_recover_rate / 100
		end
		hero:add_buff '狂战'
		{
			time = self.time,
			skill = self,
			damage = setmetatable({attack = attack, defence = defence, recover = recover}, dot_mt),
		}
	end)
end

function mt:on_remove()
	if self.trg1 then
		self.trg1:remove()
	end
	if self.trg2 then
		self.trg2:remove()
	end
	self.owner:remove_buff '狂战'
end



local mt = ac.dot_buff['狂战']

mt.cover_type = 0

function mt:on_add()
	self.attack = 0
	self.defence = 0
	self.recover = 0
end

function mt:on_remove()
	local hero = self.target
	hero:add('攻击', -self.attack)
	hero:add('护甲', -self.defence)
	hero:add('生命恢复', - self.recover)
end

function mt:on_pulse(data)
	local hero = self.target
	local skill = self.skill
	local attack  = math.floor(math.min(data.attack,  skill.add_attack_max)  - self.attack)
	local defence = math.floor(math.min(data.defence, skill.add_defence_max) - self.defence)
	local recover = math.floor(math.min(data.recover, skill.add_recover_max) - self.recover)
	if attack ~= 0 then
		hero:add('攻击', attack)
		self.attack = self.attack + attack
	end
	if attack ~= 0 then
		hero:add('护甲', defence)
		self.defence = self.defence + defence
	end
	if recover ~= 0 then
		hero:add('生命恢复', recover)
		self.recover = self.recover + recover
	end
end
