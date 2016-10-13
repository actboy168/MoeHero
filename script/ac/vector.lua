local format = string.format
local sqrt = math.sqrt
local atan = math.atan
local cos = math.cos
local sin = math.sin
local setmetatable = setmetatable

local mt = {}
local api = {}
mt.__index = api

api[1] = 0.0
api[2] = 0.0
api[3] = 0.0

local function vec_create(x, y, z)
	return setmetatable({x, y, z}, mt)
end

function mt:__call()
	return self[1], self[2], self[3]
end

function mt:__tostring()
	return format('(%.2f,%.2f,%.2f)', self[1], self[2], self[3])
end

function api:copy()
	return vec_create(self[1], self[2], self[3])
end

function api:distance()
	return sqrt(self[1] * self[1] + self[2] * self[2] + self[3] * self[3])
end

function api:angle()
	return atan(self[2], self[1])
end

function ac.vector_xy(x, y, z)
	return vec_create(x, y, z)
end

function ac.vector_o(distance, angle)
	return vec_create(distance * cos(angle), distance * sin(angle))
end
