local japi = require 'jass.japi'

local function create_template(set_class)
	return setmetatable({}, {__index = function (self, name) 
		local obj = ac.skill[name]
		set_class(obj)
		local init = {'on_add', 'on_remove', 'on_upgrade', 'on_cooldown', 'on_can_cast', 'on_cast_start', 'on_cast_break', 'on_cast_channel', 'on_cast_shot', 'on_cast_finish', 'on_cast_stop', 'on_enable', 'on_disable', 'on_open', 'on_close'}
		local hook = {}
		for i, key in ipairs(init) do
			if obj[key] then
				hook[key] = true
			end
		end
		local tbl = setmetatable({}, {
			__newindex = function (self, key, val)
				if hook[key] then
					obj['__' .. key] = val
					return
				end
				obj[key] = val
			end,
			__index = function (self, key)
				if hook[key] then
					return obj['__' .. key]
				end
				return obj[key]
			end,
			__call = function (self, ...)
				obj(...)
				set_class(obj)
			end,
		})
		self[name] = tbl
		return tbl
	end})
end


ac.book_skill = create_template(function(mt)

	mt.sub_skills = {}

	function mt:on_add()
		local hero = self.owner
		self.skills = {}
		for y = 1, 3 do
			for x = 1, 4 do
				local i = x + 4 * (y - 1)
				if self.sub_skills[i] then
					local name = '__' .. self.name .. x .. y
					local mt = ac.skill[name]
					local data = {
						ability_id = 'AX' .. x .. y,
						no_ability = true,
						never_reload = true,
						instant = 1,
						sub_id = i,
					}
					for k, v in pairs(self.sub_skills[i]) do
						data[k] = v
					end
					mt(data)
					local skill = hero:add_skill(name, '隐藏')
					table.insert(self.skills, skill)
					skill:fresh_art()
					skill:fresh_tip()
					skill:fresh_title()

					function skill.on_cast_shot()
						if self.on_cast_shot then
							self:on_cast_shot(skill)
						end
					end
				else
					-- 将通魔的图标隐藏了
					japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.owner.handle, base.string2id('AX' .. x .. y)), 1, 0x6E, 0)
				end
			end
		end
		if self.__on_add then
			self:__on_add()
		end
	end

	function mt:on_remove()
		if self.__on_remove then
			self:__on_remove()
		end
		for _, skill in ipairs(self.skills) do
			skill:remove()
		end
	end

	function mt:on_cast_shot(skill)
		if self.__on_cast_shot then
			self:__on_cast_shot(skill)
		end
	end
end)
