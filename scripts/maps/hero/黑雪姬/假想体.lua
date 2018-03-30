local mt = ac.skill['假想体']

mt.is_follow = false
mt.is_idle = true

function mt:create_dummy(target)
	local hero = self.owner
	if not hero:is_alive() then
		return nil
	end
	local p = hero:get_point()
	local face = hero:get_facing()
	if self.dummy then
		p = self.dummy:get_point()
		self.dummy:remove()
	end
	if target then
		face = p / target:get_point()
	end
	local dummy = hero:create_dummy('e004', p, face)
	self.dummy = dummy
	--dummy:set_size(1.5)
	if self.buff then
		self.buff:dummy(dummy)
	end
	return dummy
end

function mt:on_add()
	local hero = self.owner
	
	self:follow()

	self.trg1 = hero:event '单位-发动攻击' (function(_, damage)
		self:attack(damage)
		return true
	end)

	self.trg2 = hero:event '单位-死亡' (function()
		if self.dummy then
			self.dummy:remove()
		end
		self.dummy = nil
	end)

	self.trg3 = hero:event '单位-复活' (function()
		self:follow()
	end)

	self.timer = hero:loop(200, function()
		if not self.dummy or not self.is_idle or self.is_follow or self.is_attacking then
			return
		end
		local dis = self.dummy:get_point() * hero:get_point()
		if dis > 2000 then
			self:follow()
		elseif dis > 1000 then
			self:back()
		elseif dis < 150 then
			self:follow()
		end
	end)
end

function mt:on_remove()
	if self.dummy then self.dummy:remove() end
	self.trg1:remove()
	self.trg2:remove()
	self.trg3:remove()
	self.timer:remove()
	self:idle(true)
end

function mt:follow()
	local hero = self.owner
	local dummy = self:create_dummy()
	if not dummy then
		return
	end
	dummy:set_animation 'Morph'
	dummy:add_animation 'stand'
	local buff = hero:add_buff '假想体' {}
	self.is_follow = true
	local mover = hero:follow
	{
		source = hero,
		mover = dummy,
		skill = self,
		angle = 0,
		distance = -100,
		face_follow = true,
		angle_follow = true,
	}
	dummy:event '单位-移除' (function()
		self.is_follow = false
		buff:remove()
	end)

	local skill = hero:find_skill '黑之睡莲'
	if skill then
		skill:on_back()
	end
end

function mt:attack(damage)
	local hero = self.owner
	local target = damage.target
	local dummy = self:create_dummy(target:get_point())
	if not dummy then
		return
	end
	dummy:set_animation 'spell'
	dummy:add_animation 'stand'
	local mover = ac.mover.line
	{
		source = hero,
		mover = dummy,
		angle = dummy:get_point() / target:get_point(),
		distance = dummy:get_point() * target:get_point() + 200,
		speed = 3000,
		skill = self,
		super = true,
	}

	if not mover then
		return
	end

	hero:event_notify('单位-攻击出手', damage)
	target:event_notify('单位-被攻击出手', damage)
	
	function mover:on_finish()
		self.skill.is_attacking = false
		hero:attackDamage(damage)
		target:add_effect('chest', [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]]):remove()
	end

	self.is_attacking = true
	dummy:event '单位-移除' (function()
		self.is_attacking = false
	end)
end

function mt:back()
	local hero = self.owner
	local dummy = self:create_dummy(hero)
	if not dummy then
		return
	end
	dummy:set_animation(4)
	local mover = ac.mover.target
	{
		source = hero,
		mover = dummy,
		target = hero,
		speed = 2000,
		skill = self,
		super = true,
	}

	if not mover then
		return
	end

	function mover:on_remove()
		self.skill:follow()
	end
end

function mt:idle(flag)
	if flag == self.is_idle then
		return
	end
	self.is_idle = flag
	if flag then
		self.owner:remove_restriction '缴械'
	else
		self.owner:add_restriction '缴械'
	end
end


local mt = ac.buff['假想体']

function mt:on_add()
	local hero = self.target
	local skl = hero:find_skill('死亡穿刺', nil, true)
	if skl then
		skl:set_option('target_type', ac.skill.TARGET_TYPE_POINT)
		skl:stop()
	end
	local skl = hero:find_skill('黑之睡莲', nil, true)
	if skl then
		skl:set_option('passive', true)
		skl:set_show_cd()
		skl.blend = skl:add_blend('pas', 'frame', 3)
	end
	local skl = hero:find_skill('死亡旋转', nil, true)
	if skl then
		skl:set_option('target_type', ac.skill.TARGET_TYPE_NONE)
		skl:stop()
	end
end

function mt:on_remove()
	local hero = self.target
	local skl = hero:find_skill('死亡穿刺', nil, true)
	if skl then
		skl:set_option('target_type', ac.skill.TARGET_TYPE_NONE)
		skl:stop()
	end
	local skl = hero:find_skill('黑之睡莲', nil, true)
	if skl then
		skl:set_option('passive', false)
		if skl.blend then
			skl.blend:remove()
			skl.blend = nil
		end
	end
	local skl = hero:find_skill('死亡旋转', nil, true)
	if skl then
		skl:set_option('target_type', ac.skill.TARGET_TYPE_POINT)
		skl:stop()
	end
end
