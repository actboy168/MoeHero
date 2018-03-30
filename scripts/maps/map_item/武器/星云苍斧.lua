



--物品名称
local mt = ac.skill['星云苍斧']

--图标
mt.art = [[BTNattack6.blp]]

--说明
mt.tip = [[
%chance%%概率对%area%码范围的敌人释放幻雷。
这个效果每%cool%秒只能触发一次。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1800

--物品唯一
mt.unique = true

mt.chance = 25

mt.area = 600

mt.cool = 3

mt.damage = 1.2

function mt:on_add()
	local hero = self.owner
	local area = self.area
	local chance = self.chance
	if hero:is_illusion() then
		return
	end
	self.trg = hero:event '造成伤害效果' (function(trg, damage)
		if self:is_cooling() then
			return
		end
		if not damage:is_attack() then
			return
		end
		if math.random(1, 100) > chance then
			return
		end
		self:active_cd()
		local g = ac.selector()
			: in_range(damage.target, area)
			: is_enemy(hero)
			: get()
		local count = #g
		local damage = hero:get_ad() * self.damage * (0.9 + count / 10)
		for _, u in ipairs(g) do
			u:add_effect('chest', [[Abilities\Spells\Other\Monsoon\MonsoonBoltTarget.mdl]]):remove()
			u:damage
			{
				source = hero,
				damage = damage / count,
				skill = self,
				aoe = true,
				attack = true,
			}
		end
	end)
end

function mt:on_remove()
	if self.trg then self.trg:remove() end
end


