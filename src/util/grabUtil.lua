local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local grabUtil = {}

grabUtil.MaxGrabDistance = 4

grabUtil.getGrabberOffsetCastParams = function(world, grabberC)
    local characterId = localUtil.getMyCharacterEntityId(world)
    local skeletonC = world:get(characterId, Components.Skeleton)
    local grabbableC = world:get(grabberC.grabbableId, Components.Grabbable)
    local grabbableInstance = grabbableC.grabbableInstance

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {
        Players.LocalPlayer.Character,
        skeletonC.skeletonInstance,
        grabbableInstance,
    }

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
    local storage = Matter.useHookState(grabberId, function()
        -- clean up
        if not world:contains(grabberId) then return false end
        local grabberC = world:get(grabberId, Components.Grabber)
        if not grabberC then return false end
        return true
    end)
    return storage
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

grabUtil.manageConnection = function(grabberId, grabberC, world)
    local connectionState = grabUtil.getGrabRopeState(grabberId, world)
    -- print("invoked state: ", connectionState)

    if not RunService:IsServer() then
        -- if we're the client, we should only be managing our own grab state
        if not world:get(grabberId, Components.Ours) then
            print(grabberId, "is not ours")
            return
        end
    end

    if grabberC.grabbableId then
        -- if grabberC.grabbableAttachmentInstance then
        if connectionState.grabbableAtt then
            -- print("stop.")
        else
            -- automatically generate one and link to it
            local grabbableAttachment = Instance.new("Attachment")
            -- place the attachment on the surface of the grabbable, but
            -- nearby to the grabber

            local grabRayOrigin = grabberC.attachmentInstance.WorldPosition
            local grabbableComponent = world:get(grabberC.grabbableId, Components.Grabbable)
            -- print(grabbableComponent)
            if not grabbableComponent then
                warn("grabbable component not found, ", grabberC.grabbableId)
                return
            end
            local grabbableInstance = grabbableComponent.grabbableInstance
            local grabRayDirection = grabbableInstance.Position - grabRayOrigin
            local grabRayParams = RaycastParams.new()
            grabRayParams.FilterDescendantsInstances = {grabbableInstance}
            grabRayParams.FilterType = Enum.RaycastFilterType.Whitelist

            grabbableAttachment.Name = "GrabbableAttachment"
            grabbableAttachment.Parent = grabbableInstance
            -- world:insert(grabberId, grabberC:patch({
            --     grabbableAttachmentInstance = grabbableAttachment,
            -- }))

            if grabberC.preferLocalPosition then
                grabbableAttachment.Position = grabberC.preferLocalPosition
            else
                local raycastResult = workspace:Raycast(grabRayOrigin, grabRayDirection, grabRayParams)
                if raycastResult then
                    grabbableAttachment.WorldPosition = raycastResult.Position
                else
                    grabbableAttachment.Position = Vector3.new(0, 0, 0)
                end
            end

            -- connect
            local newConnection = Instance.new("AlignPosition")
            newConnection.Name = "GrabConnection"
            newConnection.Attachment0 = grabberC.attachmentInstance
            newConnection.Attachment1 = grabbableAttachment
            newConnection.MaxForce = 4000
            newConnection.MaxVelocity = 100
            newConnection.Responsiveness = 30
            newConnection.ReactionForceEnabled = true
            
            if RunService:IsServer() then
                newConnection.Enabled = false
                CollectionService:AddTag(newConnection, "ServerOwned")
            else
                newConnection.Enabled = true
            end
            newConnection.Parent = grabbableInstance

            connectionState.connectionInstance = newConnection
            connectionState.grabberAtt = grabberC.attachmentInstance
            connectionState.grabbableAtt = grabbableAttachment
        end
    else
        -- print("LETTING GO!", connectionState)
        -- for i,v in pairs(connectionState) do
            if connectionState.connectionInstance then
                connectionState.connectionInstance:Destroy()
                connectionState.connectionInstance = nil
            end
            if connectionState.grabbableAtt then
                connectionState.grabbableAtt:Destroy()
                connectionState.grabbableAtt = nil
            end
        -- end
        -- if (connectionState.connectionInstance) then connectionState.connectionInstance:Destroy() print("D 1") end
        -- if (connectionState.grabberAtt) then connectionState.grabberAtt:Destroy() print("D 2") end
        -- if (connectionState.grabbableAtt) then connectionState.grabbableAtt:Destroy() print("D 3") end
    end
end

return grabUtil