local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local Teams = require(ReplicatedStorage.Teams)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

local PlayerEvent = MatterUtil.ObservableToEvent(PlayerUtil.getPlayersObservable())

return function(world)
    for _, player in Matter.useEvent(PlayerEvent, "Event") do
        local newPlayerEntityId = PlayerUtil.makePlayerEntity(player, world)
        local teamId = TeamUtil.getUnfilledTeamId(world)
        world:insert(newPlayerEntityId,
            Components.Teamed({
                teamId = teamId,
            })
        )
    end
end

