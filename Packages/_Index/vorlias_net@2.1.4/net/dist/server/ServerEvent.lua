-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local _internal = TS.import(script, script.Parent.Parent, "internal")
local findOrCreateRemote = _internal.findOrCreateRemote
local IS_CLIENT = _internal.IS_CLIENT
local IS_RUNNING = _internal.IS_RUNNING
local MiddlewareEvent = TS.import(script, script.Parent, "MiddlewareEvent").default
--[[
	*
	* Interface for server listening events
]]
--[[
	*
	* Interface for server sender events
]]
local ServerEvent
do
	local super = MiddlewareEvent
	ServerEvent = setmetatable({}, {
		__tostring = function()
			return "ServerEvent"
		end,
		__index = super,
	})
	ServerEvent.__index = ServerEvent
	function ServerEvent.new(...)
		local self = setmetatable({}, ServerEvent)
		return self:constructor(...) or self
	end
	function ServerEvent:constructor(name, middlewares)
		if middlewares == nil then
			middlewares = {}
		end
		super.constructor(self, middlewares)
		self.instance = findOrCreateRemote("RemoteEvent", name, function(instance)
			-- Default connection
			self.defaultHook = instance.OnServerEvent:Connect(ServerEvent.DefaultEventHook)
		end)
		local _arg0 = not IS_CLIENT
		assert(_arg0, "Cannot create a NetServerEvent on the client!")
	end
	function ServerEvent:GetInstance()
		return self.instance
	end
	function ServerEvent:Connect(callback)
		local _result = self.defaultHook
		if _result ~= nil then
			_result:Disconnect()
		end
		local connection = self.instance.OnServerEvent:Connect(function(player, ...)
			local args = { ... }
			local _result_1 = self:_processMiddleware(callback)
			if _result_1 ~= nil then
				_result_1(player, unpack(args))
			end
		end)
		return connection
	end
	function ServerEvent:SendToAllPlayers(...)
		local args = { ... }
		if not IS_RUNNING then
			return nil
		end
		self.instance:FireAllClients(unpack(args))
	end
	function ServerEvent:SendToAllPlayersExcept(blacklist, ...)
		local args = { ... }
		if not IS_RUNNING then
			return nil
		end
		local Players = game:GetService("Players")
		if typeof(blacklist) == "Instance" then
			local _exp = Players:GetPlayers()
			local _arg0 = function(p)
				return p ~= blacklist
			end
			-- ▼ ReadonlyArray.filter ▼
			local _newValue = {}
			local _length = 0
			for _k, _v in ipairs(_exp) do
				if _arg0(_v, _k - 1, _exp) == true then
					_length += 1
					_newValue[_length] = _v
				end
			end
			-- ▲ ReadonlyArray.filter ▲
			local otherPlayers = _newValue
			for _, player in ipairs(otherPlayers) do
				self.instance:FireClient(player, unpack(args))
			end
		elseif type(blacklist) == "table" then
			for _, player in ipairs(Players:GetPlayers()) do
				if (table.find(blacklist, player) or 0) - 1 == -1 then
					self.instance:FireClient(player, unpack(args))
				end
			end
		end
	end
	function ServerEvent:SendToPlayer(player, ...)
		local args = { ... }
		if not IS_RUNNING then
			return nil
		end
		self.instance:FireClient(player, unpack(args))
	end
	function ServerEvent:SendToPlayers(players, ...)
		local args = { ... }
		if not IS_RUNNING then
			return nil
		end
		for _, player in ipairs(players) do
			self:SendToPlayer(player, unpack(args))
		end
	end
	ServerEvent.DefaultEventHook = function(player, ...)
		local args = { ... }
	end
end
return {
	default = ServerEvent,
}
