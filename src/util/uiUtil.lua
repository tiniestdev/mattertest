local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Intercom = require(ReplicatedStorage.Intercom)

local uiUtil = {}

function uiUtil.storableToFusionProps(storableId, world)
    local storableC = world:get(storableId, Components.Storable)
    local corporealC = world:get(storableId, Components.Corporeal)
    local equippableC = world:get(storableId, Components.Equippable)

    local storableName = "--"
    if corporealC then
        storableName = corporealC.instance.Name
    end
    if equippableC then
        storableName = equippableC.presetName
    end
    if storableC then
        storableName = storableC.displayName
    end

    -- print("StorableName for ", storableId, ": ", storableName)
    -- print(corporealC, equippableC, storableC)
    return {
        storableName = storableName,
        storableId = storableId,
        order = storableC and storableC.order or 0,
    }
end

function uiUtil.getStorablePropsFromStorage(storageId, world)
    local storageC = world:get(storageId, Components.Storage)
    local storableIds = storageC.storableIds
    local storableProps = {}
    for storableId, _ in pairs(storableIds) do
        local newProps = uiUtil.storableToFusionProps(storableId, world)
        table.insert(storableProps, newProps)
    end
    return storableProps
end

function uiUtil.fireUpdateToolbarSignal(world)
    local MatterClient = require(Players.LocalPlayer:FindFirstChild("MatterClient", true))
    local ourPlayerId = MatterClient.OurPlayerEntityId
    local ourCharacterId = world:get(ourPlayerId, Components.Player).characterId
    Intercom.Get("UpdateToolbar"):Fire(ourCharacterId)
end

return uiUtil