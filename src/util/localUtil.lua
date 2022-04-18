local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = {}

function localUtil.getMyPlayerEntityId(world)
    local player = Players.LocalPlayer
    return player.UserId
    -- local player = Players.LocalPlayer
    -- local playerC = world:get(player.UserId, Components.Player)
    -- if not playerC then
    --     return nil
    -- end
    -- return 
end

function localUtil.getMyCharacterEntityId(world)
    for id, characterC, oursC in world:query(Components.Character, Components.Ours) do
        return id
    end
end

return localUtil