local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)

return function(world)
    for id, networkOwnedCR, instanceC in world:queryChanged(Components.NetworkOwned, Components.Instance) do
        if networkOwnedCR.new and instanceC.instance then
            physicsUtil.DeepSetNetworkOwner(instanceC.instance, networkOwnedCR.new.networkOwner)
        end
    end
    for id, networkOwnedCR, skeletonC in world:queryChanged(Components.NetworkOwned, Components.Skeleton) do
        if networkOwnedCR.new and skeletonC.skeletonInstance then
            physicsUtil.DeepSetNetworkOwner(skeletonC.skeletonInstance, networkOwnedCR.new.networkOwner)
        end
    end
end