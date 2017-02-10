
local function cast_q(self, target)
	local hero = self.owner
	
	--发射箭矢
	local damage = self.damage + self.damage_plus
	local damage_rate = self.damage_rate
	local damage_area = self.damage_area
	local buff_time = self.buff_time
	local buff_damage_rate = self.buff_damage_rate
	local mana_area = self.mana_area
	local mana = self.mana_recover

	local mover = ac.mover.target
	{
		source = hero,
		speed = self.speed,
		model = [[s_arcanerocket projectile.mdx]],
		skill = self,
		high = 120,
		size = 0.6,
		target = target,
		damage = damage,
		attack = true,
	}

	if not mover then
		return
	end
	
	function mover:on_finish()
		--加个Buff
		target:add_buff '净化箭矢'
		{
			source = hero,
			skill = self.skill,
			time = buff_time,
			damage_rate = buff_damage_rate / 100,
			mana_area = mana_area,
			mana = mana,
		}
		damage = damage * (1 + hero:get '魔法' / self.skill.mana_damage / 100.0)
		for _, u in ac.selector()
			: in_range(target, damage_area)
			: is_enemy(hero)
			: ipairs()
		do
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self.skill,
				aoe = true,
				missile = self.mover,
			}
		end
	end
end


local mt = ac.skill['净化箭矢']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNxyq.blp]],

	--技能说明
	title = '净化箭矢',
	
	tip = [[
对目标和周围敌人造成%damage%(+%damage_plus%)点伤害，每%mana_damage%法力值会提升1%伤害。
目标损失受到伤害%buff_damage_rate%%的法力值。
如果目标死亡时，则恢复附加友方%mana_recover%点法力值。
	]],

	--施法时间
	cast_start_time = 0.4,

	--耗蓝
	cost = 100,

	--施法动作
	cast_animation = 'attack',

	--冷却
	cool = 3,
	
	--施法距离
	range = 700,

	--目标类型
	target_type = mt.TARGET_TYPE_UNIT,

	--弹道速度
	speed = 1500,

	--伤害
	damage = {30, 90},

	--AP加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.5
	end,

	mana_damage = 100,

	--溅射范围
	damage_area = 200,

	--Buff
	buff_time = 3,

	--受到伤害时损失的法力值
	buff_damage_rate = 25,

	--法力恢复范围
	mana_area = 1000,

	--法力恢复
	mana_recover = {4, 20},
}

function mt:on_cast_channel()
	cast_q(self, self.target)
end

local mt = ac.skill['净化箭矢(神)']

mt{
	--技能图标
	art = [[BTNxyq.blp]],

	--技能说明
	title = '净化箭矢(神)',
	
	tip = [[
对目标和周围敌人造成%damage%(+%damage_plus%)点伤害，每%mana_damage%法力值会提升1%伤害。
目标损失受到伤害%buff_damage_rate%%的法力值。
如果目标死亡时，则恢复附加友方%mana_recover%点法力值。

|cffffff11对自己使用激活自动释放|r
	]],

	--施法时间
	cast_start_time = 0.4,

	--耗蓝
	cost = 100,

	--施法动作
	cast_animation = 'attack',

	--冷却
	cool = 3,
	
	--施法距离
	range = function(self, hero)
		return hero:find_skill '圆环之理' .power_range
	end,

	--目标类型
	target_type = mt.TARGET_TYPE_UNIT,

	--弹道速度
	speed = 1500,

	--额外目标搜索范围
	radius = function(self, hero)
		return hero:find_skill '圆环之理' .power_area
	end,

	--额外目标数量
	count = function(self, hero)
		return hero:find_skill '圆环之理' .power_count
	end,

	--伤害
	damage = {30, 90},

	--AP加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.5
	end,

	mana_damage = 100,

	--溅射范围
	damage_area = 200,

	--Buff
	buff_time = 3,

	--受到伤害时损失的法力值
	buff_damage_rate = 25,

	--法力恢复范围
	mana_area = 1000,

	--法力恢复
	mana_recover = {4, 20},
}

function mt:on_cast_channel()
	cast_q(self, self.target)
	local hero = self.owner
	local g = ac.selector()
		: in_range(self.target, self.radius)
		: is_enemy(hero)
		: is_not(self.target)
		: of_visible(hero)
		: sort_nearest_hero(self.target)
		: get()

	for i = 1, self.count - 1 do
		local u = g[i]
		if not u then
			break
		end
		cast_q(self, u)
	end
	hero:replace_skill(self.name, '净化箭矢', true)
	hero:wait(1000, function()
		hero:remove_buff '圆环之理'
	end)
end



local mt = ac.buff['净化箭矢']

mt.debuff = true
		
mt.trg1 = nil
mt.trg2 = nil
mt.eff = nil

mt.keep = true

function mt:on_add()
	local hero = self.source
	local u = self.target
	local skill = self.skill

	self.eff = u:add_effect('origin', [[war3mapimported\A12_fen.mdl]])

	--伤害加深
	local damage_rate = self.damage_rate
	self.trg1 = u:event '受到伤害效果' (function(trg, damage)
		local target = damage.target
		local cost_mana = damage:get_current_damage() * damage_rate
		local damage = cost_mana - target:get '魔法'
		target:add('魔法', - cost_mana)
		if damage > 0 then
			trg:disable()
			target:damage
			{
				source = hero,
				damage = damage,
				skill = skill,
			}
			trg:enable()
		end
	end)

	--死亡时为附近单位恢复法力
	local mana_area = self.mana_area
	local mana = self.mana
	self.trg2 = u:event '单位-死亡' (function(trg, target, source)
		for _, u in ac.selector()
			: in_range(target, mana_area)
			: is_ally(hero)
			: ipairs()
		do
			u:add('魔法', mana)
			u:add_effect('origin', [[Abilities\Spells\Items\AIma\AImaTarget.mdl]]):remove()
		end
		if u:is_hero() then
			return
		end
		--淡化消失
		u:set_class '马甲'
		u:add_restriction '硬直'
		--u:set_animation_speed(0)
		u:add_buff '淡化'
		{
			source = hero,
			time = 1,
		}
	end)
end

function mt:on_remove()
	self.eff:remove()
	self.trg1:remove()
	self.trg2:remove()
end