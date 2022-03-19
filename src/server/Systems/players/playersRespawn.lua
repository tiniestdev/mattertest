local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local RequestRespawnEvent = MatterUtil.NetSignalToEvent("RequestRespawn", Remotes)

return function(world)
    for i, player in Matter.useEvent(RequestRespawnEvent, "Event") do
        if Matter.useThrottle(1, player) then
            task.spawn(function()
                player:LoadCharacter()
            end)
        end
    end
    -- Upon team change, respawn player
    for id, teamedC, playerC in world:queryChanged(Components.Teamed, Components.Player) do
        task.spawn(function()
            playerC.player:LoadCharacter()
        end)
    end
end
