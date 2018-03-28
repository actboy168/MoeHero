for i = 1, 4 do
	local mt = ac.skill['预览技能' .. i]
	{
		--默认等级
		level = 1,

		max_level = 1,

		--技能图标
		art = [[ReplaceableTextures\CommandButtons\BTNSkillz.blp]],

		--不自动刷新文本
		auto_fresh_tip = false,
	}
end
