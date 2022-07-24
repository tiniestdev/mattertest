local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Intercom = require(ReplicatedStorage.Intercom)
local RDM = Random.new()

local uiUtil = {}

function uiUtil.nameToDebugColor(name)
    -- convert string name into a number
    assert(typeof(name) == "string", "nameToDebugColor: name must be a string, we got " .. typeof(name) .. ", " .. tostring(name))
    local nameNum = 0
    for i = 1, #name do
        nameNum = nameNum + string.byte(name, i)
    end
    local randomgen = Random.new(nameNum)
    return Color3.fromHSV(
        randomgen:NextNumber(0, 1), 
        randomgen:NextNumber(0.5, 1), 
        randomgen:NextNumber(0.6, 0.9)
    )
end

function uiUtil.storableToFusionProps(storableId, world)
    local storableC = world:get(storableId, Components.Storable)
    local corporealC = world:get(storableId, Components.Corporeal)
    local equippableC = world:get(storableId, Components.Equippable)

    local storableName = "--"
    if corporealC and corporealC.instance then
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
    if not storageC then
        warn("No storage component found in entity " .. storageId)
        return {}
    end
    local storableIds = storageC.storableIds
    local storableProps = {}
    for storableId, _ in pairs(storableIds) do
        local newProps = uiUtil.storableToFusionProps(storableId, world)
        table.insert(storableProps, newProps)
    end
    return storableProps
end

return uiUtil