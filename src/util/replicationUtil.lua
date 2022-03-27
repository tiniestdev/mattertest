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
    local recipientId = replicationUtil.senderIdToRecipientId(serverId)
    return recipientId or replicationUtil.getOrCreateReplicatedEntityFromScopeIdentifier(serverId, replicationUtil.SERVERSCOPE, serverId, archetypeSet, world)
end

function replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
    return replicationUtil.getOrCreateReplicatedEntityFromScopeIdentifier(payload.entityId, payload.scope, payload.identifier, payload.archetypeSet, world)
end

function replicationUtil.getOrCreateReplicatedEntityFromScopeIdentifier(serverId, scope, identifier, archetypeNamesSet, world)
    local recipientId = replicationUtil.getRecipientIdFromScopeIdentifier(scope, identifier)

    if not recipientId then
        recipientId = world:spawn(
            Components.Replicated({
                serverId = serverId,
                scope = scope,
                identifier = identifier,
            }),
            Components.CheckArchetypes({
                archetypeSet = archetypeNamesSet,
            })
        )
        replicationUtil.setRecipientIdScopeIdentifier(recipientId, scope, identifier)
        replicationUtil.mapSenderIdToRecipientId(serverId, recipientId)
    else
        -- ensure it has a replicated component (might exist without one)
        -- check that it has the right archetypes
        local checkC = world:get(recipientId, Components.CheckArchetypes)
        local archetypeSet = checkC and checkC.archetypeSet or {}
        archetypeSet = Llama.Set.union(archetypeSet, archetypeNamesSet)

        world:insert(recipientId,
            Components.Replicated({
                serverId = serverId,
                scope = scope,
                identifier = identifier,
            }),
            Components.CheckArchetypes({
                archetypeSet = archetypeSet,
            })
        )
    end

    return recipientId
end

function replicationUtil.serializeArchetype(archetypeName, entityId, scope, identifier, world)
    local foundMethod = serializers.SerFunctions[archetypeName] and serializers.SerFunctions[archetypeName].serialize

    -- tag this entity just to indicate that this is replicated to the other side
    replicationUtil.insertOrUpdateComponent(entityId, "Replicated", {
        serverId = entityId,
        scope = scope,
        identifier = identifier,
    }, world)

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

    return {
        entityId = entityId,
        scope = scope,
        identifier = identifier,
        archetypeSet = Llama.Set.fromList({archetypeName}),
        components = components,
    }
end

function replicationUtil.deserializeArchetype(archetypeName, payload, world)
    local foundMethod = serializers.SerFunctions[archetypeName] and serializers.SerFunctions[archetypeName].deserialize
    if foundMethod then
        return foundMethod(payload, world, replicationUtil)
    else
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
    local mainRecipientId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
    replicationUtil.mapSenderIdToRecipientId(payload.entityId, mainRecipientId)
    replicationUtil.setRecipientIdScopeIdentifier(mainRecipientId, payload.scope, payload.identifier)
    -- secondary entities
    for _, entityInfo in ipairs(serverEntitiesInfos) do
        local serverId = entityInfo.entityId
        local secondaryEntityRecipientId = replicationUtil.getOrCreateReplicatedEntity(serverId, Llama.Set.fromList({entityInfo.archetype}), world)
        replicationUtil.mapSenderIdToRecipientId(serverId, secondaryEntityRecipientId)

--[[





I GIVE UP F##############
FIND OUT WHY IT KEEPS MAKING NEW ENTITIES ANDJAINS FIOHBFIUWE ITS ONT LIKE WE'RE GETETING
REPLCIATE DDTATTDATDT^AT^DT^&SAFGYDTUSYDGOGSDUYIS





]]



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
        if not payloadComponentData then continue end

        local refProps = matterUtil.getReferencePropertiesOfComponent(componentName, payloadComponentData)
        local refSetProps = matterUtil.getReferenceSetPropertiesOfComponent(componentName, payloadComponentData)
        local updatedProps = {}
        for _, refPropName in ipairs(refProps) do
            updatedProps[refPropName] = replicationUtil.senderIdToRecipientId(payloadComponentData[refPropName])
        end
        for _, refSetPropName in ipairs(refSetProps) do
            local newRefSet = {}
            for refId, _ in pairs(payloadComponentData[refSetPropName]) do
                newRefSet[replicationUtil.senderIdToRecipientId(refId)] = true
            end
            updatedProps[refSetPropName] = newRefSet
        end

        remappedComponentsData[componentName] = Llama.Dictionary.merge(payloadComponentData, updatedProps)
    end

    -- Now apply the remapped component data and hydrate em all up
    for componentName, componentData in pairs(remappedComponentsData) do
        replicationUtil.insertOrUpdateComponent(mainRecipientId, componentName, componentData, world)
    end

    return mainRecipientId
end

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
        world:insert(entityId, currComponent:patch(newData))
    else
        world:insert(entityId, Components[componentName](newData))
        currComponent = world:get(entityId, Components[componentName])
    end
    return currComponent
end

-- For clients
-- Sender is from the other side
-- Recipient is from your side
function replicationUtil.getRecipientIdFromScopeIdentifier(scope, identifier)
    return EntityLookup[scope][identifier]
end

function replicationUtil.setRecipientIdScopeIdentifier(recipientId, scope, identifier)
    EntityLookup[scope][identifier] = recipientId
end

function replicationUtil.getScopeIdentifierFromRecipientId(recipientId, world)
    local replicatedC = world:get(recipientId, Components.Replicated)
    return {scope = replicatedC.scope, identifier = replicatedC.identifier}
end

-- used for entityId field relationships
-- actual entity referencing in replication uses the above functions
function replicationUtil.senderIdToRecipientId(senderId)
    return SenderToRecipientIds[senderId]
end

function replicationUtil.mapSenderIdToRecipientId(senderId, recipientId)
    SenderToRecipientIds[senderId] = recipientId
end

function replicationUtil.getLocalPlayerEntityId()
    if RunService:IsServer() then error("Cannot get local player entity id on server") end
    return replicationUtil.getRecipientIdFromScopeIdentifier(Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
end

function replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
    local payload = replicationUtil.serializeArchetype(archetypeName, entityId, replicationUtil.SERVERSCOPE, entityId, world)
    print("serialized: ", payload)
    Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, archetypeName, payload)
end

function replicationUtil.replicateOwnPlayer(player, playerEntityId, world)
    local payload = replicationUtil.serializeArchetype("PlayerArchetype", playerEntityId, player.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER, world)
    Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, "Player", payload)
end

return replicationUtil