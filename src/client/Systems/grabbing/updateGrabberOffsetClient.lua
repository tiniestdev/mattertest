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

--[[
    This system takes care of updating the grab offset locally every render frame.
    Mouse drags around and this system writes the offset

    The bottom one actually replicates the grab offset to the server.
]]

return function(world)
    for grabberId, grabberC in world:query(Components.Grabber, Components.Ours) do
        if grabberC.grabbableId then
            local hit = localUtil.castMouseRangedHitWithParams(
                grabUtil.getGrabberOffsetCastParams(world, grabberC),
                grabUtil.MaxGrabDistance,
                grabberC.grabberInstance.Position
            )

            local newLocalOffset = grabberC.grabberInstance.CFrame:toObjectSpace(CFrame.new(hit))
            world:insert(grabberId, grabberC:patch({
                grabOffsetCFrame = newLocalOffset,
            }))

        end
    end

    for grabberId, grabberCR in world:queryChanged(Components.Grabber) do
        if not grabberCR.new then continue end
        if not world:get(grabberId, Components.Ours) then continue end
        if grabberCR.new and grabberCR.new.grabbableId then
            if Matter.useThrottle(0.2) then
                local newOffset = world:get(grabberId, Components.Grabber).grabOffsetCFrame
                Remotes.Client:Get("ReplicateGrabberOffset"):SendToServer(newOffset)
            end
        end
    end

end