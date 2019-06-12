local strchar = string.char
local strrep = string.rep
local strunpack = string.unpack
local h0, h1, h2, h3, h4

local function ToHex(num)
    local d
    local str = ""
    for _ = 1, 8 do
        d = num & 15
        if d < 10 then
            str = strchar(d + 48) .. str
        else
            str = strchar(d + 87) .. str
        end
        num = num // 16
    end
    return str
end

local function PreProcess(str)
    local str2 = ""
    local len = #str * 8
    for _ = 1, 8 do
        str2 = strchar(len & 255) .. str2
        len = len // 256
    end
    local n = 56 - ((#str + 1) & 63)
    if n < 0 then
        n = n + 64
    end
    return str .. strchar(128) .. strrep(strchar(0), n) .. str2
end

local function MainLoop(str)
    local a, b, c, d, e, t
    local w01, w02, w03, w04, w05, w06, w07, w08, w09, w10, w11, w12, w13, w14, w15, w16
        , w17, w18, w19, w20, w21, w22, w23, w24, w25, w26, w27, w28, w29, w30, w31, w32
        , w33, w34, w35, w36, w37, w38, w39, w40, w41, w42, w43, w44, w45, w46, w47, w48
        , w49, w50, w51, w52, w53, w54, w55, w56, w57, w58, w59, w60, w61, w62, w63, w64
        , w65, w66, w67, w68, w69, w70, w71, w72, w73, w74, w75, w76, w77, w78, w79, w80
    for n = 1, #str, 64 do
        w01, w02, w03, w04, w05, w06, w07, w08, w09, w10, w11, w12, w13, w14, w15, w16
        = strunpack(('>LLLLLLLLLLLLLLLL'), str, n)

        t   = (w14 ~ w09) ~ (w03 ~ w01)
        w17 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w15 ~ w10) ~ (w04 ~ w02)
        w18 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w16 ~ w11) ~ (w05 ~ w03)
        w19 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w17 ~ w12) ~ (w06 ~ w04)
        w20 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w18 ~ w13) ~ (w07 ~ w05)
        w21 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w19 ~ w14) ~ (w08 ~ w06)
        w22 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w20 ~ w15) ~ (w09 ~ w07)
        w23 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w21 ~ w16) ~ (w10 ~ w08)
        w24 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w22 ~ w17) ~ (w11 ~ w09)
        w25 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w23 ~ w18) ~ (w12 ~ w10)
        w26 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w24 ~ w19) ~ (w13 ~ w11)
        w27 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w25 ~ w20) ~ (w14 ~ w12)
        w28 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w26 ~ w21) ~ (w15 ~ w13)
        w29 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w27 ~ w22) ~ (w16 ~ w14)
        w30 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w28 ~ w23) ~ (w17 ~ w15)
        w31 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w29 ~ w24) ~ (w18 ~ w16)
        w32 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w30 ~ w25) ~ (w19 ~ w17)
        w33 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w31 ~ w26) ~ (w20 ~ w18)
        w34 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w32 ~ w27) ~ (w21 ~ w19)
        w35 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w33 ~ w28) ~ (w22 ~ w20)
        w36 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w34 ~ w29) ~ (w23 ~ w21)
        w37 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w35 ~ w30) ~ (w24 ~ w22)
        w38 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w36 ~ w31) ~ (w25 ~ w23)
        w39 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w37 ~ w32) ~ (w26 ~ w24)
        w40 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w38 ~ w33) ~ (w27 ~ w25)
        w41 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w39 ~ w34) ~ (w28 ~ w26)
        w42 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w40 ~ w35) ~ (w29 ~ w27)
        w43 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w41 ~ w36) ~ (w30 ~ w28)
        w44 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w42 ~ w37) ~ (w31 ~ w29)
        w45 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w43 ~ w38) ~ (w32 ~ w30)
        w46 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w44 ~ w39) ~ (w33 ~ w31)
        w47 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w45 ~ w40) ~ (w34 ~ w32)
        w48 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w46 ~ w41) ~ (w35 ~ w33)
        w49 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w47 ~ w42) ~ (w36 ~ w34)
        w50 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w48 ~ w43) ~ (w37 ~ w35)
        w51 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w49 ~ w44) ~ (w38 ~ w36)
        w52 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w50 ~ w45) ~ (w39 ~ w37)
        w53 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w51 ~ w46) ~ (w40 ~ w38)
        w54 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w52 ~ w47) ~ (w41 ~ w39)
        w55 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w53 ~ w48) ~ (w42 ~ w40)
        w56 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w54 ~ w49) ~ (w43 ~ w41)
        w57 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w55 ~ w50) ~ (w44 ~ w42)
        w58 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w56 ~ w51) ~ (w45 ~ w43)
        w59 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w57 ~ w52) ~ (w46 ~ w44)
        w60 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w58 ~ w53) ~ (w47 ~ w45)
        w61 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w59 ~ w54) ~ (w48 ~ w46)
        w62 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w60 ~ w55) ~ (w49 ~ w47)
        w63 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w61 ~ w56) ~ (w50 ~ w48)
        w64 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w62 ~ w57) ~ (w51 ~ w49)
        w65 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w63 ~ w58) ~ (w52 ~ w50)
        w66 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w64 ~ w59) ~ (w53 ~ w51)
        w67 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w65 ~ w60) ~ (w54 ~ w52)
        w68 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w66 ~ w61) ~ (w55 ~ w53)
        w69 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w67 ~ w62) ~ (w56 ~ w54)
        w70 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w68 ~ w63) ~ (w57 ~ w55)
        w71 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w69 ~ w64) ~ (w58 ~ w56)
        w72 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w70 ~ w65) ~ (w59 ~ w57)
        w73 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w71 ~ w66) ~ (w60 ~ w58)
        w74 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w72 ~ w67) ~ (w61 ~ w59)
        w75 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w73 ~ w68) ~ (w62 ~ w60)
        w76 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w74 ~ w69) ~ (w63 ~ w61)
        w77 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w75 ~ w70) ~ (w64 ~ w62)
        w78 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w76 ~ w71) ~ (w65 ~ w63)
        w79 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)
        t   = (w77 ~ w72) ~ (w66 ~ w64)
        w80 = (t << 1) | ((t & 0xFFFFFFFF) >> 31)

        a,b,c,d,e = h0,h1,h2,h3,h4
        t = w01 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w02 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w03 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w04 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w05 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w06 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w07 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w08 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w09 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w10 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w11 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w12 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w13 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w14 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w15 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w16 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w17 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w18 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w19 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w20 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1518500249 + ((b & c) | ((~b) & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d

        t = w21 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w22 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w23 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w24 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w25 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w26 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w27 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w28 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w29 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w30 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w31 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w32 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w33 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w34 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w35 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w36 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w37 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w38 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w39 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w40 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 1859775393 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d

        t = w41 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w42 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w43 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w44 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w45 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w46 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w47 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w48 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w49 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w50 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w51 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w52 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w53 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w54 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w55 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w56 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w57 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w58 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w59 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w60 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 2400959708 + ((b & c) | (b & d) | (c & d))
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d

        t = w61 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w62 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w63 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w64 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w65 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w66 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w67 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w68 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w69 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w70 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w71 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w72 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w73 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w74 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w75 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w76 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w77 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w78 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w79 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d
        t = w80 + ((a << 5) | ((a& 0xFFFFFFFF) >> 27)) + e + 3395469782 + ((b ~ c) ~ d)
        a,b,c,d,e = t,a,((b<<30)|((b&0xFFFFFFFF)>>2)),c,d

        h0 = (h0 + a) & 0xFFFFFFFF
        h1 = (h1 + b) & 0xFFFFFFFF
        h2 = (h2 + c) & 0xFFFFFFFF
        h3 = (h3 + d) & 0xFFFFFFFF
        h4 = (h4 + e) & 0xFFFFFFFF
    end
end

return function (str)
    str = PreProcess(str)
    h0  = 1732584193
    h1  = 4023233417
    h2  = 2562383102
    h3  = 0271733878
    h4  = 3285377520
    MainLoop(str)
    return ToHex(h0) .. ToHex(h1) .. ToHex(h2) .. ToHex(h3) .. ToHex(h4)
end
