
moe = {}

--创建等差数列
--	第一个数字
--	步长
--	总长度
function moe.series(start, step, count)
	local t = {start}
	for i = 2, count do
		t[i] = t[i - 1] + step
	end
	return t
end