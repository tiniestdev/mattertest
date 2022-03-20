local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local Teams = require(ReplicatedStorage.Teams)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

local PlayerEvent = MatterUtil.ObservableToEvent(PlayerUtil.getPlayersObservable())

return function(world)
    for i, player in Matter.useEvent(PlayerEvent, "Event") do
        local id = world:spawn(
            Components.Instance({
                instance = player,
            }),
            Components.Player({
                player = player,
                characterId = nil,
            }),
            Components.Teamed({
                -- teamId = Teams.NameToId["Raiders"],
                teamId = TeamUtil.getUnfilledTeamId(world),
            })
        )
        MatterUtil.setEntityId(player, id)
        CollectionService:AddTag(player, "Player")
    end
end

