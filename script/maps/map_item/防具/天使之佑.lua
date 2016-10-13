



--物品名称
local mt = ac.skill['天使之佑']

--图标
mt.art = [[BTNdefence10.blp]]

--说明
mt.tip = [[
受到致命伤害时，回复生命到25%，并且造成的伤害提高35%，持续5秒。
这个效果每%cool%秒只能触发一次。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.cool = 120

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '单位-即将死亡' (function(trg, damage)
		if self:is_cooling() then
			return
		end
		hero:add_effect('origin', [[Abilities\Spells\Human\Resurrect\ResurrectCaster.mdl]]):remove()
		hero:heal{ heal = hero:get '生命上限'*0.25, skill = self }
		hero:add_buff '天使之佑'
		{
			time = 5,
		}
		self:active_cd()
		return true
	end)
end

function mt:on_remove()
	self.trg:remove()
end


local buff = ac.buff['天使之佑']

function buff:on_add()
	self.target:addDamageRate(35)
end

function buff:on_remove()
	self.target:addDamageRate(-35)
end


