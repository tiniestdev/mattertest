local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)

local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local Archetypes = require(ReplicatedStorage.Archetypes)

local RequestReplicateEntities = matterUtil.NetSignalToEvent("RequestReplicateEntities", Remotes)

-- Accumulates for every replicatable entity.
local checkComponents = {}
local replicatableEntities = {}

local system = function(world)
    -- Entities that are replicated are decided ona  per frame basis
    local entitiesToReplicate = {}
    local entitiesToDespawn = {}
    local componentsToRemove = {}

    -- For players manually requesting entities
    for i, player, listOfEntityIds in Matter.useEvent(RequestReplicateEntities, "Event") do
        for _, entityId in ipairs(listOfEntityIds) do
            if not world:contains(entityId) then
                table.insert(entitiesToDespawn, entityId)
                continue
            end
            local rtcC = world:get(entityId, Components.ReplicateToClient)
            if rtcC then
                for archetypeName, _ in pairs(rtcC.archetypes) do
                    replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
                end
            end
        end
    end

    -- Add to the *total possible* entities that can replicate
    -- The actual list of entities that will ACTUALLY be replicated is made below this
    local encounteredArchetypes = {}
    local removedArchetypes = {}
    for id, rtcCR in world:queryChanged(Components.ReplicateToClient) do
        if world:contains(id) and rtcCR.new then
            replicatableEntities[id] = rtcCR.new
            entitiesToReplicate[id] = rtcCR.new
            for archetypeName, _ in pairs(rtcCR.new.archetypes) do
                if encounteredArchetypes[archetypeName] then continue end
                encounteredArchetypes[archetypeName] = true
                local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
                -- print("COMPONENT SET ", componentSet, "OF ARCHETYPE ", archetypeName, " FOR ", id)
                for componentName, _ in pairs(componentSet) do
                    checkComponents[componentName] = true
                end
            end
        else
            table.insert(entitiesToDespawn, id)
            replicatableEntities[id] = nil
            if rtcCR.old then
                for archetypeName, _ in pairs(rtcCR.old.archetypes) do
                    if removedArchetypes[archetypeName] then continue end
                    removedArchetypes[archetypeName] = true
                    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
                    for componentName, _ in pairs(componentSet) do
                        componentsToRemove[componentName] = true
                    end
                end
            end
        end
    end

    -- To prevent constantly replicating every single entity ever, we attempt to only get those
    -- entities that have *changed*
    -- Keep track of the components we encounter to prepare for removing unused components
    -- print("CHECK COMPONENTS:", checkComponents)
    for componentName, _ in pairs(checkComponents) do
        for id, CR in world:queryChanged(Components[componentName]) do
            if not CR.new then continue end
            if entitiesToReplicate[id] then continue end
            local rtcC = world:get(id, Components.ReplicateToClient)
            if not rtcC then continue end
            entitiesToReplicate[id] = rtcC
        end
    end

    -- Actual replication of all entities inside entitiesToReplicate
    -- if the server wants to erase a field, it must be specified in ComponentInfos
    -- since it will typically ignore Matter.None s while merging via patch
    local resetFlagsForIds = {}
    for id, rtcC in pairs(entitiesToReplicate) do
        if rtcC.disabled then
            if rtcC.replicateFlag then
                table.insert(resetFlagsForIds, id)
            else
                continue
            end
        end
        for archetypeName, _ in pairs(rtcC.archetypes) do
            local playersToReplicateTo = playerUtil.getFilteredPlayerSet(rtcC.whitelist, rtcC.blacklist)
            for player, _ in pairs(playersToReplicateTo) do
                replicationUtil.replicateServerEntityArchetypeTo(player, id, archetypeName, world)
                -- print("Replicating " .. id)
            end
        end
    end

    for _, id in ipairs(resetFlagsForIds) do
        local rtcC = world:get(id, Components.ReplicateToClient)
        if not rtcC then continue end
        world:insert(id, rtcC:patch({
            replicateFlag = false,
        }))
    end

    -- checkComponents is the accumulation of all previously replicated components.
    -- so if none of those components are found after replicating every single replicatable entity, we remove em
    if #entitiesToDespawn > 0 then
        Remotes.Server:Create("DespawnedEntities"):SendToAllPlayers(entitiesToDespawn)
    end
    -- If any valid replicating archetypes include a component inside componentsToRemove, sift them out
    local encounteredArchetypes = {}
    for componentName, _ in pairs(componentsToRemove) do
        -- we'd loop over every single replicatable entity, gather all their components, and check
        for entityId, rtcC in pairs(replicatableEntities) do
            for archetypeName, _ in pairs(rtcC.archetypes) do
                if encounteredArchetypes[archetypeName] then continue end
                encounteredArchetypes[archetypeName] = true
                local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
                for foundComponentName, _ in pairs(componentSet) do
                    componentsToRemove[foundComponentName] = nil
                end
            end
        end
    end
    -- by this point the component names left in the list are ACTUALLY never to be used ever again, so
    -- we can remove them from checkComponents
    for componentName, _ in pairs(componentsToRemove) do
        checkComponents[componentName] = nil
    end
end

return {
    system = system,
    priority = math.huge,
}