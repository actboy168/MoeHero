



--物品名称
local mt = ac.skill['收割之镰']

--图标
mt.art = [[BTNattack16.blp]]

--说明
mt.tip = [[
你的伤害会在%cool%秒后结算。
你的攻击命中时，你造成的伤害提高%damage_rate%%，并刷新伤害结算的时间。这个效果最多可以叠加%max_stack%次。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1700

--物品唯一
mt.unique = true

mt.cool = 2
mt.damage_rate = 3
mt.max_stack = 6
mt.ignore_cool_save = true

function mt:on_add()
	local hero = self.owner
	self.trg = hero:event '造成伤害开始' (function (trg, damage)
		if damage.skill == self then
			damage.crit_flag = false
			return
		end
		local current_damage = damage.current_damage
		if damage.crit_flag then
			current_damage = current_damage * damage['暴击伤害'] / 100
		end
		hero:add_buff '收割之镰'
		{
			source = hero,
			skill = self,
			record_target = damage.target,
			record_skill = damage.skill,
			record_damage = current_damage,
			time = self.cool,
		}
		return true
	end)
end

function mt:on_remove()
	local hero = self.owner
	hero:remove_buff '收割之镰'
	self.trg:remove()
end



local mt = ac.buff['收割之镰']

function mt:on_add()
	self.skill:set_stack(1)
	self.target_list = {
		[self.record_target] = {
			target = self.record_target,
			damage = self.record_damage,
			effect = self.record_target:add_effect('overhead', [[model\item\attack16.mdx]]),
		},
	}
	self.skill_list = { }
	if self.record_skill then
		self.skill_list[self.record_skill] = true
	end
	self.skill:active_cd()
end

function mt:on_remove()
	local hero = self.target
	local damage_rate = 1 + self.skill:get_stack() * self.skill.damage_rate / 100
	self.skill:set_stack(0)
	for _, value in pairs(self.target_list) do
		value.effect:remove()
		value.target:damage
		{
			source = hero,
			skill = self.skill,
			damage = value.damage * damage_rate,
			attack = true,
		}
	end
end

function mt:on_cover(new)
	if self.target_list[new.record_target] then
		self.target_list[new.record_target].damage = self.target_list[new.record_target].damage + new.record_damage
	else
		self.target_list[new.record_target] = {
			target = new.record_target,
			damage = new.record_damage,
			effect = new.record_target:add_effect('overhead', [[model\item\attack16.mdx]]),
		}
	end

	-- 普攻直接刷新
	if not new.record_skill then
		self:set_remaining(self.skill.cool)
		self.skill:active_cd()
		if self.skill.max_stack > self.skill:get_stack() then
			self.skill:add_stack(1)
		end
		return false
	end
	-- 技能第一次命中时刷新
	if not self.skill_list[new.record_skill] then
		self.skill_list[new.record_skill] = true
		self:set_remaining(self.skill.cool)
		self.skill:active_cd()
		if self.skill.max_stack > self.skill:get_stack() then
			self.skill:add_stack(1)
		end
		return false
	end
	return false
end
