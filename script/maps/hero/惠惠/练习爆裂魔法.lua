local mt = ac.skill['练习爆裂魔法']

mt{
	level = 0,
	art = [[model\megumin\BTNMeguminW.blp]],
	title = '练习爆裂魔法',
	tip = [[
效果和使用方法同|cffff3333爆裂魔法|r。
造成伤害时不会造成伤害，而是每命中一个单位获得%exp_per_unit%点|cffffaaaa爆裂魔法熟练度|r，命中英雄时获得5倍的熟练度。
|cffffaaaa爆裂魔法熟练度|r会强化你的|cffff3333爆裂魔法|r和|cff00ccff适合剧情展开的结界|r。

|cffffaaaa爆裂魔法熟练度|r Lv%explosion_lv% |cff888888(%explosion_exp%/%explosion_max_exp%)|r

|cffff3333爆裂魔法|r 伤害 +%explosion_damage%%
|cffff3333爆裂魔法|r 伤害范围 +%explosion_area%
|cffff3333爆裂魔法|r 施法距离 +%explosion_range%
|cff00ccff适合剧情展开的结界|r 作用范围 +%explosion_seal%
	]],

	ignore_cool_save = true,
	range = function (self, hero)
		if self.explosion then
			return self.explosion.range
		end
		return ac.skill['爆裂魔法-释放'].range
	end,
	cost = 0,
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
	instant = 1,
	cast_start_time = 0,
	cast_channel_time = 0,
	cast_shot_time = 0,
	cast_finish_time = 0,
	cast_animation = 'stand',
	exp_per_unit = {2, 6},
	show_stack = 1,
}

mt.explosion_lv  = 1
mt.explosion_exp = 0
mt.explosion_max_exp = 10
mt.explosion_damage = 0
mt.explosion_range = 0
mt.explosion_area = 0
mt.explosion_seal = 0

function mt:on_add()
	local hero = self.owner
	self:set('explosion', hero:find_skill '爆裂魔法-释放')
	self.explosion.wskl = self
	self:set_stack(self:get 'explosion_lv')
end

function mt:on_cast_channel()
	local hero = self.owner
	local skl = hero:find_cast '爆裂魔法-释放'
	if skl then
		if not self.explosion.explosion_can_convert then
			if skl.explosion_training then
				skl:stop()
			end
			return
		else
			if skl.explosion_training then
				skl:stop()
			else
				skl:explosion_convert(true)
			end
			return
		end
	end
	self.explosion:cast(self.target, {explosion_training = true})
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

local level = {
	{
		explosion_max_exp = 10,
		explosion_damage = 0,
		explosion_range = 0,
		explosion_area = 0,
		explosion_seal = 0,
	},
	{
		explosion_max_exp = 30,
		explosion_damage = 5,
		explosion_range = 50,
		explosion_area = 20,
		explosion_seal = 20,
	},
	{
		explosion_max_exp = 60,
		explosion_damage = 10,
		explosion_range = 100,
		explosion_area = 40,
		explosion_seal = 40,
	},
	{
		explosion_max_exp = 100,
		explosion_damage = 15,
		explosion_range = 150,
		explosion_area = 60,
		explosion_seal = 60,
	},
	{
		explosion_max_exp = 150,
		explosion_damage = 20,
		explosion_range = 200,
		explosion_area = 80,
		explosion_seal = 80,
	},
	{
		explosion_max_exp = 210,
		explosion_damage = 25,
		explosion_range = 250,
		explosion_area = 100,
		explosion_seal = 100,
	},
	{
		explosion_max_exp = 270,
		explosion_damage = 30,
		explosion_range = 300,
		explosion_area = 120,
		explosion_seal = 120,
	},
	{
		explosion_max_exp = 'max',
		explosion_damage = 35,
		explosion_range = 350,
		explosion_area = 140,
		explosion_seal = 140,
	},
}

function mt:explosion_training(n)
	if self.explosion.explosion_training_building then
		n = n * 1.2
	end
	self:add_exp(n * self.exp_per_unit)
end

function mt:explosion_cast(rate)
	local total_exp = self:get 'explosion_exp'
	for i = 1, self:get 'explosion_lv' - 1 do
		total_exp = total_exp + level[i]['explosion_max_exp']
	end
	total_exp = total_exp * rate
	for _, key in ipairs {
		'explosion_lv',
		'explosion_exp',
		'explosion_max_exp',
		'explosion_damage',
		'explosion_range',
		'explosion_area',
		'explosion_seal',
	} do
		self:set(key, ac.skill['练习爆裂魔法'][key])
	end
	self:set_stack(self:get 'explosion_lv')
	self:add_exp(total_exp)
end

function mt:add_exp(n)
	local hero = self.owner
	self:set('explosion_exp', self:get 'explosion_exp' + n)
	while self:get('explosion_max_exp') ~= 'max' and self:get('explosion_exp') >= self:get('explosion_max_exp') do
		self:set('explosion_lv', self:get 'explosion_lv' + 1)
		self:set_stack(self:get 'explosion_lv')
		local lvinfo = level[self:get 'explosion_lv']
		self:set('explosion_exp', self:get('explosion_exp') - self:get('explosion_max_exp'))
		self:set('explosion_max_exp', lvinfo['explosion_max_exp'])
		self:set('explosion_damage', lvinfo['explosion_damage'])
		self:set('explosion_range', lvinfo['explosion_range'])
		self:set('explosion_area', lvinfo['explosion_area'])
		self:set('explosion_seal', lvinfo['explosion_seal'])
		self.explosion:explosion_update_data('damage_ratio', nil, 1 + self.explosion_damage / 100)
		self.explosion:explosion_update_data('range', self.explosion_range)
		self.explosion:explosion_update_data('area', self.explosion_area)
		self.explosion:explosion_fresh()
		local skl = hero:find_skill '适合剧情展开的结界'
		if skl then
			skl.area = ac.skill['适合剧情展开的结界'].area + self.explosion_seal
			skl:fresh()
		end
	end
end
