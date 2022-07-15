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

local function getToolState(discriminator)
    local storage = Matter.useHookState(discriminator, function(stg)
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

return function(world, _, ui)

    for id, equipperC, aimerC, instanceC in world:query(Components.Equipper, Components.Aimer, Components.Instance) do
        local equippableId = equipperC.equippableId
        if not equippableId then continue end
        local char = instanceC.instance
        local torso = char:FindFirstChild("Torso")
        if not torso then continue end
        local rightShoulder = torso:FindFirstChild("Right Shoulder")
        if not rightShoulder then continue end

        -- local xSlide = math.rad(ui.slider(360))
        -- local ySlide = math.rad(ui.slider(360))
        -- local zSlide = math.rad(ui.slider(360))
        -- rightShoulder.Transform = CFrame.Angles(xSlide, ySlide, zSlide) + Vector3.new(0,0.5,0)
        rightShoulder.Transform = CFrame.Angles(0, 0, math.rad(90))
    end

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
        
        -- print("FLAG1")
        local aimerC = world:get(id, Components.Aimer)
        -- print("FLAG2")
        local instanceC = world:get(id, Components.Instance)
        -- print("FLAG3")
        if not (aimerC and instanceC) then continue end
        local char = instanceC.instance
        -- print("FLAG4")
        local torso = char:FindFirstChild("Torso")
        -- print("FLAG5")
        if not torso then continue end
        local rightShoulder = torso:FindFirstChild("Right Shoulder")
        if not rightShoulder then continue end

        if not equipperCR.new then continue end
        local equippableId = equipperCR.new.equippableId

        if equippableId then
            local equippableC = world:get(equippableId, Components.Equippable)
            local toolName = equippableC.presetName
            local toolInfo = ToolInfos.Catalog[toolName]

            if toolInfo["EQUIP"] then
                toolInfo["EQUIP"](equippableId, id, world)
            else
                toolUtil.defaultToolEquip(equippableId, id, world)
            end
            -- print(equipperCR)
            -- rightShoulder.Transform = CFrame.Angles(math.rad(90), 0, 0) + Vector3.new(0,1,0)
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