local mt = ac.skill['八之弹']

mt{
	instant = 1,
}

local hero_id = { 'H004', 'H005', 'H006', 'H007' }

function mt:on_add()
	self.dummys = {}
end

function mt:on_remove()
	for _, dummy in ipairs(self.dummys) do
		dummy:remove()
	end
    self.dummys = {}
end

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local dummy = hero:create_illusion(target, true)
	if not dummy then
		return
	end
	if math.random(10) == 1 then
		local hero_id = hero_id[math.random(#hero_id)]
		if hero_id ~=  dummy:get_type_id() then
			dummy:transform(hero_id)
		end
	end
	dummy:set('攻击', hero:get('攻击') * (0.04 + hero:get_level() * 0.02))
	dummy:set('破甲', hero:get('破甲'))
	dummy:set('暴击', hero:get('暴击'))
	dummy:add_restriction '定身'
	dummy:add_restriction '无敌'
	table.insert(self.dummys, dummy)
	dummy.remove_timer = ac.wait(10000, function()
		for i = 1, #self.dummys do
			if dummy == self.dummys[i] then
				table.remove(self.dummys, i)
				break
			end
		end
        if dummy.removed then
            return
        end
		dummy:add_restriction '硬直'
		dummy:set_animation 'spell channel two'
		dummy:set_animation_speed(-0.2)
		ac.wait(700, function()
			dummy:remove()
		end)
	end)
	if hero:is_ally(ac.player.self) then
		dummy:setColor(50, 50, 50)
	end
	if self.call_back then
		self:call_back(dummy)
	end
end
