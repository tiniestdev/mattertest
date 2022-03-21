local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local replicationUtil = {}

local SenderToRecipientIds = {} -- map to use in clientside

function replicationUtil.serializeStorage(storageId, world)
    local storageC = world:get(storageId, Components.Storage)
    local storables = {}
    for storableId, _ in pairs(storageC.storableIds) do
        table.insert(storables, replicationUtil.serializeStorableEntity(storableId, world))
    end
    return {
        entityId = storageId,
        Storage = storageC,
        Storables = storables,
    }
end

function replicationUtil.serializeStorableEntity(entityId, world)
    -- What properties does a client really need to know about a storable?
    if world:contains(entityId) then
        local storableC = world:get(entityId, Components.Storable)
        local corporealC = world:get(entityId, Components.Corporeal)
        local toolC = world:get(entityId, Components.Tool)

        return {
            entityId = entityId,
            Storable = storableC,
            Corporeal = corporealC,
            Tool = toolC,
        }
    else
        print("World does not have entity id ", entityId, typeof(entityId))
        error(debug.traceback())
    end
end

function replicationUtil.insertOrUpdateComponent(entityId, componentName, newData, world)
    local currComponent = world:get(entityId, Components[componentName])
    if currComponent then
        world:insert(entityId, currComponent:patch(newData))
    else
        world:spawn(entityId, Components[componentName](newData))
        currComponent = world:get(entityId, Components[componentName])
    end
    return currComponent
end

-- For clients
-- Sender is from the other side
-- Recipient is from your side
function replicationUtil.getSenderId(recipientId, world)
    local replicatedC = world:get(recipientId, Components.Replicated)
    return replicatedC.senderId
end

function replicationUtil.serverIdToClientId(senderId)
    return SenderToRecipientIds[senderId]
end

function replicationUtil.mapServerIdToClientId(senderId, clientId)
    SenderToRecipientIds[senderId] = clientId
end

--[[
    Interprets storable data, creates or updates the corresponding storable entity
    Returns *our* entityId
]]
function replicationUtil.deserializeStorage(payload, world)
    local newStorageData = Llama.Dictionary.copy(payload.Storage)

    -- First, ensure we have a recipient id for a storage entity
    -- (we will finalize its storage component data later, after we know storables are linked to this id)
    local storageSenderId = payload.entityId
    local storageRecipientId = replicationUtil.serverIdToClientId(storageSenderId)
    if not storageRecipientId then
        storageRecipientId = world:spawn(Components.Storage(newStorageData))
        replicationUtil.mapServerIdToClientId(storageSenderId, storageRecipientId)
    end

    -- Ensure all storables are linked to a recipientId (creation or updating)
    for _, storablePayload in ipairs(newStorageData) do
        replicationUtil.deserializeStorableEntity(storablePayload, world)
    end

    -- re-map all ids from senderIds to recipientIds
    newStorageData.storableIds = Llama.Dictionary.map(newStorageData.storableIds, function(_, senderStorableId)
        return true, replicationUtil.serverIdToClientId(senderStorableId)
    end)

    -- Now finalize the storage data
    local storageRecipientC = world:get(storageRecipientId, Components.Storage)
    world:insert(storageRecipientId, storageRecipientC:patch(newStorageData))

    return storageRecipientId
end

--[[
    Interprets storable data, creates or updates the corresponding storable entity
    Returns *our* entityId
]]
function replicationUtil.deserializeStorableEntity(payload, world)
    local senderId = payload.entityId
    local recipientId = replicationUtil.serverIdToClientId(senderId)

    if not recipientId then
        recipientId = world:spawn(Components.Storable(payload.Storable))
        replicationUtil.mapServerIdToClientId(senderId, recipientId)
    end

    -- At this point, there *should* be a recipientId for our storage
    local senderStorageId = payload.Storable.storageId
    local recipientStorageId = replicationUtil.serverIdToClientId(senderStorageId)
    if not recipientStorageId then
        error("Storage entity ", senderStorageId, " does not have a mapping to a clientside entity.")
    end

    local newStorableData = Llama.Dictionary.copy(payload.Storable)
    newStorableData.storageId = recipientStorageId

    replicationUtil.insertOrUpdateComponent(recipientId, "Storable", newStorableData, world)
    if payload.Corporeal then
        replicationUtil.insertOrUpdateComponent(recipientId, "Corporeal", payload.Corporeal, world)
    end
    if payload.Tool then
        replicationUtil.insertOrUpdateComponent(recipientId, "Tool", payload.Tool, world)
    end

    return recipientId
end

return replicationUtil