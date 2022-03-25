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
    for i, player in Matter.useEvent(PlayerEvent, "Event") do
        local newPlayerEntityId = PlayerUtil.makePlayerEntity(player, world)
        local teamId = TeamUtil.getUnfilledTeamId(world)
        world:insert(newPlayerEntityId, Components.Teamed({
            teamId = teamId,
        }))

        local payload = replicationUtil.serializeArchetype("Player", newPlayerEntityId, player.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER, world)
        Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, "Player", payload)

        -- print("Sent player payload to " .. player.Name .. ", :", payload)
        -- print("Server id of player is " .. newPlayerEntityId)
    end
end

