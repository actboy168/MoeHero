for i = 1, 4 do
	local mt = ac.skill['智能施法开关' .. i]
	{
		--默认等级
		max_level = 1,
		
		auto_fresh_tip = false,

		never_reload = true,

		never_copy = true,

		simple_tip = true,

		title = '智能施法开关',

		cool = 0,

		cost = 0,

		instant = 1,
	}

	--是否开启
	mt.smart_type = 0
	
	--获得技能
	function mt:on_add()
		ac.wait(0, function()
			self:on_cast_channel()
		end)
	end

	--学习技能
	function mt:on_cast_channel()
		self:set('smart_type', (self.smart_type + 1) % 3)
		if self.owner:get_owner() == ac.player.self then
			if self.smart_type == 0 then
				self:set('art', [[replaceabletextures\commandbuttons\smart_cast_off.blp]])
				self:set('tip', [[
	智能施法已|cffff1111关闭|r
				]])
			elseif self.smart_type == 1 then
				self:set('art', [[replaceabletextures\commandbuttons\smart_cast_mode_a.blp]])
				self:set('tip', [[
	智能施法已|cffffff11开启|r
				]])
			else
				self:set('art', [[replaceabletextures\commandbuttons\smart_cast_mode_b.blp]])
				self:set('tip', [[
	智能施法已|cffffff11开启|r
	显示施法指示圈
				]])
			end
		end
		self:fresh()
		self.owner:show_fresh()

		local hero = self.owner
		if not hero.smart_cast_type then
			hero.smart_cast_type = {}
		end
		hero.smart_cast_type[i] = self.smart_type
	end
end
