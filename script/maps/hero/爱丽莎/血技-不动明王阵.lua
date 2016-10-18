local mt = ac.skill['血技-不动明王阵']

local message = require 'jass.message'

local arts = {
	{[[replaceabletextures\commandbuttons\BTNAmiellaSwordQ.blp]], [[replaceabletextures\commandbuttons\BTNAmiellaGunQ.blp]]},
	{[[replaceabletextures\commandbuttons\BTNAmiellaSwordW.blp]], [[replaceabletextures\commandbuttons\BTNAmiellaGunW.blp]]},
	{[[replaceabletextures\commandbuttons\BTNAmiellaSwordE.blp]], [[replaceabletextures\commandbuttons\BTNAmiellaGunE.blp]]},
	{[[replaceabletextures\commandbuttons\BTNAmiellaSwordR.blp]], [[replaceabletextures\commandbuttons\BTNAmiellaGunR.blp]]},
}
local tip = {
	{'剑技-胧月', '炮技-连爆'},
	{'剑技-升天阵', '炮技-轰爆'},
	{'剑技-幻影突刺', '炮技-天光流隙'},
	{'剑技-樱花残月', '炮技-赤色彗星'},
}

function mt:on_add()
	local hero = self.owner
	if not hero:is_hero() then
		return
	end
	local skill = self
	local last
	for _, name in pairs(tip) do
		local skl = hero:find_skill(name[1], nil, true)
		if skl then
			function skl:on_upgrade()
				skill:update_art(last)
			end
		end
	end
	self.art_timer = ac.loop(100, function()
		if not hero:is_alive() then
			return
		end
		hero:show_fresh()
		local x, y = message.mouse()
		if x == 0 and y == 0 then
			return
		end
		local now
		if hero:get_point() * ac.point(x, y) < 350 then
			now = 1
		else
			now = 2
		end
		if last == now then
			return
		end
		last = now
		self:update_art(now)
	end)
	if hero:get_owner():is_self() then
		self.range_eff = hero:add_effect('origin', [[model\amiella\range.mdx]])
	else
		self.range_eff = hero:add_effect('origin', [[]])
	end
end

function mt:on_remove()
	local hero = self.owner
	if not hero:is_hero() then
		return
	end
	self.art_timer:remove()
	self.range_eff:remove()
end

function mt:update_art(type)
	local hero = self.owner
	if not hero:is_alive() then
		return
	end
	for i = 1, 4 do
		local skill = hero:find_skill(i, '英雄', true)
		if skill then
			local art = arts[i][type]
			local tip = tip[i][type]
			if not skill:is_enable() or skill:get_level() == 0 then
				skill:set_art(self:get_art(art, true))
			else
				skill:set_art(art)
			end
			skill.data.title = tip
			skill:fresh_title()
		end
	end
end
