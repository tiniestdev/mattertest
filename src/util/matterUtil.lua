local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Components = require(ReplicatedStorage.components)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Archetypes = require(ReplicatedStorage.Archetypes)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

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
        return "EntityId " .. entityId .. " does not exist in the local world."
    end
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
        if not world:get(entityId, Components[componentName]) then
            return false
        end
    end
    return true
end

function matterUtil.getChangedEntitiesOfArchetype(archetypeName, world, ...)
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    local componentList = tableUtil.FlipNumeric(componentSet)
    local changedEntities = {}

    -- cycle through every single component that might have changed
    -- we need to rotate the list that will go inside the queryChanged, since
    -- only the FIRST argument will be checked for changes
    
    -- rotate componentList
    for i=1, #componentList do
        tableUtil.Rotate(componentList)
        local actualComponents = {}
        for _, componentName in ipairs(componentList) do
            table.insert(actualComponents, Components[componentName])
        end
        local currentComponentName = componentList[1]
        for id, CR in world:queryChanged(unpack(actualComponents)) do
            if not changedEntities[id] then
                changedEntities[id] = {}
            end
            changedEntities[id][currentComponentName] = CR
        end
    end

    for i, componentName in ipairs(componentList) do
        for id, componentCR in world:queryChanged(Components[componentName], ...) do
            if matterUtil.isArchetype(id, archetypeName, world) then
                if not changedEntities[id] then
                    changedEntities[id] = {}
                end
                changedEntities[id][componentName] = componentCR
            end
        end
    end
    
    return changedEntities
end

function matterUtil.replicateChangedArchetypes(archetypeName, world)
    local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

    local doNotReplicateEntities = {}
    local defaultEntities = {}

    for id, crs in pairs(matterUtil.getChangedEntitiesOfArchetype(archetypeName, world, Components.ReplicateToClient)) do
        local rtcC = world:get(id, Components.ReplicateToClient)
        
        if rtcC.doNotReplicateTo then
            table.insert(doNotReplicateEntities, id)
        else
            table.insert(defaultEntities, id)
        end

        if not (rtcC.doNotReplicateTo or rtcC.doNotReplicateRecognized) then
            print("!! replicating", id)
            local componentsChanged = false
            for componentName, cr in pairs(crs) do
                componentsChanged = true
            end
            if componentsChanged then
                replicationUtil.replicateServerEntityArchetypeToAll(id, archetypeName, world)
            end
        else
            print("did not replicate ", id)
        end
    end

    for _, id in ipairs(doNotReplicateEntities) do
        local rtcC = world:get(id, Components.ReplicateToClient)
        world:insert(id, rtcC:patch({
            doNotReplicateTo = Matter.None,
            doNotReplicateRecognized = true,
        }))
        print("marked", id, " as recognized")
    end

    for _, id in ipairs(defaultEntities) do
        local rtcC = world:get(id, Components.ReplicateToClient)
        world:insert(id, rtcC:patch({
            doNotReplicateTo = Matter.None,
            doNotReplicateRecognized = false,
        }))
        print("demarked", id, " as unrecognized")
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

function matterUtil.linkBidirectionalEntityIdRefs(alphaName, betaName, world)
    -- A change in an equippable tool changes the beta(s).

    -- the referenceField is camelcase; only lowercase the first letter.
    -- For example: the component name "FruitJuices" should be "fruitJuices".
    local alphaReferenceField = string.lower(string.sub(alphaName, 1, 1)) .. string.sub(alphaName, 2)
    local betaReferenceField = string.lower(string.sub(betaName, 1, 1)) .. string.sub(betaName, 2)

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

        -- Update whatever beta component it's pointing to now
        if alphaCR.new then
            local newBetaId = alphaCR.new[betaReferenceField]
            if newBetaId then
                if world:contains(newBetaId) then
                    local betaC = world:get(newBetaId, Components[betaName])
                    if betaC then
                        world:insert(newBetaId, betaC:patch({
                            [alphaReferenceField] = alphaId,
                            doNotReconcile = true,
                        }))
                        print("LINKED " .. alphaName .. ":" .. alphaId .. " TO " .. betaName .. ":" .. newBetaId)
                    else
                        warn("Component " .. alphaName .. "'s " .. betaReferenceField .. ":" .. newBetaId .. " does not have an " .. betaName .. " component.")
                    end
                else
                    warn("Component " .. alphaName .. "'s " .. betaReferenceField .. " pointed to a non-existent entity:", newBetaId)
                    warn("Restoring old state:", alphaCR.old)
                    world:insert(alphaId, alphaCR.old:patch({
                        doNotReconcile = true,
                    }))
                    continue
                end
            end
        end

        -- Update the old beta component to remove its own reference
        if alphaCR.old then
            local oldBetaId = alphaCR.old[betaReferenceField]
            if oldBetaId then
                if world:contains(oldBetaId) then
                    local oldBetaC = world:get(oldBetaId, Components[betaName])
                    if oldBetaC then
                        if oldBetaC[alphaReferenceField] == alphaId then
                            world:insert(oldBetaId, oldBetaC:patch({
                                [alphaReferenceField] = Matter.None,
                                doNotReconcile = true,
                            }))
                            print("UNLINKED " .. alphaName .. ":" .. alphaId .. " FROM " .. betaName .. ":" .. oldBetaId)
                        else
                            warn("Previous " .. betaName .. " component did not reference " .. alphaReferenceField .. " " .. alphaId .. ", it referenced " .. oldBetaC[alphaReferenceField])
                            -- not really much to reject our own change since it wasn't there in the first place
                        end
                    else
                        warn("Component " .. betaName .. " does not exist in entity:", oldBetaId)
                        continue
                    end
                else
                    -- beta was deleted
                end
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

        -- Update the alpha component it just pointed to
        if betaCR.new then
            local newAlphaId = betaCR.new[alphaReferenceField]
            if newAlphaId then
                if world:contains(newAlphaId) then
                    local alphaC = world:get(newAlphaId, Components[alphaName])
                    if alphaC then
                        world:insert(newAlphaId, alphaC:patch({
                            [betaReferenceField] = betaId,
                            doNotReconcile = true,
                        }))
                        print("LINKED " .. alphaName .. ":" .. newAlphaId .. " TO " .. betaName .. ":" .. betaId)
                    else
                        warn("Component " .. betaName .. "'s " .. alphaReferenceField .. ":" .. newAlphaId .. " does not have an " .. alphaName .. " component.")
                    end
                else
                    warn("Component " .. betaName .. "'s " .. alphaReferenceField .. " pointed to a non-existent entity:", newAlphaId)
                    warn("Restoring old state:", betaCR.old)
                    world:insert(betaId, betaCR.old:patch({
                        doNotReconcile = true,
                    }))
                    continue
                end
            end
        end

        -- Update the alpha component that it broke away from
        if betaCR.old then
            local oldAlphaId = betaCR.old[alphaReferenceField]
            if oldAlphaId then
                if world:contains(oldAlphaId) then
                    local oldAlphaC = world:get(oldAlphaId, Components[alphaName])
                    if oldAlphaC then
                        if oldAlphaC[betaReferenceField] == betaId then
                            world:insert(oldAlphaId, oldAlphaC:patch({
                                [betaReferenceField] = Matter.None,
                                doNotReconcile = true,
                            }))
                            print("UNLINKED " .. alphaName .. ":" .. betaId .. " FROM " .. betaName .. ":" .. oldAlphaId)
                        else
                            warn("Previous " .. alphaName .. " component did not reference " .. betaReferenceField .. " " .. betaId .. ", it referenced " .. oldAlphaC[betaReferenceField])
                            -- not really much to reject our own change since it wasn't there in the first place
                        end
                    else
                        warn("Component " .. alphaName .. " does not exist in entity:", oldAlphaId)
                        continue
                    end
                else
                    -- alpha was deleted
                end
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
    for atomId, atomCR in world:queryChanged(Components[atomComponentName]) do
        -- ensure we're allowed to reconcile and that new/old collectiveids haven't changed
        if atomCR.old and atomCR.new then
            local newCollectiveId = atomCR.new[collectiveRefName]
            local oldCollectiveId = atomCR.old[collectiveRefName]
            if atomCR.new.doNotReconcile then
                world:insert(atomId, atomCR.new:patch({
                    doNotReconcile = false
                }))
                continue
            end
            if newCollectiveId == oldCollectiveId then continue end
        end

        -- Add atom to the new collective.
        if atomCR.new then
            local newCollectiveId = atomCR.new[collectiveRefName]
            if newCollectiveId then
                local newCollectiveC = world:get(newCollectiveId, Components[collectiveComponentName])
                if canBeAddedCallback and canBeAddedCallback(atomId, newCollectiveId, world) or true then
                    world:insert(newCollectiveId, newCollectiveC:patch({
                        [atomsRefName] = Set.add(newCollectiveC[atomsRefName] or {}, atomId),
                    }))
                    if DEBUG_PRINT then
                        print("Added atom " , atomId , " to collective " , newCollectiveId)
                        if newCollectiveId then
                            print("Collective ", newCollectiveId, " add: ", world:get(newCollectiveId, Components[collectiveRefName]))
                        end
                    end
                else
                    warn("Could not store atom in collective.")
                    warn("Restoring old state:", atomCR.old)
                    -- reject our own change
                    world:insert(atomId, atomCR.old)
                    continue
                end
            end
        end

        -- Remove from the old collective.
        if atomCR.old then
            local oldCollectiveId = atomCR.old[collectiveRefName]
            if oldCollectiveId then
                if world:contains(oldCollectiveId) then
                    local oldCollectiveC = world:get(oldCollectiveId, Components[collectiveComponentName])
                    if canBeRemovedCallback and canBeRemovedCallback(atomId, oldCollectiveId, world) or true then
                        world:insert(oldCollectiveId, oldCollectiveC:patch({
                            [atomsRefName] = Set.subtract(oldCollectiveC[atomsRefName] or {}, atomId),
                        }))
                        if DEBUG_PRINT then
                            print("Removed atom " , atomId , " from collective " , oldCollectiveId)
                            if oldCollectiveId then
                                print("Collective ", oldCollectiveId, " rem: ", world:get(oldCollectiveId, Components[collectiveRefName]))
                            end
                        end
                    else
                        warn("Could not remove atom from collective. Is it even in the collective?")
                        -- not really much to reject our own change since it wasn't there in the first place
                    end
                else
                    -- collective is actually completely despawned, entity does not exist
                    -- if it's still attached to the oldCollective and never had its collectiveId changed, then
                    -- it's probably being despawned by removalCollective.
                    -- so there is no oldCollective to change. we do nothing
                    -- print("Collective entity doesn't exist anymore")
                end
            end
        end
    end

    -- Listen to collective events
    -- This section deals with *changing the ATOMS* to react to a collective adding them.
    -- Or the opposite, a collective removing them.
    for collectiveId, collectiveCR in world:queryChanged(Components[collectiveComponentName]) do
        -- Collective has changed.
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

        -- Reconcile all the atoms.
        --[[
            Also, prevent them from re-reconciling after the fact,
            because their data has already been edited.
            If they check themselves, they'll find that they can't "re-insert" themselves,
            and will remove themselves from the collective.
        ]]
        for atomId, _ in pairs(completelyNewSet) do
            local atomC = world:get(atomId, Components[atomComponentName])
            world:insert(atomId, atomC:patch({
                [collectiveRefName] = collectiveId,
                ["doNotReconcile"] = true,
            }))
            if DEBUG_PRINT then
                print("Forced atom " , atomId , " into collective " , collectiveId)
                if collectiveId then
                    print("Collective ", collectiveId, " add: ", world:get(collectiveId, Components[collectiveRefName]))
                end
            end
        end
        for atomId, _ in pairs(deletedFromOldSet) do
            if world:contains(atomId) then
                local atomC = world:get(atomId, Components[atomComponentName])
                world:insert(atomId, atomC:patch({
                    [collectiveRefName] = Matter.None,
                    ["doNotReconcile"] = true,
                }))
                if DEBUG_PRINT then
                    print("Evicted atom " , atomId , " from collective " , collectiveId)
                    if collectiveId then
                        print("Collective ", collectiveId, " add: ", world:get(collectiveId, Components[collectiveRefName]))
                    end
                end
            else
                -- the atom entity literally does not exist anymore
                -- there is nothing to change, we can't change a deleted entity
                -- print("Storable Entity does not exist anymore")
            end
        end
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

return matterUtil