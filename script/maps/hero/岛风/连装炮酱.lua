local mt = ac.skill['连装炮酱']

mt{
	level = 0,
	art = [[replaceabletextures\commandbuttons\BTNmarisaE.blp]],
	title = '连装炮酱',
	tip = [[
召唤|cff11ccff连装炮酱|r并肩作战。你每次使用其他技能时，|cff11ccff连装炮酱|r也会同时使用。
|cff11ccff连装炮酱|r最多同时存在%count%个。
	]],
	cool = 0,
	cost = 0,
	range = 9999,
	cast_start_time = 0.2,
	target_type = ac.skill.TARGET_TYPE_POINT,
	count = {1,1,2,2,3}
}

local function create_gun(hero, target)
	local dummy = hero:create_unit('e00Q', target)
	dummy:add_enemy_tag()
	dummy:set_animation('birth')
	dummy:add_animation('stand')
	dummy:set('攻击', hero:get('攻击'))
	dummy:event '造成伤害' (function (_, damage)
		local target = damage.target
		if target:is_type('建筑') then
			damage:div(0.6)
		end
	end)
	dummy:event '单位-攻击出手' (function (_, damage)
		dummy:set_facing(dummy:get_point() / damage.target:get_point())
	end)
	return dummy
end

function mt:on_add()
	self:set('连装炮酱', {})
end

function mt:on_remove()
	for _, dummy in ipairs(self:get('连装炮酱')) do
		dummy:kill()
	end
	self:set('连装炮酱', {})
end

function mt:on_cast_shot()
	local hero = self.owner
	local dummy = create_gun(hero, self.target)
	local group = self:get('连装炮酱')
	if #group >= self.count then
		group[1]:kill()
		table.remove(group, 1)
	end
	table.insert(group, dummy)
end
