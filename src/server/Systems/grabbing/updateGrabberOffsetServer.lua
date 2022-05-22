local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil) 
local Remotes = require(ReplicatedStorage.Remotes)

local ReplicateGrabberOffset = matterUtil.NetSignalToEvent("ReplicateGrabberOffset", Remotes)

return function(world)
    for i, player, newOffset in Matter.useEvent(ReplicateGrabberOffset, "Event") do
        if Matter.useThrottle(0.2, player) then
            local playerId = matterUtil.getEntityId(player)
            local characterId = world:get(playerId, Components.Player).characterId
            local grabberC = world:get(characterId, Components.Grabber)
            local rtcC = world:get(characterId, Components.ReplicateToClient)
            if not grabberC then error("wtf") end

            -- TODO: sanitize, sanity check
            if newOffset.Magnitude > grabUtil.MaxGrabDistance then
                newOffset = newOffset.Unit * grabUtil.MaxGrabDistance
            end

            world:insert(characterId, grabberC:patch({
                grabberOffset = newOffset,
            }), rtcC:patch({
                doNotReplicateTo = player,
            }))
        end
    end

    for grabberId, grabberCR in world:queryChanged(Components.Grabber) do
        if grabberCR.new then
            if grabberCR.new.grabbableId then
                local newOffset = world:get(grabberId, Components.Grabber).grabberOffset
                grabberCR.new.attachmentInstance.Position = newOffset
                grabberCR.new.attachmentInstance.GrabberFX.Enabled = true
            else
                grabberCR.new.attachmentInstance.GrabberFX.Enabled = false
            end
        end
    end
end

