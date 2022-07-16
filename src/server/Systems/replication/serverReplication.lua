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

local getArchetypesToReplicate = require(ReplicatedStorage.HookStates.foo)

local checkComponents = {}

local system = function(world)
    local entitiesToReplicate = {}
    local entitiesToDespawn = {}
    local archetypesToReplicate = getArchetypesToReplicate()

    if not archetypesToReplicate.init then
        archetypesToReplicate.init = true
        archetypesToReplicate.archetypes = {}
        for i, v in pairs(Archetypes.Catalog) do
            table.insert(archetypesToReplicate.archetypes, i)
        end
    end

    -- For players manually requesting entities
    for i, player, listOfEntityIds in Matter.useEvent(RequestReplicateEntities, "Event") do
        for _, entityId in ipairs(listOfEntityIds) do
            if not world:contains(entityId) then
                table.insert(entitiesToDespawn, entityId)
            end
            local rtcC = world:get(entityId, Components.ReplicateToClient)
            if rtcC then
                for _, archetypeName in ipairs(rtcC.archetypes) do
                    replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
                end
            end
        end
    end

    -- Add to the *total possible* entities that can replicate
    -- The actual list of entities that will ACTUALLY be replicated is made below this
    for id, rtcCR in world:queryChanged(Components.ReplicateToClient) do
        if rtcCR.new then
            if rtcCR.new.archetypes == nil then
                continue
            end
            if not rtcCR.old then
                -- brand new entity. be sure to replicate it all
                entitiesToReplicate[id] = rtcCR.new
            end

            -- add any kind of new commponents to checkComponents
            -- so we can call queryChanged on them later
            for _, archetypeName in ipairs(rtcCR.new.archetypes) do
                local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
                for componentName, _ in pairs(componentSet) do
                    checkComponents[componentName] = true
                end
            end
        else
            if not world:contains(id) then
                table.insert(entitiesToDespawn, id)
            end
            if rtcCR.old and rtcCR.old.archetypes then
                for _, archetypeName in ipairs(rtcCR.old.archetypes) do
                    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
                    for componentName, _ in pairs(componentSet) do
                        checkComponents[componentName] = nil
                    end
                end
            end
        end
    end

    -- To prevent constantly replicating every single entity ever, we attempt to only get those
    -- entities that have *changed*
    for componentName, _ in pairs(checkComponents) do
        for id, CR in world:queryChanged(Components[componentName]) do
            if not CR.new then continue end
            if entitiesToReplicate[id] then continue end
            local rtcC = world:get(id, Components.ReplicateToClient)
            if not rtcC then continue end
            entitiesToReplicate[id] = rtcC
            -- print("entity " .. id .. " has changed " .. componentName)
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
        for _, archetypeName in ipairs(rtcC.archetypes) do
            local playersToReplicateTo = playerUtil.getFilteredPlayerSet(rtcC.whitelist, rtcC.blacklist)
            for player, _ in pairs(playersToReplicateTo) do
                replicationUtil.replicateServerEntityArchetypeTo(player, id, archetypeName, world)
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

    if #entitiesToDespawn > 0 then
        Remotes.Server:Create("DespawnedEntities"):SendToAllPlayers(entitiesToDespawn)
    end
end

return {
    system = system,
    priority = math.huge,
}