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
    for id, skeletonCR in world:queryChanged(Components.Skeleton) do
        local networkOwnedC = world:get(id, Components.NetworkOwned)
        if not networkOwnedC then continue end
        if skeletonCR.new then
            -- new skeleton, add it
            world:insert(id, networkOwnedC:patch({
                instances = Llama.Set.add(networkOwnedC.instances, unpack(physicsUtil.GetParts(skeletonCR.new.skeletonInstance)))
            }))
            -- print("# ADDED", skeletonCR.new.skeletonInstance, #physicsUtil.GetParts(skeletonCR.new.skeletonInstance))
            -- print(world:get(id, Components.NetworkOwned).instances)
        else
            -- remove from networkowned list
            world:insert(id, networkOwnedC:patch({
                instances = Llama.Set.subtract(networkOwnedC.instances, unpack(physicsUtil.GetParts(skeletonCR.old.skeletonInstance)))
            }))
            -- print("# REMOVED")
            -- print(world:get(id, Components.NetworkOwned).instances)
        end
    end
    for id, networkOwnedCR in world:queryChanged(Components.NetworkOwned) do
        local skeletonC = world:get(id, Components.Skeleton)
        if not skeletonC then continue end
        if not networkOwnedCR.old then
            -- new, add it
            world:insert(id, networkOwnedCR.new:patch({
                instances = Llama.Set.add(networkOwnedCR.new.instances, unpack(physicsUtil.GetParts(skeletonC.skeletonInstance)))
            }))
            -- print("# ADDED NETWONED")
            -- print(world:get(id, Components.NetworkOwned).instances)
        end
        if not networkOwnedCR.new then
            -- do nothing
        end
    end
end