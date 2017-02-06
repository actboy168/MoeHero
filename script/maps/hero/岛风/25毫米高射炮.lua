local mt = ac.skill['25毫米高射炮']

mt{
	level = 0,
	max_level = 3,
	requirement = {6, 11, 16},
	art = [[replaceabletextures\commandbuttons\BTNmarisaE.blp]],
	title = '25毫米高射炮',
	tip = [[
对一片区域进行炮火打击，造成伤害。
	]],
	cool = 0,
	cost = 0,
	range = 3000,
	cast_start_time = 0.2,
	target_type = ac.skill.TARGET_TYPE_POINT,
	area = 300,
	time = 2,
}

function mt:shimakazeCast(target)
	local target_mark = target:effect
	{
		model = [[model\dantalian\target_mark.mdl]], 
		size = self.area / 400,
		speed = 3 / self.time,
		height = 50,
	}
	ac.wait(self.time * 1000, function ()
		target_mark:remove()
	end)
end

function mt:on_cast_shot()
	local hero = self.owner
	local n = 2
	local skl = hero:find_skill '连装炮酱'
	if skl then
		for _, dummy in ipairs(skl:getShimakaze()) do
			if dummy:get_point() * self.target <= self.range then
				n = n + 2
			end
		end
	end
	local list = {}
	for i = 1, n do
		local target = self.target - { 360 / n * (i + math.random()/2), math.random(100, 300 + n * 50)}
		table.insert(list, target)
	end
	for i = 1, n do
		local k = math.random(n)
		local tmp = list[k]
		list[k] = list[i]
		list[i] = tmp
	end
	ac.timer(200, #list, function()
		local target = list[#list]
		list[#list] = nil
		self:shimakazeCast(target)
	end)
end
