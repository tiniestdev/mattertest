local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local Remotes = require(ReplicatedStorage.Remotes)
local ReplicateStorage = MatterUtil.NetSignalToEvent("ReplicateStorage", Remotes)

return function(world)
    for i, payload in Matter.useEvent(ReplicateStorage, "Event") do
        local clientId = replicationUtil.deserializeArchetype("Storage", payload, world)
    end
end