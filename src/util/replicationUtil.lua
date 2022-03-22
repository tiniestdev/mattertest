local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local Archetypes = require(ReplicatedStorage.Archetypes)
local serializers = require(ReplicatedStorage.Util.serializers)
local replicationUtil = {}

local SenderToRecipientIds = {} -- map to use in clientside
local EntityLookup = {}

-- This scope is used for strictly server-owned and server-created entities that should
-- never be expected to exist on the client.
-- The indentifier to go with such a scope would be the server's entityId.
replicationUtil.SERVERSCOPE = "Server_"
replicationUtil.CLIENTIDENTIFIERS = {
    PLAYER = "Player",
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

function replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
    return replicationUtil.getOrCreateReplicatedEntity(payload.entityId, payload.scope, payload.identifier, world)
end
function replicationUtil.getOrCreateReplicatedEntity(serverId, scope, identifier, world)
    local recipientId = replicationUtil.getRecipientIdFromScopeIdentifier(scope, identifier)
    if not recipientId then
        recipientId = world:spawn(Components.Replicated({
            serverId = serverId,
            scope = scope,
            identifier = identifier,
        }))
        replicationUtil.setRecipientIdScopeIdentifier(recipientId, scope, identifier)
        replicationUtil.mapSenderIdToRecipientId(serverId, recipientId)
    else
        -- ensure it has a replicated component (might exist without one)
        world:insert(recipientId, Components.Replicated({
            serverId = serverId,
            scope = scope,
            identifier = identifier,
        }))
    end

    return recipientId
end

-- Quick serialize without regard to any possible entityIds the components have in their data (does not convert)
function replicationUtil.serializeArchetype(archetypeName, entityId, scope, identifier, world)
    local foundMethod = serializers.SerFunctions[archetypeName] and serializers.SerFunctions[archetypeName].serialize
    if foundMethod then
        return foundMethod(entityId, scope, identifier, world, replicationUtil)
    else
        return replicationUtil.serializeArchetypeDefault(archetypeName, entityId, scope, identifier, world)
    end
end

function replicationUtil.serializeArchetypeDefault(archetypeName, entityId, scope, identifier, world)
    local componentNames = Archetypes[archetypeName]
    local components = {}

    if componentNames then
        for _, componentName in ipairs(componentNames) do
            components[componentName] = world:get(entityId, Components[componentName])
        end
    else
        -- just assume the archetypeName is the single component it's made of
        components[archetypeName] = world:get(entityId, Components[archetypeName])
    end

    return {
        entityId = entityId,
        scope = scope,
        identifier = identifier,
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
    local recipientId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)

    local componentNames = Archetypes[archetypeName]
    if componentNames then
        for _, componentName in ipairs(componentNames) do
            replicationUtil.insertOrUpdateComponent(recipientId, componentName, payload.components[componentName], world)
        end
    else
        -- just assume the archetypeName is the single component it's made of
        replicationUtil.insertOrUpdateComponent(recipientId, archetypeName, payload.components[archetypeName], world)
    end

    return recipientId
end

function replicationUtil.insertOrUpdateComponent(entityId, componentName, newData, world)
    if not world:contains(entityId) then
        error("Tried to insert or update component on entityId " .. entityId .. " which does not exist")
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

return replicationUtil