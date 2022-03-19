-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local _configuration = TS.import(script, script.Parent.Parent, "configuration")
local DebugLog = _configuration.DebugLog
local DebugWarn = _configuration.DebugWarn
local _internal = TS.import(script, script.Parent.Parent, "internal")
local getRemoteOrThrow = _internal.getRemoteOrThrow
local IS_SERVER = _internal.IS_SERVER
local waitForRemote = _internal.waitForRemote
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
--[[
	*
	* An event that behaves like a function
	* @rbxts client
]]
local ClientAsyncFunction
do
	ClientAsyncFunction = setmetatable({}, {
		__tostring = function()
			return "ClientAsyncFunction"
		end,
	})
	ClientAsyncFunction.__index = ClientAsyncFunction
	function ClientAsyncFunction.new(...)
		local self = setmetatable({}, ClientAsyncFunction)
		return self:constructor(...) or self
	end
	function ClientAsyncFunction:constructor(name)
		self.timeout = 10
		self.listeners = {}
		self.instance = getRemoteOrThrow("AsyncRemoteFunction", name)
		local _arg0 = not IS_SERVER
		assert(_arg0, "Cannot create a Net.ClientAsyncFunction on the Server!")
	end
	function ClientAsyncFunction:Wait(name)
		return TS.Promise.defer(TS.async(function(resolve)
			TS.await(waitForRemote("AsyncRemoteFunction", name, 60))
			resolve(ClientAsyncFunction.new(name))
		end))
	end
	function ClientAsyncFunction:SetCallTimeout(timeout)
		local _arg0 = timeout > 0
		assert(_arg0, "timeout must be a positive number")
		self.timeout = timeout
	end
	function ClientAsyncFunction:GetCallTimeout()
		return self.timeout
	end
	function ClientAsyncFunction:SetCallback(callback)
		if self.connector then
			self.connector:Disconnect()
			self.connector = nil
		end
		self.connector = self.instance.OnClientEvent:Connect(TS.async(function(...)
			local args = { ... }
			local _binding = args
			local eventId = _binding[1]
			local data = _binding[2]
			if type(eventId) == "string" and type(data) == "table" then
				local result = callback(unpack(data))
				if TS.Promise.is(result) then
					local _arg0 = function(promiseResult)
						self.instance:FireServer(eventId, promiseResult)
					end
					result:andThen(_arg0):catch(function(err)
						warn("[rbx-net] Failed to send response to server: " .. err)
					end)
				else
					self.instance:FireServer(eventId, result)
				end
			else
				warn("Recieved message without eventId")
			end
		end))
	end
	ClientAsyncFunction.CallServerAsync = TS.async(function(self, ...)
		local args = { ... }
		local id = HttpService:GenerateGUID(false)
		local _fn = self.instance
		local _ptr = {}
		for _k, _v in pairs(args) do
			_ptr[_k] = _v
		end
		_fn:FireServer(id, _ptr)
		return TS.Promise.new(function(resolve, reject)
			local startTime = tick()
			DebugLog("Connected CallServerAsync EventId", id)
			local connection
			connection = self.instance.OnClientEvent:Connect(function(...)
				local recvArgs = { ... }
				local _binding = recvArgs
				local eventId = _binding[1]
				local data = _binding[2]
				if type(eventId) == "string" and data ~= nil then
					if eventId == id then
						DebugLog("Disconnected CallServerAsync EventId", eventId)
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
					RunService.Heartbeat:Wait()
				end
			until not (connection.Connected and tick() < startTime + self.timeout)
			-- ▼ Map.delete ▼
			self.listeners[id] = nil
			-- ▲ Map.delete ▲
			if tick() >= startTime and connection.Connected then
				DebugWarn("(timeout) Disconnected CallServerAsync EventId", id)
				connection:Disconnect()
				reject("Request to server timed out after " .. tostring(self.timeout) .. " seconds")
			end
		end)
	end)
end
return {
	default = ClientAsyncFunction,
}
