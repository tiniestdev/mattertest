local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = require(script.Parent.MatterStart)
local TaggedStart = {}

TaggedStart.AxisName = "TaggedStartAxis"
local RDM = Random.new()

local tagToTask = {
    Grabbable = function(instance, world)
        return world:spawn(
            Components.Instance({
                instance = instance,
            }),
            Components.Grabbable({
                grabbableInstance = instance,
            }),
            Components.ReplicateToClient({
                archetypes = {"GrabbableArchetype"}
            }),
            Components.NetworkOwned({
                instances = instance,
            })
        )
    end,
}

function TaggedStart:AxisPrepare()
end

function TaggedStart:AxisStarted()
    local world = MatterStart.World

    for tagName, func in pairs(tagToTask) do
        for i, instance in ipairs(CollectionService:GetTagged(tagName)) do
            matterUtil.setEntityId(instance, func(instance, world))
        end
        CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
            matterUtil.setEntityId(instance, func(instance, world))
        end)
    end
end

return TaggedStart