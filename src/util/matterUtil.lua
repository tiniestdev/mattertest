local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Components = require(ReplicatedStorage.components)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Archetypes = require(ReplicatedStorage.Archetypes)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)

local Set = Llama.Set

local matterUtil = {}

matterUtil.instanceToComponentData = {
    BasePart = {
        Physics = function(part)
            return {
                velocity = part.AssemblyLinearVelocity,
                angularVelocity = part.AssemblyAngularVelocity,
                mass = part.AssemblyMass,
                density = part.CustomPhysicalProperties.Density,
                friction = part.CustomPhysicalProperties.Friction,
                restitution = part.CustomPhysicalProperties.Elasticity,
            }
        end,
        Transform = function(part)
            return {
                cframe = part.CFrame,
                size = part.Size,
            }
        end,
    },
    Attachment = {
        Physics = {

        },
        Transform = function(att)
            return {
                cframe = att.WorldCFrame,
            }
        end,
    }
}

function matterUtil.getProcedures(instance, overrides)
    for className, procedures in pairs(overrides) do
        if instance:IsA(className) then
            return procedures
        end
    end
    error("No procedures for " .. instance.ClassName)
end

function matterUtil.getInstanceComponentData(instance, componentName)
    -- find the correct key using IsA()
    for key, value in pairs(matterUtil.instanceToComponentData) do
        if instance:IsA(key) then
            return value[componentName](instance)
        end
    end
    return nil
end

function matterUtil.getEntityId(instance)
    return RunService:IsServer() and instance:GetAttribute("entityServerId") or instance:GetAttribute("entityClientId")
end

function matterUtil.setEntityId(instance, id)
    if RunService:IsServer() then
        instance:SetAttribute("entityServerId", id)
    else
        instance:SetAttribute("entityClientId", id)
    end
end

-- There will be instances that are bound to entities.
-- Even though entities are technically data-only and non corporeal,
-- they are often represented by a corporeal object (an instance in workspace).
-- If a client sees it, it will request it to be replicated.
function matterUtil.addInstanceReplicatedArchetype(instance, archetypeName)
    CollectionService:AddTag(instance, "AUTOREPLICATE_" .. archetypeName)
end

--[[
    Tags should never be directly synonymous with components.
    Instead, they should be programmatically handled to be assigned some entity with some archetype(s)
    more like how a tag "Zombie" can make a Character archetype that is configured differently from
    some tag "Human" that makes a Character archetype too.

    Tags should be handled individually by some provider, which will apply all the
    matter components and entities, and let the matter world handle things from there.
]]

-- function matterUtil.createComponentsTagged(componentName, world)
--     local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
--     for i, instance in ipairs(CollectionService:GetTagged(componentName)) do
--         -- does it already have an id?
--         local entityId = matterUtil.getEntityId(instance)
--         if entityId then
--             replicationUtil.insertOrUpdateComponent(entityId, componentName, {}, world)
--         else
--             -- create a new id
--             entityId = world:spawn(
--                 Components[componentName]({}),
--                 Components.Replicated({
--                     archetypes = {componentName},
--                 })
--             )
--             matterUtil.setEntityId(instance, entityId)
--         end
--         replicationUtil.replicateServerEntityArchetypeToAll(entityId, componentName, world)
--     end
-- end

function matterUtil.SignalToEvent(event)
    local newSignal = Instance.new("BindableEvent")
    event:Connect(function(...)
        newSignal:Fire(...)
    end)
    return newSignal
end

function matterUtil.NetSignalToEvent(signalName, remotes)
    local newSignal = Instance.new("BindableEvent")
    if RunService:IsServer() then
        remotes.Server:OnEvent(signalName, function(...)
            newSignal:Fire(...)
        end)
    else
        remotes.Client:WaitFor(signalName):andThen(function(fromServer)
            fromServer.instance.OnClientEvent:Connect(function(...)
                newSignal:Fire(...)
            end)
        end)
    end
    return newSignal
end

function matterUtil.ObservableToEvent(observable)
    local newSignal = Instance.new("BindableEvent")
    observable:Subscribe(function(...)
        newSignal:Fire(...)
    end)
    return newSignal
end

function matterUtil.cmdrPrintEntityDebugInfo(context, entityId, world)
    if world:contains(entityId) then
        context:Reply("EntityId " .. entityId .. ":")
        for componentName, _ in pairs(Components) do
            if world:get(entityId, Components[componentName]) then
                context:Reply("Is a " .. componentName .. ":")
                for componentField, fieldValue in pairs(world:get(entityId, Components[componentName])) do
                    if typeof(fieldValue) == "Instance" then
                        context:Reply("\t" .. fieldValue.ClassName .. " " .. componentField .. ": " .. fieldValue:GetFullName())
                    else
                        if typeof(fieldValue) == "table" then
                            for i,v in pairs(fieldValue) do
                                context:Reply("\t\t" .. tostring(i) .. " : " .. tostring(v))
                            end
                        else
                            context:Reply("\t" .. typeof(fieldValue) .. " " .. componentField .. ": " .. tostring(fieldValue))
                        end
                    end
                end
            end
        end
        return true
    else
        if RunService:IsServer() then
            return "EntityId " .. entityId .. " does not exist in the SERVER world."
        else
            return "EntityId " .. entityId .. " does not exist in the CLIENT world."
        end
    end
end

function matterUtil.getEntityViewerData(world)
    local entityDumps = {}

    for id, entityData in world do
        local entityDump = {
            entityId = id,
        }

        -- a table, every key = component name, every value = its data
        local componentDumps = {}
        
        -- list all archetypes it has on the header
        local headerTags = {}
        for archName, _ in pairs(Archetypes.Catalog) do
            if matterUtil.isArchetype(id, archName, world) then
                table.insert(headerTags, archName)
            end
        end

        -- print(entityData)
        for i, compInfo in pairs(entityData) do
            local compName = tostring(i)
            local comp = tableUtil.Copy(compInfo)
            for fieldName, fieldInfo in pairs(compInfo) do
                comp[fieldName] = comp[fieldName] or "*nil*"
            end
            componentDumps[compName] = comp
        end

        -- list all components it has
        -- for compName, compInfo in pairs(ComponentInfo.Catalog) do
        --     if not Components[compName] then continue end
        --     local comp = world:get(id, Components[compName])
        --     if comp then
        --         comp = tableUtil.Copy(comp)
        --         for fieldName, fieldInfo in pairs(compInfo) do
        --             comp[fieldName] = comp[fieldName] or "*nil*"
        --         end
        --         componentDumps[compName] = comp
        --     end
        -- end

        entityDump.componentDumps = componentDumps
        entityDump.headerTags = headerTags

        table.insert(entityDumps, entityDump)
    end

    return entityDumps
end

function matterUtil.getMissingComponentsOfArchetype(entityId, archetypeName, world)
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    local missing = {}
    for componentName, _ in pairs(componentSet) do
        if not world:get(entityId, Components[componentName]) then
            table.insert(missing, componentName)
        end
    end
    return missing
end

function matterUtil.isArchetype(entityId, archetypeName, world)
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    for componentName, _ in pairs(componentSet) do
        if not world:contains(entityId) then
            return false
        end
        if not world:get(entityId, Components[componentName]) then
            return false
        end
    end
    return true
end

function matterUtil.getChangedEntitiesOfArchetype(archetypeName, world)
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    local componentList = tableUtil.FlipNumeric(componentSet)
    local changedEntities = {}

    -- cycle through every single component that might have changed
    local changed = false
    for _, currentComponentName in ipairs(componentList) do
        for id, CR in world:queryChanged(Components[currentComponentName]) do
            if not matterUtil.isArchetype(id, archetypeName, world) then continue end
            if not changedEntities[id] then changedEntities[id] = {} end
            changedEntities[id][currentComponentName] = CR
            changed = true
        end
    end

    -- if changed then
    --     print("changedentityies: ", changedEntities)
    -- end
    return changedEntities
end

function matterUtil.replicateChangedArchetypes(archetypeName, world)
    local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

    local resetFlagsForIds = {}

    for id, crs in pairs(matterUtil.getChangedEntitiesOfArchetype(archetypeName, world)) do
        local rtcC = world:get(id, Components.ReplicateToClient)
        if not rtcC then continue end
        if rtcC.disabled then
            if rtcC.replicateFlag then
                --proceed normally
                table.insert(resetFlagsForIds, id)
            else
                continue
            end
        end
        
        local players = playerUtil.getSetOfPlayers()
        if rtcC.whitelist then
            players = rtcC.whitelist
        end
        if rtcC.blacklist then
            for player, v in pairs(rtcC.blacklist) do
                players[player] = nil
            end
        end
        if not (rtcC.whitelist or rtcC.blacklist) then
            replicationUtil.replicateServerEntityArchetypeToAll(id, archetypeName, world)
            -- print("Replicating to all:", id, archetypeName)
        else
            for player, v in pairs(players) do
                replicationUtil.replicateServerEntityArchetypeTo(player, id, archetypeName, world)
                -- print("Replicating to ", player)
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
end

function matterUtil.getComponentSetFromArchetype(archetypeName)
    local archetypesToCheck = Archetypes.Catalog[archetypeName]
    if archetypesToCheck then
        -- print("Archetypes to check:", archetypesToCheck)
        local componentNameSet = {}
        for _, subArchetypeName in ipairs(archetypesToCheck) do
            componentNameSet = Llama.Set.union(componentNameSet, matterUtil.getComponentSetFromArchetype(subArchetypeName))
        end
        return componentNameSet
    else
        -- print("Archetypes to check:", archetypeName)
        return Llama.Set.fromList({ archetypeName })
    end
end

function matterUtil.getReferenceSetPropertiesOfComponent(componentName, componentData)
    local propertyNames = {}
    local componentPropertyInfos = ComponentInfo.Catalog[componentName]
    for propertyName, propertyMetadata in pairs(componentPropertyInfos) do
        if propertyMetadata.isReferenceSet then
            table.insert(propertyNames, propertyName)
        end
    end
    return propertyNames
end

function matterUtil.getReferencePropertiesOfComponent(componentName, componentData)
    local propertyNames = {}
    local componentPropertyInfos = ComponentInfo.Catalog[componentName]
    for propertyName, propertyMetadata in pairs(componentPropertyInfos) do
        if propertyMetadata.isReference then
            table.insert(propertyNames, propertyName)
        end
    end
    return propertyNames
end

-- Takes a payload, and gets a list of all the serverIds of entities to make shells of from component properties.
function matterUtil.getServerEntityArchetypesOfReferences(payload)
    local serverEntities = {}
    local components = payload.components
    for componentName, componentData in pairs(components) do
        local properties = ComponentInfo.Catalog[componentName]
        for propertyName, propertyMetadata in pairs(properties) do
            if componentData[propertyName] then
                if propertyMetadata.isReference then
                    local refArchetype = propertyMetadata.referenceToArchetype
                    assert(refArchetype, "No referenceToArchetype for " .. componentName .. "." .. propertyName)

                    -- does the field actually reference an entity or is it nil
                    -- print(typeof(componentData[propertyName]), componentData[propertyName])
                    -- print("THe property name: " .. propertyName)
                    -- print("The referenceToArchetype: " .. refArchetype)
                    table.insert(serverEntities, {
                        entityId = componentData[propertyName],
                        archetype = refArchetype,
                    })
                elseif propertyMetadata.isReferenceSet then
                    local refArchetype = propertyMetadata.referenceToArchetype
                    assert(refArchetype, "No referenceToArchetype for " .. componentName .. "." .. propertyName)

                    -- loop through the *set*
                    for entityId, _ in pairs(componentData[propertyName]) do
                        table.insert(serverEntities, {
                            entityId = entityId,
                            archetype = refArchetype,
                        })
                    end
                end
            end
        end
    end

    return serverEntities
end

function matterUtil.isClientLocked(entityId, world)
    if RunService:IsServer() then return false end
    local clientLockedC = world:get(entityId, Components.ClientLocked)
    return (clientLockedC and clientLockedC.clientLocked)
end

function matterUtil.isClientLinkLocked(entityId, world)
    if RunService:IsServer() then return false end
    local clientLockedC = world:get(entityId, Components.ClientLocked)
    return (clientLockedC and clientLockedC.lockLinks)
end

function matterUtil.linkBidirectionalEntityIdRefs(alphaName, betaName, world)
    -- A change in an equippable tool changes the beta(s).
    -- the referenceField is camelcase; only lowercase the first letter.
    -- For example: the component name "FruitJuices" should be "fruitJuices".
    local alphaReferenceField = matterUtil.camelCaseWord(alphaName) .. "Id" --string.lower(string.sub(alphaName, 1, 1)) .. string.sub(alphaName, 2) .. "Id"
    local betaReferenceField = matterUtil.camelCaseWord(betaName) .. "Id" --string.lower(string.sub(betaName, 1, 1)) .. string.sub(betaName, 2) .. "Id"

    for alphaId, alphaCR in world:queryChanged(Components[alphaName]) do

        -- check for actual change and reconciliation
        if alphaCR.old and alphaCR.new then
            local newBetaId = alphaCR.new[betaReferenceField]
            local oldBetaId = alphaCR.old[betaReferenceField]
            if alphaCR.new.doNotReconcile then
                world:insert(alphaId, alphaCR.new:patch({
                    doNotReconcile = false
                }))
                continue
            end
            if newBetaId == oldBetaId then continue end
        end

        local function attemptUpdateNewBetaId()
            if alphaCR.new then
                local newBetaId = alphaCR.new[betaReferenceField]
                if newBetaId then
                    if world:contains(newBetaId) then
                        local betaC = world:get(newBetaId, Components[betaName])
                        if betaC then
                            if not matterUtil.isClientLinkLocked(newBetaId, world) then
                                world:insert(newBetaId, betaC:patch({
                                    [alphaReferenceField] = alphaId,
                                    doNotReconcile = true,
                                }))
                                return true
                                -- print("LINKED " .. alphaName .. ":" .. alphaId .. " TO " .. betaName .. ":" .. newBetaId)
                            else
                                warn("LINKING " .. alphaName .. ":" .. alphaId .. " TO " .. betaName .. ":" .. newBetaId .. " FAILED: client locked")
                                -- The entity is clientlocked, we should revert our changes
                                return false
                            end
                        else
                            warn("Component " .. alphaName .. "'s " .. betaReferenceField .. ":" .. newBetaId .. " does not have an " .. betaName .. " component.")
                            -- The entity isn't even valid to link with, we should revert our changes
                            return false
                        end
                    else
                        warn("Component " .. alphaName .. "'s " .. betaReferenceField .. " pointed to a non-existent entity:", newBetaId)
                        -- The entity does not exist, we should revert our changes
                        return false
                    end
                end
            end
            return true
        end

        local function attemptUpdateOldBetaId()
            if alphaCR.old then
                local oldBetaId = alphaCR.old[betaReferenceField]
                if oldBetaId then
                    if world:contains(oldBetaId) then
                        local oldBetaC = world:get(oldBetaId, Components[betaName])
                        if oldBetaC then
                            if oldBetaC[alphaReferenceField] == alphaId then
                                if not matterUtil.isClientLinkLocked(oldBetaId, world) then
                                    world:insert(oldBetaId, oldBetaC:patch({
                                        [alphaReferenceField] = Matter.None,
                                        doNotReconcile = true,
                                    }))
                                    -- print("UNLINKED " .. alphaName .. ":" .. alphaId .. " FROM " .. betaName .. ":" .. oldBetaId)
                                    return true
                                else
                                    warn("UNLINKING " .. alphaName .. ":" .. alphaId .. " FROM " .. betaName .. ":" .. oldBetaId .. " FAILED: client locked")
                                    -- The entity is clientlocked, we should revert our changes
                                    return false
                                end
                            else
                                -- warn("Previous " .. betaName .. " component did not reference " .. alphaReferenceField .. " " .. alphaId .. ", it referenced " .. oldBetaC[alphaReferenceField])
                                -- Though we removed the old beta id, the beta entity never pointed to us in the first place. No need to revert changes
                                return true
                            end
                        else
                            warn("Component " .. betaName .. " does not exist in entity:", oldBetaId)
                            -- The entity was never even valid to link with, no need to revert changes
                            return true
                        end
                    else
                        -- warn("Entity " .. oldBetaId .. " does not exist at all")
                        return true
                    end
                end
            end
            return true
        end

        -- Fail checking
        if not (attemptUpdateNewBetaId() and attemptUpdateOldBetaId()) then
            if alphaCR.old then
                warn("Restoring old state due to failure:", alphaCR.old)
                world:insert(alphaId, alphaCR.old:patch({
                    doNotReconcile = true,
                }))
                continue;
            else
                -- we can't revert because there's nothing to revert to. might as well keep it
            end
        end
    end

    -- When an beta changes what it's equipping, update the alpha 
    for betaId, betaCR in world:queryChanged(Components[betaName]) do

        if betaCR.new and betaCR.old then
            local newAlphaId = betaCR.new[alphaReferenceField]
            local oldAlphaId = betaCR.old[alphaReferenceField]
            if betaCR.new.doNotReconcile then
                world:insert(betaId, betaCR.new:patch({
                    doNotReconcile = false
                }))
                continue
            end
            if newAlphaId == oldAlphaId then continue end
        end

        local function attemptUpdateNewAlphaId()
            if betaCR.new then
                local newAlphaId = betaCR.new[alphaReferenceField]
                if newAlphaId then
                    if world:contains(newAlphaId) then
                        local alphaC = world:get(newAlphaId, Components[alphaName])
                        if alphaC then
                            if not matterUtil.isClientLinkLocked(newAlphaId, world) then
                                world:insert(newAlphaId, alphaC:patch({
                                    [betaReferenceField] = betaId,
                                    doNotReconcile = true,
                                }))
                                return true
                                -- print("LINKED " .. betaName .. ":" .. betaId .. " TO " .. alphaName .. ":" .. newAlphaId)
                            else
                                warn("LINKING " .. betaName .. ":" .. betaId .. " TO " .. alphaName .. ":" .. newAlphaId .. " FAILED: client locked")
                                -- The entity is clientlocked, we should revert our changes
                                return false
                            end
                        else
                            warn("Component " .. betaName .. "'s " .. alphaReferenceField .. ":" .. newAlphaId .. " does not have an " .. alphaName .. " component.")
                            -- The entity isn't even valid to link with, we should revert our changes
                            return false
                        end
                    else
                        warn("Component " .. betaName .. "'s " .. alphaReferenceField .. " pointed to a non-existent entity:", newAlphaId)
                        -- The entity does not exist, we should revert our changes
                        return false
                    end
                end
            end
            return true
        end

        local function attemptUpdateOldAlphaId()
            if betaCR.old then
                local oldAlphaId = betaCR.old[alphaReferenceField]
                if oldAlphaId then
                    if world:contains(oldAlphaId) then
                        local oldAlphaC = world:get(oldAlphaId, Components[alphaName])
                        if oldAlphaC then
                            if oldAlphaC[betaReferenceField] == betaId then
                                if not matterUtil.isClientLinkLocked(oldAlphaId, world) then
                                    world:insert(oldAlphaId, oldAlphaC:patch({
                                        [betaReferenceField] = Matter.None,
                                        doNotReconcile = true,
                                    }))
                                    -- print("UNLINKED " .. betaName .. ":" .. betaId .. " FROM " .. alphaName .. ":" .. oldAlphaId)
                                    return true
                                else
                                    warn("UNLINKING " .. betaName .. ":" .. betaId .. " FROM " .. alphaName .. ":" .. oldAlphaId .. " FAILED: client locked")
                                    -- The entity is clientlocked, we should revert our changes
                                    return false
                                end
                            else
                                -- warn("Previous " .. alphaName .. " component did not reference " .. betaReferenceField .. " " .. betaId .. ", it referenced " .. oldAlphaC[betaReferenceField])
                                -- Though we removed the old alpha id, the alpha entity never pointed to us in the first place. No need to revert changes
                                return true
                            end
                        else
                            warn("Component " .. alphaName .. " does not exist in entity:", oldAlphaId)
                            -- The entity was never even valid to link with, no need to revert changes
                            return true
                        end
                    else
                        -- Alpha entity was deleted, no need to revert changes
                        return true
                    end
                end
            end
            return true
        end

        -- Fail checking
        if not (attemptUpdateNewAlphaId() and attemptUpdateOldAlphaId()) then
            if betaCR.old then
                warn("Restoring old state due to failure:", betaCR.old)
                world:insert(betaId, betaCR.old:patch({
                    doNotReconcile = true,
                }))
                continue;
            else
                -- we can't revert because there's nothing to revert to. might as well keep it
            end
        end
    end
end

function matterUtil.getCharacterIdOfPlayer(player, world)
    local playerId = matterUtil.getEntityId(player)
    if not playerId then
        warn("Could not get player entity id of " .. player.Name)
        return nil
    end
    local playerC = world:get(playerId, Components.Player)
    if not playerC.characterId then return nil end
    return playerC.characterId
end

function matterUtil.editComponent(world, entityId, componentName, fieldName, fieldData)
    local existing = world:get(entityId, Components[componentName])
    if existing then
        world:insert(entityId, existing:patch({
            [fieldName] = fieldData,
        }))
    else
        world:insert(entityId, Components[componentName]({
            [fieldName] = fieldData,
        }))
    end
    return "Done\n"
end

function matterUtil.getPlayerFromCharacterEntity(charEntityId, world)
    local charC = world:get(charEntityId, Components.Character)
    if not charC then return end
    local playerId = charC.playerId
    if not playerId then return end
    local playerC = world:get(playerId, Components.Player)
    if not playerC then return end

    return playerC.player
end

function matterUtil.camelCaseWord(word)
    local first = string.sub(word, 1, 1)
    local rest = string.sub(word, 2)
    return string.lower(first) .. rest
end

function matterUtil.reconcileManyToOneRelationship(world, atomComponentName, collectiveComponentName, canBeAddedCallback, canBeRemovedCallback)
    -- Terminology:
    -- ATOM = entity that will link to a collective
    -- COLLECTIVE = entity that will be linked to by many ATOMS

    local DEBUG_PRINT = false

    local atomsRefName = matterUtil.camelCaseWord(atomComponentName) .. "Ids"
    local collectiveRefName = matterUtil.camelCaseWord(collectiveComponentName ) .. "Id"

    -- This section deals with *changing the collectives* to react to an ATOM attaching itself to them.
    -- Or the opposite, an ATOM detaching itself from a collective.

    -- atomsToChange is used to undo changes due to clientlocked stuff
    local atomsToChange = {}
    for atomId, atomCR in world:queryChanged(Components[atomComponentName]) do
        -- ensure we're allowed to reconcile and that new/old collectiveids haven't changed
        if atomCR.old and atomCR.new then
            local newCollectiveId = atomCR.new[collectiveRefName]
            local oldCollectiveId = atomCR.old[collectiveRefName]
            if atomCR.new.doNotReconcile then
                world:insert(atomId, atomCR.new:patch({
                    ["doNotReconcile"] = false,
                }))
                continue
            end
            if newCollectiveId == oldCollectiveId then continue end
        end

        -- Make the collective add the atom to its set.
        local function attemptUpdateNewCollective()
            if atomCR.new then
                local newCollectiveId = atomCR.new[collectiveRefName]
                if newCollectiveId and world:contains(newCollectiveId) then
                    -- print("newCollectiveId:", newCollectiveId)
                    local newCollectiveC = world:get(newCollectiveId, Components[collectiveComponentName])
                    -- print("atom ", atomId, "attempting to add to collective ", newCollectiveId)
                    -- print(newCollectiveId, "newCollectiveC:", newCollectiveC, collectiveComponentName)

                    if canBeAddedCallback and canBeAddedCallback(atomId, newCollectiveId, world) or true then
                        if not matterUtil.isClientLinkLocked(newCollectiveId, world) then
                            -- Actual change
                            world:insert(newCollectiveId, newCollectiveC:patch({
                                [atomsRefName] = Set.add(newCollectiveC[atomsRefName] or {}, atomId),
                                doNotReconcile = true,
                            }))
                            -- print("Added atom " , atomId , " to collective " , newCollectiveId)
                            return true
                        else
                            warn("Adding atom " .. atomId .. " to collective " .. newCollectiveId .. " FAILED: client locked")
                            return false
                        end
                    else
                        warn("Failed to add atom " .. atomId .. " to collective " .. newCollectiveId .. " (canBeAddedCallback): " .. tostring(canBeAddedCallback))
                        return false
                    end
                else
                    -- print("Nonexistent collective:", newCollectiveId)
                end
            end
            return true
        end

        local function attemptUpdateOldCollective()
            -- Remove from the old collective.
            if atomCR.old then
                local oldCollectiveId = atomCR.old[collectiveRefName]
                if oldCollectiveId then
                    if world:contains(oldCollectiveId) then
                        local oldCollectiveC = world:get(oldCollectiveId, Components[collectiveComponentName])
                        if canBeRemovedCallback and canBeRemovedCallback(atomId, oldCollectiveId, world) or true then
                            if not matterUtil.isClientLinkLocked(oldCollectiveId, world) then
                                world:insert(oldCollectiveId, oldCollectiveC:patch({
                                    [atomsRefName] = Set.subtract(oldCollectiveC[atomsRefName] or {}, atomId),
                                    doNotReconcile = true,
                                }))
                                return true
                            else
                                warn("Removing atom " .. atomId .. " from collective " .. oldCollectiveId .. " FAILED: client locked")
                                return false
                            end
                        else
                            warn("Could not remove atom from collective. Is it even in the collective?")
                            -- not really much to reject our own change since it wasn't there in the first place
                            return true
                        end
                    else
                        -- collective is actually completely despawned, entity does not exist
                        -- if it's still attached to the oldCollective and never had its collectiveId changed, then
                        -- it's probably being despawned by removalCollective.
                        -- so there is no oldCollective to change. we do nothing
                        return true
                    end
                end
            end
            return true
        end

        local res1 = attemptUpdateNewCollective()
        local res2 = attemptUpdateOldCollective()
        if not (res1 and res2) then
            if atomCR.old then
                -- reject our own change
                warn("rejecting atom change:", res1, res2)
                atomsToChange[atomId] = atomCR.old:patch({
                    ["doNotReconcile"] = true,
                })
            else
                -- we can't revert because there's nothing to revert to. might as well keep it
            end
        end

    end

    for atomId, componentData in pairs(atomsToChange) do
        warn("Restoring old state for atom ", atomId, ":", componentData)
        world:insert(atomId, componentData)
    end

    -- Listen to collective events
    -- This section deals with *changing the ATOMS* to react to a collective adding them.
    -- Or the opposite, a collective removing them.

    -- collectivesToChange is for collectives that have to re-update to reject their changes
    local collectivesToChange = {}
    for collectiveId, collectiveCR in world:queryChanged(Components[collectiveComponentName]) do
        -- Collective has changed.
        -- Ensure we're allowed to reconcile
        if collectiveCR.new and collectiveCR.new.doNotReconcile then
            world:insert(collectiveId, collectiveCR.new:patch({
                ["doNotReconcile"] = false,
            }))
            continue
        end

        local completelyNewSet = {}
        if collectiveCR.new then
            completelyNewSet = Set.filter(collectiveCR.new[atomsRefName] or {}, function(value)
                if collectiveCR.old then
                    return not Set.has(collectiveCR.old[atomsRefName] or {}, value)
                else
                    return true
                end
            end)
        end
        local deletedFromOldSet = {}
        if collectiveCR.old then
            deletedFromOldSet = Set.filter(collectiveCR.old[atomsRefName] or {}, function(value)
                if collectiveCR.new then
                    return not Set.has(collectiveCR.new[atomsRefName] or {}, value)
                else
                    return true
                end
            end)
        end

        -- These sets are atoms that shouldn't be edited, and should be either re-added or kept out of
        -- our collective due to being locked.
        local reDeleteFromCollective = {}
        local reAddToCollective = {}
        -- Reconcile all the atoms.
        --[[
            Also, prevent them from re-reconciling after the fact,
            because their data has already been edited.
            If they check themselves, they'll find that they can't "re-insert" themselves,
            and will remove themselves from the collective.
        ]]
        for atomId, _ in pairs(completelyNewSet) do

            local atomC = world:get(atomId, Components[atomComponentName])
            if not matterUtil.isClientLinkLocked(atomId, world) then
                world:insert(atomId, atomC:patch({
                    [collectiveRefName] = collectiveId,
                    ["doNotReconcile"] = true,
                }))
                -- if DEBUG_PRINT then
                --     print("Forced atom " , atomId , " into collective " , collectiveId)
                --     if collectiveId then
                --         print("Collective ", collectiveId, " add: ", world:get(collectiveId, Components[collectiveRefName]))
                --     end
                -- end
            else
                warn("Adding atom " .. atomId .. " to collective " .. collectiveId .. " FAILED: client locked")
                table.insert(reDeleteFromCollective, atomId)
            end

        end

        for atomId, _ in pairs(deletedFromOldSet) do
            
            if world:contains(atomId) then
                if not matterUtil.isClientLinkLocked(atomId, world) then
                    local atomC = world:get(atomId, Components[atomComponentName])
                    world:insert(atomId, atomC:patch({
                        [collectiveRefName] = Matter.None,
                        ["doNotReconcile"] = true,
                    }))
                    -- if DEBUG_PRINT then
                    --     print("Evicted atom " , atomId , " from collective " , collectiveId)
                    --     if collectiveId then
                    --         print("Collective ", collectiveId, " add: ", world:get(collectiveId, Components[collectiveRefName]))
                    --     end
                    -- end
                else
                    warn("Removing atom " .. atomId .. " from collective " .. collectiveId .. " FAILED: client locked")
                    table.insert(reAddToCollective, atomId)
                end
            else
                -- the atom entity literally does not exist anymore
                -- there is nothing to change, we can't change a deleted entity
                -- print("Storable Entity does not exist anymore")
            end

        end

        -- reject invalid changes here
        if #reAddToCollective + #reDeleteFromCollective > 0 then
            warn("Restoring or re-deleting locked atoms.")
            local finalSet = Set.copy(collectiveCR.new[atomsRefName])
            for _, atomId in ipairs(reAddToCollective) do
                Set.add(finalSet, atomId)
            end
            for _, atomId in ipairs(reDeleteFromCollective) do
                Set.subtract(finalSet, atomId)
            end
            collectivesToChange[collectiveId] = collectiveCR.new:patch({
                [atomsRefName] = finalSet,
                ["doNotReconcile"] = true,
            })
        end

    end

    for collectiveId, componentData in pairs(collectivesToChange) do
        warn("Restoring old state for collective ", collectiveId, ":", componentData)
        world:insert(collectiveId, componentData)
    end

end

--[[
    Provide a list of components (as in {Component.A, Component.B, ...})
    It will listen to changes for *any of them*.
    Provide a callback.
    The callback will be called with the component and component name that changed as an argument.
]]
-- this is too much for me to think about so if things really do get out of hand ill implement this
-- but for now im gonna do it quick n messy
--[[
function matterUtil.queryMultipleChanged(componentNameList, world)
    local queryLists = {} -- takes form of a lua tuple : Components.A, Components.B, ...
    for i = 1, #componentNameList do
        local queryList = {}
        for i, componentName in ipairs(componentNameList) do
            if not Components[componentName] then
                warn("Component " .. componentName .. " does not exist")
                return
            end
            table.insert(trackedComponents, Components[componentName])
        end
    end
    for id, comp in world:queryChanged(unpack(trackedComponents))

    --for id, ragdollableCR, characterC, instanceC, skeletonC in world:queryChanged(
end]]

function matterUtil.isNone(value)
    return value == Matter.None or value == Llama.None or value == nil or (not value)
end

return matterUtil