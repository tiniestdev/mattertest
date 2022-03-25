local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)

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

    return {
        storableName = storableName,
        storableId = storableId,
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

return uiUtil