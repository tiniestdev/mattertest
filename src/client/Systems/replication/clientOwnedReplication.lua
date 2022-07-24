local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

-- Accumulates for every replicatable entity.
local checkComponents = {}
local replicatableEntities = {}
-- Accumulated, then gets dumped after it sent to the server.
local entityToComponentsMap = {}
local invokeReplicate = false

local system = function(world)
    -- Entities that are replicated are decided ona  per frame basis
    local entitiesToReplicate = {}
    local entitiesToDefer = {}
    local switchToServerOwned = {}
    local componentsToRemove = {}

    -- Add to the *total possible* entities that can replicate
    -- The actual list of entities that will ACTUALLY be replicated is made below this
    local encounteredArchetypes = {}
    local removedArchetypes = {}
    for id, coCR in world:queryChanged(Components.ClientOwned) do
        if world:contains(id) and coCR.new and coCR.new.archetypes then
            replicatableEntities[id] = coCR.new
            entitiesToReplicate[id] = coCR.new
            -- print("ADDED ", id, " TO REPLICATABLE ENTITIES")
            for archetypeName, _ in pairs(coCR.new.archetypes) do
                if encounteredArchetypes[archetypeName] then continue end
                encounteredArchetypes[archetypeName] = true
                local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
                for componentName, _ in pairs(componentSet) do
                    checkComponents[componentName] = true
                end
            end
        else
            if not coCR.new and world:contains(id) then
                local replicatedC = world:get(id, Components.Replicated)
                local serverId = replicatedC.serverId
                if serverId then
                    table.insert(switchToServerOwned, serverId)
                end
            end
            replicatableEntities[id] = nil
            if coCR.old and coCR.old.archetypes then
                for archetypeName, _ in pairs(coCR.old.archetypes) do
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

    -- These entities no longer have a ClientOwned component. Immediately replicate whatever the server's info has
    -- if #switchToServerOwned > 0 then
    --     print("Replicating " .. #switchToServerOwned .. " entities that were switched to server owned", switchToServerOwned)
    --     Remotes.Client:Get("RequestReplicateEntities"):SendToServer(switchToServerOwned)
    -- end

    -- To prevent constantly replicating every single entity ever, we attempt to only get those
    -- entities that have *changed*
    -- Keep track of the components we encounter to prepare for removing unused components
    for componentName, _ in pairs(checkComponents) do
        for id, CR in world:queryChanged(Components[componentName]) do
            if not CR.new then continue end
            if entitiesToReplicate[id] then continue end
            local coC = world:get(id, Components.ClientOwned)
            if not coC then continue end
            if not coC.archetypes then continue end

            -- TODO (please figure this out)
            -- if coC.replicationRate then
            --     if not Matter.useThrottle(1/coC.replicationRate) then
            --     end
            -- end
            -- print("Replicating " .. id .. " because of " .. componentName)
            entitiesToReplicate[id] = coC
        end
    end

    -- Actual replication of all entities inside entitiesToReplicate
    -- if the server wants to erase a field, it must be specified in ComponentInfos
    -- since it will typically ignore Matter.None s while merging via patch
    local resetFlagsForIds = {}
    for id, coC in pairs(entitiesToReplicate) do
        local repC = world:get(id, Components.Replicated)
        if not repC then continue end
        local serverId = repC.serverId
        if not serverId then continue end

        if coC.disabled then
            if coC.replicateFlag then
                table.insert(resetFlagsForIds, id)
            else
                continue
            end
        end
        local componentMap = {}
        for archetype, _ in pairs(coC.archetypes) do
            local componentSet = matterUtil.getComponentSetFromArchetype(archetype)
            for componentName, _ in pairs(componentSet) do
                if componentMap[componentName] then continue end
                local componentData = world:get(id, Components[componentName])
                
                -- we have to remap any possible reference field to server ids
                local remappedData = {}
                
                for i, refPropName in ipairs(matterUtil.getReferencePropertiesOfComponent(componentName, componentData)) do
                    if componentData[refPropName] then
                        remappedData[refPropName] = replicationUtil.recipientIdToSenderId(componentData[refPropName])
                        -- print("Remapped ID of ", refPropName, componentData[refPropName], " to ", remappedData[refPropName])
                    end
                end
                for i, refSetPropName in ipairs(matterUtil.getReferenceSetPropertiesOfComponent(componentName, componentData)) do
                    local newRefSet = {}
                    if componentData[refSetPropName] then
                        for refId, _ in pairs(componentData[refSetPropName]) do
                            newRefSet[replicationUtil.recipientIdToSenderId(refId)] = true
                            -- print("Remapped ID of ", refSetPropName, refId, " to ", replicationUtil.recipientIdToSenderId(refId))
                        end
                    end
                    remappedData[refSetPropName] = newRefSet
                end
                componentMap[componentName] = Llama.Dictionary.merge(componentData, remappedData)
            end
        end

        entityToComponentsMap[tostring(serverId)] = componentMap
        invokeReplicate = true
        -- print("client replicating ", id, " to ", serverId)
    end

    -- actually replicate
    if invokeReplicate then
        if Matter.useThrottle(1/20) then
            Remotes.Client:Get("ReplicateClientOwnedEntityStates"):CallServerAsync(entityToComponentsMap):andThen(function(response)
                local success = response[1]
                local correctDataMap = response[2]
                -- print("got success", success, "correctDataMap", correctDataMap)
                if not success then
                    -- warn("replication failed, correcting")
                    for serverId, componentMap in pairs(correctDataMap) do
                        local clientId = replicationUtil.senderIdToRecipientId(serverId)
                        if not world:contains(clientId) then warn("client id not found", clientId) continue end
                        for componentName, componentData in pairs(componentMap) do
                            world:insert(clientId, Components[componentName](componentData))
                            -- print("corrected ", clientId, " with ", componentName, ":", componentData)
                        end
                    end
                end
            end)
        else
            -- print("Didn not replicate yet")
        end
        entityToComponentsMap = {}
    end

    for _, id in ipairs(resetFlagsForIds) do
        local coC = world:get(id, Components.ClientOwned)
        if not coC then continue end
        world:insert(id, coC:patch({
            replicateFlag = false,
        }))
    end

    -- checkComponents is the accumulation of all previously replicated components.
    -- so if none of those components are found after replicating every single replicatable entity, we remove em
    -- If any valid replicating archetypes include a component inside componentsToRemove, sift them out
    local encounteredArchetypes = {}
    for componentName, _ in pairs(componentsToRemove) do
        -- we'd loop over every single replicatable entity, gather all their components, and check
        for entityId, coC in pairs(replicatableEntities) do
            for archetypeName, _ in pairs(coC.archetypes) do
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