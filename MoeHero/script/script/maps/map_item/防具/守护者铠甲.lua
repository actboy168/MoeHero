



--物品名称
local mt = ac.skill['守护者铠甲']

--图标
mt.art = [[BTNdefence5.blp]]

--说明
mt.tip = [[
周围%area%码内的友方英雄受到伤害的20%由你代受。
每个受到你保护的友方英雄会为你增加%block%%格挡。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1200

--物品唯一
mt.unique = true

--光环附着时间
mt.time = 1

--光环扫描周期
mt.pulse = 0.5

--影响范围
mt.area = 1000

mt.block = 4

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	local area = self.area
	local pulse = self.pulse * 1000
	local time = self.time
	self.buff = hero:add_buff '天启护符'
	{
		source = hero,
		skill = self,
		selector = ac.selector()
			: in_range(hero, self.area)
			: is_ally(hero)
			: of_hero()
			: of_not_illusion()
			,
		data = {
			block = self.block
		},
	}
end

function mt:on_remove()
	if self.buff then
		self.buff:remove()
	end
end



local buff = ac.aura_buff['天启护符']

buff.cover_type = 1
buff.cover_max = 1
buff.keep = true

function buff:on_add()
	local source, target = self.source, self.target
	if source == target then
		return
	end
	self.trg = target:event '受到伤害' (function (trg, damage)
		if damage:is_skill() and damage.skill.name == self.skill.name then
			return
		end
		damage:div(0.2, function(damage)
			local d = damage:get_current_damage() * 0.2
			if damage:is_crit() then
				d = d / damage['暴击伤害'] * 100
			end
			source:damage
			{
				source = damage.source,
				skill = self.skill,
				damage = d,
				crit_flag = damage:is_crit(),
				['暴击伤害'] = damage['暴击伤害'],
			}
		end)
	end)
	self.source:add('格挡', self.data.block)
end

function buff:on_remove()
	local source, target = self.source, self.target
	if source == target then
		return
	end
	self.trg:remove()
	self.source:add('格挡', - self.data.block)
end
