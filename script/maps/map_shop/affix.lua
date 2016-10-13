
local affix = require 'types.affix'

local mt = {}
mt.name = '吸血'
mt.gold = 750
mt.item_type = '武器'
mt.level = 2
mt.life_steal = 9
affix.create(mt)

local mt = {}
mt.name = '攻速'
mt.gold = 750
mt.item_type = '武器'
mt.level = 2
mt.attack_speed = 12
affix.create(mt)

local mt = {}
mt.name = '溅射'
mt.gold = 650
mt.item_type = '武器'
mt.level = 2
mt.splash = 25
affix.create(mt)

local mt = {}
mt.name = '攻击%'
mt.gold = 900
mt.item_type = '武器'
mt.level = 3
mt.attack_rate = 9
affix.create(mt)

local mt = {}
mt.name = '暴击'
mt.gold = 900
mt.item_type = '武器'
mt.level = 3
mt.crit = 12
affix.create(mt)

local mt = {}
mt.name = '破甲'
mt.gold = 900
mt.item_type = '武器'
mt.level = 3
mt.pene = 15
affix.create(mt)

local mt = {}
mt.name = '生命'
mt.gold = 850
mt.item_type = '武器'
mt.level = 3
mt.life = 300
affix.create(mt)

local mt = {}
mt.name = '回复'
mt.gold = 750
mt.item_type = '防具'
mt.level = 2
mt.restore = 12
affix.create(mt)

local mt = {}
mt.name = '法力'
mt.gold = 750
mt.item_type = '防具'
mt.level = 2
mt.mana = 300
affix.create(mt)

local mt = {}
mt.name = '减耗'
mt.gold = 750
mt.item_type = '防具'
mt.level = 2
mt.cost_save = 12
affix.create(mt)

local mt = {}
mt.name = '生命%'
mt.gold = 850
mt.item_type = '防具'
mt.level = 3
mt.life_rate = 6
affix.create(mt)

local mt = {}
mt.name = '防御'
mt.gold = 850
mt.item_type = '防具'
mt.level = 3
mt.defence = 20
affix.create(mt)

local mt = {}
mt.name = '格挡'
mt.gold = 850
mt.item_type = '防具'
mt.level = 3
mt.block = 8
affix.create(mt)

local mt = {}
mt.name = '攻击'
mt.gold = 850
mt.item_type = '防具'
mt.level = 3
mt.attack = 30
affix.create(mt)

local mt = {}
mt.name = '冷却'
mt.gold = 1200
mt.item_type = '鞋子'
mt.level = 2
mt.cool_save = 20
affix.create(mt)

local mt = {}
mt.name = '暴击'
mt.gold = 1200
mt.item_type = '鞋子'
mt.level = 2
mt.crit = 20
affix.create(mt)

local mt = {}
mt.name = '防御%'
mt.gold = 1200
mt.item_type = '鞋子'
mt.level = 2
mt.defence_rate = 20
affix.create(mt)

local mt = {}
mt.name = '穿透'
mt.gold = 1200
mt.item_type = '鞋子'
mt.level = 2
mt.pene_rate_ex = 20
affix.create(mt)
