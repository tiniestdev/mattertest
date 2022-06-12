local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

return function(world)
    for grabberId, grabberCR in world:queryChanged(Components.Grabber) do
        local state = grabUtil.getServerGrabberState(grabberId, world)

        if grabberCR.new and grabberCR.new.grabbableId and not matterUtil.isNone(grabberCR.new.grabbableId) then
            
            local grabberC = grabberCR.new
            local grabbableId = grabberC.grabbableId
            local grabbableC = world:get(grabbableId, Components.Grabbable)
            if not grabbableC then warn("WTF: grabbableId " .. grabbableId .. " is not in the world") end

            local grabbableInstance = grabbableC.grabbableInstance
            if not grabbableInstance then warn("WTF: grabbableId " .. grabbableId .. " has no grabbableInstance") end
            
            local grabberInstance = grabberC.grabberInstance;
            if not grabberInstance then warn("WTF: grabberId " .. grabberId .. " has no grabberInstance") end

            if not state.GoalAttachment then
                local GoalAttachment = Instance.new("Attachment")
                GoalAttachment.Name = "GrabGoal"
                -- we don't want this to be attached to the player at all
                -- because if we do, physics ownership will be screwy
                GoalAttachment.Parent = workspace.Terrain
                state.GoalAttachment = GoalAttachment
            end
            state.GoalAttachment.WorldCFrame = grabberInstance.CFrame:toWorldSpace(grabberC.grabOffsetCFrame)

            if not state.grabbableAttachment then
                local grabbableAttachment = Instance.new("Attachment")
                grabbableAttachment.Name = "GrabPoint"

                local alignPos = grabUtil.getAlignPos(grabbableAttachment)
                alignPos.Attachment0 = grabbableAttachment
                alignPos.Attachment1 = state.GoalAttachment
                CollectionService:AddTag(alignPos, "ServerOwned")
                local alignRot = grabUtil.getAlignRot(grabbableAttachment)
                alignRot.Attachment0 = grabbableAttachment
                alignRot.Attachment1 = state.GoalAttachment
                CollectionService:AddTag(alignRot, "ServerOwned")

                state.grabbableAttachment = grabbableAttachment
                state.alignPos = alignPos
                state.alignRot = alignRot
            end
            
            local networkOwnedC = world:get(grabbableId, Components.NetworkOwned)
            if matterUtil.isNone(networkOwnedC.networkOwner) then
                state.grabbableAttachment.Parent = grabbableInstance
            else
                state.grabbableAttachment.Parent = nil
            end
            
            state.grabbableAttachment.CFrame = grabberC.grabPointObjectCFrame

            -- grabberInstance = {}; -- Define a specific grab PART to use to calculate offset
            -- grabbableInstance = {}; -- Same (may be redundant cause this can be derived from grabbableId)
            -- grabOffsetCFrame = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
            -- grabPointObjectCFrame = {}; -- for players who click a specific point on the grabbable part to manipulate

            local percent = grabUtil.getEffectPercent(grabberC, grabbableC)

            state.alignPos.MaxForce = grabberC.grabStrength * (percent*percent)
            state.alignPos.MaxVelocity = grabberC.grabVelocity
            state.alignPos.Responsiveness = grabberC.grabResponsiveness

            state.alignRot.MaxAngularVelocity = grabberC.grabStrength * (percent*percent)
            state.alignRot.MaxTorque = grabberC.grabVelocity
            state.alignRot.Responsiveness = grabberC.grabResponsiveness
        else
            for i, v in pairs(state) do
                if typeof(v) == "Instance" then
                    v:Destroy()
                    state[i] = nil
                end
            end
        end
    end
end