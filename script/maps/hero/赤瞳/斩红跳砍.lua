local mt = ac.skill['斩红跳砍']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[BTNctw.blp]],

	--技能说明
	title = '斩红跳砍',
	
	tip = [[
跃向空中无敌并留下迷惑性残像，%cast_channel_time%秒内可跃向指定点的%area%范围造成%damage%(+%damage_plus%)伤害并击晕%stun%秒。
如果残像被敌人击中，|cff11ccff斩红跳砍|r的伤害提高%damage_rate%%。
		]],

	--耗蓝
	cost = 80,

	--冷却
	cool = {15, 11},

	cast_channel_time = 1.0,

	--施法距离
	range = 500,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_NONE,

	--眩晕时间
	stun = 0.5,

	--最大高度
	max_height = 400,

	break_move = 0,

	--作用范围
	area = 150,

	damage_rate = {30, 50},

	--伤害
	damage = {80, 160},

	damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_restriction '幽灵'
	hero:add_restriction '定身'
	hero:add_restriction '隐身'

	--创建幻象
	self.illustion = hero:create_illusion(hero:get_point())
	hero:blink(self.illustion:get_point(), true, true)

	if self.illustion:is_ally(ac.player.self) then
		self.illustion:setColor(10,10,100)
	end

	self.trg1 = hero:event '受到伤害开始' (function()
		if self.illustion then
			self.illustion:get_point():add_effect([[Abilities\Spells\Orc\MirrorImage\MirrorImageDeathCaster.mdl]]):remove()
			self.illustion:remove()
			self.illustion = nil
		end
		if not self.blend then
			self.blend = self:add_blend('2', 'frame', 2)
		end
		return true
	end)
	self.illustion:event '受到伤害开始' (function()
		if self.illustion then
			self.illustion:get_point():add_effect([[Abilities\Spells\Orc\MirrorImage\MirrorImageDeathCaster.mdl]]):remove()
			self.illustion:remove()
			self.illustion = nil
		end
		if not self.blend then
			self.blend = self:add_blend('2', 'frame', 2)
		end
		return true
	end)

	self.buff = hero:add_buff '高度'
	{
		time = 0.1,
		speed = self.max_height / 0.1,
	}

	self.eff = hero:add_effect('hand',[[Abilities\Weapons\PhoenixMissile\Phoenix_Missile.mdl]])
	hero:issue_order 'stop'
	self.trg2 = hero:event '单位-发布指令' (function(_, _, order, target)
		if order ~= 'smart' then
			return
		end
		local point = nil
		if target.get_point then
			point = target:get_point()
		else
			point = target
		end
		--到目标点的距离大于施法距离则按最大距离算
		if (hero:get_point() * point) > self.range then
			point = hero:get_point() - {(hero:get_point()/point), self.range}
		end

		hero:blink(point)
		point:add_effect([[chaosexplosion.mdl]]):remove()

		local damage =  self.damage + self.damage_plus
		if self.blend then
			damage = damage * (1 + self.damage_rate / 100)
			for i = 1, 12 do
				local eff = (point - {i * 30, self.area}):add_effect([[crimsonwake.mdl]])
				eff:remove()
			end
		end

		for _, u in ac.selector()
			: in_range(point, self.area)
			: is_enemy(hero)
			: ipairs()
		do
			u:add_buff '晕眩'
			{
				source = hero,
				time = self.stun,
			}
			u:damage
			{
				source = hero,
				skill = self,
				damage = damage,
				aoe = true,
			}
		end
		self:finish()
	end)
end

function mt:on_cast_stop()
	local hero = self.owner
	self.buff:remove()
	hero:add_high(-self.max_height)
	hero:remove_restriction '幽灵'
	hero:remove_restriction '定身'
	hero:remove_restriction '隐身'
	if self.eff then self.eff:remove() end
	if self.trg1 then self.trg1:remove() end
	if self.trg2 then self.trg2:remove() end
	if self.illustion then
		self.illustion:get_point():add_effect([[Abilities\Spells\Orc\MirrorImage\MirrorImageDeathCaster.mdl]]):remove()
		self.illustion:remove()
	end
	if self.blend then
		self.blend:remove()
	end
end
