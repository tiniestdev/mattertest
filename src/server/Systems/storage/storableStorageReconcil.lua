local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local storageUtil = require(ReplicatedStorage.Util.storageUtil)

local Llama = require(ReplicatedStorage.Packages.llama)
local Set = Llama.Set

return function(world)
    -- Listen to storable events
    for storableId, storableCR in world:queryChanged(Components.Storable) do

        -- ensure we're allowed to reconcile and that new/old storageids haven't changed
        if storableCR.old and storableCR.new then
            local newStorageId = storableCR.new.storageId
            local oldStorageId = storableCR.old.storageId

            if storableCR.new.doNotReconcile then
                world:insert(storableId, storableCR.new:patch({
                    doNotReconcile = false
                }))
                continue
            end
            if newStorageId == oldStorageId then continue end
        end

        -- Add to the new storage.
        if storableCR.new then
            local newStorageId = storableCR.new.storageId
            if newStorageId then
                local newStorageC = world:get(newStorageId, Components.Storage)
                print("\tSTORAGE STATE IS: ", newStorageC.storableIds)
                print("\tSTORAGE CAPACITY IS: ", storageUtil.getCapacity(newStorageC, world))
                if storageUtil.canBeStored(storableId, newStorageId, world) then
                    world:insert(newStorageId, newStorageC:patch({
                        storableIds = Set.add(newStorageC.storableIds, storableId),
                        -- Weight is done by storageCapacity system
                    }))
                else
                    warn("Could not store storable in storage. Size limits?")
                    warn("Restoring old state:", storableCR.old)
                    -- reject our own change
                    world:insert(storableId, storableCR.old)
                    continue
                end
            end
        end

        -- Remove from the old storage.
        if storableCR.old then
            local oldStorageId = storableCR.old.storageId
            if oldStorageId then
                local oldStorageC = world:get(oldStorageId, Components.Storage)
                print("\tSTORAGE STATE IS: ", oldStorageC.storableIds)
                print("\tSTORAGE CAPACITY IS: ", storageUtil.getCapacity(oldStorageC, world))
                if storageUtil.canBeRemoved(storableId, oldStorageId, world) then
                    world:insert(oldStorageId, oldStorageC:patch({
                        storableIds = Set.subtract(oldStorageC.storableIds, storableId),
                        -- Weight is done by storageCapacity system
                    }))
                else
                    warn("Could not remove storable from storage. Is it even in the storage?")
                    -- not really much to reject our own change since it wasn't there in the first place
                end
            end
        end
    end

    -- Listen to storage events
    --[[
        I'm thinking because we're most likely going to do storable -> set storageId,
        we don't need to do size checks if we explicitly define a storage's storableIds
        since that can only be intentional from our end. Maybe just do a warning if it's over sized.
        But if we attempt to do a storable -> set storageId, we will do checks.
    ]]
    for storageId, storageCR in world:queryChanged(Components.Storage) do

        -- Storage has changed.
        local completelyNewSet = {}
        if storageCR.new then
            completelyNewSet = Set.filter(storageCR.new.storableIds, function(value)
                return not Set.has(storageCR.old.storableIds, value)
            end)
            print("STORAGE ADDED THESE NEW ITEMS: ", completelyNewSet)
        end
        local deletedFromOldSet = {}
        if storageCR.old then
            deletedFromOldSet = Set.filter(storageCR.old.storableIds, function(value)
                return not Set.has(storageCR.new.storableIds, value)
            end)
            print("STORAGE DELETED THESE ITEMS: ", deletedFromOldSet)
        end

        -- Reconcile all the storables.
        --[[
            Also, prevent them from re-reconciling after the fact,
            because their data has already been edited.
            If they check themselves, they'll find that they can't "re-insert" themselves,
            and will remove themselves from the storage.
        ]]
        for storableId, _ in pairs(completelyNewSet) do
            local storableC = world:get(storableId, Components.Storable)
            world:insert(storableId, storableC:patch({
                ["storageId"] = storageId,
                ["doNotReconcile"] = true,
            }))
            print("INSERTED STORABLE", storableId, "IN STORAGE", storageId)
        end
        for storableId, _ in pairs(deletedFromOldSet) do
            local storableC = world:get(storableId, Components.Storable)
            world:insert(storableId, storableC:patch({
                ["storageId"] = Matter.None,
                ["doNotReconcile"] = true,
            }))
            print("REMOVED STORABLE ", storableId, " FROM STORAGE ", storageId)
        end
    end
end