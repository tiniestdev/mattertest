local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local storageUtil = require(ReplicatedStorage.Util.storageUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

return function(world)

    for entityId, storageCR in world:queryChanged(Components.Storage) do
        if not world:get(entityId, Components.Ours) then continue end
        uiUtil.fireUpdateToolbarSignal(world)
    end

    for entityId, storableCR in world:queryChanged(Components.Storable) do
        if not world:get(entityId, Components.InToolbar) then continue end
        uiUtil.fireUpdateToolbarSignal(world)
    end

    for entityId, storageCR in world:queryChanged(Components.Storage) do
        if not world:get(entityId, Components.Character) then continue end
        if not world:get(entityId, Components.Ours) then continue end
        if storageCR.new then
            local newStorableIds = storageCR.new.storableIds
            for storableId, _ in pairs(newStorableIds) do
                -- new storables get tracked
                if not world:contains(storableId) then
                    warn("storableId ", storableId, "is not in world")
                    error(debug.traceback())
                end
                world:insert(storableId, Components.InToolbar())
            end
            if storageCR.old then
                local oldStorableIds = storageCR.old.storableIds
                local deletedIds = storageUtil.getRemovedFromOldSet(newStorableIds, oldStorableIds)
                for storableId, _ in pairs(deletedIds) do
                    -- old storables get untracked
                    if world:contains(storableId) then
                        world:remove(storableId, Components.InToolbar)
                    end
                end
            end
        else
            -- everything was deleted, we do nothing
        end
    end
end