local setmetatable = setmetatable
local ipairs = ipairs

local ac_game = ac.game

function ac.event_dispatch(obj, name, ...)
	local events = obj.events
	if not events then
		return
	end
	local event = events[name]
	if not event then
		return
	end
	for i = #event, 1, -1 do
		local res = event[i](...)
		if res ~= nil then
			return res
		end
	end
end

function ac.event_notify(obj, name, ...)
	local events = obj.events
	if not events then
		return
	end
	local event = events[name]
	if not event then
		return
	end
	for i = #event, 1, -1 do
		event[i](...)
	end
end

function ac.event_register(obj, name)
	local events = obj.events
	if not events then
		events = {}
		obj.events = events
	end
	local event = events[name]
	if not event then
		event = {}
		events[name] = event
		function event:remove()
			events[name] = nil
		end
	end
	return function (f)
		return ac.trigger(event, f)
	end
end

function ac.game:event_dispatch(name, ...)
	return ac.event_dispatch(self, name, ...)
end

function ac.game:event_notify(name, ...)
	return ac.event_notify(self, name, ...)
end

function ac.game:event(name)
	return ac.event_register(self, name)
end
