
local mt = ac.skill['风王结界']

mt{
	--初始等级
	level = 0,
	
	--技能图标
	art = [[BTNsaberq.blp]],

	--技能说明
	title = '风王结界',
	
	tip = [[
激活风王结界,提高%pene%点护甲穿透并持续对%slow_area%范围造成减速效果,持续%buff_time%秒

再次按下该技能解放风王结界,对%stun_area%范围造成%stun_time%秒晕眩,下次攻击额外造成%damage%(+%damage_plus%)点伤害
	]],

	--冷却
	cool = {17, 14},

	--耗蓝
	cost = 100,

	--护甲穿透
	pene = {5, 25},

	--减速范围
	slow_area = 500,

	--移速降低(%)
	slow_rate = {5, 25},

	--持续时间
	buff_time = 6,

	--晕眩范围
	stun_area = 500,

	--晕眩时间
	stun_time = 1,

	--额外伤害
	damage = {70, 270},

	--额外伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1.6
	end,

	--解放Buff持续时间
	attack_buff_time = 3,
}

function mt:on_cast_channel()
	local hero = self.owner
	hero:add_buff '风王结界-激活'
	{
		pene = self.pene,
		slow_area = self.slow_area,
		slow_rate = self.slow_rate,
		time = self.buff_time,
	}
end

local mt = ac.buff['风王结界-激活']

mt.pulse = 0.5

mt.pene = 0
mt.eff = nil

function mt:on_add()
	local hero = self.target
	
	hero:add('破甲', self.pene)
	hero:replace_skill('风王结界', '风王结界-解放')

	self.eff = hero:add_effect('origin',[[modeldekan\ability\DEKAN_Saber_Q_WindBuff2.mdl]])

end

function mt:on_remove()
	local hero = self.target

	hero:add('破甲', - self.pene)
	self.eff:remove()
	hero:replace_skill('风王结界-解放', '风王结界')
end

function mt:on_pulse()
	local hero = self.target
	local move_speed_rate = self.slow_rate
	local time = self.pulse + 0.1
	for _, u in ac.selector()
		: in_range(hero, self.slow_area)
		: is_enemy(hero)
		: ipairs()
	do
		u:add_buff '减速'
		{
			source = hero,
			move_speed_rate = move_speed_rate,
			time = time,
			model = [[Abilities\Spells\Other\Tornado\Tornado_Target.mdl]],
		}
	end
end

function mt:on_cover()
	return true
end
