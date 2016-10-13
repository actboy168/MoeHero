
local skill = require 'ac.skill'

--技能目标类型常量
skill.__index.TARGET_TYPE_NONE	= 0			--点目标
skill.__index.TARGET_TYPE_UNIT	= 1			--单位目标
skill.__index.TARGET_TYPE_POINT	= 2			--点目标
skill.__index.TARGET_TYPE_UNIT_OR_POINT	= 3	--单位或点

ac.skill.TARGET_TYPE_NONE	= 0			--点目标
ac.skill.TARGET_TYPE_UNIT	= 1			--单位目标
ac.skill.TARGET_TYPE_POINT	= 2			--点目标
ac.skill.TARGET_TYPE_UNIT_OR_POINT	= 3	--单位或点

--转换目标允许
skill.__index.convert_targets = {
	["地面"]	= 2 ^ 1,
    ["空中"]	= 2 ^ 2,
    ["建筑"]	= 2 ^ 3,
    ["守卫"]	= 2 ^ 4,
    ["物品"]	= 2 ^ 5,
    ["树木"]	= 2 ^ 6,
    ["墙"]		= 2 ^ 7,
    ["残骸"]	= 2 ^ 8,
    ["装饰物"]	= 2 ^ 9,
   	["桥"]		= 2 ^ 10,
    ["未知"]	= 2 ^ 11,
    ["自己"]	= 2 ^ 12,
    ["玩家单位"]	= 2 ^ 13,
    ["联盟"]	= 2 ^ 14,
    ["中立"]	= 2 ^ 15,
    ["敌人"]	= 2 ^ 16,
    ["未知"]	= 2 ^ 17,
    ["未知"]	= 2 ^ 18,
    ["未知"]	= 2 ^ 19,
    ["可攻击的"]	= 2 ^ 20,
    ["无敌"]	= 2 ^ 21,
    ["英雄"]	= 2 ^ 22,
    ["非-英雄"]	= 2 ^ 23,
    ["存活"]	= 2 ^ 24,
    ["死亡"]	= 2 ^ 25,
    ["有机生物"]	= 2 ^ 26,
    ["机械类"]	= 2 ^ 27,
    ["非-自爆工兵"]	= 2 ^ 28,
    ["自爆工兵"]	= 2 ^ 29,
    ["非-古树"]	= 2 ^ 30,
    ["古树"]	= 2 ^ 31,
}

function skill.__index.convertTargets(data)
	local result = 0
	for name in data:gmatch '%S+' do
		local flag = skill.convert_targets[name]
		if not flag then
			error('错误的目标允许类型: ' .. name)
		end
		result = result + flag
	end
	return result
end

--技能目标允许常量
skill.__index.TARGET_DATA_ENEMY = '敌人'
skill.__index.TARGET_DATA_ALLY = '自己 玩家单位 联盟'

skill.__index.target_data = skill.__index.TARGET_DATA_ENEMY
skill.__index.target_type = skill.__index.TARGET_TYPE_NONE

base.target_filter = function(dest, target_data, is_skill)
	return function(self)
		if self:has_restriction '无敌' then
			return false
		end

		if is_skill and self:has_restriction '魔免' then
			return false
		end

		if not self:is_alive() then
			return false
		end
		
		if not self:is_visible(dest) then
			return false
		end

		if self:is_enemy(dest) then
			if not target_data:find '敌人' then
				return false
			end
		end

		if self == dest then
			if target_data:find '自己' then
				return true
			else
				return false
			end
		end

		if self:get_owner() == dest:get_owner() then
			if not target_data:find '玩家单位' then
				return false
			end
		end

		if self:is_ally(dest) then
			if not target_data:find '联盟' then
				return false
			end
		end

		if self:is_hero() then
			if target_data:find '非-英雄' then
				return false
			end
		else
			if target_data:find '英雄' then
				return false
			end
		end
		
		return true
	end
end
