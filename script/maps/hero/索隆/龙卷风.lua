local mt = ac.skill['龙卷风']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNZoroQ.blp]],

	--技能说明
	title = '龙卷风',
	
	tip = [[|cff11ccff被动：|r索隆对每个敌人的第三下攻击会在%dur_time2%秒内降低其%slow_rate%%的移动速度。|n|cffffcc00主动：|r索隆凭空手卷起气流，将周围%radius%范围的随机%target_count%个敌人吹起，持续%dur_time%秒，每秒造成%damage%(+%damage_plus%)的伤害。冷却过程中被动失效。
	]],

	--耗蓝
	cost = 110,

	--冷却
	cool = 14,

	--持续时间（被动）
	dur_time2 = 0.5,

	--被动标记时间
	debuff_time = 30,
	
	--触发层数
	max_stack = 3,

	--移动速度降低
	slow_rate = 70,

	--持续时间（主动）
	dur_time = {1,3},

	--目标数量
	target_count = 2,

	--范围
	radius = 400,
	
	--伤害
	damage = {80,150},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.4
	end,
}

--主动
function mt:on_cast_channel()
	local hero = self.owner
	local group = ac.selector()
		: in_range(hero, self.radius)
		: is_enemy(hero)
		: sort_nearest_hero(hero)
		: get()
	local damage = self.damage + self.damage_plus
	hero:get_point():add_effect([[modeldekan\ability\DEKAN_Zoro_Q_Tornado_Tag.mdx]]):remove()
	for i=1,self.target_count do
		if #group > 0 then
			local u = table.remove(group, math.random(#group))
			u:add_buff '龙卷风-吹起'
			{
				source = hero,
				time = self.dur_time,
				skill = self,
				--龙卷风并不是眩晕，而是降低90%的攻击速度和移动速度
				slow_rate = 90,
				damage = damage,
			}
		end
	end
end

--被动
mt.orb = nil

function mt:on_upgrade()
	if self:get_level() == 1 then
		local hero = self.owner		
		--添加法球
		self.buff = hero:add_buff '龙卷风-法球'
		{
			skill = self,
		}
	end
end

function mt:on_remove()
	if self.buff then self.buff:remove() end
end

function mt:add_q_buff(target)
	self:update_data()
	if self:is_cooling() then
		return
	end
	
	local hero = self.owner
	target:add_buff '龙卷风-连击'
	{
		source = hero,
		skill = self,
		time = self.debuff_time,
		max_stack = self.max_stack,
		dur_time2 = self.dur_time2,
		slow_rate = self.slow_rate,
	}
end


local mt = ac.orb_buff['龙卷风-法球']

function mt:on_hit(damage)
	self.skill:add_q_buff(damage.target)
end


local mt = ac.buff['龙卷风-吹起']

mt.pulse = 0.5
mt.eff = nil
mt.debuff = true
mt.slowbuff = nil

function mt:on_add()
	local hero = self.source
	local u = self.target
	--吹起
	self.eff = u:get_point():add_effect([[modeldekan\ability\DEKAN_Zoro_Q_Tornado.mdl]])
	self.buff = u:add_buff '高度'
	{
		time = 1,
		speed = 300,
	}
	self.slowbuff = u:add_buff '减攻速'
	{
		source = hero,
		move_speed_rate = self.slow_rate,
		attack_speed = 200,
		time = self.time,
		--model = [[modeldekan\ability\DEKAN_Zoro_Q_Tornado.mdl]],
		skill = self.skill,
	}
	--u:set_high(300)
end

function mt:on_remove()
	local hero = self.source
	local u = self.target
	self.buff:remove()
	local buff = u:add_buff '高度'
	{
		time = 0.3,
		speed = -1000,
	}
	
	if not buff then
		u:add_high(-300)
	end
	
	self.eff:remove()
end

function mt:on_pulse()
	local hero = self.source
	local u = self.target
	u:damage
	{
		source = hero,
		damage = self.damage * self.pulse,
		skill = self.skill,
	}
end

function mt:on_cover(dest)
	self.source = dest.source
	self:set_remaining(dest.time)
	self.slowbuff:set_remaining(dest.time)
	return false
end

local bff = ac.buff['龙卷风-连击']

bff.eff1 = nil
bff.eff2 = nil

function bff:on_add()
	self:fresh()
end

function bff:on_remove()
	for i = 1, self.max_stack - 1 do
		local eff = self['eff' .. i]
		if eff then
			eff:remove()
		end
	end
	if self.asuna_q_buff_texttag then
		self.asuna_q_buff_texttag:remove()
	end
end

function bff:fresh()
	local target = self.target
	self:add_stack()
	local count = self:get_stack()
	
	if count == 1 then
		local tt = ac.texttag
		{
			string = '1',
			size = 12,
			position = target:get_point(),
			zoffset = 80,
			red = 0,
			green = 100,
			blue = 30,
			permanent = true,
			player = self.source:get_owner(),
			show = ac.texttag.SHOW_SELF,
			target = target,
		}
		self.asuna_q_buff_texttag = tt
		self.asuna_q_buff_texttag:jump(1.8,-0.3)
	elseif count == 2 then
		self.asuna_q_buff_texttag:setText('2')
		self.asuna_q_buff_texttag:jump(1.8,-0.3)
	end
	
	if count >= self.max_stack then
		target:get_point():add_effect([[ModelDEKAN\Ability\DEKAN_Zoro_Q_Tornado_Death.mdl]]):remove()
		--减速
		target:add_buff '减速'
		{
			source = self.source,
			time = self.dur_time2,
			move_speed_rate = self.slow_rate,
			skill = self.skill,
		}
		self:remove()
	end
end

function bff:on_cover(dest)
	self.source = dest.source
	self.max_stack = dest.max_stack
	self:set_remaining(dest.time)
	self:fresh()
	return false
end
