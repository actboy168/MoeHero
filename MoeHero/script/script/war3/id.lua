--转换256进制整数
base.ids1 = {}
base.ids2 = {}

function base._id(a)
	local s1 = math.floor(a/256/256/256)%256
	local s2 = math.floor(a/256/256)%256
	local s3 = math.floor(a/256)%256
	local s4 = a%256
	local r = string.char(s1, s2, s3, s4)
	base.ids1[a] = r
	base.ids2[r] = a
	return r
end

function base.id2string(a)
	return base.ids1[a] or base._id(a)
end

function base.__id2(a)
	local n1 = string.byte(a, 1) or 0
	local n2 = string.byte(a, 2) or 0
	local n3 = string.byte(a, 3) or 0
	local n4 = string.byte(a, 4) or 0
	local r = n1*256*256*256+n2*256*256+n3*256+n4
	base.ids2[a] = r
	base.ids1[r] = a
	return r
end

function base.string2id(a)
	return base.ids2[a] or base.__id2(a)
end