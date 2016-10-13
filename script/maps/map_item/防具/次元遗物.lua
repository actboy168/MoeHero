



--物品名称
local mt = ac.skill['次元遗物']

--图标
mt.art = [[BTNdefence3.blp]]

--说明
mt.tip = [[
%area%范围友方英雄获得以下效果
防御+%defence_area%
暴击+%crit_area%%
格挡+%block_area%%
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1400

--物品唯一
mt.unique = true

--影响范围
mt.area = 700

mt.defence_area = 20
mt.crit_area = 5
mt.block_area = 5

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.eff = hero:add_effect('origin', [[Abilities\Spells\Human\Brilliance\Brilliance.mdl]])
	hero:add_buff '次元遗物'
	{
		source = hero,
		data = {
			defence = self.defence_area,
			crit = self.crit_area,
			block = self.block_area,
		},
		selector = ac.selector()
			: in_range(hero, self.area)
			: is_ally(hero)
			: of_hero()
			,
	}
end

function mt:on_remove()
	if self.eff then self.eff:remove() end
end



local buff = ac.aura_buff['次元遗物']

buff.cover_type = 1
buff.cover_max = 1

function buff:on_add()
	local u = self.target
	self.eff = u:add_effect('origin', [[Abilities\Spells\Other\GeneralAuraTarget\GeneralAuraTarget.mdl]])
	u:add('护甲', self.data.defence)
	u:add('暴击', self.data.crit)
	u:add('格挡', self.data.block)
end

function buff:on_remove()
	local u = self.target
	self.eff:remove()
	u:add('护甲', - self.data.defence)
	u:add('暴击', - self.data.crit)
	u:add('格挡', - self.data.block)
end
