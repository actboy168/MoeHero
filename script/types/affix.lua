
local affix = {}
local mt = {}
affix.__index = mt

--词缀表
affix.list = {
	{'gold',			'|cffcccccc价格: |cffffff11%.f|r\n'},
	{'shoes_count',		'脱离战斗后，移动速度在10秒内提升50%%'},	
	{'attack',			'攻击+%s'},
	{'attack_rate',		'攻击+%s%%'},
	{'attack_speed',	'攻速+%s%%'},
	{'crit',			'暴击+%s%%'},
	{'life_steal',		'吸血+%s%%'},
	{'pene',			'破甲+%s'},
	{'pene_rate_ex',	'穿透+%s%%'},
	{'splash',			'溅射+%s'},
	{'life',			'生命+%s'},
	{'mana',			'法力+%s'},
	{'restore',			'回复+%s'},
	{'life_recover',	'回血+%s'},
	{'mana_recover',	'回蓝+%s'},
	{'defence',			'防御+%s'},
	{'defence_rate',	'防御+%s%%'},
	{'move_speed',		'移速+%s'},
	{'block',			'格挡+%s%%'},
	{'cost_save',		'减耗+%s%%'},
	{'cool_save',		'冷却-%s%%'},
	{'life_rate',		'生命+%s%%'},
}

--词缀类型
affix.types = {}
for _, data in ipairs(affix.list) do
	local name, value = data[1], data[2]
	affix.types[name] = value
end

--类型
mt.type = 'affix'

--价格
mt.gold = 0

--名称
mt.name = ''

--词缀类型
mt.item_type = '无'

--词缀等级
mt.level = 0

local all_affix = {}
local affix_list = {}

--添加词缀列表
function affix.add_list(type_name, affix_meta)
	local list = affix.get_list(type_name)
	table.insert(list, affix_meta)
	return list
end

--获取词缀列表
function affix.get_list(type_name)
	local list = affix_list[type_name]
	if not list then
		list = {}
		affix_list[type_name] = list
	end
	return list
end

--清空词缀列表
function affix.clear_list()
	affix_list = {}
end

--注册词缀
function affix.create(data)
	local name = data.name
	setmetatable(data, affix)
	all_affix[name] = data
	
	--保存类型
	local item_type = data.item_type .. data.level
	affix.add_list(item_type, data)
	
	return data
end

--获取词缀
function affix.get(name)
	return all_affix[name]
end

return affix