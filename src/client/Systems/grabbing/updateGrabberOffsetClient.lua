local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Remotes = require(ReplicatedStorage.Remotes)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)

local Mouse = Players.LocalPlayer:GetMouse()

return function(world)
    for grabberId, grabberC in world:query(Components.Grabber, Components.Ours) do
        if grabberC.grabbableId then

            -- print(grabberId, "valid:", grabberC.grabbableId)
            -- will always update grabberOffset if it's grabbing something
            local head = localUtil.getHead()
            if not head then return warn("No head.") end
            local hit = localUtil.castMouseRangedHitWithParams(grabUtil.getGrabberOffsetCastParams(world, grabberC), grabUtil.MaxGrabDistance, head.Position)
            if not hit then return end

            local grabberOriginCF = grabberC.attachmentInstance.Parent.CFrame
            local rayOriginCF = head.CFrame
            local direction = (hit - rayOriginCF.Position).Unit
            local grabDistance = math.clamp((hit - rayOriginCF.Position).Magnitude, 0, 4)
            local newWorldOffset = direction * grabDistance

            local newLocalOffset = grabberOriginCF:VectorToObjectSpace(newWorldOffset)

            world:insert(grabberId, grabberC:patch({
                grabberOffset = newLocalOffset,
            }))
            -- print(world:get(grabberId, Components.Grabber).grabberOffset)
        end
    end

    for grabberId, grabberCR in world:queryChanged(Components.Grabber, Components.Ours) do
        if grabberCR.new then
            if grabberCR.new.grabbableId then
                print("got grabbableId:", grabberId, grabberCR.new.grabbableId)
                local newOffset = world:get(grabberId, Components.Grabber).grabberOffset
                grabberCR.new.attachmentInstance.Position = newOffset
                grabberCR.new.attachmentInstance.GrabberFX.Enabled = true

                if Matter.useThrottle(0.5) then
                    Remotes.Client:Get("ReplicateGrabberOffset"):SendToServer(newOffset)
                end
            else
                print("no grabbableId:", grabberId)
                grabberCR.new.attachmentInstance.GrabberFX.Enabled = false
            end
        end
    end
end