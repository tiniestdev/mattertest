local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)

local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local Archetypes = require(ReplicatedStorage.Archetypes)

local RequestReplicateEntities = matterUtil.NetSignalToEvent("RequestReplicateEntities", Remotes)

local function getArchetypesToReplicate(dis)
    local storage = Matter.useHookState(dis)
    return storage
end

local encountered = {}
local recordedChange = {}
local entitiesToReplicate = {}
local entityIdToIndex = {}

local system = function(world)
    local removedReplicatedIds = {}
    local archetypesToReplicate = getArchetypesToReplicate()

    if not archetypesToReplicate.init then
        archetypesToReplicate.init = true
        archetypesToReplicate.archetypes = {}
        for i, v in pairs(Archetypes.Catalog) do
            table.insert(archetypesToReplicate.archetypes, i)
        end
    end

    for i, player, listOfEntityIds in Matter.useEvent(RequestReplicateEntities, "Event") do
        -- print("GOT REQUEST FROM PLAYER TO REPLICATE ENTITIES", player, listOfEntityIds)
        for _, entityId in ipairs(listOfEntityIds) do
            if not world:contains(entityId) then continue end
            local rtcC = world:get(entityId, Components.ReplicateToClient)
            if rtcC then
                for _, archetypeName in ipairs(rtcC.archetypes) do
                    replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
                    -- print("RR EVENT: replicated entity " .. entityId .. " to archetype " .. archetypeName)
                end
            end
        end
    end

    -- force replicate entities that a client is currently missing
    -- Automatically replicates changes in an entity's archetypes
    -- like if it wanted to take on a different archetype
    local allComponentsSet = {}
    for id, rtcCR in world:queryChanged(Components.ReplicateToClient) do
        if rtcCR.new then
            if rtcCR.new.archetypes == nil then
                continue
            end
            -- entitiesToReplicate[id] = rtcCR.new.archetypes

            for _, archetypeName in ipairs(rtcCR.new.archetypes) do
                if not table.find(archetypesToReplicate.archetypes, archetypeName) then
                    table.insert(archetypesToReplicate.archetypes, archetypeName)
                end
            end
        else
            table.insert(removedReplicatedIds, id)
        end
    end

    for id, archetypeList in ipairs(entitiesToReplicate) do
        
    end

    for i, archetypeName in ipairs(archetypesToReplicate.archetypes) do
        local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
        for componentName, v in pairs(componentSet) do
            allComponentsSet[componentName] = true
        end
    end

    local changedEntitiesToChangeRecords = {}
    local changedEntitiesToChangedArchetypes = {}
    local function recordChangedEntity(id, componentName, CR, validArchetypesList)
        if not validArchetypesList then return end
        if not changedEntitiesToChangeRecords[id] then changedEntitiesToChangeRecords[id] = {} end
        if not changedEntitiesToChangedArchetypes[id] then changedEntitiesToChangedArchetypes[id] = {} end
        changedEntitiesToChangeRecords[id][componentName] = CR
        local archetypesContainingComponent = matterUtil.getArchetypesContainingComponentOutOf(componentName, validArchetypesList)
        tableUtil.AppendUnique(changedEntitiesToChangedArchetypes[id], archetypesContainingComponent)
        print("entity id " .. id .. " changed archetypes: " .. table.concat(changedEntitiesToChangedArchetypes[id], ", "))
    end

    for componentName, v in pairs(allComponentsSet) do
        if recordedChange[componentName] then
            for id, CR in world:queryChanged(Components[componentName]) do
                local rtcC = world:get(id, Components.ReplicateToClient)
                if not rtcC then continue end
                if not matterUtil.isChangeRecordDiff(CR) then return end
                recordChangedEntity(id, componentName, CR, rtcC.archetypes)
            end
        else
            for id, component, rtcC in world:query(Components[componentName], Components.ReplicateToClient) do
                local CR = {
                    new = component,
                    old = nil,
                }
                recordChangedEntity(id, componentName, CR, rtcC.archetypes)
            end
            recordedChange[componentName] = true
        end
    end

    -- so i know we just got a list of components we changed but
    -- we should stick with working with archetypes for whatever reason idk WHATEVER
    matterUtil.replicateEntitiesWithChangedArchetypes(changedEntitiesToChangedArchetypes, world)

    -- some function here that manages every single archetype's changed event
    if #removedReplicatedIds > 0 then
        Remotes.Server:Create("DespawnedEntities"):SendToAllPlayers(removedReplicatedIds)
    end

end

return {
    system = system,
    priority = math.huge,
}