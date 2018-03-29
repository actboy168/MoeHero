local player = require 'ac.player'
local map = require 'maps.map'
local fogmodifier = require 'types.fogmodifier'
local hero = require 'types.hero'
local game = require 'types.game'
local jass = require 'jass.common'
local japi = require 'jass.japi'
local slk = require 'jass.slk'
local rect = require 'types.rect'
local multiboard = require 'types.multiboard'

require 'maps.choose_hero.skills'

local hero_types = {}
local cent = rect.j_rect('choose_hero'):get_point()
local target_angle
local skip
local radius
local last_target

--多面板
local mb = nil
local flygroup = {}
local function DEKAN_flyfunction(hero)
	hero:set_high(2*(math.sin(0.7*hero.DEKAN_flyheight_X)+1) + hero.DEKAN_flyheight_base)
end

local function lookAtHero(p, hero, is_skip)
	if p == player.self then
		target_angle = hero:get_facing() + 180
		if is_skip then
			last_target = hero:get_point()
		end
		skip = is_skip
	end
end

--初始化英雄属性
local function setHeroState(u)
	local hero_data = hero.hero_list[u:get_name()].data
	local hero = setmetatable(u, hero)

	for k, v in pairs(hero_data.attribute) do
		hero:set(k, v)
	end
	hero:set('生命', hero:get '生命上限')
	hero:set('魔法', hero:get '魔法上限')

	for i = 1, 4 do
		local skl = hero:add_skill('预览技能' .. i, '预览', i)
	end
end

local function random(a, b)
	return a + math.floor(ac.clock() / 17) % (b - a + 1)
end

local function show_animation(u)
	local hero_name = u:get_name()
	local hero_data = hero.hero_list[hero_name].data
	local hero = u
	if hero_data.show_animation then
		if type(hero_data.show_animation) == 'table' then
			hero:set_animation(hero_data.show_animation[random(1, #hero_data.show_animation)])
		else
			hero:set_animation(hero_data.show_animation)
		end
	else
		hero:set_animation('spell channel')
	end
end

--显示英雄属性
local function showHeroState(p, u)
	local hero_name = u:get_name()
	local hero_data = hero.hero_list[hero_name].data
	local hero = u

	local tip = [[
|cffffcc11生命:                                     |cffcccccc%attribute.生命上限%|cff00ff00(+%upgrade.生命上限%)|r
|cffffcc11%resource_type%:                                     |cffcccccc%attribute.魔法上限%|cff00ff00(+%upgrade.魔法上限%)|r
|cffffcc11攻击:                                     |cffcccccc%attribute.攻击%|cff00ff00(+%upgrade.攻击%)|r
|cffffcc11防御:                                     |cffcccccc%attribute.护甲%|cff00ff00(+%upgrade.护甲%)|r
|cffffcc11生命恢复:                               |cffcccccc%attribute.生命恢复%|cff00ff00(+%upgrade.生命恢复%)|r
|cffffcc11%resource_type%恢复:                               |cffcccccc%attribute.魔法恢复%|cff00ff00(+%upgrade.魔法恢复%)|r

|cff888888登场作品                                |cff888888%production%
|cff888888模型来源                                |cff888888%model_source%
|cff888888设计                                      |cff888888%hero_designer%
|cff888888代码                                      |cff888888%hero_scripter%
]]
	local difficulty_level = {
		'|cffffaaaa★|r|cffeeeeee☆☆☆☆|r',
		'|cffff8888★★|r|cffeeeeee☆☆☆|r',
		'|cffff6666★★★|r|cffeeeeee☆☆|r',
		'|cffff4444★★★★|r|cffeeeeee☆|r',
		'|cffff2222★★★★★|r|cffeeeeee|r',
	}
	local difficulty_tip = '|cffffcc11操作难度:                              ' .. difficulty_level[hero_data.difficulty or 1]
	p:sendMsg(difficulty_tip .. '\n' .. tip:gsub('%%(.-)%%', function(name)
		local data = hero_data
		for path in name:gmatch '[^%.]+' do
			data = data[path]
		end
		return data
	end), 60)
	--刷新技能说明
	if p == ac.player.self then
		for i = 1, 4 do
			local skl = hero:find_skill('预览技能' .. i, '预览', true)
			local dest = hero_data.skill_datas[i]
			skl:set_tip(dest:get_tip(hero, 0, true))
			skl:set_title(dest:get_title(hero, 0, true))
			skl:set_art(dest.art)
		end
	end
end

--等待选人完成
local function start()
	--在选人区创建英雄
	local cent	= map.rects['选人区域']:get_point()
	local r		= 360 / hero.hero_count
	radius		= math.sqrt(hero.hero_count - 1) * 120
	
	for i, hero_type in ipairs(hero.hero_list) do
		local name, hero_data = hero_type[1], hero_type.data
		local shadow01 = jass.CreateImage([[ReplaceableTextures\CommandButtons\BTNPeasant.blp]], 1, 1, 1, 0, 0, 0, 0, 0, 0, 2)
		local shadow02 = jass.CreateImage([[ReplaceableTextures\CommandButtons\BTNPeasant.blp]], 1, 1, 1, 0, 0, 0, 0, 0, 0, 2)
		jass.DestroyImage(shadow01)
		jass.DestroyImage(shadow02)
		local hero_id = hero_data.id
		local hero_slk = slk.unit[hero_id]
		local hero = player[16]:create_unit(hero_id, cent - {r * i + 90, radius}, r * i - 90)
		hero.name = name
		player[16]:create_unit('h002',cent - {r * i + 90, radius-50}, r * i - 90)
		hero:set_high(3000)
		hero:remove_ability 'Amov'
		hero:add_restriction '缴械'
		hero_types[name] = hero
		hero:set_data('英雄类型', name)
		setHeroState(hero)
		jass.DestroyImage(shadow01)
		table.insert(flygroup, hero)
	end

	--初始化英雄漂浮
	for _, hero in ipairs(flygroup) do
		hero.DEKAN_flyheight_X = math.random(-130,380)
		hero.DEKAN_flyheight_base = math.random(6,20) + 3000
		DEKAN_flyfunction(hero)
	end

	for i = 1, 10 do
		local p = player[i]
		--在选人区域创建可见度修整器(对每个玩家,永久)
		fogmodifier.create(p, map.rects['选人区域'])

		--设置镜头属性
		p:setCameraField('CAMERA_FIELD_ANGLE_OF_ATTACK', 0)
		p:setCameraField('CAMERA_FIELD_ZOFFSET', 3200)
		p:setCameraField('CAMERA_FIELD_TARGET_DISTANCE', 500)
		p:setCameraBounds 'choose_hero'

		--禁止框选
		p:disableDragSelect()

		--看着一个英雄
		
		local name = hero.hero_list[math.random(1, #hero.hero_list)][1]
		lookAtHero(p, hero_types[name], true)
	end

	--启动计时器
	local look_timer = ac.loop(10, function()
		local p = player.self
		if p.hero then
			return
		end
		local current_target = p:getCamera()
		local angle
		if skip then
			skip = nil
			angle = target_angle
		else
			angle = p:getCameraField 'CAMERA_FIELD_ROTATION'
			local a, w = ac.math_angle(angle, target_angle)
			if a < 1 then
				--计算当前镜头距离与上次镜头距离的偏差,检测玩家是否自己拖动了镜头
				local dis = current_target * last_target
				if dis > 30 then
					local _, w = ac.math_angle(cent / last_target, cent / current_target)
					target_angle = angle + w * 360 / hero.hero_count * 3
					a, w = ac.math_angle(angle, target_angle)
				end
			end
			angle = angle + a * w / 10
		end
		
		local target = cent - {angle, radius}
		last_target = target
		if current_target * last_target > 1 then
			p:setCamera(target)
		end
		p:setCameraField('CAMERA_FIELD_ROTATION', angle)
		p:setCameraField('CAMERA_FIELD_ANGLE_OF_ATTACK', 0)
		p:setCameraField('CAMERA_FIELD_ZOFFSET', 3130)
		p:setCameraField('CAMERA_FIELD_TARGET_DISTANCE', 500)
	
		--漂浮的英雄
		for _, hero in ipairs(flygroup) do
			hero.DEKAN_flyheight_X = hero.DEKAN_flyheight_X + 1.5
			DEKAN_flyfunction(hero)
		end
	end)

	ac.loop(200, function()
		local p = player.self
		if p.hero then
			if p.camera_high then
				p:setCameraField('CAMERA_FIELD_TARGET_DISTANCE', p.camera_high)
			end
		end
	end)

	local player_hero_count = 0

	--注册事件
	local select_unit_trg = ac.game:event '玩家-选择单位' (function(self, p, hero)
		if not p.hero and hero_types[hero:get_data '英雄类型'] == hero then
			p:clearMsg()
			--记录英雄类型
			local hero_name = hero:get_data '英雄类型'
			local current_time = ac.clock()
			if p.last_select_hero_name ~= hero_name
			or not p.last_select_hero_time
			or current_time - p.last_select_hero_time > 1000 then
				if p.last_select_hero then
					p.last_select_hero:set_animation('stand')
				end
				show_animation(hero)
				p.last_select_hero_time = current_time
				p.last_select_hero_name = hero_name
				p.last_select_hero = hero
				p:sendMsg(('双击选择 |cffffcc00%s|r !'):format(hero_name))
				lookAtHero(p, hero)
				showHeroState(p, hero)
				return
			else
				show_animation(hero)
			end
			p:event_notify('玩家-选择英雄', p, hero_name)
		end
	end)

	local random_hero_trg = ac.game:event '玩家-聊天' (function(self, player, str)
		if str ~= '-random' then
			return
		end
		if player.hero then
			return
		end
		local list = {}
		for name, _ in pairs(hero_types) do
			if name ~= '金木研' and name ~= '更木剑八' then
				table.insert(list, name)
			end
		end
		player:event_notify('玩家-选择英雄', player, list[math.random(1, #list)])
	end)

	ac.game:event '玩家-选择英雄' (function(self, p, hero_name)
		if not p.hero and hero_types[hero_name] then
			p:clearMsg()
			local hero = hero_types[hero_name]
			--移除选人区马甲
			hero_types[hero_name] = nil
			hero:setAlpha(50)
			hero:set_class '马甲'
	
			--等待初始化
			p:hideInterface(1)
			--创建英雄给选择者
			local pnt	= map.rects['出生点'][p:get_team()]:get_point()
			local r		= 360 / 5 * p:get()
			p.hero = p:createHero(hero_name, pnt - {r, 150}, r + 180)
	
			player_hero_count = player_hero_count + 1
	
			p:event_notify('玩家-注册英雄', p, p.hero)
	
			p:setCameraBounds(-7200, -7200, 7200, 7200)
			--把镜头移动过去
	
			--敌我识别特效
			p.hero:add_enemy_tag()
			
			ac.wait(1000, function()
				p:setCameraField('CAMERA_FIELD_TARGET_DISTANCE', 1000)
				p:setCameraField('CAMERA_FIELD_ANGLE_OF_ATTACK', 304)
				p:setCameraField('CAMERA_FIELD_ZOFFSET', 0)
				p:setCameraField('CAMERA_FIELD_ROTATION', 90)
				p:setCamera(p.hero)
				p:showInterface(1)
				--镜头动画
				p:setCameraField('CAMERA_FIELD_TARGET_DISTANCE', 2000, 1)
				p:setCameraBounds(-7200, -7200, 7200, 7200)
	
				--允许框选
				p:enableDragSelect()
				
				--选中英雄
				p:selectUnit(p.hero)
	
				--强制镜头高度
				ac.wait(1000, function()
					p.camera_high = 2000
				end)
			end)
		end
	
		--检查是否还有人没选英雄
		for i = 1, 10 do
			local p = player[i]
			if p:is_player() and not p.hero then
				return
			end
		end

		look_timer:remove()
		select_unit_trg:remove()
		random_hero_trg:remove()
	end)

	local has_started = false
	local function f(obj)
		--检查是否还有人没选英雄
		local flag = true
		for i = 1, 10 do
			local p = player[i]
			if p:is_player() and not p.hero then
				flag = false
			end
		end

		if obj.type == 'timer' or flag then
			if not has_started then
				--游戏-开始
				ac.game:event_notify('游戏-开始')
				has_started = true
			end
		end

		if flag then
			obj:remove()
		end
	end
	
	ac.game:event '玩家-注册英雄' (f)
	ac.game:event '玩家-离开' (f)
	ac.wait(60000, f)
end

start()
