local jass = require 'jass.common'
local japi = require 'jass.japi'
local math = math

--技能升级
local mt = ac.skill['技能升级']
{
	level = 1,

	max_level = 1,
	
	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNSkillz.blp]],

	never_copy = true,

	--技能说明
	tip = [[
	
你有尚未分配的技能点：%points%

|cffff1111注意,学习技能会打断持续施法!|r
	]],

	--技能数据
	cost = 0,
	--冷却
	cool = 0,
	--剩余技能点
	points = function(self, hero)
		return hero.skill_points
	end,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_NONE,
}

function mt:on_add()
	self.sub_skills = {}
end

function mt:on_remove()
	for i = 1, 4 do
		self:remove_sub_skill(i, true)
	end
end

local function init_learn_skill(self)
	local __on_cast_shot = self.on_cast_shot
	function self:on_cast_shot(skill)
		local hero = self.owner
		if hero.skill_points <= 0 then
			return
		end
		self.sub_skill:upgrade(1, skill or self)
		hero:addSkillPoint(-1)
		if not self:is_ability_enable() and hero:get_owner() == ac.player.self then
			jass.ForceUICancel()
		end
		if __on_cast_shot then
			__on_cast_shot(self, skill or self)
		end
	end
end

function mt:add_sub_skill(i)
	local hero = self.owner
	local skill = hero.skill_datas[i]
	local name = skill.learn_skill or '学习技能' .. i
	local lskill = hero:find_skill(name, '学习', true)
	if not lskill then
		local dest = hero:find_skill(i, '英雄', true)
		lskill = hero:add_skill(name, '学习', i, {
			max_level = dest.max_level,
		})
		lskill.sub_skill = dest
		self.sub_skills[i] = lskill
		init_learn_skill(lskill)
		function lskill:get_tip(...)
			return dest:get_learn_tip(...)
		end
		function lskill:get_title(...)
			return dest:get_learn_title(...)
		end
	end
	lskill:enable_ability()
	
	local smart_skill = hero:find_skill('智能施法开关' .. i, '智能施法')
	if smart_skill then
		smart_skill:disable_ability()
	end
	return lskill
end

function mt:remove_sub_skill(i, real_remove)
	local hero = self.owner
	local skill = self.sub_skills[i]
	if skill then
		skill:disable_ability()
		if real_remove then
			skill:remove()
			self.sub_skills[i] = nil
		end
		local smart_skill = hero:find_skill('智能施法开关' .. i, '智能施法')
		if smart_skill then
			smart_skill:enable_ability()
		else
			local smart_skill = hero:add_skill('智能施法开关' .. i, '智能施法', i)
		end
	end
end

function mt:call_updateSkillPoint()
	local hero = self.owner
	local level = hero:get_level()
	--技能点为0时退出技能学习界面
	if hero.skill_points <= 0 then
		for i = 1, 4 do
			self:remove_sub_skill(i)
		end
		return
	end
	--检查是否还有能学习的技能
	local flag = false
	for i = 1, 4 do
		local skl = hero:find_skill(i, '英雄', true)
		if skl and skl.level < skl.max_level then
			flag = true
			if ac.skill[skl.name].requirement[skl:get_level() + 1] <= level then
				local skill = self:add_sub_skill(i)
				skill:set_level(skl:get_level() + 1)
				skill:fresh()
				skill:set_target(ac.skill.TARGET_TYPE_NONE)
			else
				self:remove_sub_skill(i)
			end
		else
			self:remove_sub_skill(i, true)
		end
	end

	if not flag then
		if hero.skill_points ~= 0 then
			hero:addSkillPoint(- hero.skill_points)
		end
		return
	end
end

for i = 1, 4 do
	local mt = ac.skill['学习技能' .. i]
	{
		level = 1,
		instant = 1,
		force_cast = 1,
		never_reload = true,
		never_copy = true,
		art = [[ReplaceableTextures\CommandButtons\BTNSkillz.blp]],
		cool = 0,
		cost = 0,
	}
end
