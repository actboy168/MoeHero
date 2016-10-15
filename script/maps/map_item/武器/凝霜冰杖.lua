




--物品名称
local mt = ac.skill['凝霜冰杖']

--图标
mt.art = [[BTNattack15.blp]]

--说明
mt.tip = [[
每%cool%秒会产生一个围绕你旋转的冰球，最多%count%个。
冰球碰到敌人时会碎裂，造成伤害并减少敌人的移动速度%move_speed_rate%%，持续2秒。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1500

--物品唯一
mt.unique = true

mt.cool = 5
mt.count = 4
mt.damage = 0.8
mt.move_speed_rate = 40

local function add_mover(self, index)
	local hero = self.owner
	local movers = self.movers
	local skill = self
	local angle = 0
	for i = 1, self.count do
		if movers[i] then
			angle = movers[i].angle + (index - i) * 360 / self.count
			break
		end
	end
	local mvr = hero:follow
	{
		source = hero,
		skill = skill,
		angle = angle,
		distance = 100,
		size = 0.1,
		high = 100,
		model = [[FrostWyrmMissile.mdx]],
		angle_speed = 166,
	}
	if not mvr then
		return
	end
	function mvr:on_move()
		for _, unit in ac.selector()
			: in_range(self.mover, 100)
			: is_enemy(hero)
			: add_filter(function(unit)
				return (not u:has_restriction '禁锢') and (not unit:find_buff '凝霜冰杖')
			end)
			: ipairs()
		do
			movers[index] = nil
			unit:add_effect('origin', [[Abilities\Weapons\FrostWyrmMissile\FrostWyrmMissile.mdl]]):remove()
			for _, u in ac.selector()
				: in_range(unit, 200)
				: is_enemy(hero)
				: ipairs()
			do
				u:add_buff '凝霜冰杖'
				{
					source = hero,
					time = 2,
					move_speed_rate = skill.move_speed_rate,
				}
				u:damage
				{
					source = hero,
					skill = skill,
					damage = skill.damage * hero:get_ad(),
					aoe = true,
					attack = true,
				}
			end
			if not skill:is_cooling() then
				skill:active_cd()
			end
			self:remove()
			break
		end
	end
	
	movers[index] = mvr
end

function mt:on_add()
	local hero = self.owner
	self.movers = {}
	if hero:is_illusion() then
		return
	end
	self:on_cooldown()
	self.trg1 = hero:event '单位-死亡' (function ()
		self:disable()
	end)
	self.trg2 = hero:event '单位-复活' (function ()
		self:enable()
	end)
end

function mt:on_remove()
	self:on_disable()
	self.trg1:remove()
	self.trg2:remove()
end

function mt:on_cooldown()
	for i = 1, self.count do
		if not self.movers[i] then
			add_mover(self, i)
			break
		end
	end
	for i = 1, self.count do
		if not self.movers[i] then
			self:active_cd()
			return
		end
	end
end

function mt:on_enable()
	print('on_enable')
	self:on_cooldown()
end

function mt:on_disable()
	print('on_disable')
	for i = 1, self.count do
		if self.movers[i] then
			self.movers[i]:remove()
			self.movers[i] = nil
		end
	end
end



local buff = ac.buff['凝霜冰杖']

function buff:on_add()
	self.target:add_buff '减速'
	{
		source = self.source,
		time = self.time,
		move_speed_rate = self.move_speed_rate
	}
end

function buff:on_remove()
end

function buff:on_cover()
	return true
end
