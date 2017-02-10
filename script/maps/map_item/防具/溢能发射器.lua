



--物品名称
local mt = ac.skill['溢能发射器']

--图标
mt.art = [[BTNdefence6.blp]]

--说明
mt.tip = [[
每%pulse%秒随机对%area%码内的敌人造成一次普通攻击,但伤害只有%damage_rate%%。
]]

--物品类型
mt.item_type = '防具'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1600

--物品唯一
mt.unique = true

--影响范围
mt.area = 600

--伤害周期
mt.pulse = 1
mt.damage_rate = 25
mt.proc = 0.25

function mt:on_add()
	local hero = self.owner
	local area = self.area
	local pulse = self.pulse
	local damage_rate = self.damage_rate
	self.eff = hero:add_effect('origin', [[Abilities\Spells\Orc\CommandAura\CommandAura.mdl]])
	self.timer = hero:loop(pulse * 1000, function()
		if not hero:is_alive() then
			return
		end
		if nil ~= hero:find_buff '隐身' then
			return
		end
		local g = ac.selector()
			: in_range(hero, area)
			: is_enemy(hero)
			: of_visible(hero)
			: add_filter(function(u)
				return not u:is_type('野怪') or u:isActive()
			end)
			: sort_nearest_hero(hero)
			: get()
		if g[1] then
			hero:attack_start(g[1], self, hero:get '攻击' * damage_rate / 100.0)
		end
	end)
end

function mt:on_remove()
	local hero = self.owner
	self.eff:remove()
	self.timer:remove()
end


