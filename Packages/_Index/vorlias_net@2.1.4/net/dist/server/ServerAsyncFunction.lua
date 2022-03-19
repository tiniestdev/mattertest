-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local _configuration = TS.import(script, script.Parent.Parent, "configuration")
local DebugLog = _configuration.DebugLog
local DebugWarn = _configuration.DebugWarn
local _internal = TS.import(script, script.Parent.Parent, "internal")
local findOrCreateRemote = _internal.findOrCreateRemote
local IS_CLIENT = _internal.IS_CLIENT
local MiddlewareEvent = TS.import(script, script.Parent, "MiddlewareEvent").default
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local function isEventArgs(value)
	if #value < 2 then
		return false
	end
	local _binding = value
	local eventId = _binding[1]
	local data = _binding[2]
	return type(eventId) == "string" and type(data) == "table"
end
--[[
	*
	* An asynchronous function for two way communication between the client and server
]]
local ServerAsyncFunction
do
	local super = MiddlewareEvent
	ServerAsyncFunction = setmetatable({}, {
		__tostring = function()
			return "ServerAsyncFunction"
		end,
		__index = super,
	})
	ServerAsyncFunction.__index = ServerAsyncFunction
	function ServerAsyncFunction.new(...)
		local self = setmetatable({}, ServerAsyncFunction)
		return self:constructor(...) or self
	end
	function ServerAsyncFunction:constructor(name, middlewares)
		if middlewares == nil then
			middlewares = {}
		end
		super.constructor(self, middlewares)
		self.timeout = 10
		self.listeners = {}
		self.instance = findOrCreateRemote("AsyncRemoteFunction", name, function(instance)
			-- Default connection
			self.defaultHook = instance.OnServerEvent:Connect(ServerAsyncFunction.DefaultEventHook)
		end)
		local _arg0 = not IS_CLIENT
		assert(_arg0, "Cannot create a NetServerAsyncFunction on the client!")
	end
	function ServerAsyncFunction:GetInstance()
		return self.instance
	end
	function ServerAsyncFunction:SetCallTimeout(timeout)
		local _arg0 = timeout > 0
		assert(_arg0, "timeout must be a positive number")
		self.timeout = timeout
		return self
	end
	function ServerAsyncFunction:GetCallTimeout()
		return self.timeout
	end
	function ServerAsyncFunction:SetCallback(callback)
		local _result = self.defaultHook
		if _result ~= nil then
			_result:Disconnect()
		end
		if self.connector then
			self.connector:Disconnect()
			self.connector = nil
		end
		self.connector = self.instance.OnServerEvent:Connect(TS.async(function(player, ...)
			local args = { ... }
			if isEventArgs(args) then
				local _binding = args
				local eventId = _binding[1]
				local data = _binding[2]
				local _result_1 = self:_processMiddleware(callback)
				if _result_1 ~= nil then
					_result_1 = _result_1(player, unpack(data))
				end
				local result = _result_1
				if TS.Promise.is(result) then
					local _arg0 = function(promiseResult)
						self.instance:FireClient(player, eventId, promiseResult)
					end
					result:andThen(_arg0):catch(function(err)
						warn("[rbx-net] Failed to send response to client: " .. err)
					end)
				else
					if result == nil then
						warn("[rbx-net-async] " .. self.instance.Name .. " returned undefined")
					end
					self.instance:FireClient(player, eventId, result)
				end
			else
				warn("[rbx-net-async] Recieved message without eventId")
			end
		end))
	end
	ServerAsyncFunction.CallPlayerAsync = TS.async(function(self, player, ...)
		local args = { ... }
		local id = HttpService:GenerateGUID(false)
		local _fn = self.instance
		local _ptr = {}
		for _k, _v in pairs(args) do
			_ptr[_k] = _v
		end
		_fn:FireClient(player, id, _ptr)
		return TS.Promise.new(function(resolve, reject)
			local startTime = tick()
			DebugLog("Connected CallPlayerAsync EventId", id)
			local connection
			connection = self.instance.OnServerEvent:Connect(function(fromPlayer, ...)
				local recvArgs = { ... }
				local _binding = recvArgs
				local eventId = _binding[1]
				local data = _binding[2]
				if type(eventId) == "string" and data ~= nil then
					if player == player and eventId == id then
						DebugLog("Disconnected CallPlayerAsync EventId", eventId)
						connection:Disconnect()
						resolve(data)
					end
				end
			end)
			local _listeners = self.listeners
			local _arg1 = {
				connection = connection,
				timeout = self.timeout,
			}
			-- ▼ Map.set ▼
			_listeners[id] = _arg1
			-- ▲ Map.set ▲
			repeat
				do
					RunService.Stepped:Wait()
				end
			until not (connection.Connected and tick() < startTime + self.timeout)
			-- ▼ Map.delete ▼
			self.listeners[id] = nil
			-- ▲ Map.delete ▲
			if tick() >= startTime and connection.Connected then
				DebugWarn("(timeout) Disconnected CallPlayerAsync EventId", id)
				connection:Disconnect()
				reject("Request to client timed out")
			end
		end)
	end)
	ServerAsyncFunction.DefaultEventHook = function(player, ...)
		local args = { ... }
	end
end
local default = ServerAsyncFunction
return {
	default = default,
}
