local shop = require 'types.shop'

local mt = ac.skill['商店物品']

mt.auto_fresh_tip = false

function mt:fresh()
	local hero = self.owner:get_owner().hero
	if not hero then
		self:set_tip '' 
		self:set_title '空' 
		self:set_art [[shop\item.blp]]
		return
	end

	local slotid = self.slotid
	local it = hero:find_skill(slotid, '物品')
	if not it then
		self:set_tip '' 
		self:set_title '空' 
		self:set_art [[shop\item.blp]]
		return
	end

	self:set_tip(it:get_tip())
	self:set_title(it:get_title())
	self:set_art(it.art)
end

function mt:on_add()
	self:disable_drop()
end

function mt:on_use()
	local shop = self.owner
	local hero = shop:get_owner().hero
	if not hero then
		return
	end

	local slotid = self.slotid
	local it = hero:find_skill(slotid, '物品')
	if not it or it.level >= 4 then
		shop.current_item = nil
		shop:clearPageStack()
		shop:setCurrentPage '主页'
		return
	end
	
	shop.current_item = it
	shop:setCurrentPage(it.item_type .. it.level)
end
