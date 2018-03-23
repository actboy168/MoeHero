
for i = 1, 16 do
	local p = ac.player(i)
	p.ability_list = {}
	if i <= 10 then
		p.ability_list['英雄'] = {size = 4}
		p.ability_list['学习'] = {size = 4}
		p.ability_list['智能施法'] = {size = 4}
		for x = 1, p.ability_list['英雄'].size do
			p.ability_list['英雄'][x] = ('A0%d%d'):format(i - 1, x - 1)
		end
		for x = 1, p.ability_list['学习'].size do
			p.ability_list['学习'][x] = ('AL%d%d'):format(i - 1, x)
		end
		for x = 1, p.ability_list['智能施法'].size do
			p.ability_list['智能施法'][x] = ('AF0%d'):format(x)
		end
	elseif i == 16 then
		p.ability_list['预览'] = {size = 4}
		for x = 1, p.ability_list['预览'].size do
			p.ability_list['预览'][x] = ('A20%d'):format(x - 1)
		end
	end
end
