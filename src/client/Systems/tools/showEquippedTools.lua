local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

local ToolInfos = require(ReplicatedStorage.ToolInfos)

local function getToolState()
    local storage = Matter.useHookState(nil, function(stg)
        -- print("CLEANUP CALLED")
        if stg.cleanup then
            if stg.instance then
                stg.instance:Destroy()
            end
        else
            return true
        end
    end)
    return storage
end

return function(world)
    for id, equipperCR in world:queryChanged(Components.Equipper) do
        if not equipperCR.new then continue end
        local equippableId = equipperCR.new.equippableId
        local toolState = getToolState()

        if equippableId then
            print("NOTICED:", id, equippableId)
            local equippableC = world:get(equippableId, Components.Equippable)
            local toolName = equippableC.presetName
            local info = ToolInfos.Catalog[toolName]

            print("TOOLSTATE:", toolState)

            if (info.Corporeal.instance) then
                if (not toolState.instance)
                or toolState.instance.Name ~= toolName then
                    local handle = info.Corporeal.instance:Clone()
                    local tool = Instance.new("Tool")
                    local char = world:get(id, Components.Instance).instance
                    tool.Name = toolName
                    handle.Name = "Handle"
                    handle.Parent = tool
                    toolState.instance = tool
                    tool.Parent = char

                    -- todo: weld it to the player's arms i guess. f####
                    --
                    print("MADE NEW TOOL")
                end
            end
        else
            print("NOTICED:", id, "NONE")
            toolState.cleanup = true
            -- if toolState.instance then
            --     toolState.instance:Destroy()
            --     toolState.instance = nil
            --     print("DESTROYED")
            -- end
        end
    end
end