
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
        local state = grabUtil.getOtherGrabberState(grabberId, world)
        state.otherGrabberId = grabberId

        if grabberCR.new and grabberCR.new.grabbableId and not matterUtil.isNone(grabberCR.new.grabbableId) then
            local grabberC = grabberCR.new
            local grabbableId = grabberC.grabbableId
            local grabbableC = world:get(grabbableId, Components.Grabbable)
            if not grabbableC then warn("WTF: grabbableId " .. grabbableId .. " is not in the world") end

            local grabbableInstance = grabbableC.grabbableInstance
            if not grabbableInstance then warn("WTF: grabbableId " .. grabbableId .. " has no grabbableInstance") end
            
            local grabberInstance = grabberC.grabberInstance;
            if not grabberInstance then warn("WTF: grabberId " .. grabberId .. " has no grabberInstance") end

            if not state.grabPointAttachment then
                local grabPointAttachment = Instance.new("Attachment")
                grabPointAttachment.Parent = grabbableInstance
                state.grabPointAttachment = grabPointAttachment
            end
            state.grabPointAttachment.CFrame = grabberC.grabPointObjectCFrame

            if not state.grabberAttachment then
                local grabberAttachment = Instance.new("Attachment")
                state.grabberAttachment = grabberAttachment
                grabberAttachment.Parent = grabberInstance
                local grabBeam = ReplicatedStorage.Assets.Particles.GrabberBeam:Clone()
                grabBeam.Parent = grabberAttachment
                grabBeam.Attachment0 = grabberAttachment
                grabBeam.Attachment1 = state.grabPointAttachment
                grabBeam.Name = "BEAM"
                state.grabBeam = grabBeam
            end
            
            local percent = grabUtil.getEffectPercent(grabberC, grabbableC)
            state.grabBeam.Transparency = NumberSequence.new(1-percent)
            state.grabBeam.Width0 = percent * 0.1
            state.grabBeam.Width1 = percent * 0.4
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