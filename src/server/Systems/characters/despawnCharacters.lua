local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local Remotes = require(ReplicatedStorage.Remotes)


local CharacterRemovingEvent = MatterUtil.ObservableToEvent(playerUtil.getLeavingCharactersObservable())

return function(world)
    for i, char in Matter.useEvent(CharacterRemovingEvent, "Event") do
        local id = MatterUtil.getEntityId(char)
        if id then
            world:despawn(id)
        end
    end
end


