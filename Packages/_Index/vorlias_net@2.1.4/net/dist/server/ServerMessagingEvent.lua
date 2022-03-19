-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local _MessagingEvent = TS.import(script, script.Parent.Parent, "messaging", "MessagingEvent")
local MessagingEvent = _MessagingEvent.default
local isSubscriptionMessage = _MessagingEvent.isSubscriptionMessage
local _internal = TS.import(script, script.Parent.Parent, "internal")
local getGlobalRemote = _internal.getGlobalRemote
local IS_CLIENT = _internal.IS_CLIENT
local isLuaTable = _internal.isLuaTable
local ServerEvent = TS.import(script, script.Parent, "ServerEvent").default
local Players = game:GetService("Players")
local function isTargetedSubscriptionMessage(value)
	if isSubscriptionMessage(value) then
		if isLuaTable(value.Data) then
			return value.Data.InnerData ~= nil
		end
	end
	return false
end
--[[
	*
	* Similar to a ServerEvent, but works across all servers.
]]
local ServerMessagingEvent
do
	ServerMessagingEvent = setmetatable({}, {
		__tostring = function()
			return "ServerMessagingEvent"
		end,
	})
	ServerMessagingEvent.__index = ServerMessagingEvent
	function ServerMessagingEvent.new(...)
		local self = setmetatable({}, ServerMessagingEvent)
		return self:constructor(...) or self
	end
	function ServerMessagingEvent:constructor(name)
		self.instance = ServerEvent.new(getGlobalRemote(name))
		self.event = MessagingEvent.new(name)
		local _arg0 = not IS_CLIENT
		assert(_arg0, "Cannot create a Net.GlobalServerEvent on the Client!")
		self.eventHandler = self.event:Connect(function(message)
			if isTargetedSubscriptionMessage(message) then
				self:recievedMessage(message.Data)
			else
				warn("[rbx-net] Recieved malformed message for ServerGameEvent: " .. name)
			end
		end)
	end
	function ServerMessagingEvent:getPlayersMatchingId(matching)
		if type(matching) == "number" then
			return Players:GetPlayerByUserId(matching)
		else
			local players = {}
			for _, id in ipairs(matching) do
				local player = Players:GetPlayerByUserId(id)
				if player then
					-- ▼ Array.push ▼
					players[#players + 1] = player
					-- ▲ Array.push ▲
				end
			end
			return players
		end
	end
	function ServerMessagingEvent:recievedMessage(message)
		if message.TargetIds then
			local players = self:getPlayersMatchingId(message.TargetIds)
			if players then
				self.instance:SendToPlayers(players, unpack(message.InnerData))
			end
		elseif message.TargetId ~= nil then
			local player = self:getPlayersMatchingId(message.TargetId)
			if player then
				self.instance:SendToPlayer(player, unpack(message.InnerData))
			end
		else
			self.instance:SendToAllPlayers(unpack(message.InnerData))
		end
	end
	function ServerMessagingEvent:Disconnect()
		self.eventHandler:Disconnect()
	end
	function ServerMessagingEvent:SendToAllServers(...)
		local args = { ... }
		local _fn = self.event
		local _ptr = {}
		local _left = "data"
		local _ptr_1 = {}
		local _length = #_ptr_1
		table.move(args, 1, #args, _length + 1, _ptr_1)
		_ptr[_left] = _ptr_1
		_fn:SendToAllServers(_ptr)
	end
	function ServerMessagingEvent:SendToServer(jobId, ...)
		local args = { ... }
		local _fn = self.event
		local _ptr = {}
		local _left = "data"
		local _ptr_1 = {}
		local _length = #_ptr_1
		table.move(args, 1, #args, _length + 1, _ptr_1)
		_ptr[_left] = _ptr_1
		_fn:SendToServer(jobId, _ptr)
	end
	function ServerMessagingEvent:SendToPlayer(userId, ...)
		local args = { ... }
		local player = Players:GetPlayerByUserId(userId)
		-- If the player exists in this instance, just send it straight to them.
		if player then
			self.instance:SendToPlayer(player, unpack(args))
		else
			local _fn = self.event
			local _ptr = {}
			local _left = "data"
			local _ptr_1 = {}
			local _length = #_ptr_1
			table.move(args, 1, #args, _length + 1, _ptr_1)
			_ptr[_left] = _ptr_1
			_ptr.targetId = userId
			_fn:SendToAllServers(_ptr)
		end
	end
	function ServerMessagingEvent:SendToPlayers(userIds, ...)
		local args = { ... }
		-- Check to see if any of these users are in this server first, and handle accordingly.
		for _, targetId in ipairs(userIds) do
			local player = Players:GetPlayerByUserId(targetId)
			if player then
				self.instance:SendToPlayer(player, unpack(args))
				table.remove(userIds, targetId + 1)
			end
		end
		if #userIds > 0 then
			local _fn = self.event
			local _ptr = {}
			local _left = "data"
			local _ptr_1 = {}
			local _length = #_ptr_1
			table.move(args, 1, #args, _length + 1, _ptr_1)
			_ptr[_left] = _ptr_1
			_ptr.targetIds = userIds
			_fn:SendToAllServers(_ptr)
		end
	end
end
return {
	default = ServerMessagingEvent,
}
