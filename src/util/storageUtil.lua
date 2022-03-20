local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)

local storageUtil = {}

function storageUtil.getCapacity(storageC, world)
    local capacity = 0
    for storableId, _ in pairs(storageC.storableIds) do
        local storableC = world:get(storableId, Components.Storable)
        capacity = capacity + storableC.size
    end
    return capacity
end

function storageUtil.canBeStored(storableId, storageId, world)
    local storableC = world:get(storableId, Components.Storable)
    local storageC = world:get(storageId, Components.Storage)
    local currCapacity = storageUtil.getCapacity(storageC, world)

    return not Llama.Set.has(storageC.storableIds, storableId)
        and storableC.size + currCapacity <= storageC.maxCapacity
end

function storageUtil.canBeRemoved(storableId, storageId, world)
    local storageC = world:get(storageId, Components.Storage)
    return Llama.Set.has(storageC.storableIds, storableId)
end

return storageUtil