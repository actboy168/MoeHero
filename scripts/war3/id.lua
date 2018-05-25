--转换256进制整数
base.ids1 = {}
base.ids2 = {}

function base._id(a)
	local r = ('>I4'):pack(a)
	base.ids1[a] = r
	base.ids2[r] = a
	return r
end

function base.id2string(a)
	return base.ids1[a] or base._id(a)
end

function base.__id2(a)
	local r = ('>I4'):unpack(a)
	base.ids2[a] = r
	base.ids1[r] = a
	return r
end

function base.string2id(a)
	return base.ids2[a] or base.__id2(a)
end