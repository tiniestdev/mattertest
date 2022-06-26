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

local function checkRagdoll(id, world)
    if not world:get(id, Components.Character) then return end
    local instanceC = world:get(id, Components.Instance)
    -- if not instanceC then return end
    if not instanceC.instance then return end
    local skeletonC = world:get(id, Components.Skeleton)
    -- if not skeletonC then return end
    if not skeletonC.skeletonInstance then return end
    local ragdollableC = world:get(id, Components.Ragdollable)

    if not ragdollableC then
        -- ragdollable is being removed
        ragdollUtil.UnragdollCharacter(instanceC.instance, skeletonC.skeletonInstance)
    end

    if shouldBeRagdolled(ragdollableC) then
        ragdollUtil.Ragdoll(instanceC.instance, skeletonC.skeletonInstance)
    else
        ragdollUtil.Unragdoll(instanceC.instance, skeletonC.skeletonInstance)
    end
end

return function(world)
    for id, CRs in matterUtil.getChangedEntitiesOfArchetype("RagdollableArchetype", world) do
        checkRagdoll(id, world)
    end
end