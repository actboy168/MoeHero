local mt = ac.skill['适合剧情展开的结界']

mt{
	level = 0,
	art = [[model\megumin\BTNMeguminE.blp]],
	title = '适合剧情展开的结界',
	tip = [[
吟唱|cffff3333爆裂魔法|r或练习|cffff3333爆裂魔法|r时，可以使用。
%area%范围内区域时间停止，直到|cffff3333爆裂魔法|r释放完毕。
	]],

	cost = 0,
	cool = {32, 24},
	area = 400,
	instant = 1,
}

function mt:on_can_cast()
	local hero = self.owner
	local skl = hero:find_cast '爆裂魔法-释放'
	if not skl then
		return false, '没有检测到爆裂魔法'
	end
	return true
end

function mt:on_cast_shot()
	local hero = self.owner
	local area = self.area
	hero:add_buff '适合剧情展开的结界'
	{
		time = 5,
		area = area,
		skill = self,
		selector = ac.selector()
			: in_range(hero, area)
			: allow_god()
			,
	}
end

local mt = ac.aura_buff['适合剧情展开的结界']

mt.aura_pulse = 0.1
mt.child_buff = '适合剧情展开的结界-时停'
mt.force = true

function mt:on_add()
	local hero = self.target
	local animation = (self.area - 400) / 20
	if animation < 0 then animation = 0 end
	if animation > 10 then animation = 10 end
	self.eff = hero:effect
	{
		model = [[model\megumin\effect_e.mdl]],
		animation = animation,
	}
	self.block = hero:create_block { area = self.area }
	function self.block:on_entry(mover)
		mover:pause(true)
	end
end

function mt:on_remove()
	local hero = self.target
	for mover in pairs(self.block.movers) do
		mover:pause(false)
	end
	self.block:remove()
	self.eff:remove()
end

local mt = ac.buff['适合剧情展开的结界-时停']

mt.cover_type = 1
mt.cover_max = 1
mt.force = true

function mt:on_add()
	if self.source == self.target then
		return
	end
	self.target:add_restriction '时停'
end

function mt:on_remove()
	if self.source == self.target then
		return
	end
	self.target:remove_restriction '时停'
end

function mt:on_cover(new)
	return false
end
