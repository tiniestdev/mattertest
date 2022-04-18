local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)

return function(world)
    for id, skeletonCR, networkOwnedC in world:queryChanged(Components.Skeleton, Components.NetworkOwned) do
        if skeletonCR.new then
            -- new skeleton, add it
            world:insert(id, networkOwnedC:patch({
                instances = Llama.Set.add(networkOwnedC.instances, unpack(physicsUtil.GetParts(skeletonCR.new.skeletonInstance)))
            }))
            print("# ADDED", skeletonCR.new.skeletonInstance, #physicsUtil.GetParts(skeletonCR.new.skeletonInstance))
            print(world:get(id, Components.NetworkOwned).instances)
        else
            -- remove from networkowned list
            world:insert(id, networkOwnedC:patch({
                instances = Llama.Set.subtract(networkOwnedC.instances, unpack(physicsUtil.GetParts(skeletonCR.old.skeletonInstance)))
            }))
            print("# REMOVED")
            print(world:get(id, Components.NetworkOwned).instances)
        end
    end
    for id, networkOwnedCR, skeletonC in world:queryChanged(Components.NetworkOwned, Components.Skeleton) do
        if not networkOwnedCR.old then
            -- new, add it
            world:insert(id, networkOwnedCR.new:patch({
                instances = Llama.Set.add(networkOwnedCR.new.instances, unpack(physicsUtil.GetParts(skeletonC.skeletonInstance)))
            }))
            print("# ADDED NETWONED")
            print(world:get(id, Components.NetworkOwned).instances)
        end
        if not networkOwnedCR.new then
            -- do nothing
        end
    end
end