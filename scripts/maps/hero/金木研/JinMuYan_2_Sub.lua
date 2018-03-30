



local mt = ac.skill['JinMuYan_2_Sub']

mt{
	--技能图标
	art = [[BTNjmyw.blp]],

	--技能说明
	title = '横扫甩击(连击)',
	
	tip = [[
冲向目标造成伤害
	]],

	--动画
	cast_animation = 'Spell two',

	--动画速度
	cast_animation_speed = 3,

	--施法前摇
	cast_start_time = 0.4,
	cast_channel_time = 10,
	cast_shot_time = 0.3,
	
	--飞行距离
	distance = 500,

	--飞行速度
	speed = 1200,

	--伤害
	damage = {0, 75, 150, 225},

	--伤害加成
	damage_plus = function(self, hero)
		return hero:get_ad() * 1
	end,

	break_order = 1,
}

function mt:on_cast_start()
	local hero = self.owner
	local bff = hero:find_buff 'JinMuYan_2_Buff'
	if not bff then
		self:stop()
		return
	end

	local dest = bff.dest
	hero:set_facing(hero:get_point() / dest:get_point())
end

function mt:on_cast_channel()
	local hero = self.owner
	local bff = hero:find_buff 'JinMuYan_2_Buff'
	if not bff then
		self:stop()
		return
	end

	local dest = bff.dest
	local damage = self.damage + self.damage_plus

	bff:remove()

	--播放动画
	hero:set_animation 'Spell three'
	hero:add_animation 'stand'
	
	local mvr = ac.mover.target
	{
		source = hero,
		mover = hero,
		target = dest,
		speed = self.speed,
		distance = self.distance,
		skill = self,
		hit_area = self.hit_area,
	}

	if not mvr then
		self:stop()
		return
	end

	function mvr:on_move()
		hero:set_facing(hero:get_point() / dest:get_point())
	end

	function mvr:on_finish()
		local dest = self.target
		hero:set_animation 'Spell one'
		hero:add_animation 'stand'
		hero:set_facing(hero:get_point() / dest:get_point())

		dest:add_effect('origin', [[Objects\Spawnmodels\Human\HumanBlood\BloodElfSpellThiefBlood.mdl]]):remove()
		dest:add_effect('chest', [[Objects\Spawnmodels\Human\HumanBlood\BloodElfSpellThiefBlood.mdl]]):remove()

		--造成伤害
		dest:damage
		{
			source = self.source,
			damage = damage,
			skill = self.skill
		}
		self.skill:finish()
		return true
	end

	function mvr:on_remove()
		self.skill:stop()
	end
end
