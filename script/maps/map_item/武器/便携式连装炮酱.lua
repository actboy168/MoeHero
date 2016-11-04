



--物品名称
local mt = ac.skill['便携式连装炮酱']

--图标
mt.art = [[replaceabletextures\commandbuttons\BTNMultipleGun.blp]]

--说明
mt.tip = [[
连装炮酱会和你并肩作战。
]]

--物品类型
mt.item_type = '武器'

--物品等级
mt.level = 4

--附魔价格
mt.gold = 1700

--物品唯一
mt.unique = true

function mt:on_add()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.dummy = hero:create_unit('e00N', hero:get_point() - {math.random(0, 360), 200})
	self.dummy:set_size(2)
	self.dummy:add_enemy_tag()
	self.dummy:set_animation('birth')
	self.dummy:add_animation('stand')
	self.dummy:add_skill('暴走的连装炮酱', '隐藏')
	self.dummy:set('攻击', hero:get('攻击'))
	local attack_clock = self.dummy:clock()
	self.timer = hero:loop(5000, function()
		if self.dummy:get_point() * hero:get_point() > 500 then
			self.dummy:get_point():add_effect([[model\shimakaze\multiple_gun_003.mdl]]):remove()
			self.dummy:setPoint(hero:get_point() - {self.dummy:get_point() / hero:get_point(), 200})
			self.dummy:set_animation('birth')
			self.dummy:add_animation('stand')
		end
		self.dummy:set('攻击', hero:get('攻击'))
		hero:wait(700, function ()
			if self.dummy:clock() - attack_clock > 3000 then
				return
			end
			self.dummy:cast('暴走的连装炮酱')
		end)
	end)
	self.attack_trg = self.dummy:event '单位-攻击出手' (function (_, damage)
		attack_clock = self.dummy:clock()
		self.dummy:set_facing(self.dummy:get_point() / damage.target:get_point())
	end)
	self.damage_trg = self.dummy:event '造成伤害' (function (_, damage)
		local target = damage.target
		if target:is_type('建筑') then
			damage:div(0.6)
		end
	end)
end

function mt:on_remove()
	local hero = self.owner
	if hero:is_illusion() then
		return
	end
	self.timer:remove()
	self.attack_trg:remove()
	self.damage_trg:remove()
	self.dummy:kill()
end



local mt = ac.skill['暴走的连装炮酱']

mt{
	level = 1,
	cast_channel_time = 1,
}

function mt:on_cast_channel()
	local hero = self.owner
	local angle = hero:get_facing()
	local facing = angle
	local min_facing = facing - 20
	local max_facing = facing + 20
	local delta = 10
	local mark = {}
	local damage = hero:get_ad() * 0.8
	self.timer = hero:loop(60, function()
		if facing > max_facing then
			delta = -math.abs(delta)
		elseif facing < min_facing then
			delta = math.abs(delta)
		end
		facing = facing + delta
		hero:set_facing(facing)
		local start = hero:get_point() - {facing, 80}
		local mvr = ac.mover.line
		{
			source = hero,
			distance = 1200,
			start = start,
			model = [[model\shimakaze\multiple_gun_missile.mdx]],
			speed = 2000,
			angle = facing,
			missile = true,
			skill = self,
			high = 60,
			target_high = 0,
			hit_area = 100,
		}
		if not mvr then
			return
		end
		function mvr:on_hit(u)
			if mark[u] == nil then
				mark[u] = 1
			elseif mark[u] < 4 then
				mark[u] = mark[u] + 1
			else
				return
			end
			u:damage
			{
				source = hero,
				damage = damage,
				skill = self.skill,
				aoe = true,
				attack = true,
			}
			return true
		end
	end)
	self.timer:on_timer()
end

function mt:on_cast_stop()
	local hero = self.owner
	self.timer:remove()
end
