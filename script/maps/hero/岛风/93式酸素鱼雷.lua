local mt = ac.skill['93式酸素鱼雷']

mt{
    level = 0,
    art = [[replaceabletextures\commandbuttons\BTNmarisaE.blp]],
    title = '93式酸素鱼雷',
    tip = [[
向指定地点发射一枚鱼雷，命中敌人后会产生小规模的爆炸，造成%damage_base%(+%damage_plus%)伤害。
    ]],
    damage_base = {20, 40},
    damage_plus = function(self, hero)
        return hero:get_ad() * 0.4
    end,
    damage = function(self, hero)
        return self.damage_base + self.damage_plus
    end,
}
