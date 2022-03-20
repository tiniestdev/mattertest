local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local replicationUtil = {}

function replicationUtil.serializeStorage(storageId, world)
    local storageC = world:get(storageId, Components.Storage)
    local storables = {}
    for storableId, _ in pairs(storageC) do
        table.insert(storables, replicationUtil.serializeStorableEntity(storableId, world))
    end
    return {
        Storage = storageC,
        Storables = storables,
    }
end

function replicationUtil.serializeStorableEntity(entityId, world)
    -- What properties does a client really need to know about a storable?
    local storableC, corporealC, toolC = world:get(entityId, Components.Storable, Components.Corporeal, Components.Tool)
    return {
        Storable = storableC,
        Corporeal = corporealC,
        Tool = toolC,
    }
end

return replicationUtil