local mt = {}
mt.__index = mt

-- 上限提升比例
mt.add_max_rate = 0
-- 回复提升比例
mt.add_recover_rate = 0
-- 减耗比例
mt.get_cost_save_rate = 0
-- 颜色
mt.color = 'ffff11'
-- 复活时恢复的能量(0:变成0 1:维持上一次死亡的值 2:回满)
mt.reborn_type = 0

ac.resource = setmetatable({}, {__index = function(self, name)
	local resource = setmetatable({}, mt)
	rawset(self, name, resource)
	return resource
end})
