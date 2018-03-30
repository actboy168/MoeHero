
local mt = ac.skill['爆裂魔法-释放']

mt{
	level = 1,
	title = '爆裂魔法',
	tip = [[
吟唱%cast_channel_time%秒，对%area%范围的敌人造成%damage%伤害%tip2%。%tip3%
如果命中两个以上敌方英雄，对其伤害降低%hero_damage_rate%%。
|cffff3333爆裂魔法|r被打断时，返还消耗的魔力。
	]],
	cost = 0,
	cool = 0,
	range = 1000,
	area = 400,
	cast_channel_time = 3,
	break_cast_channel = 1,
	target_type = ac.skill.TARGET_TYPE_POINT,
	hero_damage_rate = {52, 36},
	damage_ratio = 8,
	damage_rate = 1,
	damage_pene_rate = 20,
	damage_base = {60, 100},
	damage = function (self, hero)
		return (self.damage_base + hero:get_ad()) * self.damage_ratio * self.damage_rate
	end,
	tip2 = function (self, hero)
		if self.damage_pene_rate <= 0 then
			return [[]]
		end
		return [[(|cff888888穿透+%damage_pene_rate%%|r)]]
	end,
	tip3 = function (self, hero)
		if self.explosion_nohard then
			return [[]]
		end
		return [[之后自己硬直2秒。]]
	end,
}

function mt:explosion_update_data(key, add, mul)
	if add then
		self[key .. '_add'] = add
	elseif not self[key .. '_add'] then
		self[key .. '_add'] = 0
	end
	if mul then
		self[key .. '_mul'] = mul
	elseif not self[key .. '_mul'] then
		self[key .. '_mul'] = 1
	end
	self[key] = (ac.skill['爆裂魔法-释放'][key] + self[key .. '_add']) * self[key .. '_mul']
end

function mt:explosion_fresh()
	local hero = self.owner
	self:fresh()
	if self.qskl then self.qskl:fresh() end
	if self.wskl then self.wskl:fresh() end
end

function mt:explosion_convert(training)
	if training then
		if self.explosion_training then
			return
		end
	else
		if not self.explosion_training then
			return
		end
	end
	local hero = self.owner
	self.explosion_training = training
	if not self.qskl or not self.wskl then
		return
	end
	self.qskl:explosion_enable()
	self.wskl:explosion_enable()
	if not self.explosion_training then
		self.qskl:explosion_disable()
		self.qskl:set_cd(self.wskl:get_cd())
		self.wskl:set_cd(0)
	else
		self.wskl:explosion_disable()
		self.wskl:set_cd(self.qskl:get_cd())
		self.qskl:set_cd(0)
	end
end

function mt:on_cast_channel()
	local hero = self.owner
	-- 施法点视野
	self.fog = hero:get_owner():createFogmodifier(self.target, self.area)
	-- 施法特效、动画、声音
	local function cast_animation()
		self.target_mark = self.target:effect
		{
			model = [[model\dantalian\target_mark.mdl]], 
			size = self.area / 400,
			height = 50,
		}
		local sound_time = self.cast_channel_time
		if not self.explosion_fast_channel then
			sound_time = sound_time - 0.5
		end
		if sound_time < 2.1 then
			hero:get_owner():play_sound [[response\惠惠\skill\Explosion.mp3]]
		elseif sound_time < 2.8 then
			hero:wait(sound_time * 1000 - 2000, function ()
				hero:get_owner():play_sound [[response\惠惠\skill\Explosion.mp3]]
			end)
		elseif sound_time < 3.1 then
			hero:get_owner():play_sound [[response\惠惠\skill\Explosion_3.mp3]]
		else
			hero:wait(sound_time * 1000 - 3000, function ()
				hero:get_owner():play_sound [[response\惠惠\skill\Explosion_3.mp3]]
			end)
		end
		hero:set_animation_speed(0.3)
		hero:set_animation('spell two alternate')
		self.eff1 = hero:effect
		{
			socket = 'origin', 
			model = [[model\megumin\explosion.mdl]],
		}
		self.animation_timer = hero:wait(500, function()
			hero:set_animation_speed(1)
			self.eff2 = (hero:get_point() - {hero:get_facing(), 270}):effect
			{
				model = [[model\megumin\explosion.mdl]],
				angle = {hero:get_facing(), 90},
				size = 0.7,
				height = 140,
			}
			
			self.eff3 = self.target:effect
			{
				model = [[model\megumin\explosion.mdl]],
				size = 1.8 * self.area / 400,
				height = 500,
				alpha = 50,
			}
			self.eff4 = self.target:effect
			{
				model = [[model\megumin\explosion.mdl]],
				size = 0.4 * self.area / 400,
				height = 400,
				alpha = 50,
			}
			self.eff5 = self.target:effect
			{
				model = [[model\megumin\explosion.mdl]],
				size = 1.0 * self.area / 400,
				height = 300,
				alpha = 50,
			}
			self.eff6 = self.target:effect
			{
				model = [[model\megumin\explosion.mdl]],
				size = 1.6 * self.area / 400,
				height = 200,
				alpha = 50,
			}
			self.eff7 = self.target:effect
			{
				model = [[model\megumin\explosion.mdl]],
				size = 1.0 * self.area / 400,
				height = 100,
				alpha = 50,
			}
			self.eff8 = self.target:effect
			{
				model = [[model\megumin\explosion.mdl]],
				size = 0.4 * self.area / 400,
				height = 0,
				alpha = 50,
			}
		end)
	end
	-- 有高速吟唱后就不抖披风了
	if self.explosion_fast_channel then
		cast_animation()
	else
		hero:set_animation 'spell channel one'
		self.animation_timer = hero:wait(500, function()
			cast_animation()
		end)
	end
	-- 如果没有虚实之道，施法时QW不可用，否则不在施法的那个可用
	if self.explosion_can_convert then
		if not self.explosion_training then
			if self.qskl then
				self.qskl:explosion_disable()
			end
		else
			if self.wskl then
				self.wskl:explosion_disable()
			end
		end
	else
		if self.qskl then
			self.qskl:explosion_disable()
		end
		if self.wskl then
			self.wskl:explosion_disable()
		end
	end
	-- 施法的技能设置冷却
	if self.explosion_training then
		if self.wskl then self.wskl:set_cd(self.cast_channel_time) end
	else
		if self.qskl then self.qskl:set_cd(self.cast_channel_time) end
	end
	-- 右键可以打断施法
	self.break_trigger = hero:event '单位-发布指令' (function(_, _, order)
		if order == 'smart' then
			self:stop()
		end
	end)
	-- 离惠惠或者施法点较近的人会降低光线
	self.light = {}
	for _, u in ac.selector()
		: in_range(self.target, self.area + 400)
		: of_hero()
		: of_not_illusion()
		: ipairs()
	do
		local playerid = u:get_owner().id
		if not self.light[playerid] then
			self.light[playerid] = true
			u:get_owner():set_day('')
		end
	end
	for _, u in ac.selector()
		: in_range(hero, self.range)
		: of_hero()
		: of_not_illusion()
		: ipairs()
	do
		local playerid = u:get_owner().id
		if not self.light[playerid] then
			self.light[playerid] = true
			u:get_owner():set_day('')
		end
	end
end

function mt:on_cast_shot()
	local hero = self.owner
	-- 吟唱结束了，QW不可用
	if self.qskl then
		self.qskl:explosion_disable()
	end
	if self.wskl then
		self.wskl:explosion_disable()
	end
	-- 爆炸特效
	local effect = self.target:effect
	{
		model = [[model\megumin\explosion_bomb.mdl]],
		height = 30,
		size = self.area * 0.002,
		speed = 40,
		animation = 'death',
	}
	-- 如果播放了爆炸特效施法点视野延迟删除
	local fog = self.fog
	self.fog = nil
	ac.wait(100, function()
		effect:set_speed(3)
		ac.wait(2000, function()
			effect:kill()
			fog:remove()
		end)
	end)
	-- 爆炸声音
	self.target:play_sound([[response\惠惠\skill\Boom_]] .. math.floor(math.random(7)) .. '.mp3')
	
	-- 训练
	if self.explosion_training then
		local function do_damage()
			local damage = self.damage * 0.5 * 0.25
			for _, u in ac.selector()
				: in_range(self.target, self.area)
				: is_enemy(hero)
				: ipairs()
			do
				-- 有爆裂道
				if self.explosion_training_building and u:is_type('建筑') then
					u:damage
					{
						source = hero,
						skill = self,
						attack = true,
						aoe = true,
						damage = damage,
						['穿透'] = hero:get '穿透' + self.damage_pene_rate,
					}
				end
				if u:is_hero() then
					self.wskl:explosion_training(2.5)
				else
					self.wskl:explosion_training(0.5)
				end
			end
		end
		do_damage()
		ac.wait(1000, do_damage)
		return
	end

	--消耗熟练度
	if self.wskl then
		self.wskl:explosion_cast(0.1)
	end

	-- 对英雄的效果
	local function do_damage()
		local hero_group = ac.selector()
			: in_range(self.target, self.area)
			: is_enemy(hero)
			: of_hero()
			: get()
		local damage = self.damage / 2
		if #hero_group > 2 then
			damage = damage * (1 - self.hero_damage_rate / 100)
		end
		for _, u in ipairs(hero_group) do
			u:damage
			{
				source = hero,
				skill = self,
				attack = true,
				aoe = true,
				damage = damage,
				['穿透'] = hero:get '穿透' + self.damage_pene_rate,
			}
		end
		-- 对非英雄的效果
		local damage = self.damage / 2
		for _, u in ac.selector()
			: in_range(self.target, self.area)
			: is_enemy(hero)
			: of_not_hero()
			: ipairs()
		do
			u:damage
			{
				source = hero,
				skill = self,
				attack = true,
				aoe = true,
				damage = damage,
				['穿透'] = hero:get '穿透' + self.damage_pene_rate,
			}
		end
	end
	do_damage()
	ac.wait(1000, do_damage)
end

function mt:on_cast_finish()
	local hero = self.owner
	if not self.explosion_training then
		-- 扣除魔力
		local buff = hero:find_buff '爆裂魔法-和真的支援'
		if buff then
			buff:remove()
			hero:add_buff '爆裂魔法-生命吸收'
			{
				skill = self,
			}
		else
			hero:add_resource('魔力', -100)
		end
		-- 没有维兹，施法后进入硬直
		if not self.explosion_nohard then
			self.explosion_stagger = true
			hero:cast('爆裂魔法-硬直')
		end
	end
end

function mt:on_cast_stop()
	local hero = self.owner
	-- 清除特效
	if self.target_mark then self.target_mark:remove() end
	if self.fog then self.fog:remove() end
	if self.eff1 then self.eff1:remove() end
	if self.eff2 then self.eff2:remove() end
	if self.eff3 then self.eff3:remove() end
	if self.eff4 then self.eff4:remove() end
	if self.eff5 then self.eff5:remove() end
	if self.eff6 then self.eff6:remove() end
	if self.eff7 then self.eff7:remove() end
	if self.eff8 then self.eff8:remove() end
	self.break_trigger:remove()
	self.animation_timer:remove()
	-- 如果没有硬直，重置动画
	if not self.explosion_stagger then
		hero:remove_buff '适合剧情展开的结界'
		hero:set_animation_speed(1)
		hero:set_animation('stand')
	end
	-- 重置冷却, 恢复QW可用
	if self.qskl then
		self.qskl:set_cd(0)
		self.qskl:explosion_enable()
	end
	if self.wskl then
		self.wskl:set_cd(0)
		self.wskl:explosion_enable()
	end
	-- 恢复光线
	for id in pairs(self.light) do
		ac.player(id):set_day(nil)
	end
end

local mt = ac.skill['爆裂魔法-硬直']
mt{
	cast_animation = 'death alternate',
	cast_animation_speed = 1.5625,
	cast_start_time = 1.1,
	cast_channel_time = 10,
	cast_shot_time = 0.4,
	cast_finish_time = 0.4,
}

function mt:on_cast_channel()
	local hero = self.owner
	self.break_timer = hero:wait(500, function()
		hero:remove_buff '适合剧情展开的结界'
		self.break_trigger = hero:event '单位-发布指令' (function(_, _, order)
			self:finish()
		end)
	end)
end

function mt:on_cast_shot()
	local hero = self.owner
	hero:set_animation('spell channel three')
end
function mt:on_cast_stop()
	if self.break_timer then self.break_timer:remove() end
	if self.break_trigger then self.break_trigger:remove() end
end

local mt = ac.skill['爆裂魔法']
local data = {
	level = 0,
	art = [[model\megumin\BTNMeguminQ.blp]],
	tip_relation = '爆裂魔法-释放',
	instant = 1,
	cast_start_time = 0,
	cast_channel_time = 0,
	cast_shot_time = 0,
	cast_finish_time = 0,
	cast_animation = 'stand',
	ignore_cool_save = true,
	range = function (self, hero)
		if self.explosion then
			return self.explosion.range
		end
		return ac.skill['爆裂魔法-释放'].range
	end,
	cost = 100,
	cool = function (self, hero)
		if self.explosion then
			return self.explosion.cast_channel_time
		end
		return ac.skill['爆裂魔法-释放'].cast_channel_time
	end,
	target_type = function (self, hero)
		if self.explosion then
			return self.explosion.target_type
		end
		return ac.skill['爆裂魔法-释放'].target_type
	end,
	area = function (self, hero)
		if self.explosion then
			return self.explosion.area
		end
		return ac.skill['爆裂魔法-释放'].area
	end,
}

for k, v in pairs(ac.skill['爆裂魔法-释放'].data) do
	if not data[k] then
		data[k] = v
	end
end
mt(data)

function mt:on_add()
	local hero = self.owner
	self:set('explosion', hero:find_skill '爆裂魔法-释放')
	self.explosion.qskl = self
end

function mt:on_upgrade()
	self.explosion:set_level(self:get_level())
end

function mt:on_cast_channel()
	local hero = self.owner
	local skl = hero:find_cast '爆裂魔法-释放'
	if skl then
		if not self.explosion.explosion_can_convert then
			if not skl.explosion_training then
				skl:stop()
			end
			return
		else
			if not skl.explosion_training then
				skl:stop()
			else
				if not self.ignore_cost then
					hero:add_resource('魔力', 100)
				end
				skl:explosion_convert(false)
			end
			return
		end
	end
	if not self.ignore_cost then
		hero:add_resource('魔力', 100)
	end
	self.explosion:cast(self.target)
end

function mt:explosion_enable()
	if not self.has_explosion_disable then
		return
	end
	self.has_explosion_disable = false
	self:set_option('passive', false)
end

function mt:explosion_disable()
	if self.has_explosion_disable then
		return
	end
	self.has_explosion_disable = true
	self:set_option('passive', true)
end

local mt = ac.buff['爆裂魔法-生命吸收']

mt.keep = true
mt.pulse = 1

function mt:on_add()
	local hero = self.target
	local time = 100 / hero:get_resource '魔力恢复'
	self:set_time(time)
	self:set_remaining(time)
	self.target_skill = hero:find_skill('爆裂魔法', nil, true)
	self.target_skill:show_buff(self)
end

function mt:on_pulse()
	local hero = self.target
	local time = 100 / hero:get_resource '魔力恢复'
	if time ~= self.time then
		local rate = self:get_remaining() / self.time
		self:set_time(time)
		self:set_remaining(time * rate)
	end
end

function mt:on_finish()
	local hero = self.target
	hero:add_buff '爆裂魔法-和真的支援'
	{
		skill = self.skill,
		target_skill = self.target_skill,
	}
end

local mt = ac.buff['爆裂魔法-和真的支援']

function mt:on_add()
	self.blend = self.target_skill:add_blend('2', 'frame', 2)
	self.target_skill:set_option('ignore_cost', true)
end

function mt:on_remove()
	self.blend:remove()
	self.target_skill:set_option('ignore_cost', false)
end
