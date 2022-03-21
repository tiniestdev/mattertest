local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local Remotes = require(ReplicatedStorage.Remotes)

--local StorageUpdateEvent = MatterUtil.NetSignalToEvent("ReplicateStorage", Remotes)

return function(world)
    -- for i, payload in Matter.useEvent(StorageUpdateEvent, "Event") do
    --     print("got payload from server", payload)
    --     print("REMOTES:", Remotes)
    --     --replicationUtil.deserializeStorage(payload, world)
    --     print("done deserializing")
    -- end
end
