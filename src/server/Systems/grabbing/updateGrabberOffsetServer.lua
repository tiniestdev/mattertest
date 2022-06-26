local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil) 
local Remotes = require(ReplicatedStorage.Remotes)
local Llama = require(ReplicatedStorage.Packages.llama)

local ReplicateGrabberOffset = matterUtil.NetSignalToEvent("ReplicateGrabberOffset", Remotes)
local cframeUtil = require(ReplicatedStorage.Util.cframeUtil)

return function(world)
    for _, player, newOffset in Matter.useEvent(ReplicateGrabberOffset, "Event") do
        if Matter.useThrottle(0.1, player) then
            local playerId = matterUtil.getEntityId(player)
            local characterId = world:get(playerId, Components.Player).characterId
            local grabberC = world:get(characterId, Components.Grabber)
            local rtcC = world:get(characterId, Components.ReplicateToClient)
            if not grabberC then error("wtf") end

            -- TODO: sanitize, sanity check
            if newOffset.Position.Magnitude > grabUtil.MaxGrabDistance then
                newOffset = cframeUtil.getCFrameToPosition(newOffset, newOffset.Position.Unit * grabUtil.MaxGrabDistance)
            end

            -- grabOffsetCFrame = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
            world:insert(characterId, grabberC:patch({
                grabOffsetCFrame = newOffset,
            }), rtcC:patch({
                blacklist = Llama.List.toSet({player}),
            }))
        end
    end
end

