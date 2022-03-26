local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local localUtil = {}

function localUtil.getMyPlayerEntity(world)
    local player = Players.LocalPlayer
    local playerC = world:get(player.UserId, Components.Player)
    if not playerC then
        return nil
    end
end

return localUtil