local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Remotes = require(ReplicatedStorage.Remotes)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local drawUtil = require(ReplicatedStorage.Util.drawUtil)

local UPDATES_PER_SECOND = 10

return function(world)
    local charId = localUtil.getMyCharacterEntityId(world)
    if not charId then return end

    for id, aimerC in world:query(Components.Aimer, Components.Ours) do
        -- update our aimer component and keep updating data to the server
        local viewer = aimerC.aimerCFrame or aimerC.aimerInstance.CFrame
        local mouseParams = localUtil.getDefaultLocalCastParams(world)
        local castHit = localUtil.castMouseRangedHitWithParams(mouseParams, 100, viewer.Position)

        local lookCF = CFrame.new(viewer.Position, castHit)
        local calcPitch, calcYaw, calcRoll = viewer:toObjectSpace(lookCF):ToOrientation()
        local calcTarget = castHit

        world:insert(id, aimerC:patch({
            pitch = calcPitch, -- (up and down look) (in degrees)
            yaw = calcYaw, -- (side to side turns) (in degrees)
            roll = calcRoll, -- (tilt) (in degrees, less used)
            target = calcTarget,
        }))

        -- update the server
        if Matter.useThrottle(1/UPDATES_PER_SECOND) then
            Remotes.Client:Get("UpdateAimerPitchYaw"):SendToServer(calcPitch, calcYaw)
        end
    end
end