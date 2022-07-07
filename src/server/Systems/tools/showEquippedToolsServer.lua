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
            if stg.serverInstance then
                stg.serverInstance:Destroy()
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
        if not equipperCR.new then continue end
        local equippableId = equipperCR.new.equippableId
    end
end