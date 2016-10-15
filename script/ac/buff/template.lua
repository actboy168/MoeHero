
local function create_template(set_class)
	return setmetatable({}, {__index = function (self, name) 
		local obj = ac.buff[name]
		set_class(obj)
		local init = {'on_add', 'on_remove', 'on_finish', 'on_pulse', 'on_cover', 'on_cast'}
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
		})
		self[name] = tbl
		return tbl
	end})
end

ac.orb_buff = create_template(function(mt)
	mt.cover_type = 0
	mt.orb_count = 0
	mt.orb_effect = nil
	mt.model = nil
	mt.ref = 'origin'
	function mt:on_cast(damage)
		if self.__on_cast and self:__on_cast(damage) then
			return false
		end
		if self.orb_count <= 0 then
			return false
		end
		self.orb_count = self.orb_count - 1
		if self.orb_count == 0 then
			self:remove()
		end
		return true
	end
	function mt:on_add()
		self.orb_trg1 = self.target:event '单位-攻击开始' (function(trg, damage)
			if self.on_start then
				if self:on_start(damage) then
					return
				end
			end
			self.flag = true
		end)
		self.orb_trg2 = self.target:event '单位-攻击出手' (function(trg, damage)
			if self.flag then
				self.flag = nil
				self:on_cast(damage)
				damage:event '法球命中' (function (trg, damage)
					if self.on_hit then
						trg:disable()
						self:on_hit(damage)
						trg:enable()
					end
				end)
			end
		end)
		self.orb_trg3 = self.target:event '法球命中' (function(trg, damage)
			if self.on_start then
				if self:on_start(damage) then
					return
				end
			end
			self:on_cast(damage)
			if self.on_hit then
				trg:disable()
				self:on_hit(damage)
				trg:enable()
			end
		end)
		if self.model then
			self.orb_effect = self.target:add_effect(self.ref, self.model)
		end
		if self.__on_add then self:__on_add() end
	end
	function mt:on_remove()
		if self.orb_trg1 then self.orb_trg1:remove() end
		if self.orb_trg2 then self.orb_trg2:remove() end
		if self.orb_trg3 then self.orb_trg3:remove() end
		if self.orb_effect then self.orb_effect:remove() end
		if self.__on_remove then self:__on_remove() end
	end
end)

ac.aura_buff = create_template(function(mt)
	function mt:on_add()
		if not self.aura_pulse then
			self.aura_pulse = 0.5
		end
		local aura_pulse = self.aura_pulse * 1000
		local hero = self.target
		self.child_buff = self.child_buff or self.name
		local child_pulse = ac.buff[self.child_buff].pulse or self.pulse
		if not self.aura_child then
			if self.name == self.child_buff then
				self.selector:is_not(hero)
			end
			self.aura_node = {}
			self.aura_timer = hero:loop(aura_pulse, function ()
				if not hero:is_alive() then
					for u in pairs(self.aura_node) do
						self.aura_node[u]:remove()
						self.aura_node[u] = nil
					end
					return
				end
				local update = {}
				local delete = {}
				self.selector:select(function (u)
					update[u] = true
				end)
				for u in pairs(self.aura_node) do
					if not update[u] then
						table.insert(delete, u)
					end
				end
				for _, u in ipairs(delete) do
					self.aura_node[u]:remove()
					self.aura_node[u] = nil
				end
				for u in pairs(update) do
					if not self.aura_node[u] then
						self.aura_node[u] = u:add_buff(self.child_buff)
						{
							source = self.source,
							skill = self.skill,
							data = self.data,
							aura_child = true,
							parent_buff = self,
							pulse = child_pulse,
						}
					end
				end
			end)
			self.aura_timer:on_timer()
		end
		if self.__on_add then self:__on_add() end
	end
	function mt:on_remove()
		if self.aura_timer then self.aura_timer:remove() end
		if self.aura_node then
			for u, buff in pairs(self.aura_node) do
				buff:remove()
			end
		end
		if self.__on_remove then self:__on_remove() end
	end
	function mt:on_cover(new)
		if self.name == self.child_buff then
			if not new.aura_child then
				return true
			end
			self:set_remaining(new.time)
			return false
		else
			if self.__on_cover then
				return self:__on_cover(new)
			end
			return true
		end
	end
end)

local mt = ac.buff['通用-护盾特效']
mt.cover_type = 0
mt.cover_global = 1
function mt:on_add()
	self.count = 1
	self.shield_eff = self.target:add_effect('chest', [[model\common\shield.mdx]])
end
function mt:on_remove()
	if self.shield_eff then self.shield_eff:remove() end
end
function mt:on_cover()
	return false
end
function mt:refence()
	self.count = self.count + 1
end
function mt:unrefence()
	self.count = self.count - 1
	if self.count <= 0 then
		self:remove()
	end
end

local function add_shield_effect(hero, skill)
	local buff = hero:find_buff '通用-护盾特效'
	if buff then
		buff:refence()
	else
		hero:add_buff '通用-护盾特效' { skill = skill }
	end
end
local function del_shield_effect(hero)
	local buff = hero:find_buff '通用-护盾特效'
	if buff then
		buff:unrefence()
	end
end

ac.shield_buff = create_template(function(mt)
	mt.cover_type = 0
	function mt:on_add()
		local hero = self.target
		local shields = hero.shields
		if not shields then
			shields = {}
			hero.shields = shields
		end
		table.insert(shields, self)
		hero:add('护盾', self.life)
		if self.ref and self.model then
			self.shield_eff = hero:add_effect(self.ref, self.model)
		else
			add_shield_effect(hero, self.skill)
		end
		if self.__on_add then self:__on_add() end
	end
	function mt:on_remove()
		local hero = self.target
		local shields = hero.shields
		for i = 1, #shields do
			if shields[i] == self then
				table.remove(shields, i)
				break
			end
		end
		hero:add('护盾', - self.life)
		del_shield_effect(hero)
		if self.shield_eff then self.shield_eff:remove() end
		if self.__on_remove then self:__on_remove() end
	end
	function mt:on_cover(dst)
		if self.__on_cover then return self:__on_cover(dst) end
		if self.life < dst.life then
			self.life = dst.life
		end
		if self:get_remaining() < dst.time then
			self:set_remaining(dst.time)
		end
		return false
	end
	function mt:add_life(life)
		if self.life + life <= 0 then
			hero:add('护盾', - self.life)
			self.life = 0
			self:remove()
			return
		end
		self.life = self.life + life
		self.target:add('护盾', life)
	end
end)

ac.dot_buff = create_template(function(mt)
	mt.cover_type = 0
	mt.pulse = 0.2
	function mt:on_add()
		local count = math.floor(self.time / self.pulse)
		self.damages = {}
		for i = 1, count do
			self.damages[i] = self.damage
		end
		local last = self.time / self.pulse - count
		if last ~= 0 and type(self.damage) == 'number' then
			self.damages[count + 1] = self.damage * last
		end
		if self.__on_add then self:__on_add() end
		self:on_pulse()
	end
	function mt:on_remove()
		if self.__on_remove then self:__on_remove() end
	end
	function mt:on_pulse()
		if #self.damages == 0 then
			return
		end
		local damage = self.damages[1]
		table.remove(self.damages, 1)
		if self.__on_pulse then
			self:__on_pulse(damage)
		end
	end
	function mt:on_cover(dst)
		local count = math.floor(dst.time / dst.pulse)
		for i = 1, count do
			if not self.damages[i] then
				self.damages[i] = dst.damage
			else
				self.damages[i] = self.damages[i] + dst.damage
			end
		end
		local last = dst.time / dst.pulse - count
		if last ~= 0 and type(dst.damage) == 'number' then
			if not self.damages[count + 1] then
				self.damages[count + 1] = dst.damage * last
			else
				self.damages[count + 1] = self.damages[i] + dst.damage * last
			end
		end
		self:set_remaining(dst.time)
		if self.__on_cover then return self:__on_cover(dst) end
		return false
	end
end)
