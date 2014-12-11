local function get_millis()
	return minetest.get_us_time() / 1000
end
local Timer = { --port of a timer module I use for arduino
	lastTime = 0,
	interval = 0,
	first = true
}
setmetatable(Timer, { --OOP style
  __call = function (cls, ...)
    return cls._init(...)
  end,
})

function Timer:_init()
	self.lastTime = get_millis()
end
function Timer:Reset()
	self.lastTime = get_millis()
end
function Timer:SetInterval(interval)
	this.interval = interval
end
function Timer:CheckInterval()
	return self:Check(interval)
end
function Timer:Check(time)
	local isGo = false
	local first = false
	local ms = get_millis()

	isGo = self.lastTime + time < ms
	if isGo then
		self.lastTime = ms
	end
end
function Timer:Every(time)
	return self.First() or self.Check()
end
function Timer:StaticCheck(time)
	return self.lastTime + time < get_millis()
end
function Timer:First()
	val = self.first
	self.first = false
	return val
end
return Timer