local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local grabUtil = {}

local Llama = require(ReplicatedStorage.Packages.llama)

grabUtil.MaxGrabDistance = 4

grabUtil.getGrabberOffsetCastParams = function(world, grabberC, ignoreList)
    local characterId = localUtil.getMyCharacterEntityId(world)

    local ignore = {
        Players.LocalPlayer.Character,
        workspace.CurrentCamera,
    }

    local skeletonC = world:get(characterId, Components.Skeleton)
    if skeletonC then table.insert(ignore, skeletonC.skeletonInstance) end
    local instanceC = world:get(characterId, Components.Instance)
    if instanceC then table.insert(ignore, instanceC.instance) end

    if grabberC.grabbableId then
        local grabbableC = world:get(grabberC.grabbableId, Components.Grabbable)
        local grabbableInstance = grabbableC.grabbableInstance
        table.insert(ignore, grabbableInstance)
    end
    if ignoreList then
        for _, v in ipairs(ignoreList) do
            table.insert(ignore, v)
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignore
    -- params.CollisionGroup = "Default"

    return params
end


grabUtil.getGrabbableEntity = function(instance, world)
    local grabbableId = matterUtil.getEntityId(instance)
    if not grabbableId then
        -- warn("Could not find grabbable entity for instance: ", instance)
        return nil
    end
    local grabbableC = world:get(grabbableId, Components.Grabbable)
    if not grabbableC then
        -- warn("Could not find grabbable component for instance: ", instance)
        return nil
    end
    return grabbableId, grabbableC
end

grabUtil.getGrabRopeState = function(grabberId, world)
    local storage = Matter.useHookState(grabberId, function(storage)
        return grabUtil.grabberCleanupFunction(grabberId, world, storage)
    end)
    return storage
end

grabUtil.getOtherGrabberState = function(grabberId, world)
    local storage = Matter.useHookState(grabberId, function(storage)
        return grabUtil.grabberCleanupFunction(grabberId, world, storage)
    end)
    return storage
end

grabUtil.getServerGrabberState = function(grabberId, world)
    local storage = Matter.useHookState(grabberId, function(storage)
        return grabUtil.grabberCleanupFunction(grabberId, world, storage)
    end)
    return storage
end

grabUtil.grabberCleanupFunction = function(grabberId, world, storage)
    -- clean up
    if not world:contains(grabberId) then
        for i, v in pairs(storage) do
            if typeof(v) == "Instance" then
                v:Destroy()
                storage[i] = nil
            end
        end
        return false
    end
    local grabberC = world:get(grabberId, Components.Grabber)
    if not grabberC then
        for i, v in pairs(storage) do
            if typeof(v) == "Instance" then
                v:Destroy()
                storage[i] = nil
            end
        end
        return false
    end
    return true
end

grabUtil.getServerOwnedGrabConnections = function(instance)
    local connections = {}
    for i,v in ipairs(instance:GetChildren()) do
        if v.Name == "GrabConnection" and CollectionService:HasTag(v, "ServerOwned") then
            table.insert(connections, v)
        end
    end
    return connections
end

grabUtil.getAlignPos = function(parent)
    local alignPos = Instance.new("AlignPosition")
    alignPos.MaxForce = 2000
    alignPos.MaxVelocity = 100
    alignPos.Responsiveness = 30
    alignPos.Parent = parent
    return alignPos
end
grabUtil.getAlignRot = function(parent)
    local alignRot = Instance.new("AlignOrientation")
    alignRot.MaxAngularVelocity = 4000
    alignRot.MaxTorque = 1000
    alignRot.Responsiveness = 30
    alignRot.Parent = parent
    return alignRot
end

grabUtil.getGrabConnections = function(startPart, accum, grabbableIds, world)
    local connected = startPart:GetConnectedParts()
    table.insert(connected, startPart)

    local accum = accum or {}
    local grabbableIds = grabbableIds or {}

    local partId = matterUtil.getEntityId(startPart)
    if (partId and world:contains(partId) and world:get(partId, Components.Grabbable)) then grabbableIds[partId] = true end

    accum[startPart] = true
    for i, connectedPart in ipairs(connected) do
        accum[connectedPart] = true

        partId = matterUtil.getEntityId(startPart)
        if (partId and world:contains(partId) and world:get(partId, Components.Grabbable)) then grabbableIds[partId] = true end

        for _, child in ipairs(connectedPart:GetChildren()) do
            if child:IsA("NoCollisionConstraint") then
                if child.Part0 then
                    local target = child.Part0
                    if not accum[target] then
                        accum, grabbableIds = grabUtil.getGrabConnections(target, accum, grabbableIds, world)
                    end
                end
                if child.Part1 then
                    local target = child.Part1
                    if not accum[target] then
                        accum, grabbableIds = grabUtil.getGrabConnections(target, accum, grabbableIds, world)
                    end
                end
            elseif child:IsA("Constraint") then
                if child.Attachment0 then
                    local target = child.Attachment0.Parent
                    if not accum[target] then
                        accum, grabbableIds = grabUtil.getGrabConnections(target, accum, grabbableIds, world)
                    end
                end
                if child.Attachment1 then
                    local target = child.Attachment1.Parent
                    if not accum[target] then
                        accum, grabbableIds = grabUtil.getGrabConnections(target, accum, grabbableIds, world)
                    end
                end
            end
        end
    end

    return accum, grabbableIds
end

grabUtil.manageClientGrabConnection = function(grabberId, grabberC, world)
    local state = grabUtil.getGrabRopeState(grabberId, world)
    -- if we're the client, we should only be managing our own grab state
    if not world:get(grabberId, Components.Ours) then
        print(grabberId, "is not ours")
        return
    end

    if grabberC.grabbableId then

        if not grabberC.grabbableInstance and grabberC.grabPointObjectCFrame then
            warn("grabbableId is set but grabbableInstance and grabPointObjectCFrame are nil")
        end
        -- Creation of Goal attachment, our source of truth
        -- It's the attachment that the grabbed part will actually follow
        -- and is entirely disconnected from the player's character/grabber
        if not state.GoalAttachment then
            local goalAttachment = Instance.new("Attachment")
            goalAttachment.Name = "GRAB_Goal"
            goalAttachment.Parent = workspace.Terrain
            state.GoalAttachment = goalAttachment
        end

        -- Creation of the GrabbableAttachment, which aligns itself
        -- with the goal attachment
        if not state.GrabbableAttachment then
            local grabbableAttachment = Instance.new("Attachment")
            grabbableAttachment.Name = "GRAB_GrabbableAligner"
            grabbableAttachment.CFrame = grabberC.grabPointObjectCFrame
            grabbableAttachment.Parent = grabberC.grabbableInstance

            local alignPos = grabUtil.getAlignPos(grabbableAttachment)
            alignPos.Attachment0 = grabbableAttachment
            alignPos.Attachment1 = state.GoalAttachment
            local alignRot = grabUtil.getAlignRot(grabbableAttachment)
            alignRot.Attachment0 = grabbableAttachment
            alignRot.Attachment1 = state.GoalAttachment
            
            state.GrabbableAttachment = grabbableAttachment
        end

        -- Creation of the GrabberGuideAttachment, which only ensures that the
        -- grabber doesn't stray too far from the grabbable point by attaching a rope
        -- to the below GrabberAttachment
        if not state.GrabberGuidePart then
            local grabberGuidePart = Instance.new("Part")
            grabberGuidePart.Size = Vector3.new(1,1,1)
            grabberGuidePart.Transparency = 1
            grabberGuidePart.Anchored = true
            grabberGuidePart.CanCollide = false
            grabberGuidePart.Name = "GRAB_GrabberGuidePart"
            grabberGuidePart.Parent = workspace.CurrentCamera
            local fxatt = Instance.new("Attachment")
            fxatt.Parent = grabberGuidePart
            local fx = ReplicatedStorage.Assets.Particles.GrabberFX:Clone()
            fx.Parent = fxatt
            fx.Enabled = true
            state.GrabberGuidePart = grabberGuidePart
        end
        if not state.GrabberGuideAttachment then
            local grabberGuideAttachment = Instance.new("Attachment")
            grabberGuideAttachment.Name = "GRAB_GrabberGuide"
            grabberGuideAttachment.Parent = state.GrabberGuidePart
            state.GrabberGuideAttachment = grabberGuideAttachment
        end
        if not state.GrabberAttachment then
            local grabberAttachment = Instance.new("Attachment")
            grabberAttachment.Name = "GRAB_Grabber"
            grabberAttachment.CFrame = CFrame.new()
            grabberAttachment.Parent = grabberC.grabberInstance
            state.GrabberAttachment = grabberAttachment
        end

        -- i cant find a way to make this rope NOT freeze the character
        -- if not state.GuideRope then
        --     local guideRope = Instance.new("RopeConstraint")
        --     guideRope.Name = "GRAB_GuideRope"
        --     guideRope.Attachment0 = state.GrabberAttachment
        --     guideRope.Attachment1 = state.GrabberGuideAttachment
        --     guideRope.Length = grabUtil.MaxGrabDistance
        --     guideRope.Parent = grabberC.grabberInstance
        --     guideRope.Visible = true
        --     guideRope.Enabled = true
        --     state.GuideRope = guideRope
        -- end

        -- GoalAttachment
        -- GrabbableAttachment
        -- GrabberGuideAttachment
        -- GrabberAttachment
        local grabbableCF = grabberC.grabbableInstance.CFrame
        local grabberCF = grabberC.grabberInstance.CFrame

        -- grabbableId = {};
        -- grabberInstance = {}; -- Define a specific grab PART to use to calculate offset
        -- grabbableInstance = {}; -- Same
        -- grabOffsetCFrame = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
        -- grabPointObjectCFrame = {}; -- for players who click a specific point on the grabbable part to manipulate
        local goalCFrame = grabberCF:toWorldSpace(grabberC.grabOffsetCFrame)
        state.GoalAttachment.WorldCFrame = goalCFrame
        -- state.GrabberGuidePart.CFrame = goalCFrame
        state.GrabberGuidePart.CFrame = grabbableCF:toWorldSpace(grabberC.grabPointObjectCFrame)
    else
        -- we're deleting all our connections
        for i, v in pairs(state) do
            if typeof(v) == "Instance" then
                v:Destroy()
                state[i] = nil
            end
        end
    end
end

return grabUtil