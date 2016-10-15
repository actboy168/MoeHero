
local rect = require 'types.rect'
local player = require 'ac.player'

local bff = ac.buff['基地光环']

bff.pulse = 0.5

function bff:on_pulse()
	local unit = self.target
	local area = 1000
	local life_rate = 10
	local mana_rate = 10
	local pulse = self.pulse
	
	for _, u in ac.selector()
		: in_range(unit, area)
		: is_not(unit)
		: ipairs()
	do
		if u:is_ally(unit) then
			local life = u:get '生命'
			local max_life = u:get '生命上限'
			if life < max_life then
				u:add('生命', max_life * life_rate / 100 * pulse)
			end

			local mana = u:get_resource '魔法'
			local max_mana = u:get_resource '魔法上限'
			if mana < max_mana then
				u:add_resource('魔法', max_mana * mana_rate / 100 * pulse)
			end
		else
			if u:get_type_id() ~= 'e00D' then
				u:add_effect('origin', [[!orbitalray2!.mdl]]):remove()
				u:damage
				{
					source = unit,
					damage = 1000,
					skill = false,
				}
			end
		end
	end
end


--创建泉水回血
for i = 1, 2 do
	local u = player.com[i]:create_unit('e001', rect.j_rect('player_home_' .. i))
	u:add_buff '基地光环' {}
end
