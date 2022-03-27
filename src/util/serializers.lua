local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local Matter = require(ReplicatedStorage.Packages.matter)
local serializers = {}

serializers.SerFunctions = {
    PlayerArchetype = {
        serialize = function(entityId, scope, identifier, world, replicationUtil)
            local payload = replicationUtil.serializeArchetypeDefault("Player", entityId, scope, identifier, world)
            return payload
        end,
        deserialize = function(payload, world, replicationUtil)
            -- every time we deal with reference ids, we have to translate from serialization
            -- because we're dealing with references to actual entities, we may have to include everything about
            -- the OTHER entity as well, so we have a payload within a payload
            -- in the future we might have it so entityids are just passed without any entity payload information
            -- then we can have it so that if the client truly has nothing referencing that server entityId, and thus
            -- nothing to refer to locally, then it'll make a separate request to the server to get the full payload
            -- this could prevent unnecessary data being serialized and transported
            local recipientPlayerId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)
            local foundCharId = payload.components.Player.characterId
            if foundCharId then
                -- Create empty shell, will be populated later maybe on the next frame
                local recipientCharacterId = replicationUtil.getOrCreateReplicatedEntity(
                    foundCharId,
                    replicationUtil.SERVERSCOPE,
                    foundCharId,
                    Llama.Set.fromList({ "Character" }),
                    world
                )
                payload.components.Player.characterId = recipientCharacterId
            end
            -- Deserialize with the re-mapped ids
            replicationUtil.deserializeArchetypeDefault("Player", payload, world)
            return recipientPlayerId
        end,
    },
    CharacterArchetype = {
        serialize = function(entityId, scope, identifier, world, replicationUtil)
            local payload = replicationUtil.serializeArchetypeDefault("Character", entityId, scope, identifier, world)
            -- local StoragePayload = replicationUtil.serializeArchetype("Storage", entityId, scope, identifier, world)
            -- payload.StoragePayload = StoragePayload
            return payload
        end,
        deserialize = function(payload, world, replicationUtil)
            local recipientCharacterId = replicationUtil.getOrCreateReplicatedEntityFromPayload(payload, world)

            -- Take care of the linked player
            local senderPlayerId = payload.components.Character.playerId
            if senderPlayerId then
                local recipientPlayerId = replicationUtil.senderIdToRecipientId(payload.components.Character.playerId)
                if not recipientPlayerId then
                    -- Usually we'd make a false player entity here and not bother making a check/error handling.
                    -- However, this case is different because something is clearly wrong if a character is being replicated
                    -- before being linked to an actual player.
                    error("Server player entity ".. senderPlayerId .." does not have a mapping to a clientside entity.")
                end
                payload.components.Character.playerId = recipientPlayerId
            else
                -- this character has no player... kinda Weird.?????
                warn("Character ".. recipientCharacterId .." has no playerId")
            end

            -- Take care of equipped component
            local foundEquippableId = payload.components.Equipper.equippableId
            if foundEquippableId then
                local recipientEquippableId = replicationUtil.getOrCreateReplicatedEntity(
                    foundEquippableId,
                    replicationUtil.SERVERSCOPE,
                    foundEquippableId,
                    Llama.Set.fromList({ "Equippable" }),
                    world
                )
                payload.components.Equipper.equippableId = recipientEquippableId
            end

            -- Take care of storage component
            -- The character entity itself is storage, so we just deserialize again but in the context of being a storage.
            replicationUtil.deserializeArchetypeDefault("CharacterArchetype", payload, world)
            -- Overwrite the newly created storage and equippers
            replicationUtil.deserializeArchetype("Storage", payload, world)

            -- Equipped and Storage components will be added, and they'll have the serverids there
            -- uh oh
            -- those won't be translated because they are straight up just copied
            -- we only took care of mapping the character part
            -- we should take care of each component of this archetype here, but it's just making replicated entities ya know
            -- the storage part of character should be individually replicated by the server

            return recipientCharacterId
        end,
    },
    Equipper = {

    },
    Equippable = {

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

            --[[
            for storableId, storablePayload in pairs(payload.StorablePayloads) do
                local newRecievedStorableId = replicationUtil.deserializeArchetype("Storable", storablePayload, world)
                replicationUtil.mapSenderIdToRecipientId(storableId, newRecievedStorableId)
            end]]

            -- re-map all ids from senderIds to recipientIds
            --[[
            local newStorableIds = Llama.Dictionary.map(payload.components.Storage.storableIds, function(_, senderStorableId)
                return true, replicationUtil.senderIdToRecipientId(senderStorableId)
            end)]]
            local newStorableIds = Llama.Dictionary.map(payload.components.Storage.storableIds, function(_, senderStorableId)
                return true, replicationUtil.getOrCreateReplicatedEntity(
                    senderStorableId,
                    replicationUtil.SERVERSCOPE,
                    senderStorableId,
                    Llama.Set.fromList({ "Storable" }),
                    world
                )
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
            
            if senderStorageId then
                local recipientStorageId = replicationUtil.getOrCreateReplicatedEntity(
                    senderStorageId,
                    replicationUtil.SERVERSCOPE,
                    senderStorageId,
                    Llama.Set.fromList({ "Storage" }),
                    world
                )
                --[[
                local recipientStorageId = replicationUtil.senderIdToRecipientId(senderStorageId)
                if not recipientStorageId then
                    warn("Storage entity ", senderStorageId, " does not have a mapping to a clientside entity.")
                    warn("recipientStorABLEId: ", recipientId)
                    warn("senderStorageId: ", senderStorageId)
                    warn("recipientStorageId: ", recipientStorageId)
                    warn(payload)
                    error(debug.traceback())
                end]]
                -- actually make it a storable
                replicationUtil.insertOrUpdateComponent(recipientId, "Storable", Llama.Dictionary.merge(
                    payload.Storable,
                    { storageId = recipientStorageId }
                ), world)
            else
                -- this storable is not in any storage
                replicationUtil.insertOrUpdateComponent(recipientId, "Storable", Llama.Dictionary.merge(
                    payload.Storable,
                    { storageId = Matter.None }
                ), world)
            end

            return recipientId
        end,
    },
}

return serializers