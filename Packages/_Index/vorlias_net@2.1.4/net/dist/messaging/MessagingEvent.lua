-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local _internal = TS.import(script, script.Parent.Parent, "internal")
local isLuaTable = _internal.isLuaTable
local ServerTickFunctions = _internal.ServerTickFunctions
-- const MessagingService = game.GetService("MessagingService");
local MessagingService = TS.import(script, script.Parent, "MessagingService")
local Players = game:GetService("Players")
local IS_STUDIO = game:GetService("RunService"):IsStudio()
--[[
	*
	* Checks if a value matches that of a subscription message
	* @param value The value
]]
local function isSubscriptionMessage(value)
	if isLuaTable(value) then
		local hasData = value.Data ~= nil
		return hasData
	else
		return false
	end
end
local function isJobTargetMessage(value)
	if isSubscriptionMessage(value) then
		if isLuaTable(value.Data) then
			return value.Data.jobId ~= nil
		end
	end
	return false
end
local globalMessageQueue = {}
local lastQueueTick = 0
local globalEventMessageCounter = 0
local globalSubscriptionCounter = 0
local MessagingEvent
local function processMessageQueue()
	if tick() >= lastQueueTick + 60 then
		globalEventMessageCounter = 0
		globalSubscriptionCounter = 0
		lastQueueTick = tick()
		while #globalMessageQueue > 0 do
			-- ▼ Array.pop ▼
			local _length = #globalMessageQueue
			local _result = globalMessageQueue[_length]
			globalMessageQueue[_length] = nil
			-- ▲ Array.pop ▲
			local message = _result
			MessagingService:PublishAsync(message.Name, message.Data)
			globalEventMessageCounter += 1
		end
		if globalEventMessageCounter >= MessagingEvent:GetMessageLimit() then
			warn("[rbx-net] Too many messages are being sent, any further messages will be queued!")
		end
	end
end
--[[
	*
	* Message Size: 1kB
	* MessagesPerMin: 150 + 60 * NUMPLAYERS
	* MessagesPerTopicMin: 30M
	* MessagesPerUniversePerMin: 30M
	* SubsPerServer: 5 + 2 * numPlayers
	* SubsPerUniverse: 10K
]]
--[[
	*
	* An event that works across all servers
	* @see https://developer.roblox.com/api-reference/class/MessagingService for limits, etc.
]]
do
	MessagingEvent = setmetatable({}, {
		__tostring = function()
			return "MessagingEvent"
		end,
	})
	MessagingEvent.__index = MessagingEvent
	function MessagingEvent.new(...)
		local self = setmetatable({}, MessagingEvent)
		return self:constructor(...) or self
	end
	function MessagingEvent:constructor(name)
		self.name = name
	end
	function MessagingEvent:GetMessageLimit()
		return 150 + 60 * #Players:GetPlayers()
	end
	function MessagingEvent:GetSubscriptionLimit()
		return 5 + 2 * #Players:GetPlayers()
	end
	function MessagingEvent:sendToAllServersOrQueue(data)
		local limit = MessagingEvent:GetMessageLimit()
		if globalEventMessageCounter >= limit then
			warn("[rbx-net] Exceeded message limit of " .. tostring(limit) .. ", adding to queue...")
			local _arg0 = {
				Name = self.name,
				Data = data,
			}
			-- ▼ Array.push ▼
			globalMessageQueue[#globalMessageQueue + 1] = _arg0
			-- ▲ Array.push ▲
		else
			globalEventMessageCounter += 1
			-- Since this yields
			MessagingService:PublishAsync(self.name, data)
		end
	end
	function MessagingEvent:SendToServer(jobId, message)
		self:sendToAllServersOrQueue({
			jobId = jobId,
			message = message,
		})
	end
	function MessagingEvent:SendToAllServers(message)
		self:sendToAllServersOrQueue(message)
	end
	function MessagingEvent:Connect(handler)
		local limit = MessagingEvent:GetSubscriptionLimit()
		if globalSubscriptionCounter >= limit then
			error("[rbx-net] Exceeded Subscription limit of " .. tostring(limit) .. "!")
		end
		globalSubscriptionCounter += 1
		return MessagingService:SubscribeAsync(self.name, function(data, sent)
			local recieved = {
				Data = data,
				Sent = sent,
			}
			local _binding = recieved
			local Sent = _binding.Sent
			if isJobTargetMessage(recieved) then
				local _binding_1 = recieved
				local Data = _binding_1.Data
				if game.JobId == Data.JobId then
					handler(Data.InnerData, Sent)
				end
			else
				handler(recieved.Data, Sent)
			end
		end)
	end
end
-- ▼ Array.push ▼
ServerTickFunctions[#ServerTickFunctions + 1] = processMessageQueue
-- ▲ Array.push ▲
return {
	isSubscriptionMessage = isSubscriptionMessage,
	default = MessagingEvent,
}
