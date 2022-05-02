local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local grabUtil = {}

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

grabUtil.manageConnection = function(grabberId, grabberC, world)
    local connectionState = grabUtil.getGrabRopeState(grabberId, world)
    -- print("invoked state: ", connectionState)

    if grabberC.grabbableId then
        -- if grabberC.grabbableAttachmentInstance then
        if connectionState.grabbableAtt then
            -- print("stop.")
        else
            print("go.")
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
            newConnection.MaxForce = 2000
            newConnection.MaxVelocity = 100
            newConnection.Responsiveness = 10
            newConnection.ReactionForceEnabled = true
            -- newConnection.Length = 2
            -- newConnection.Restitution = 0.2
            -- newConnection.Visible = true
            newConnection.Parent = grabberC.attachmentInstance

            connectionState.connectionInstance = newConnection
            connectionState.grabberAtt = grabberC.attachmentInstance
            connectionState.grabbableAtt = grabbableAttachment

            print("connected.")
        end
    else
        -- print("LETTING GO!", connectionState)
        for i,v in pairs(connectionState) do
            if connectionState.connectionInstance then
                connectionState.connectionInstance:Destroy()
                connectionState.connectionInstance = nil
            end
            if connectionState.grabbableAtt then
                connectionState.grabbableAtt:Destroy()
                connectionState.grabbableAtt = nil
            end
        end
        -- if (connectionState.connectionInstance) then connectionState.connectionInstance:Destroy() print("D 1") end
        -- if (connectionState.grabberAtt) then connectionState.grabberAtt:Destroy() print("D 2") end
        -- if (connectionState.grabbableAtt) then connectionState.grabbableAtt:Destroy() print("D 3") end
    end
end

return grabUtil