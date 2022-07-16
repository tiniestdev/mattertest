local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local Players = game:GetService("Players")

local function getWeightStore(instance)
    local storage = Matter.useHookState(instance, function(storage)
        -- if storage.cleanup then
            if storage.att then
                storage.att:Destroy()
                storage.att = nil
            end
            if storage.force then
                storage.force:Destroy()
                storage.force = nil
            end
            -- print("cleanup of ", instance)
        -- else
            -- return true
        -- end
    end)
    return storage
end

return function(world)
    for id, grabbableC in world:query(Components.Grabbable) do
        local grabbableInstance = grabbableC.grabbableInstance

        local totalAddedWeight = 0
        local humanoidsTouching = {}

        -- if grabbableInstance.Parent.Name == "Skeleton" then
        --     local char = grabbableInstance.WeldConstraint.Part1.Parent
        --     -- print("CHAR:", char)
        -- end

        -- local touching = grabbableInstance:GetTouchingParts()
        if not grabbableInstance then
            -- this might be valid in case a server part stored in someone's private backpack is inaccessible to other clients
            -- i guess we don't need to worry about this if it's a regular grabbable public part
            continue
        end

        local overlapParams = OverlapParams.new()
        overlapParams.MaxParts = 5;
        local overlapping = workspace:GetPartsInPart(grabbableInstance, overlapParams)

        -- for i, hit in Matter.useEvent(grabbableInstance, "Touched") do
        for i, hit in ipairs(overlapping) do
            -- print("overlapping with ",hit)
            -- check if it's touching a character that owns it
            if not humanoidsTouching[hit.Parent] and hit.Parent:FindFirstChild("Humanoid") then
                humanoidsTouching[hit.Parent] = true
                totalAddedWeight = totalAddedWeight + hit.AssemblyMass
            end
        end

        if totalAddedWeight > 0 then
            -- local weightStore = getWeightStore(grabbableInstance)
            -- print("TAW:", totalAddedWeight)

            local addedForce = grabbableInstance:FindFirstChild("AddedForce")
            if not addedForce then
                local addedAtt = Instance.new("Attachment")
                addedAtt.Name = "AddedAtt"
                addedAtt.Parent = grabbableInstance
                addedForce = Instance.new("VectorForce")
                addedForce.Name = "AddedForce"
                addedForce.Parent = grabbableInstance
                addedForce.Attachment0 = addedAtt
                addedForce.RelativeTo = Enum.ActuatorRelativeTo.World
                addedForce.ApplyAtCenterOfMass = true
                addedForce.Enabled = true
            end
            -- grabbableInstance.Color = Color3.new(1, 0, 0)
            addedForce.Force = Vector3.new(0, -totalAddedWeight * workspace.Gravity, 0)
        else
            if Matter.useThrottle(0.5, grabbableInstance) then
                -- weightStore.cleanup = true
                local addedForce = grabbableInstance:FindFirstChild("AddedForce")
                local addedAtt = grabbableInstance:FindFirstChild("AddedAtt")
                if addedForce then addedForce:Destroy() end
                if addedAtt then addedAtt:Destroy() end
                -- grabbableInstance.Color = Color3.new(0, 1, 0)
            -- else
                -- getWeightStore(grabbableInstance)
            end
        end
    end
end