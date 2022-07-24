local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local storageUtil = require(ReplicatedStorage.Util.storageUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

local Intercom = require(ReplicatedStorage.Intercom)

return function(world)

    for entityId, storageCR in world:queryChanged(Components.Storage) do
        if not matterUtil.isChangeRecordDiff(storageCR) then continue end
        if not storageCR.new then continue end
        if not world:get(entityId, Components.Ours) then continue end
        -- print("firing cause storage entityId", entityId)
        -- print(storageCR)
        Intercom.Get("UpdateToolbar"):Fire()
    end

    for entityId, storableCR in world:queryChanged(Components.Storable) do
        if not matterUtil.isChangeRecordDiff(storableCR) then continue end
        if not storableCR.new then continue end
        if not world:get(entityId, Components.InToolbar) then continue end
        -- print("firing cause storable entityId", entityId)
        Intercom.Get("UpdateToolbar"):Fire()
    end

    for entityId, storageCR in world:queryChanged(Components.Storage) do
        if not storageCR.new then continue end
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