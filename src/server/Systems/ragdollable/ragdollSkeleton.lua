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
    for id, ragdollableCR in world:queryChanged(Components.Ragdollable) do
        if not ragdollableCR.new then continue end
        local characterC = world:get(id, Components.Character)
        if not characterC then continue end
        local instanceC = world:get(id, Components.Instance)
        if not instanceC then continue end
        local skeletonC = world:get(id, Components.Skeleton)
        if not skeletonC then continue end
        checkRagdoll(ragdollableCR.new, instanceC, skeletonC)
    end
    for id, instanceCR in world:queryChanged(Components.Instance) do
        if not instanceCR.new then continue end
        local ragdollableC = world:get(id, Components.Ragdollable)
        if not ragdollableC then continue end
        local characterC = world:get(id, Components.Character)
        if not characterC then continue end
        local skeletonC = world:get(id, Components.Skeleton)
        if not skeletonC then continue end
        checkRagdoll(ragdollableC, instanceCR.new, skeletonC)
    end
    for id, skeletonCR in world:queryChanged(Components.Skeleton) do
        if not skeletonCR.new then continue end
        local ragdollableC = world:get(id, Components.Ragdollable)
        if not ragdollableC then continue end
        local characterC = world:get(id, Components.Character)
        if not characterC then continue end
        local instanceC = world:get(id, Components.Instance)
        if not instanceC then continue end
        checkRagdoll(ragdollableC, instanceC, skeletonCR.new)
    end
end