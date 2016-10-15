



--物品名称
local mt = ac.skill['魔力之星']

--图标
mt.art = [[BTNattack17.blp]]

--说明
mt.tip = [[
魔力之星会提高你技能的伤害，根据你剩余能量的百分比，最多提高%max_damage_rate%%。
每次使用技能时，转换的比例会上升%damage_rate%%，持续%time%秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

mt.time = 3
mt.damage_rate = 5
mt.max_damage_rate = 20

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.mvr = hero:follow
	{
		source = hero,
		skill = self,
		angle = hero:get_facing() + 90,
		distance = 200,
		size = 0.1,
		high = 150,
		hit_area = 100,
		model = [[model\item\attack17.mdl]],
	}
	if not self.mvr then
		return
	end
	function self.mvr:on_move()
		self.angle = self.angle + self.skill:get_stack() / 2 + 1
	end
	self.trg1 = hero:event '技能-施法开始'(function (_, _, skill)
		skill['魔力之星'] = self:get_stack() / 100
	end)
	self.trg2 = hero:event '技能-施法引导'(function (_, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		hero:add_buff '魔力之星'
		{
			time = self.time,
			value = self.damage_rate,
			skill = self,
		}
		self.mvr.mover:add_effect('origin', [[model\item\attack17.mdl]]):remove()
	end)
	self.trg3 = hero:event '造成伤害'(function (_, damage)
		if not damage.skill then
			return
		end
		if not damage.skill['魔力之星'] then
			return
		end
		damage:mul(damage.skill['魔力之星'])
	end)
	self:add_stack(self.max_damage_rate)
	self.timer = hero:loop(200, function ()
		local new_value = math.floor(self.max_damage_rate * hero:get '魔法' / hero:get '魔法上限')
		local value = self:get_stack()
		self:add_stack(new_value - value)
	end)
end

function mt:on_remove()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.mvr:remove()
	self.trg1:remove()
	self.trg2:remove()
	self.trg3:remove()
	self.timer:remove()
end



local mt = ac.buff['魔力之星']

mt.cover_type = 1
mt.cover_max = 4

function mt:on_add()
	self.skill.max_damage_rate = self.skill.max_damage_rate + self.value
end

function mt:on_remove()
	self.skill.max_damage_rate = self.skill.max_damage_rate - self.value
end
