-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local _internal = TS.import(script, script.Parent.Parent, "internal")
local format = _internal.format
local IS_SERVER = _internal.IS_SERVER
local ServerTickFunctions = _internal.ServerTickFunctions
local throttler = TS.import(script, script, "throttle")
local GetConfiguration = TS.import(script, script.Parent.Parent, "configuration").GetConfiguration
local throttles = {}
local function rateLimitWarningHandler(rateLimitError)
	warn("[rbx-net]", rateLimitError.Message)
end
--[[
	*
	* Creates a throttle middleware for this event
	*
	* Will limit the amount of requests a player can make to this event
	*
	* _NOTE: Must be used before **other** middlewares as it's not a type altering middleware_
	* @param maxRequestsPerMinute The maximum requests per minute
]]
local function createRateLimiter(options)
	local maxRequestsPerMinute = options.MaxRequestsPerMinute
	local _condition = options.ErrorHandler
	if _condition == nil then
		_condition = rateLimitWarningHandler
	end
	local errorHandler = _condition
	return function(processNext, event)
		local instance = event:GetInstance()
		local throttle = throttles[event]
		if throttle == nil then
			throttle = throttler:Get(instance:GetFullName())
		end
		return function(player, ...)
			local args = { ... }
			local count = throttle:Get(player)
			if count >= maxRequestsPerMinute then
				local _result = errorHandler
				if _result ~= nil then
					_result({
						Message = format(GetConfiguration("ServerThrottleMessage"), {
							player = player.UserId,
							remote = instance.Name,
							limit = maxRequestsPerMinute,
						}),
						MaxRequestsPerMinute = maxRequestsPerMinute,
						RemoteId = instance.Name,
						UserId = player.UserId,
					})
				end
			else
				throttle:Increment(player)
				return processNext(player, unpack(args))
			end
		end
	end
end
if IS_SERVER then
	local lastTick = 0
	local _arg0 = function()
		if tick() > lastTick + GetConfiguration("ServerThrottleResetTimer") then
			lastTick = tick()
			throttler:Clear()
		end
	end
	-- ▼ Array.push ▼
	ServerTickFunctions[#ServerTickFunctions + 1] = _arg0
	-- ▲ Array.push ▲
end
local default = createRateLimiter
return {
	rateLimitWarningHandler = rateLimitWarningHandler,
	default = default,
}
