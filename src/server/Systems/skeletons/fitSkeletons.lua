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
    for id, skeletonCR in world:queryChanged(Components.Skeleton) do
        if skeletonCR.new then

            local characterC = world:get(id, Components.Character)
            if not characterC then continue end
            local instanceC = world:get(id, Components.Instance)
            if not instanceC then continue end

            if not skeletonCR.old then
                local newSkeleton = ragdollUtil.initSkeleton(instanceC.instance)
                world:insert(id, skeletonCR.new:patch({
                    skeletonInstance = newSkeleton,
                }))
                task.delay(0.5, function()
                    local player = matterUtil.getPlayerFromCharacterEntity(id, world)
                    if player then
                        for _,v in ipairs(newSkeleton:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v:SetNetworkOwner(player)
                            end
                        end
                    end
                end)
            end

        end
    end
end