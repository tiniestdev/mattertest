local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local toolUtil = require(ReplicatedStorage.Util.toolUtil)

local ToolInfos = require(ReplicatedStorage.ToolInfos)

local function getToolState()
    local storage = Matter.useHookState(nil, function(stg)
        -- print("CLEANUP CALLED")
        if stg.cleanup then
            if stg.localInstance then
                stg.localInstance:Destroy()
                stg.toolName = nil
            end
        else
            return true
        end
    end)
    return storage
end

return function(world)
    for id, equipperCR in world:queryChanged(Components.Equipper) do

        if equipperCR.old and equipperCR.old.equippableId then
            local oldEquippableId = equipperCR.old.equippableId
            if equipperCR.new and equipperCR.new.equippableId ~= oldEquippableId then
                local equippableC = world:get(oldEquippableId, Components.Equippable)
                local toolName = equippableC.presetName
                local toolInfo = ToolInfos.Catalog[toolName]
                if toolInfo["UNEQUIP"] then
                    toolInfo["UNEQUIP"](oldEquippableId, id, world)
                else
                    toolUtil.defaultToolUnequip(oldEquippableId, id, world)
                end
            end
        end

        if not equipperCR.new then continue end
        local equippableId = equipperCR.new.equippableId
        -- local toolState = getToolState()

        if equippableId then
            local equippableC = world:get(equippableId, Components.Equippable)
            local toolName = equippableC.presetName
            local toolInfo = ToolInfos.Catalog[toolName]

            if toolInfo["EQUIP"] then
                toolInfo["EQUIP"](equippableId, id, world)
            else
                toolUtil.defaultToolEquip(equippableId, id, world)
            end
        else
            -- toolState.cleanup = true
            -- if toolState.instance then
            --     toolState.instance:Destroy()
            --     toolState.instance = nil
            --     print("DESTROYED")
            -- end
        end
    end
end