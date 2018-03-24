




--物品名称
local mt = ac.skill['烈焰之握']

--图标
mt.art = [[BTNdefence15.blp]]

--说明
mt.tip = [[
当你处于战斗中时，每%time%秒会在自己脚下留下一个烈焰图腾，持续%time%秒。
烈焰图腾受到来友军的伤害时，会把伤害转为烈焰，由周围%area%码范围内的所有敌人均摊伤害。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.time = 5
mt.area = 400

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.trg1 = hero:event '单位-进入战斗' (function(trg)
		self.timer = hero:loop(self.time * 1000, function ()
			if self.dummy_unit then
				self.dummy_unit:remove()
			end
			self.dummy_unit = ac.player.com[3 - hero:get_team()]:create_unit('e00D', hero:get_point(), 0)
			self.dummy_unit:add_effect('chest', [[Abilities\Spells\NightElf\BattleRoar\RoarTarget.mdl]])
			self.dummy_unit:event '受到伤害开始' (function (_, damage)
				self.dummy_unit:get_point():add_effect([[Abilities\Spells\Other\Doom\DoomDeath.mdl]]):remove()
				local group = ac.selector()
					: in_range(self.dummy_unit, self.area)
					: is_enemy(hero)
					: add_filter(function(u)
						return u:get_type_id() ~= 'e00D'
					end)
					: get()
				local damage_value = damage:get_current_damage() / #group
				for _, u in ipairs(group) do
					u:damage
					{
						source = damage.source,
						damage = damage_value,
						aoe = true,
						skill = self,
					}
				end
				return true
			end)
		end)
		self.timer:on_timer()
	end)
	self.trg2 = hero:event '单位-脱离战斗' (function(trg)
		if self.timer then self.timer:remove() end
	end)
end

function mt:on_remove()
	if self.dummy_unit then self.dummy_unit:remove() end
	if self.trg1 then self.trg1:remove() end
	if self.trg2 then self.trg2:remove() end
	if self.timer then self.timer:remove() end
end


