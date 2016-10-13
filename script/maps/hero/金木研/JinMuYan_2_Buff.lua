
local bff = ac.buff['JinMuYan_2_Buff']

bff.pulse = 0.1

bff.distance = nil

function bff:on_add()
	local hero = self.target

	self:on_pulse()
end

function bff:on_pulse()
	local hero = self.target
	local dest = self.dest
	if dest:is_alive() and hero:get_point() * dest:get_point() <= self.distance then
		hero:replace_skill('JinMuYan_2', 'JinMuYan_2_Sub')
	else
		hero:replace_skill('JinMuYan_2_Sub', 'JinMuYan_2')
	end
end

function bff:on_remove()
	local hero = self.target
	hero:replace_skill('JinMuYan_2_Sub', 'JinMuYan_2')
end

function bff:on_cover()
	return true
end