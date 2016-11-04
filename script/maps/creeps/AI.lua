--AI脱战范围
local creep_range = 700

--野怪攻击附近的单位
local function creepAttack(u, target)
	--找到最近的一个单位
	local poi = u:get_point()
	if u.damage_group then
		for _, u in pairs(u.damage_group) do
			if not target then
				target = u
			elseif u:get_point() * poi < target:get_point() * poi then
				target = u
			end
		end
	end
	if not target then
		u:add_buff '野怪脱战回血' {}
		return
	end
	u:issue_order('attack', target)
	--呼叫周围的小弟
	for _, uu in ipairs(u.creep_group) do
		if uu:is_alive() and not uu:isActive() then
			uu:setActive()
			creepAttack(uu, target)
		end
	end
	if u.creep_timer then
		return
	end
	local born_point = u:getBornPoint()
	u.creep_timer = ac.loop(1000, function()
		if u:get_point() * born_point > creep_range or not u:isActive() then
			u:issue_order('move', born_point)
			u.creep_timer = nil
			u:add_buff '野怪脱战回血' {}
			return true
		end
	end)
end


--受到伤害时反击
ac.game:event '受到伤害开始' (function(trg, damage)
	local source, target = damage.source, damage.target
	if not source then
		return
	end
	if source:is_type('野怪') and source:get_point() * source:getBornPoint() < creep_range then
		source:remove_buff '野怪脱战回血'
		return
	end
	if not target:is_type('野怪') then
		return
	end
	if not source:has_restriction '物免' then
		if not target.damage_group then
			target.damage_group = {}
		end
		target.damage_group[source.handle] = source
	end
	if target:get_point() * target:getBornPoint() > creep_range then
		return
	end
	target:remove_buff '野怪脱战回血'
	creepAttack(target)
end)

--监听野怪归位
ac.game:event '单位-发布指令' (function(self, u, order, target, player_order)
	if not u:is_type('野怪') then
		return
	end
	if not player_order then
		return
	end
	if order == 'move' then
		creepAttack(u)
	end
end)

--注册野怪脱战回血
local mt = ac.buff['野怪脱战回血']

mt.recover_rate = 20
mt.changed_recover = 0

function mt:on_add()
	local u = self.target
	local max_life = u:get '生命上限'
	self.changed_recover = max_life * self.recover_rate / 100
	u:add('生命恢复', self.changed_recover)
end

function mt:on_remove()
	local u = self.target
	u:add('生命恢复', - self.changed_recover)
end
