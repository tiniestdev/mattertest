local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)

return function(world)
    -- for every new skeleton added to an entity, call ragdollUtil.initSkeleton()  on it
    for id, skeletonCR, characterC, instanceC in world:queryChanged(Components.Skeleton, Components.Character, Components.Instance) do
        if not skeletonCR.old then
            local newSkeleton = ragdollUtil.initSkeleton(instanceC.instance)
            world:insert(id, skeletonCR.new:patch({
                skeletonInstance = newSkeleton,
            }))
            print("fit skeleton", id)
        end
    end
end