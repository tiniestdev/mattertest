local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local updateEvent = matterUtil.NetSignalToEvent("UpdateAimerPitchYaw", Remotes)

return function(world)
    for _, plr, pitch, yaw in Matter.useEvent(updateEvent, "Event") do
        local characterId = matterUtil.getCharacterIdOfPlayer(plr, world)
        local aimerC = world:get(characterId, Components.Aimer)
        if not aimerC then warn("wtf no aimerC??") end
        world:insert(characterId, aimerC:patch({
            pitch = pitch,
            yaw = yaw,
        }))
    end
end