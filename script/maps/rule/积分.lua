ac.game:record(0, '胜利')
ac.game:record(1, '萌力')
ac.game:record(2, '萌王')
ac.game:record(3, '萌杀')
ac.game:record(4, '百合控')
ac.game:record(5, '平胸控')
ac.game:record(6, '萝莉控')
ac.game:record(7, '中出率')

local moe = {0, 0}
local pc = {0, 0}
-- 把双方的萌力加起来
for i = 1, 12 do
	local p = ac.player(i)
	if p:is_player() then
		local tid = p:get_team()
		moe[tid] = moe[tid] + p:get_record '萌力'
		pc[tid] = pc[tid] + 1
	end
end

-- 如果双方队伍人数不同则无效
if pc[1] ~= pc[2] then
	return
end

-- 求平均
moe[1] = moe[1] / 5
moe[2] = moe[2] / 5
-- 计算每个玩家的预期胜利得分/失败扣分
for i = 1, 12 do
	local p = ac.player(i)
	if p:is_player() then
		local t = p:get_team()
		local my_moe = p:get_record '萌力'
		local m = (my_moe + moe[t]) / 2
		local enemy = moe[t % 2 + 1]
		p.win_moe = math.floor(my_moe + math.min(100, math.max(10, 50 - (m - enemy) * 2)))
		p.lose_moe = math.floor(my_moe + math.min(50, math.max(-100, -50 - (m - enemy) * 2)))
		-- 先认为玩家输了
		p:set_record('萌力', p.lose_moe)
		-- 先认为所有人都逃跑
		local r1 = p:get_record 'r1'
		local r2 = p:get_record 'r2'
		local r1h = r1 & (1 << 24)
		local r2h = r2 & (1 << 24)
		r1 = r1 << 1
		r1 = r1 & (1 << 25 - 1)
		r2 = r2 << 1
		r2 = r2 & (1 << 25 - 1)
		r2 = r2 | (r1h == 0 and 0 or 1)
		if r2h ~= 0 then
			p:add_record('中出率', -2)
		end
		r1 = r1 | 1
		p:add_record('中出率', 2)
		p:set_record('r1', r1)
		p:set_record('r2', r2)
		p:save_record()
	end
end

local has_allow_leave = false
local function allow_leave()
	if has_allow_leave then
		return
	end
	has_allow_leave = true
	for i = 1, 12 do
		local p = ac.player(i)
		if p:is_player() then
			p:add_record('中出率', -2)
			p:add_record('r1', -1)
			p:save_record()
		end
	end
end

ac.game:event '玩家-离开' (allow_leave)

ac.game:event '游戏-结束' (function(_, team)
	allow_leave()
	local max_kill = 0
	local max_mvp = 0
	for i = 1, 12 do
		local p = ac.player(i)
		if p:get_team() == team	 then
			p:add_record('胜利', 1)
			p:set_record('萌力', p.win_moe or 0)
		end
		if p:is_player() then
			max_kill = math.max(max_kill, p.kill_count)
			p.mvp = (p.kill_count + p.assist_count * 0.7) / (1 + p.dead_count * 0.1)
			max_mvp = math.max(max_mvp, p.mvp)
		end
		p:add_record('局数', 1)
		local hero = p.hero
		if hero then
			if hero.yuri then
				p:add_record('百合', 1)
				p:set_record('百合控', math.floor(p:get_record '百合' / p:get_record '局数' * 100))
			end
			if hero.pad then
				p:add_record('平胸', 1)
				p:set_record('平胸控', math.floor(p:get_record '平胸' / p:get_record '局数' * 100))
			end
			if hero.loli then
				p:add_record('萝莉', 1)
				p:set_record('萝莉控', math.floor(p:get_record '萝莉' / p:get_record '局数' * 100))
			end
		end
		p:save_record()
	end
	for i = 1, 12 do
		local p = ac.player(i)
		if max_mvp >= 1 then
			if p.mvp == max_mvp then
				p:add_record('萌王', 1)
			end
		end
		if max_kill >= 5 then
			if p.kill_count == max_kill then
				p:add_record('萌杀', 1)
			end
		end
		p:save_record()
	end
end)
