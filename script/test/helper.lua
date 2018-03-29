local player = require 'ac.player'
local fogmodifier = require 'types.fogmodifier'
local sync = require 'types.sync'
local jass = require 'jass.common'
local hero = require 'types.hero'
local item = require 'types.item'
local affix = require 'types.affix'
local japi = require 'jass.japi'

local error_handle = require 'jass.runtime'.error_handle

local helper = {}

local function helper_reload(callback)
	local real_require = require
	function require(name, ...)
		if name:sub(1, 5) == 'jass.' then
			return real_require(name, ...)
		end
		if name:sub(1, 6) == 'types.' then
			return real_require(name, ...)
		end
		if not package.loaded[name] then
			return real_require(name, ...)
		end
		package.loaded[name] = nil
		return real_require(name, ...)
	end
	
	callback()

	require = real_require
end

local function reload_skill_buff()
	local ac_skill = ac.skill
	local ac_buff = ac.buff
	ac.skill = setmetatable({}, {__index = function(self, k)
		if type(ac_skill[k]) ~= 'table' then
			return ac_skill[k]
		end
		ac_skill[k] = nil
		self[k] = ac_skill[k]
		return ac_skill[k]
	end})
	ac.buff = setmetatable({}, {__index = function(self, k)
		if type(ac_buff[k]) ~= 'table' then
			return ac_buff[k]
		end
		ac_buff[k] = nil
		self[k] = ac_buff[k]
		return ac_buff[k]
	end})
	return function()
		ac.skill = ac_skill
		ac.buff = ac_buff
	end
end

--重载
function helper:reload()
	log.info('---- Reloading start ----')

	local reload_finish = reload_skill_buff()
	local map = require 'maps.map'

	helper_reload(function()
		require 'ac.buff.init'
		require 'ac.template_skill'
		require 'maps.hero.upgrade'
		require 'maps.smart_cast.init'
		map.load_heroes()
		item.clear_list()
		affix.clear_list()
		require 'maps.map_item._init'
		require 'maps.map_shop.page'
		require 'maps.map_shop.affix'
	end)

	reload_finish()
	
	--重载技能和Buff
	local levels = {}

	for i = 1, 10 do
		local hero = player[i].hero
		if hero then
			hero:cast_stop()
			if hero.buffs then
				local tbl = {}
				for bff in pairs(hero.buffs) do
					if not bff.name:match '宝箱奖励' then
						tbl[#tbl + 1] = bff
					end
				end
				for i = 1, #tbl do
					tbl[i]:remove()
				end
			end
			if hero.movers then
				local tbl = {}
				for mover in pairs(hero.movers) do
					tbl[#tbl + 1] = mover
				end
				for i = 1, #tbl do
					tbl[i]:remove()
				end
			end
		end
	end

	for i = 1, 10 do
		local hero = player[i].hero
		if hero then
			hero:set('生命', 1000000)
			hero:set('魔法', 1000000)
			local level_skills = {}
			--遍历身上的技能
			for skill in hero:each_skill(nil, true) do
				if not skill.never_reload then
					local name = skill.name
					skill:_call_event('on_reload', true)
					local level = skill:get_level()
					local slotid = skill.slotid
					local type = skill:get_type()
					local upgrade = skill._upgrade_skill
					skill:remove()
					local skill = select(2, xpcall(hero.add_skill, error_handle, hero, name, type, slotid, {level = ac.skill[name].level}))
					if skill then
						table.insert(level_skills, {skill, level, upgrade})
					end
				end
			end
			local skill_points = 0
			for _, data in ipairs(level_skills) do
				local skill = data[1]
				local level = data[2]
				skill:set_level(ac.skill[skill.name].level)
				skill_points = skill_points + level - skill:get_level()
			end
			hero:addSkillPoint(skill_points)
			for _, data in ipairs(level_skills) do
				local skill = data[1]
				local level = data[2]
				local upgrade = data[3]
				print('重载技能', skill.name, level, upgrade)
				if upgrade then
					for i = 1, level do
						if upgrade[i] then
							local skill = hero:find_skill(upgrade[i].name)
							if skill then
								skill:cast_force()
							end
						end
					end
				end
			end
			hero:addSkillPoint(0)
		end
	end

	--遍历身上的物品
	for i = 1, 6 do
		local it = self:find_skill(i, '物品')
		if it then
			local name = it.name
			local affixs = it.affixs
			local slotid = it.slotid
			it:remove()
			local skl = self:add_skill(name, '物品', slotid)
			if skl then
				skl:set_affixs(affixs)
				skl:fresh_tip()
			end
		end
	end
	log.info('---- Reloading end   ----')

	ac.game:event_notify('游戏-脚本重载')
end

--创建全图视野
function helper:icu()
	fogmodifier.create(self:get_owner(), require('maps.map').rects['全地图'])
end

--移动英雄
function helper:move()
	local data = self:get_owner():getCamera()
	self:get_owner():sync(data, function(data)
		self:blink(ac.point(data[1], data[2]), true)
	end)
end

--添加Buff
function helper:add_buff(name, time)
	if self then
		self:add_buff(name)
		{
			time = tonumber(time),
		}
	end
end

--移除Buff
function helper:remove_buff(name)
	if self then
		self:remove_buff(name)
	end
end

--创建瀑布
function helper:wave()
	require('maps.spring').start()
end

--创建宝箱
function helper:box()
	require('maps.spring').createBox()
end

--满级
function helper:lv(lv)
	self:set_level(tonumber(lv))
end

--动画
function helper:ani(name)
	self:set_animation(name)
end

--伤害自己
function helper:damage(damage)
	self:damage
	{
		source = self,
		damage = damage,
		skill = false,
	}
end

function helper:setre()
	all_lb[11] = 20
end

function helper:hotfix()
	require('types.hot_fix').main(self:get_owner())
end

--显示伤害漂浮文字
function helper:show()
	local function text(damage)
		local size = 20
		local x, y = damage.target:get_point():get()
		local z = damage.target:get_point():getZ()
		local tag = ac.texttag
		{
			string = ('%d'):format(math.floor(damage:get_current_damage())),
			size = size,
			position = ac.point(x - 60, y, z - 30),
			speed = 86,
			angle = 90,
			red = 100,
			green = 20,
			blue = 20,
		}
	end
	ac.game:event '造成伤害效果' (function(trg, damage)
		if not damage.source or not damage.source:is_hero() then
			return
		end
		text(damage)
	end)
end

--计时器测试
function helper:timer()
    local count = 0
	local t = ac.loop(100, function(t)
        print(ac.clock())
        count = count + 1
        if count == 10 then
            t:pause()
        end
    end)
	ac.wait(3000, function()
		t:resume()
	end)
	ac.wait(5000, function()
		t:remove()
	end)
end

--测试
function helper:power()
	helper.move(self)
	helper.lv(self, 18)
	if not ac.wtf then
		helper.wtf(self)
	end
	self:add_restriction '免死'
	self:addGold(999999)
end

--创建一个敌方英雄在地图中间，如果playerid有参数，则是为playerid玩家创建
function helper:dummy(life, playerid)
	if not playerid then
		playerid = 13
	end
	local p = player[playerid]
	p.hero = p:createHero('小悟空', ac.point(0,0,0), 270)
	p:event_notify('玩家-注册英雄', p, p.hero)
	p.hero:add_enemy_tag()
	p.hero:add_restriction '缴械'
	p.hero:add('生命上限', tonumber(life) or 1000000)
end

function helper:black()
	jass.SetDayNightModels('', 'Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl')
end

function helper:wtf()
	ac.wtf = not ac.wtf
	if ac.wtf then
		for i = 1, 10 do
			local hero = ac.player(i).hero
			if hero then
				for skill in hero:each_skill() do
					skill:set_cd(0)
				end
			end
		end
	end
end

function helper:never_dead(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self:add_restriction '免死'
	else
		self:remove_restriction '免死'
	end
end

function helper:creep()
	local creeps = require 'maps.creeps'
	for _, data in ipairs(creeps.group) do
		data[3] = 0
		data[4] = 0
	end
	creeps.start()
end

function helper:light(type)
	local light = {
		'Ashenvale',
		'Dalaran',
		'Dungeon',
		'Felwood',
		'Lordaeron',
		'Underground',
	}
	if not tonumber(type) or tonumber(type) > #light or tonumber(type) < 1 then
		return
	end
	local name = light[tonumber(type)]
	jass.SetDayNightModels(([[Environment\DNC\DNC%s\DNC%sTerrain\DNC%sTerrain.mdx]]):format(name, name, name), ([[Environment\DNC\DNC%s\DNC%sUnit\DNC%sUnit.mdx]]):format(name, name, name))
end

function helper:sha1(name)
	local storm = require 'jass.storm'
	local rsa = require 'util.rsa'
	local file = storm.load(name)
	local sign = rsa:get_sign(file)
	print(sign)
	storm.save('我的英雄不可能那么萌\\sign.txt', sign)
end

local show_message = false
function helper:show_message()
    show_message = not show_message
end

local function message(obj, ...)
    local n = select('#', ...)
    local arg = {...}
    for i = 1, n do
        arg[i] = tostring(arg[i])
    end
    local str = table.concat(arg, '\t')
    print(obj, '-->', str)
    if show_message then
        for i = 1, 12 do
            ac.player(i):sendMsg(str)
        end
    end
end

local function call_method(obj, cmd)
    local f = obj[cmd[1]]
    if type(f) == 'function' then
        for i = 2, #cmd do
            local v = cmd[i]
            v = tonumber(v) or v
            if v == 'true' then
                v = true
            elseif v == 'false' then
                v = false
            end
            cmd[i] = v
        end
        local rs = {xpcall(f, error_handle, obj, table.unpack(cmd, 2))}
        message(obj, table.unpack(rs, 2))
    else
        message(obj, f)
    end
end

function helper:player(cmd)
    table.remove(cmd, 1)
    call_method(self:get_owner(), cmd)
end

local function main()
	ac.game:event '玩家-聊天' (function(self, player, str)
        if str:sub(1, 1) ~= '-' and str:sub(1, 1) ~= '.' then
            return
        end
		local hero = player.hero
		local strs = {}
		for s in str:gmatch '%S+' do
			table.insert(strs, s)
		end
		local str = strs[1]:sub(2)
        strs[1] = str
		print(str)

		if type(helper[str]) == 'function' then
			xpcall(helper[str], error_handle, hero, table.unpack(strs, 2))
            return
		end
		if hero then
			call_method(hero, strs)
            return
		end
	end)

	--按下ESC来重载脚本
	ac.game:event '按下ESC' (function(trg)
		--helper.reload(data.player)
	end)
end

main()
