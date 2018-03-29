




--物品名称
local mt = ac.skill['奈课']

--图标
mt.art = [[ReplaceableTextures\CommandButtons\BTNBootsOfSpeed.blp]]

--物品类型
mt.item_type = '鞋子'

--物品等级
mt.level = 1

--物品唯一
mt.unique = true

function mt:canBuy(hero)
	if hero and hero:find_buff '鞋-加速' then
		return '你只能拥有一双鞋子'
	end
end


