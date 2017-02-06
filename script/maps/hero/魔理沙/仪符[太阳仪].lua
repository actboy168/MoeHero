


local mt = ac.skill['仪符[太阳仪]']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[replaceabletextures\commandbuttons\PASBTNmarisaW.blp]],

	--技能说明
	title = '仪符[太阳仪]',
	
	tip = [[
魔理沙在施法和引导时，会释放星弹。每颗星弹造成%damage%(+%damage_plus%)伤害。
被星弹击中的敌人，受到的伤害提高%damaged_rate%%，持续%time%秒。这个效果最多可以叠加%max_stack%层。
	]],

	shot_cool = {200, 140},
	damage = {4, 20},
	damage_plus = function(self, hero)
		return hero:get_ad() * 0.2
	end,
	speed = 600,
	damaged_rate = {7, 15},
	max_stack = 3,
	time = 5,
	passive = true,
}

mt.timer = { remove = function() end }

local star = {
	[[marisastarm_1b.mdx]],
	[[marisastarm_1g.mdx]],
	[[marisastarm_1y.mdx]],
}

function mt:on_add()
	local hero = self.owner
	local damage = self.damage + self.damage_plus
	local function cast_w()
		for i = 1, 3 do
			local mvr = ac.mover.line
			{
				source = hero,
				start = hero:get_point(),
				model = star[i % 3 + 1],
				angle = math.random(0, 360),
				distance = 600,
				speed = self.speed,
				high = 60,
				size = 1.0,
				skill = self,
				damage = damage,
				hit_type = ac.mover.HIT_TYPE_ENEMY,
				hit_area = 100,
			}
			if mvr then
				function mvr:on_hit(target)
					target:damage
					{
						source = hero,
						damage = damage,
						skill = self.skill,
						attack = true,
					}
					target:add_buff '仪符[太阳仪]'
					{
						source = hero,
						skill = self.skill,
						time = self.skill.time,
					}
					return true
				end
			end
		end
	end
	local skills = {}
	self.trg1 = hero:event '技能-施法引导' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		if skill.instant ~= 0 then
			cast_w()
			return
		end
		self.timer:remove()
		self.timer = hero:loop(self.shot_cool, cast_w)
		skills[skill] = true
	end)
	self.trg2 = hero:event '技能-施法出手' (function(trg, _, skill)
		if skill:get_type() ~= '英雄' then
			return
		end
		if skill.instant ~= 0 then
			return
		end
		self.timer:on_timer()
		self.timer:remove()
		skills[skill] = true
	end)
	self.trg3 = hero:event '技能-施法停止' (function(trg, _, skill)
		if not skills[skill] then
			return
		end
		skills[skill] = nil
		self.timer:remove()
	end)
end

function mt:on_remove()
	self.trg1:remove()
	self.trg2:remove()
	self.trg3:remove()
	if self.timer then self.timer:remove() end
end

local mt = ac.buff['仪符[太阳仪]']

mt.debuff = true

function mt:on_add()
	self:add_stack(1)
	self.target:addDamagedRate(self.skill.damaged_rate)
	if self.eff then
		self.eff:remove()
	end
	self.eff = self.target:add_effect("origin", star[self:get_stack()])
end

function mt:on_remove()
	self.target:addDamagedRate(self:get_stack() * self.skill.damaged_rate * -1)
	self.eff:remove()
end

function mt:on_cover(new)
	if self:get_stack() < self.skill.max_stack then
		self:on_add()
	end
	self:set_remaining(new.time)
	return false
end
