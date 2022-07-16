local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo)
local Llama = require(ReplicatedStorage.Packages.llama)
local Archetypes = require(ReplicatedStorage.Archetypes)
local serializers = require(ReplicatedStorage.Util.serializers)
local Remotes = require(ReplicatedStorage.Remotes)

local Intercom = require(ReplicatedStorage.Intercom)
local Matter = require(ReplicatedStorage.Packages.matter)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

local replicationUtil = {}

local SenderToRecipientIds = {} -- map to use in clientside
local EntityLookup = {}

-- This scope is used for strictly server-owned and server-created entities that should
-- never be expected to exist on the client.
-- The indentifier to go with such a scope would be the server's entityId.
replicationUtil.SERVERSCOPE = "_SERVER"
replicationUtil.CLIENTIDENTIFIERS = {
    PLAYER = "_PLAYER",
}

EntityLookup.__index = function(tab, key)
    if not rawget(tab, key) then
        rawset(tab, key, {})
    end
    return rawget(tab, key)
end
EntityLookup.__newindex = function(tab, key)
    rawset(tab, key, {})
    return rawget(tab, key)
end
setmetatable(EntityLookup, EntityLookup)

--[[
    A payload schema looks like:
    {
        entityId = server-side entity id
        scope = scope of the entity
        identifier = identifier of the entity
        archetypeSet = {} SET of archetype names it's supposed to represent
        components = {
            [componentName] = {
                [key] = value
            }
        }
    }
]]

function replicationUtil.getOrCreateReplicatedEntity(serverId, archetypeSet, world)
    return replicationUtil.getOrCreateReplicatedEntityFromScopeIdentifier(serverId, replicationUtil.SERVERSCOPE, serverId, archetypeSet, world)
end

function replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
    return replicationUtil.getOrCreateReplicatedEntityFromScopeIdentifier(payload.entityId, payload.scope, payload.identifier, payload.archetypeSet, world)
end

function replicationUtil.getOrCreateReplicatedEntityFromScopeIdentifier(serverId, scope, identifier, archetypeNamesSet, world)
    if Intercom.DespawnMap[serverId] then
        Intercom.DespawnMap[serverId] = nil
        -- print("Preemptively caught despawned entity " .. serverId)
        return nil
    end
    local recipientId = replicationUtil.senderIdToRecipientId(serverId) or replicationUtil.getRecipientIdFromScopeIdentifier(scope, identifier)

    if recipientId == nil then
        -- print("RECIPIENT ID: ", recipientId)
        -- print("There is no entity in local space that has a server id of ", serverId)
        -- print(SenderToRecipientIds)
        -- print(typeof(serverId))
        recipientId = world:spawn(
            Components.Replicated({
                serverId = tonumber(serverId),
                scope = scope,
                identifier = identifier,
            }),
            Components.CheckArchetypes({
                archetypeSet = archetypeNamesSet,
            })
        )
    else
        -- print("There EXISTS an entity in local space that has a server id of ", serverId, "mapped to", recipientId)
        -- ensure it has a replicated component (might exist without one)
        -- check that it has the right archetypes
        local checkC = world:get(recipientId, Components.CheckArchetypes)
        local archetypeSet = checkC and checkC.archetypeSet or {}
        archetypeSet = Llama.Set.union(archetypeSet, archetypeNamesSet)

        world:insert(recipientId,
            Components.Replicated({
                serverId = tonumber(serverId),
                scope = scope,
                identifier = identifier,
            }),
            Components.CheckArchetypes({
                archetypeSet = archetypeSet,
            })
        )
    end

    replicationUtil.setRecipientIdScopeIdentifier(recipientId, scope, identifier)
    replicationUtil.mapSenderIdToRecipientId(serverId, recipientId)
    -- print("Returning recipientId", recipientId)

    return recipientId
end

function replicationUtil.serializeArchetype(archetypeName, entityId, scope, identifier, world)
    local foundMethod = serializers.SerFunctions[archetypeName] and serializers.SerFunctions[archetypeName].serialize

    -- tag this entity just to indicate that this is replicated to the other side

    -- server should only be sending the relevant component data and the entity id
    -- we don't need a component for this

    -- replicationUtil.insertOrUpdateComponent(entityId, "Replicated", {
    --     serverId = entityId,
    --     scope = scope,
    --     identifier = identifier,
    -- }, world)

    if foundMethod then
        return foundMethod(entityId, scope, identifier, world, replicationUtil)
    else
        return replicationUtil.serializeArchetypeDefault(archetypeName, entityId, scope, identifier, world)
    end
end

-- Quick serialize without regard to any possible entityIds the components have in their data (does not convert)
function replicationUtil.serializeArchetypeDefault(archetypeName, entityId, scope, identifier, world)
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    local components = {}

    for componentName, _ in pairs(componentSet) do
        components[componentName] = world:get(entityId, Components[componentName])
    end

    local payload = {
        entityId = entityId,
        scope = scope,
        identifier = identifier,
        archetypeSet = Llama.Set.fromList({archetypeName}),
        components = components,
    }
    -- print("Serializing archetype", archetypeName, "with payload", payload)
    return payload
end

function replicationUtil.deserializeArchetype(archetypeName, payload, world)

    if typeof(payload.serverId) == "table" then
        print("ERROR: deserializeArchetype called with payload that has no serverId")
        print(payload)
    end

    -- print("Deserializing archetype", archetypeName, "with payload", payload)

    local foundMethod = serializers.SerFunctions[archetypeName] and serializers.SerFunctions[archetypeName].deserialize
    if foundMethod then
        return foundMethod(payload, world, replicationUtil)
    else
        -- print("Deserializing archetype", archetypeName, "with payload", payload)
        return replicationUtil.deserializeArchetypeDefault(archetypeName, payload, world)
    end
end

function replicationUtil.deserializeArchetypeDefault(archetypeName, payload, world)
    -- Get information about the entities we're going to have to construct or find
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    local serverEntitiesInfos = matterUtil.getServerEntityArchetypesOfReferences(payload)

        -- CONSTRUCT SHELLS
    -- main entity, don't populate it yet because remapping must happen before that
    -- ...and remapping is all the way down there so we'll wait
    -- Check for the special case that it's our own player (don't make an entirely new entity, use our premade entity)
    local mainRecipientId
    local addOursComponent = false
    if payload.archetypeSet then
        local myPlayerId = replicationUtil.getRecipientIdFromScopeIdentifier(Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
        if payload.archetypeSet["PlayerArchetype"] then
            if payload.components["Player"] and payload.components["Player"].player == Players.LocalPlayer then
                mainRecipientId = replicationUtil.getRecipientIdFromScopeIdentifier(Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
                myPlayerId = mainRecipientId
                addOursComponent = true -- redundant, but here for consistency
                -- i think we already add an "ours" component when we initialize our player entity clientside
            end
        end
        if payload.archetypeSet["CharacterArchetype"] then
            if payload.components["Character"] and payload.components["Character"].playerId == myPlayerId then
                addOursComponent = true
            end
        end
    end
    if not mainRecipientId then
        local newEntity = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
        if not newEntity then
            warn("Failed to create mainRecipient entity from payload (may have been deleted serverside already)")
            print(payload)
        end
        mainRecipientId = newEntity
    end


    replicationUtil.mapSenderIdToRecipientId(payload.entityId, mainRecipientId)
    replicationUtil.setRecipientIdScopeIdentifier(mainRecipientId, payload.scope, payload.identifier)
    -- secondary entities
    for _, entityInfo in ipairs(serverEntitiesInfos) do
        local serverId = entityInfo.entityId
        local secondaryEntityRecipientId = replicationUtil.getOrCreateReplicatedEntity(serverId, Llama.Set.fromList({entityInfo.archetype}), world)
        if not secondaryEntityRecipientId then
            warn("Failed to create seconaryEntityRecipient entity from entityInfo (may have been deleted serverside already)")
            print(entityInfo)
        end

        replicationUtil.mapSenderIdToRecipientId(serverId, secondaryEntityRecipientId)
        -- idk how we'd handle scope and identifier below
        -- replicationUtil.setRecipientIdScopeIdentifier(secondaryEntityRecipientId, payload.scope, payload.identifier)
        -- ADD CHECKARCHETYPE COMPONENTS
        local existingCheckC = world:get(secondaryEntityRecipientId, Components.CheckArchetypes)
        local existingArchetypeSet = existingCheckC and existingCheckC.archetypeSet or {}
        if existingCheckC then
            world:insert(secondaryEntityRecipientId, existingCheckC:patch({
                archetypeSet = existingArchetypeSet,
            }))
        else
            world:insert(secondaryEntityRecipientId, Components.CheckArchetypes({
                archetypeSet = existingArchetypeSet,
            }))
        end
    end

        -- REMAPPING OF PROPERTIES
    local oldComponentsData = payload.components
    local remappedComponentsData = {}
    for componentName, _ in pairs(componentSet) do
        local payloadComponentData = oldComponentsData[componentName]
        -- print("payloadComponentData", componentName, payloadComponentData)
        if not payloadComponentData then continue end

        local refProps = matterUtil.getReferencePropertiesOfComponent(componentName, payloadComponentData)
        local refSetProps = matterUtil.getReferenceSetPropertiesOfComponent(componentName, payloadComponentData)
        local updatedProps = {}
        for _, refPropName in ipairs(refProps) do
            if payloadComponentData[refPropName] then
                updatedProps[refPropName] = replicationUtil.senderIdToRecipientId(payloadComponentData[refPropName])
            end
            -- print("Remapped ID of ", refPropName, payloadComponentData[refPropName], " to ", updatedProps[refPropName])
        end
        for _, refSetPropName in ipairs(refSetProps) do
            local newRefSet = {}
            if payloadComponentData[refSetPropName] then
                for refId, _ in pairs(payloadComponentData[refSetPropName]) do
                    newRefSet[replicationUtil.senderIdToRecipientId(refId)] = true
                    -- print("Remapped ID of ", refSetPropName, refId, " to ", replicationUtil.senderIdToRecipientId(refId))
                end
            end
            updatedProps[refSetPropName] = newRefSet
        end

        remappedComponentsData[componentName] = Llama.Dictionary.merge(payloadComponentData, updatedProps)
        -- make sure we dont get feedback loops for commponents that look for changes and ask the server to change it
        -- or "propose" changes
        remappedComponentsData[componentName]["doNotReconcile"] = true
    end

    -- Now apply the remapped component data and hydrate em all up
    -- THE PART WHERE ALL THE COMPONENT DATA IS ACTUALLY REPLICATED INTO THE ENTITY
    if not matterUtil.isClientLocked(mainRecipientId, world) and not payload.OVERRIDELOCK then
        for componentName, componentData in pairs(remappedComponentsData) do
            -- testing to see if this just makes more sense instead of specifying nil fields
            -- actually yeah it just makes sense to overwrite the component.
            -- the server's not going to replicate a few select fields, it'll just send the entire component
            -- so don't worry about specifying nil fields those seem to be a rare case
            -- replicationUtil.insertOrUpdateComponent(mainRecipientId, componentName, componentData, world)
            replicationUtil.overwriteComponent(mainRecipientId, componentName, componentData, world)
        end
    end

    -- Because this was replicated, make Replicated component that has its replication data
    replicationUtil.insertOrUpdateComponent(mainRecipientId, "Replicated", {
        serverId = payload.entityId,
        scope = payload.scope,
        identifier = payload.identifier,
    }, world)

    -- addOursComponent is set above, where it checks if it's our own player or character being deserialized
    if addOursComponent then
        replicationUtil.insertOrUpdateComponent(mainRecipientId, "Ours", {}, world)
    end

    -- give it an serverEntityId/clientEntityId attribute
    if remappedComponentsData["Instance"] then
        if remappedComponentsData.Instance.instance then
            matterUtil.setEntityId(remappedComponentsData.Instance.instance, mainRecipientId)
        else
            -- UHHHHHHHHHHHHH OOPS???????????
            -- instance is nil for some ODD REASON!!!!!!!!
            -- probably indicative of some private player-owned part that isn't accessible to every other client
            -- so just do nothing and deal with the lack of entityId in whatever systems wanted it

            -- warn("INSTANCE IS NIL:", mainRecipientId, "... RETRYING")
            -- task.delay(1, function()
            --     Remotes.Client:Get("RequestReplicateEntities"):SendToServer({payload.entityId})
            -- end)
        end
    end

    return mainRecipientId
end

function replicationUtil.overwriteComponent(entityId, componentName, newData, world)
    if not world:contains(entityId) then
        warn("Tried to insert or update component on entityId ", entityId, " which does not exist")
        error(debug.traceback())
    end
    if not Components[componentName] then
        warn("Tried to insert or update component ", componentName, " which does not exist")
        error(debug.traceback())
    end
    local currComponent = world:get(entityId, Components[componentName])

    world:insert(entityId, Components[componentName](newData))
    currComponent = world:get(entityId, Components[componentName])
    return currComponent
end

-- TO ALLOW THE SERVER TO ERASE A FIELD (nils), IT SHOULD BE SPECIFIED IN COMPONENTINNFOS
function replicationUtil.insertOrUpdateComponent(entityId, componentName, newData, world)
    if not world:contains(entityId) then
        warn("Tried to insert or update component on entityId ", entityId, " which does not exist")
        error(debug.traceback())
    end
    if not Components[componentName] then
        warn("Tried to insert or update component ", componentName, " which does not exist")
        error(debug.traceback())
    end
    local currComponent = world:get(entityId, Components[componentName])

    if currComponent then
        -- if the server wants to erase a field, it must be specified in ComponentInfos
        -- since it will typically ignore Matter.None s while merging via patch
        local patchedData = currComponent:patch(newData)
        for _, fieldName in ipairs(ComponentInfo.getReplicateNilFields(componentName)) do
            if not newData[fieldName] then
                patchedData = patchedData:patch({
                    [fieldName] = Matter.None;
                })
                -- print("replicateNil", fieldName)
            end
        end
        world:insert(entityId, patchedData)
    else
        world:insert(entityId, Components[componentName](newData))
        currComponent = world:get(entityId, Components[componentName])
    end
    return currComponent
end

function replicationUtil.getServerLookup()
    return EntityLookup[replicationUtil.SERVERSCOPE]
end

-- For clients
-- Sender is from the other side
-- Recipient is from your side
function replicationUtil.getRecipientIdFromScopeIdentifier(scope, identifier)
    return EntityLookup[scope][tostring(identifier)]
end

function replicationUtil.setRecipientIdScopeIdentifier(recipientId, scope, identifier)
    EntityLookup[scope][tostring(identifier)] = recipientId
end

function replicationUtil.getScopeIdentifierFromRecipientId(recipientId, world)
    local replicatedC = world:get(recipientId, Components.Replicated)
    return {scope = replicatedC.scope, identifier = replicatedC.identifier}
end

-- used for entityId field relationships
-- actual entity referencing in replication uses the above functions
function replicationUtil.senderIdToRecipientId(senderId)
    return tonumber(SenderToRecipientIds[tostring(senderId)])
end

function replicationUtil.mapSenderIdToRecipientId(senderId, recipientId)
    SenderToRecipientIds[tostring(senderId)] = recipientId
end

function replicationUtil.getLocalPlayerEntityId()
    if RunService:IsServer() then error("Cannot get local player entity id on server") end
    return replicationUtil.getRecipientIdFromScopeIdentifier(Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
end

function replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
    -- check that we're not missing components, or else the client's gonna keep requesting the same thing over and over again
    if matterUtil.isArchetype(entityId, archetypeName, world) then
        local payload = replicationUtil.serializeArchetype(archetypeName, entityId, replicationUtil.SERVERSCOPE, entityId, world)
        Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, archetypeName, payload)
    else
        warn("ReplicationUtil: Tried to replicate archetype ", archetypeName, " of ", entityId, " but it is missing the following components")
        for i,v in ipairs(matterUtil.getMissingComponentsOfArchetype(entityId, archetypeName, world)) do
            warn("ReplicationUtil: Missing component ", v)
        end
        error(debug.traceback())
    end
end

function replicationUtil.replicateServerEntityArchetypeToAll(entityId, archetypeName, world)
    for i, player in ipairs(Players:GetPlayers()) do
        replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
    end
end

function replicationUtil.replicateEntity(id, world)
end

function replicationUtil.replicateOwnPlayer(player, playerEntityId, world)
    local payload = replicationUtil.serializeArchetype("PlayerArchetype", playerEntityId, player.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER, world)
    Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, "PlayerArchetype", payload)
end

return replicationUtil