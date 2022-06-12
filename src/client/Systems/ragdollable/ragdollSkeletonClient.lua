local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)

local function shouldBeRagdolled(state)
    return state.downed or state.stunned or state.sleeping
end

local function checkRagdoll(ragdollableC, instanceC, skeletonC)
    if not instanceC then return end
    if not skeletonC then return end
    if not ragdollableC then
        -- ragdollable is being removed
        ragdollUtil.UnragdollCharacter(instanceC.instance, skeletonC.skeletonInstance)
    end
    if not instanceC.instance then return end
    if not skeletonC.skeletonInstance then return end

    if shouldBeRagdolled(ragdollableC) then
        ragdollUtil.Ragdoll(instanceC.instance, skeletonC.skeletonInstance)
    else
        ragdollUtil.Unragdoll(instanceC.instance, skeletonC.skeletonInstance)
    end
end

return function(world)
    for id, ragdollableCR, characterC, instanceC, skeletonC in world:queryChanged(Components.Ragdollable) do
        if not world:get(id, Components.Character) then continue end
        if not world:get(id, Components.Instance) then continue end
        if not world:get(id, Components.Skeleton) then continue end
        if not world:get(id, Components.Ours) then continue end
        checkRagdoll(ragdollableCR.new, instanceC, skeletonC)
    end
    for id, instanceCR, characterC, ragdollableC, skeletonC in world:queryChanged(Components.Instance) do
        if not world:get(id, Components.Character) then continue end
        if not world:get(id, Components.Ragdollable) then continue end
        if not world:get(id, Components.Skeleton) then continue end
        if not world:get(id, Components.Ours) then continue end
        checkRagdoll(ragdollableC, instanceCR.new, skeletonC)
    end
    for id, skeletonCR, ragdollableC, characterC, instanceC, skeletonC in world:queryChanged(Components.Skeleton) do
        if not world:get(id, Components.Ragdollable) then continue end
        if not world:get(id, Components.Character) then continue end
        if not world:get(id, Components.Instance) then continue end
        if not world:get(id, Components.Ours) then continue end
        checkRagdoll(ragdollableC, instanceC, skeletonCR.new)
    end
end