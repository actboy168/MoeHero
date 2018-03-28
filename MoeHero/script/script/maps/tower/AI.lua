local sound = require 'types.sound'
local confirmTarget

local function pick(t, f1, f2)
	local count = #t
	if count == 0 then
		return
	elseif count == 1 then
		return t[1]
	end

	local y = f2 and f2(t[1]) or t[1]
	local r = 1
	for i = 2, count do
		local x = f2 and f2(t[i]) or t[i]
		if f1(x, y) then
			y = x
			r = i
		end
	end

	return t[r]
end

--查找附近的可攻击目标
local function find_target (source, target)
	--检查附近是否有可攻击的单位
	local p = source:get_point()
	local g = ac.selector()
		: in_range(source, source:get '攻击范围')
		: is_enemy(source)
		: add_filter(function(u)
			return not u:is_type('野怪')
		end)
		: get()
	--防止唯一一个目标被注意到后马上跑开
	table.insert(g, target)
	local u = pick(g, function(u1, u2)
		if u1:is_hero() and not u2:is_hero() then
			return false
		end
		if not u1:is_hero() and u2:is_hero() then
			return true
		end
		return u1:get_point() * p < u2:get_point() * p
	end)
	if u then
		return confirmTarget(source, u)
	end
	return nil
end

--确定攻击目标
function confirmTarget(source, target)
	if not source:issue_order('attack', target) then
		--防止死循环
		--print([[source:issue_order('attack', target)==false]],source:issue_order('attack', target))
		if source.last_target ~= target then
			source.last_target = target
			return find_target(source, target)
		end
		--print('防御塔激光，防御塔周围只存在一个敌人，但这个敌人却无法被防御塔攻击')
	end
	source.last_target = target
	local l = source:get_data('防御塔激光')
	if not l then
		return
	end

	l:setMoveTimes(10,-0.04)
	l:move(source, target)
	l:setAlpha(300)
	
	----如果是英雄,则警告音效
	--if target:is_hero() then
	--	target:get_owner():playSound([[Sound\Interface\Warning.wav]])
	--end
	return target
end

--这个是为了防御塔激光，每攻击一次防御塔激光的alpha值就会更新
ac.game:event '单位-攻击开始' (function(trg, data)
	local source, target = data.source, data.target
	local l = source:get_data('防御塔激光')
	if not l then
		if source:is_type('建筑') and (source:get_team() == 1 or source:get_team() == 2) then
			local l = ac.lightning('LN01',source,source,300,55)
			l:setAlpha(0)
			l:fade(-8,'淡出后不删除')
			l:setColor(100,0,0)
			source:set_data('防御塔激光',l)
		else
			return
		end
	end
	if target == source.last_target then
		confirmTarget(source, target)
		return
	end
	local target = find_target(source, target)
	if target then
		data.target = target
	end
end)

--防御塔仇恨
ac.game:event '造成伤害效果' (function(trg, data)
	local source, target = data.source, data.target
	if not (source and source:is_hero() and target:is_hero()) then
		return
	end
	for _, tower in ac.selector()
		: in_range(source, 1000)
		: is_enemy(source)
		: of_building()
		: add_filter(function(u)
			if u:get '攻击' > 0 and u:get_point() * source:get_point() <= u:get '攻击范围' then
				return true
			end
			return false
		end)
		: ipairs()
	do
		tower.last_target = nil
		confirmTarget(tower, source)
	end
end)

--防御塔死亡后删除激光
ac.game:event '单位-死亡' (function(trg, u, source)
	if u and u:is_type('建筑') and u:get '攻击' > 0 then
		--print('防御塔死亡')
		local l = u:get_data('防御塔激光')
		if not l then
			return
		end
		l:remove()
	end
end)
