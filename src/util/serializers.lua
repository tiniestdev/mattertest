local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local serializers = {}

serializers.SerFunctions = {
    Character = {
        serialize = function(entityId, scope, identifier, world, replicationUtil)
            local payload = replicationUtil.serializeArchetypeDefault("Character", entityId, scope, identifier, world)

            local StoragePayload = replicationUtil.serializeArchetype("Storage", entityId, scope, identifier, world)
            payload.StoragePayload = StoragePayload
            
            return payload
        end,
        deserialize = function(payload, world, replicationUtil)
            local recipientCharacterId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
            local senderPlayerId = payload.components.Character.playerId
            local recipientPlayerId = replicationUtil.senderIdToRecipientId(payload.components.Character.playerId)
            if not recipientPlayerId then
                error("Player entity ".. senderPlayerId .." does not have a mapping to a clientside entity.")
            end
            payload.components.Character.playerId = recipientPlayerId
        
            replicationUtil.deserializeArchetypeDefault("Character", payload, world)
            replicationUtil.deserializeArchetype("Storage", payload.StoragePayload, world)
            
            return recipientCharacterId
        end,
    },
    Storage = {
        serialize = function(entityId, scope, identifier, world, replicationUtil)
            local payload = replicationUtil.serializeArchetypeDefault("Storage", entityId, scope, identifier, world)
            payload.StorablePayloads = {}
            for storableId, _ in pairs(payload.components.Storage.storableIds) do
                local storablePayload = replicationUtil.serializeArchetype("Storable", storableId, scope, storableId, world)
                payload.StorablePayloads[storableId] = storablePayload
            end
            return payload
        end,
        deserialize = function(payload, world, replicationUtil)
            -- First, ensure we have a recipient id for a storage entity
            -- (we will finalize its storage component data later, after we know storables are linked to this id)
            local storageRecipientId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)

            -- Ensure all storables are linked to a recipientId (creation or updating)
            for storableId, storablePayload in pairs(payload.StorablePayloads) do
                local newRecievedStorableId = replicationUtil.deserializeArchetype("Storable", storablePayload, world)
                replicationUtil.mapSenderIdToRecipientId(storableId, newRecievedStorableId)
            end

            -- re-map all ids from senderIds to recipientIds
            local newStorableIds = Llama.Dictionary.map(payload.components.Storage.storableIds, function(_, senderStorableId)
                return true, replicationUtil.senderIdToRecipientId(senderStorableId)
            end)

            -- Now finalize the storage data (merge replicated data with what we have)
            replicationUtil.insertOrUpdateComponent(storageRecipientId, "Storage", payload.components.Storage, world)

            -- actually make it a storage (which includes the appropriate RECIPIENT ids)
            local storageRecipientC = world:get(storageRecipientId, Components.Storage)
            world:insert(storageRecipientId, storageRecipientC:patch(
                Llama.Dictionary.merge(payload.components.Storage, {
                    storableIds = newStorableIds,
                })
            ))

            return storageRecipientId
        end,
    },
    Storable = {
        deserialize = function(payload, world, replicationUtil)
            local recipientId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)

            -- At this point, there *should* be a recipientId for our storage
            local senderStorageId = payload.components.Storable.storageId
            local recipientStorageId = replicationUtil.senderIdToRecipientId(senderStorageId)
            if not recipientStorageId then
                error("Storage entity ", senderStorageId, " does not have a mapping to a clientside entity.")
            end

            -- actually make it a storable
            replicationUtil.insertOrUpdateComponent(recipientId, "Storable", Llama.Dictionary.merge(
                payload.Storable,
                { storageId = recipientStorageId }
            ), world)

            return recipientId
        end,
    },
}

return serializers